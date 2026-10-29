-- Catalog: what the app explains. Content is edited in Supabase Studio
-- (the dashboard); the app downloads it once and then delta-syncs by
-- updated_at, so content changes never need an app release.
--
--   categories   roots are sections (Café now, Restaurants later…); children
--                are the chips (Coffee, Frappés…). trait_schema (roots only)
--                drives the taste quiz and the trait pills.
--   items        one drink/dish. Hide it with is_published = false (or
--                delete it): both reach the app through catalog_removed_since.
--   item_terms   extra search words (ar / en / franco). Any change to an
--                item's terms bumps the item, and the app replaces them all.
--
-- Nobody but the service role (Studio, CI) writes. anon reads published rows.

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9_]{1,40}$'),
  name_ar text not null check (char_length(name_ar) between 1 and 60),
  name_en text not null check (char_length(name_en) between 1 and 60),
  icon text check (icon is null or icon ~ '^[a-z0-9_]{1,40}$'),
  trait_schema jsonb check (trait_schema is null or jsonb_typeof(trait_schema) = 'array'),
  sort_order int not null default 0,
  is_published boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint traits_on_sections_only check (parent_id is null or trait_schema is null),
  constraint not_own_parent check (parent_id is distinct from id)
);

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories (id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9_]{1,60}$'),
  menu_name text not null check (char_length(menu_name) between 1 and 80),
  menu_name_ar text not null check (char_length(menu_name_ar) between 1 and 80),
  explanation_ar text not null check (char_length(explanation_ar) between 1 and 300),
  explanation_en text not null check (char_length(explanation_en) between 1 and 300),
  calories int check (calories between 0 and 3000),
  size_ml int check (size_ml between 1 and 3000),
  price_min_egp int check (price_min_egp between 0 and 100000),
  price_max_egp int check (price_max_egp between 0 and 100000),
  price_updated_at date,
  image_path text check (image_path is null or char_length(image_path) <= 300),
  audio_barista_path text check (audio_barista_path is null or char_length(audio_barista_path) <= 300),
  audio_original_path text check (audio_original_path is null or char_length(audio_original_path) <= 300),
  traits jsonb not null default '{}' check (jsonb_typeof(traits) = 'object'),
  is_published boolean not null default true,
  sort_order int not null default 0,
  updated_at timestamptz not null default now(),
  constraint price_range check (price_max_egp is null or price_min_egp is null or price_max_egp >= price_min_egp)
);

create table if not exists public.item_terms (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  term text not null check (char_length(term) between 1 and 60),
  lang text not null check (lang in ('ar', 'en', 'franco')),
  kind text not null default 'name' check (kind in ('name', 'ingredient', 'description')),
  updated_at timestamptz not null default now(),
  unique (item_id, term, lang)
);

-- Rows deleted in Studio, so the app can drop them too (only ids, no content).
create table if not exists public.catalog_tombstones (
  kind text not null check (kind in ('category', 'item')),
  id uuid not null,
  deleted_at timestamptz not null default now(),
  primary key (kind, id)
);

create index if not exists categories_updated_at on public.categories (updated_at);
create index if not exists items_updated_at on public.items (updated_at);
create index if not exists items_category on public.items (category_id);
create index if not exists item_terms_item on public.item_terms (item_id);
create index if not exists tombstones_deleted_at on public.catalog_tombstones (deleted_at);

-- updated_at on every change.
drop trigger if exists touch on public.categories;
create trigger touch before update on public.categories
  for each row execute function public.touch_updated_at();
drop trigger if exists touch on public.items;
create trigger touch before update on public.items
  for each row execute function public.touch_updated_at();
drop trigger if exists touch on public.item_terms;
create trigger touch before update on public.item_terms
  for each row execute function public.touch_updated_at();

-- A change to an item's terms bumps the item, so delta sync picks it up.
create or replace function public.bump_item_for_terms()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.items set updated_at = now()
  where id in (
    select item_id from (select new.item_id union select old.item_id) as changed (item_id)
    where item_id is not null
  );
  return null;
end;
$$;

drop trigger if exists bump_item on public.item_terms;
create trigger bump_item after insert or update or delete on public.item_terms
  for each row execute function public.bump_item_for_terms();

-- Deletes leave a tombstone.
create or replace function public.record_tombstone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  insert into public.catalog_tombstones (kind, id)
  values (tg_argv[0], old.id)
  on conflict (kind, id) do update set deleted_at = now();
  return old;
end;
$$;

drop trigger if exists tombstone on public.categories;
create trigger tombstone after delete on public.categories
  for each row execute function public.record_tombstone('category');
drop trigger if exists tombstone on public.items;
create trigger tombstone after delete on public.items
  for each row execute function public.record_tombstone('item');

-- Row Level Security: read published content, write nothing.
alter table public.categories enable row level security;
alter table public.items enable row level security;
alter table public.item_terms enable row level security;
alter table public.catalog_tombstones enable row level security;

drop policy if exists "Published categories are public" on public.categories;
create policy "Published categories are public"
  on public.categories for select to anon, authenticated
  using (is_published);

drop policy if exists "Published items are public" on public.items;
create policy "Published items are public"
  on public.items for select to anon, authenticated
  using (is_published);

drop policy if exists "Terms of published items are public" on public.item_terms;
create policy "Terms of published items are public"
  on public.item_terms for select to anon, authenticated
  using (exists (
    select 1 from public.items i where i.id = item_id and i.is_published
  ));

-- catalog_tombstones: no policies and no grants; read only through the
-- function below.
revoke all on public.catalog_tombstones from anon, authenticated;

-- What disappeared since the app's last sync: hidden or deleted categories
-- and items, as ids only.
create or replace function public.catalog_removed_since(since timestamptz)
returns table (kind text, id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select 'category', c.id from public.categories c
    where not c.is_published and c.updated_at > since
  union all
  select 'item', i.id from public.items i
    where not i.is_published and i.updated_at > since
  union all
  select t.kind, t.id from public.catalog_tombstones t
    where t.deleted_at > since;
$$;

revoke all on function public.catalog_removed_since(timestamptz) from public;
grant execute on function public.catalog_removed_since(timestamptz) to anon, authenticated;

-- Trigger functions are not callable from the API.
revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.bump_item_for_terms() from public, anon, authenticated;
revoke all on function public.record_tombstone() from public, anon, authenticated;

-- Photos and pronunciation clips: public read (by URL), service-role write.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('item-images', 'item-images', true, 409600, array['image/webp', 'image/jpeg', 'image/png']),
  ('item-audio', 'item-audio', true, 1048576, array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/ogg'])
on conflict (id) do nothing;
