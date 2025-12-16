-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.insulina enable row level security;
alter table public.glicemia enable row level security;
alter table public.eventos enable row level security;

-- Profiles: Users can view and edit their own profile
create policy "Users can view own profile" 
on public.profiles for select 
using ( auth.uid() = id );

create policy "Users can update own profile" 
on public.profiles for update 
using ( auth.uid() = id );

-- Insulin: Users can CRUD their own data
create policy "Users can view own insulin records"
on public.insulina for select
using ( auth.uid() = user_id );

create policy "Users can insert own insulin records"
on public.insulina for insert
with check ( auth.uid() = user_id );

create policy "Users can update own insulin records"
on public.insulina for update
using ( auth.uid() = user_id );

create policy "Users can delete own insulin records"
on public.insulina for delete
using ( auth.uid() = user_id );

-- Glucose: Users can CRUD their own data
create policy "Users can view own glucose records"
on public.glicemia for select
using ( auth.uid() = user_id );

create policy "Users can insert own glucose records"
on public.glicemia for insert
with check ( auth.uid() = user_id );

create policy "Users can update own glucose records"
on public.glicemia for update
using ( auth.uid() = user_id );

create policy "Users can delete own glucose records"
on public.glicemia for delete
using ( auth.uid() = user_id );

-- Events: Users can CRUD their own data
create policy "Users can view own events"
on public.eventos for select
using ( auth.uid() = user_id );

create policy "Users can insert own events"
on public.eventos for insert
with check ( auth.uid() = user_id );

create policy "Users can update own events"
on public.eventos for update
using ( auth.uid() = user_id );

create policy "Users can delete own events"
on public.eventos for delete
using ( auth.uid() = user_id );
