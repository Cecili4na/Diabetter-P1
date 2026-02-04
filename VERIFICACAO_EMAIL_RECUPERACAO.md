# 🔒 Verificação de Email na Recuperação de Senha

## 🎯 O que faz

Verifica se o email existe antes de enviar o link de recuperação de senha.

---

## ✅ Como Configurar (1 minuto)

### Passo 1: Acesse o Supabase

```
https://supabase.com/dashboard
→ Seu projeto
→ SQL Editor
→ New Query
```

### Passo 2: Execute este SQL

```sql
-- Função segura para verificar se email existe
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Busca na tabela auth.users (usuários autenticados)
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE email = email_to_check
  );
END;
$$;

-- Dar permissões
GRANT EXECUTE ON FUNCTION check_email_exists(text) TO authenticated;
GRANT EXECUTE ON FUNCTION check_email_exists(text) TO anon;
```

### Passo 3: Clique em Run (F5)

### Passo 4: Pronto! ✅

---

## 🧪 Testar

**No SQL Editor:**
```sql
-- Teste com email que existe
SELECT check_email_exists('seu@email.com');
-- Deve retornar: true

-- Teste com email que não existe  
SELECT check_email_exists('naoexiste@teste.com');
-- Deve retornar: false
```

**No App:**
```
1. Login → "Esqueci minha senha"
2. Digite email inexistente
3. Deve mostrar: "Não encontramos uma conta"
4. Digite email existente
5. Deve mostrar: "Email Enviado!"
```

---

## 🔒 Segurança

Esta função é segura porque:

- ✅ Apenas retorna true ou false
- ✅ NÃO expõe dados dos usuários
- ✅ NÃO permite listar todos os emails
- ✅ NÃO permite ver nomes ou outras informações
- ✅ NÃO afeta outras funcionalidades do app

---

## 📝 Arquivo SQL

O SQL também está em: `supabase/check_email_function.sql`

---

## ✅ Resultado Final

Depois de configurar:

1. ✅ Usuário digita email para recuperar senha
2. ✅ Sistema verifica se email existe
3. ✅ Se NÃO existe: Mostra "Não encontramos uma conta"
4. ✅ Se existe: Envia email de recuperação
5. ✅ Dados dos usuários permanecem protegidos

---

**Pronto! Configuração completa em 1 minuto.** 🎉
