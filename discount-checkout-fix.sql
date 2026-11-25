begin;
create or replace function public.place_shop_order_discount_v2(p_name text,p_phone text,p_governorate text,p_address text,p_ids uuid[]) returns uuid language plpgsql security definer set search_path='' as $$
declare oid uuid; n integer; amount numeric; snapshot jsonb;
begin
if p_name is null or length(trim(p_name)) not between 2 and 100 or p_phone is null or p_phone !~ '^[0-9]{8}$' or p_address is null or length(trim(p_address)) not between 5 and 300 or p_governorate is null or p_governorate not in ('تونس','أريانة','بن عروس','منوبة','نابل','زغوان','بنزرت','باجة','جندوبة','الكاف','سليانة','سوسة','المنستير','المهدية','صفاقس','القيروان','القصرين','سيدي بوزيد','قابس','مدنين','تطاوين','قفصة','توزر','قبلي') or p_ids is null or cardinality(p_ids) not between 1 and 20 then raise exception 'Invalid order'; end if;
perform id from public.products where id=any(p_ids) order by id for update;
select count(*),sum(coalesce(sale_price,price)),jsonb_agg(jsonb_build_object('id',id,'name',name,'price',coalesce(sale_price,price))) into n,amount,snapshot from public.products where id=any(p_ids) and available and reserved_order is null;
if n<>cardinality(p_ids) then raise exception 'Product unavailable'; end if;
insert into public.orders(customer_name,phone,governorate,address,product_ids,total,items,delivery_fee) values(trim(p_name),p_phone,p_governorate,trim(p_address),p_ids,amount,snapshot,9) returning id into oid;
update public.orders set total=amount,items=snapshot,delivery_fee=9 where id=oid;
if not exists(select 1 from public.orders where id=oid and total=amount and items=snapshot) then raise exception 'Order price mismatch'; end if;
update public.products set reserved_order=oid where id=any(p_ids);
return oid;
end $$;
revoke all on function public.place_shop_order_discount_v2(text,text,text,text,uuid[]) from public;
grant execute on function public.place_shop_order_discount_v2(text,text,text,text,uuid[]) to anon,authenticated;
commit;
