begin;
alter table public.products add column if not exists condition text not null default 'غير محددة';
alter table public.products add column if not exists description text not null default '';
alter table public.products add column if not exists extra_photos text[] not null default '{}';
commit;
