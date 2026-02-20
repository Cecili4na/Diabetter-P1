// @ts-nocheck
// supabase/functions/send_email_notifications/index.ts
// MVP email reminder Edge Function – hardened with idempotency, batch cap & concurrency limit.

import { serve } from "https://deno.land/std@0.177.1/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import nodemailer from "npm:nodemailer@6.9.13";

declare const Deno: any;

// ── Config ──────────────────────────────────────────────────────────────
const SMTP_HOST = Deno.env.get("SMTP_HOST") || "smtp.gmail.com";
const SMTP_PORT = parseInt(Deno.env.get("SMTP_PORT") || "465", 10);
const SMTP_USER = Deno.env.get("SMTP_USER");
const SMTP_PASS = Deno.env.get("SMTP_PASS");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const CRON_SECRET = Deno.env.get("CRON_SECRET");

const MAX_PER_RUN = 200;       // hard cap on emails per invocation
const CONCURRENCY_LIMIT = 10;  // max parallel SMTP sends

// ── Helpers ─────────────────────────────────────────────────────────────

/** Compute the current BRT (UTC-3) slot rounded down to 10-minute buckets. */
function getBrtSlot(): string {
    const brNow = new Date(Date.now() - 3 * 60 * 60 * 1000);
    const hh = brNow.getUTCHours().toString().padStart(2, "0");
    const rawMin = brNow.getUTCMinutes();
    const mm = (Math.floor(rawMin / 10) * 10).toString().padStart(2, "0");
    return `${hh}:${mm}`;
}

/** Today's date in YYYY-MM-DD (BRT). */
function getBrtDate(): string {
    const brNow = new Date(Date.now() - 3 * 60 * 60 * 1000);
    return brNow.toISOString().slice(0, 10);
}

/** Process items with a concurrency limit. */
async function mapWithConcurrency<T, R>(
    items: T[],
    limit: number,
    fn: (item: T) => Promise<R>,
): Promise<R[]> {
    const results: R[] = [];
    let index = 0;

    async function worker() {
        while (index < items.length) {
            const i = index++;
            results[i] = await fn(items[i]);
        }
    }

    const workers = Array.from({ length: Math.min(limit, items.length) }, () => worker());
    await Promise.all(workers);
    return results;
}

// ── Main handler ────────────────────────────────────────────────────────

serve(async (req: Request) => {
    try {
        // Auth check
        const authHeader = req.headers.get("Authorization");
        if (authHeader !== `Bearer ${CRON_SECRET}`) {
            return new Response("Unauthorized", { status: 401 });
        }

        if (!SMTP_USER || !SMTP_PASS || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
            throw new Error("Missing required env vars (SMTP_USER, SMTP_PASS, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)");
        }

        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        const slot = getBrtSlot();
        const today = getBrtDate();

        // ── 1. Find users scheduled for this slot ──────────────────────────
        const { data: users, error: queryErr } = await supabase
            .from("profiles")
            .select("id, email, nome, horarios_notificacao")
            .contains("horarios_notificacao", [slot]);

        if (queryErr) throw queryErr;

        if (!users || users.length === 0) {
            return json({ slot, matched: 0, attempted: 0, sent: 0, skipped: 0, errors: 0 });
        }

        // ── 2. Cap the batch ───────────────────────────────────────────────
        const batch = users.slice(0, MAX_PER_RUN);

        // ── 3. SMTP transporter (reused for the whole run) ─────────────────
        const transporter = nodemailer.createTransport({
            host: SMTP_HOST,
            port: SMTP_PORT,
            secure: SMTP_PORT === 465,
            auth: { user: SMTP_USER, pass: SMTP_PASS },
        });

        // ── 4. Send with idempotency + concurrency limit ───────────────────
        let sent = 0;
        let skipped = 0;
        let errors = 0;

        const sendResults = await mapWithConcurrency(batch, CONCURRENCY_LIMIT, async (user) => {
            if (!user.email) { skipped++; return "no_email"; }

            // Attempt idempotent claim: insert … on conflict do nothing
            const { data: inserted, error: insertErr } = await supabase
                .from("email_reminder_sends")
                .insert({ user_id: user.id, slot, send_date: today, status: "sent" })
                .select("id")
                .maybeSingle();

            if (insertErr) {
                // Unique constraint violation → already sent
                skipped++;
                return "duplicate";
            }
            if (!inserted) {
                // on conflict do nothing returns null → duplicate
                skipped++;
                return "duplicate";
            }

            // Send email
            try {
                await transporter.sendMail({
                    from: `"Diabetter" <${SMTP_USER}>`,
                    to: user.email,
                    subject: "Diabetter – Lembrete de Medição",
                    html: buildEmailHtml(user.nome, slot),
                });
                sent++;
                return "sent";
            } catch (sendErr) {
                // Mark the row as failed so it can be retried later
                await supabase
                    .from("email_reminder_sends")
                    .update({ status: "failed" })
                    .eq("id", inserted.id);
                errors++;
                console.error(`SMTP error for ${user.id}:`, sendErr);
                return "error";
            }
        });

        return json({
            slot,
            matched: users.length,
            attempted: batch.length,
            sent,
            skipped,
            errors,
        });

    } catch (err) {
        console.error("Edge function error:", err);
        return json({ error: err instanceof Error ? err.message : String(err) }, 500);
    }
});

// ── Utilities ───────────────────────────────────────────────────────────

function json(body: Record<string, unknown>, status = 200) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
    });
}

function buildEmailHtml(nome: string | null, slot: string): string {
    return `
    <div style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;padding:20px;">
      <h2 style="color:#0056b3;margin-top:0;">Olá, ${nome || "Usuário"}</h2>
      <p>Este é um lembrete automático do seu aplicativo <strong>Diabetter</strong>.</p>
      <p>Está na hora da sua medição de glicemia programada para as <strong style="color:#e91e63;">${slot}</strong>.</p>
      <br/>
      <p>Acesse o aplicativo para registrar sua medição e manter seu acompanhamento em dia!</p>
      <hr style="border:none;border-top:1px solid #eee;margin:20px 0;"/>
      <p style="font-size:12px;color:#999;margin-bottom:0;">Em caso de dúvidas, contate support@diabetter.com</p>
    </div>
  `;
}
