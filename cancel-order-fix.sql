begin;
create or replace function public.cancel_shop_order(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
if not coalesce(public.is_shop_admin(),false) then raise exception 'Access denied'; end if;
update public.orders set status='cancelled' where id=p_id and status not in ('delivered','cancelled');
if not found then raise exception 'Order not cancellable'; end if;
update public.products set reserved_order=null where reserved_order=p_id;
end $$;
revoke all on function public.cancel_shop_order(uuid) from public;
grant execute on function public.cancel_shop_order(uuid) to authenticated;
commit;