begin;
create table if not exists public.shop_private_expenses(id uuid primary key default gen_random_uuid(), expense_date date not null, description text not null check(length(trim(description)) between 1 and 200), amount numeric(12,3) not null check(amount>0));
alter table public.shop_private_expenses enable row level security;
revoke all on public.shop_private_expenses from public,anon,authenticated;
grant select,insert,delete on public.shop_private_expenses to authenticated;
drop policy if exists admin_expenses on public.shop_private_expenses;
create policy admin_expenses on public.shop_private_expenses for all to authenticated using (public.is_shop_admin()) with check (public.is_shop_admin());
commit;