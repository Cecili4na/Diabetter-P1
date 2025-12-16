create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email, nome, termos_aceitos)
  values (
    new.id, 
    new.email, 
    coalesce(new.raw_user_meta_data->>'nome', ''),
    coalesce((new.raw_user_meta_data->>'termos_aceitos')::boolean, false)
  );
  return new;
exception when others then
  -- Prevent the Trigger from blocking the SignUp if it fails
  -- Log the error (visible in Supabase Database Logs)
  raise warning 'Profile creation failed for user %: %', new.id, SQLERRM;
  return new;
end;
$$ language plpgsql security definer;
