begin;
alter table public.orders add column if not exists governorate text;
alter table public.orders add column if not exists total numeric(12,3);
alter table public.orders add column if not exists items jsonb;
alter table public.orders add column if not exists delivery_fee numeric(12,3) not null default 0;
alter table public.orders add column if not exists payable_total numeric(12,3) generated always as (total + delivery_fee) stored;
create or replace function public.place_shop_order(p_name text,p_phone text,p_governorate text,p_address text,p_ids uuid[]) returns uuid language plpgsql security definer set search_path='' as $$
declare oid uuid; n integer; amount numeric; snapshot jsonb;
begin
if p_name is null or length(trim(p_name)) not between 2 and 100 or p_phone is null or p_phone !~ '^[0-9]{8}$' or p_address is null or length(trim(p_address)) not between 5 and 300 or p_governorate is null or p_governorate not in ('تونس','أريانة','بن عروس','منوبة','نابل','زغوان','بنزرت','باجة','جندوبة','الكاف','سليانة','سوسة','المنستير','المهدية','صفاقس','القيروان','القصرين','سيدي بوزيد','قابس','مدنين','تطاوين','قفصة','توزر','قبلي') or p_ids is null or cardinality(p_ids) not between 1 and 20 then raise exception 'Invalid order'; end if;
perform id from public.products where id=any(p_ids) order by id for update;
select count(*),sum(price),jsonb_agg(jsonb_build_object('id',id,'name',name,'price',price)) into n,amount,snapshot from public.products where id=any(p_ids) and available;
if n<>cardinality(p_ids) then raise exception 'Product unavailable'; end if;
insert into public.orders(customer_name,phone,governorate,address,product_ids,total,items,delivery_fee) values(trim(p_name),p_phone,p_governorate,trim(p_address),p_ids,amount,snapshot,9) returning id into oid;
return oid;
end $$;
revoke all on function public.place_shop_order(text,text,text,text,uuid[]) from public;
grant execute on function public.place_shop_order(text,text,text,text,uuid[]) to anon,authenticated;
commit;
