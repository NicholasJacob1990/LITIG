-- Ensure lawyers table exists with correct structure
create table if not exists public.lawyers (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    oab_number text,
    primary_area text,
    specialties text[],
    avatar_url text,
    is_available boolean default true,
    rating numeric default 0,
    lat numeric,
    lng numeric,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Insert sample data if table is empty
insert into public.lawyers (name, oab_number, primary_area, specialties, avatar_url, is_available, rating, lat, lng)
select 
    'Dr. Maria Silva',
    'OAB/SP 123456',
    'Direito Trabalhista',
    array['Direito Trabalhista', 'Direito Previdenciário'],
    'https://i.pravatar.cc/150?u=maria',
    true,
    4.5,
    -23.5505,
    -46.6333
where not exists (select 1 from public.lawyers limit 1);

insert into public.lawyers (name, oab_number, primary_area, specialties, avatar_url, is_available, rating, lat, lng)
select 
    'Dr. João Santos',
    'OAB/SP 654321',
    'Direito Civil',
    array['Direito Civil', 'Direito de Família'],
    'https://i.pravatar.cc/150?u=joao',
    true,
    4.8,
    -23.5605,
    -46.6433
where (select count(*) from public.lawyers) < 2;

-- Enable RLS
alter table public.lawyers enable row level security;

-- Create policy for public read access
do $$
begin
    if not exists (
        select 1 from pg_policies 
        where schemaname = 'public' 
        and tablename = 'lawyers' 
        and policyname = 'Allow public read access'
    ) then
        create policy "Allow public read access" on public.lawyers
            for select using (true);
    end if;
end $$; 