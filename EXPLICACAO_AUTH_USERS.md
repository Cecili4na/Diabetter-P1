# 📚 Diferença: auth.users vs profiles

## 🎯 Entendendo as Tabelas

### `auth.users` (Tabela de Autenticação)
- **O que é:** Tabela gerenciada pelo Supabase Auth
- **Onde fica:** Schema `auth` (sistema)
- **O que armazena:**
  - ✅ Email
  - ✅ Senha (criptografada)
  - ✅ Status de confirmação
  - ✅ Tokens de autenticação
  - ✅ Metadados de autenticação

**Criado quando:** Usuário faz signup

### `public.profiles` (Tabela de Perfil)
- **O que é:** Tabela criada por você
- **Onde fica:** Schema `public` (seu banco)
- **O que armazena:**
  - ✅ Nome
  - ✅ Tipo de diabetes
  - ✅ Configurações
  - ✅ Preferências
  - ✅ Dados do perfil

**Criado quando:** Trigger após signup cria o perfil

---

## 🔄 Fluxo de Cadastro

```
1. Usuário faz signup
   ↓
2. Supabase cria registro em auth.users
   ↓
3. Trigger "on_auth_user_created" é acionado
   ↓
4. Trigger cria registro em public.profiles
```

---

## 🤔 Qual usar para verificar email?

### Opção 1: `auth.users` (Recomendado) ✅

```sql
SELECT 1 FROM auth.users WHERE email = 'teste@email.com'
```

**Vantagens:**
- ✅ Fonte oficial de usuários
- ✅ Sempre atualizado
- ✅ Inclui usuários que confirmaram email
- ✅ Inclui usuários que NÃO confirmaram email
- ✅ Mais confiável

**Use quando:** Quer saber se usuário existe no sistema

### Opção 2: `public.profiles` ❌

```sql
SELECT 1 FROM public.profiles WHERE email = 'teste@email.com'
```

**Desvantagens:**
- ⚠️ Pode não existir se trigger falhou
- ⚠️ Pode estar dessincronizado
- ⚠️ Depende do trigger funcionar

**Use quando:** Quer dados específicos do perfil

---

## 🎯 Para Recuperação de Senha

**Use `auth.users`** porque:

1. ✅ É a tabela oficial de autenticação
2. ✅ Supabase usa essa tabela para enviar emails
3. ✅ Mais confiável
4. ✅ Não depende de triggers

---

## 📊 Comparação

| Aspecto | auth.users | public.profiles |
|---------|-----------|-----------------|
| Gerenciado por | Supabase | Você |
| Sempre existe | ✅ Sim | ⚠️ Depende do trigger |
| Tem email | ✅ Sim | ✅ Sim (copiado) |
| Tem senha | ✅ Sim | ❌ Não |
| Tem nome | ❌ Não | ✅ Sim |
| Tem configurações | ❌ Não | ✅ Sim |
| Para autenticação | ✅ Use esta | ❌ Não |
| Para dados do perfil | ❌ Não | ✅ Use esta |

---

## ✅ Função Corrigida

A função agora busca em `auth.users`:

```sql
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Busca na tabela auth.users (fonte oficial)
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE email = email_to_check
  );
END;
$$;
```

---

## 🔒 Segurança

Ambas as abordagens são seguras quando usadas com função SQL:

- ✅ Função retorna apenas true/false
- ✅ Não expõe dados
- ✅ `SECURITY DEFINER` permite acesso controlado

---

## 📝 Resumo

**Para verificar se email existe (recuperação de senha):**
→ Use `auth.users` ✅

**Para buscar dados do perfil (nome, configurações):**
→ Use `public.profiles` ✅

---

**Conclusão:** A função foi corrigida para usar `auth.users`, que é a fonte oficial e mais confiável! ✅
