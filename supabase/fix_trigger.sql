-- Function to handle new user signup
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email, nome, termos_aceitos)
  values (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'nome',
    (new.raw_user_meta_data->>'termos_aceitos')::boolean
  );
  return new;
end;
$$ language plpgsql security definer;
