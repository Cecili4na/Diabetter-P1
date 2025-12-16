-- Create a table for public profiles (extends auth.users)
create table public.profiles (
  id uuid not null references auth.users(id) on delete cascade,
  nome text,
  email text, -- Optional: redundant with auth.users but useful for queries
  tipo_diabetes text,
  termos_aceitos boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  primary key (id)
);

-- Insulin Records
create table public.insulina (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  quantidade numeric not null, -- Quantity in units
  horario timestamptz not null default now(),
  tipo text, -- e.g., 'Basal', 'Bolus'
  parte_corpo text, -- e.g., 'Abdomen', 'Braço'
  created_at timestamptz default now()
);

-- Glucose Readings
create table public.glicemia (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  quantidade numeric not null, -- e.g., mg/dL
  horario timestamptz not null default now(),
  created_at timestamptz default now()
);

-- Events / Notes
create table public.eventos (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  titulo text not null,
  descricao text,
  horario timestamptz not null default now(),
  created_at timestamptz default now()
);
