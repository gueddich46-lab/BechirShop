begin;
alter table public.orders add column if not exists governorate text;
alter table public.orders add column if not exists total numeric(12,3);
alter table public.orders add column if not exists items jsonb;
alter table public.orders add column if not exists delivery_fee numeric(12,3) not null default 0;
alter table public.orders add column if not exists payable_total numeric(12,3) generated always as (total + delivery_fee) stored;
alter table public.products add column if not exists reserved_order uuid references public.orders(id) on delete set null;
create or replace function public.place_shop_order(p_name text,p_phone text,p_governorate text,p_address text,p_ids uuid[]) returns uuid language plpgsql security definer set search_path='' as $$
declare oid uuid; n integer; amount numeric; snapshot jsonb;
begin
if p_name is null or length(trim(p_name)) not between 2 and 100 or p_phone is null or p_phone !~ '^[0-9]{8}$' or p_address is null or length(trim(p_address)) not between 5 and 300 or p_governorate is null or p_governorate not in ('تونس','أريانة','بن عروس','منوبة','نابل','زغوان','بنزرت','باجة','جندوبة','الكاف','سليانة','سوسة','المنستير','المهدية','صفاقس','القيروان','القصرين','سيدي بوزيد','قابس','مدنين','تطاوين','قفصة','توزر','قبلي') or p_ids is null or cardinality(p_ids) not between 1 and 20 then raise exception 'Invalid order'; end if;
perform id from public.products where id=any(p_ids) order by id for update;
select count(*),sum(price),jsonb_agg(jsonb_build_object('id',id,'name',name,'price',price)) into n,amount,snapshot from public.products where id=any(p_ids) and available and reserved_order is null;
if n<>cardinality(p_ids) then raise exception 'Product unavailable'; end if;
insert into public.orders(customer_name,phone,governorate,address,product_ids,total,items,delivery_fee) values(trim(p_name),p_phone,p_governorate,trim(p_address),p_ids,amount,snapshot,9) returning id into oid;
update public.products set reserved_order=oid where id=any(p_ids);
return oid;
end $$;
revoke all on function public.place_shop_order(text,text,text,text,uuid[]) from public;
grant execute on function public.place_shop_order(text,text,text,text,uuid[]) to anon,authenticated;
create or replace function public.shop_release_reservation() returns trigger language plpgsql security definer set search_path='' as $reservation$
begin
if TG_OP='DELETE' then
if old.status not in ('cancelled','delivered') then raise exception 'Cancel or deliver order before deleting'; end if;
return old;
end if;
if old.status in ('cancelled','delivered') and new.status is distinct from old.status then raise exception 'Final order status cannot be reopened'; end if;
if new.status='cancelled' then update public.products set reserved_order=null where reserved_order=old.id;
elsif new.status='delivered' then update public.products set available=false,reserved_order=null where reserved_order=old.id;
end if;
return new;
end $reservation$;
drop trigger if exists shop_order_reservation on public.orders;
create trigger shop_order_reservation before update of status or delete on public.orders for each row execute function public.shop_release_reservation();
commit;
