begin;
grant delete on public.orders to authenticated;
drop policy if exists "admin delete orders" on public.orders;
create policy "admin delete orders" on public.orders for delete to authenticated using (public.is_shop_admin());
commit;
