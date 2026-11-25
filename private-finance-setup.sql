begin;
create table if not exists public.shop_private_costs(product_id uuid primary key, cost numeric(12,3) not null check(cost>=0), extra numeric(12,3) not null default 0 check(extra>=0));
create table if not exists public.shop_private_sales(order_id uuid primary key, delivered_at timestamptz not null default now(), cost numeric(12,3), extra numeric(12,3));
alter table public.shop_private_costs enable row level security;
alter table public.shop_private_sales enable row level security;
revoke all on public.shop_private_costs,public.shop_private_sales from public,anon,authenticated;
grant select,insert,update on public.shop_private_costs to authenticated;
grant select on public.shop_private_sales to authenticated;
drop policy if exists admin_costs on public.shop_private_costs;
create policy admin_costs on public.shop_private_costs for all to authenticated using (public.is_shop_admin()) with check (public.is_shop_admin());
drop policy if exists admin_sales on public.shop_private_sales;
create policy admin_sales on public.shop_private_sales for select to authenticated using (public.is_shop_admin());
create or replace function public.shop_snapshot_costs() returns trigger language plpgsql security definer set search_path='' as $$
begin
if new.status='delivered' and old.status is distinct from new.status then
insert into public.shop_private_sales(order_id,cost,extra)
select new.id,case when count(c.product_id)=cardinality(new.product_ids) then sum(c.cost) end,case when count(c.product_id)=cardinality(new.product_ids) then sum(c.extra) end
from unnest(new.product_ids) as p(id) left join public.shop_private_costs c on c.product_id=p.id
on conflict(order_id) do nothing;
end if;
return new;
end $$;
revoke all on function public.shop_snapshot_costs() from public,anon,authenticated;
drop trigger if exists shop_snapshot_costs on public.orders;
create trigger shop_snapshot_costs after update of status on public.orders for each row execute function public.shop_snapshot_costs();
commit;