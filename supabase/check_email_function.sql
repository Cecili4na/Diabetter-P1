-- Função para verificar se um email existe no sistema de autenticação
-- Execute este SQL no Supabase Dashboard → SQL Editor

-- Drop function if exists
DROP FUNCTION IF EXISTS check_email_exists(text);

-- Create function
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Busca na tabela auth.users (onde ficam os usuários autenticados)
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE email = email_to_check
  );
END;
$$;

-- Grant execute permission to authenticated and anon users
GRANT EXECUTE ON FUNCTION check_email_exists(text) TO authenticated;
GRANT EXECUTE ON FUNCTION check_email_exists(text) TO anon;

-- Test the function (optional)
-- SELECT check_email_exists('teste@exemplo.com');
