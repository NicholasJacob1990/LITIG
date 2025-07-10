-- supabase/migrations/20250706000000_setup_cases_and_messages.sql

-- 1. Create Messages Table if it doesn't exist
create table if not exists public.messages (
    id uuid primary key default gen_random_uuid(),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    case_id uuid references public.cases(id) on delete cascade not null,
    user_id uuid references auth.users(id) on delete cascade not null,
    content text not null,
    read boolean default false not null
);

-- 2. Grant usage for the messages table
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on table public.messages to postgres, anon, authenticated, service_role;

-- 3. Enable RLS for messages
alter table public.messages enable row level security;

-- 4. Create RLS policies for messages
-- Users can see messages in cases they are part of.
create policy "Users can view messages in their own cases"
on public.messages for select
using (
    case_id in (
        select id from public.cases where client_id = auth.uid() or lawyer_id = auth.uid()
    )
);

-- Users can insert messages in cases they are part of.
create policy "Users can insert messages in their own cases"
on public.messages for insert
with check (
    (
        case_id in (
            select id from public.cases where client_id = auth.uid() or lawyer_id = auth.uid()
        )
    ) and (user_id = auth.uid())
);

-- Users can update their own messages (e.g., to mark as read)
create policy "Users can update their own messages"
on public.messages for update
using ( auth.uid() = user_id );


-- 5. Create the RPC function to get cases for a user
-- Drop existing function first to avoid conflicts
drop function if exists get_user_cases(uuid);

create or replace function get_user_cases(p_user_id uuid)
returns table (
    id uuid,
    created_at timestamp with time zone,
    client_id uuid,
    lawyer_id uuid,
    status text,
    area text,
    summary_ai jsonb,
    unread_messages bigint,
    client_name text,
    lawyer_name text
)
language plpgsql
security definer
as $$
begin
    return query
    select
        c.id,
        c.created_at,
        c.client_id,
        c.lawyer_id,
        c.status,
        c.area,
        c.summary_ai,
        (select count(*) from public.messages m where m.case_id = c.id and m.read = false and m.user_id <> p_user_id) as unread_messages,
        (select u.raw_user_meta_data->>'full_name' from auth.users u where u.id = c.client_id) as client_name,
        (select u.raw_user_meta_data->>'full_name' from auth.users u where u.id = c.lawyer_id) as lawyer_name
    from
        public.cases as c
    where
        c.client_id = p_user_id or c.lawyer_id = p_user_id
    order by
        c.created_at desc;
end;
$$; 