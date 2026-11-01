-- Generic items: «يعني إيه؟» explains any word or thing, café drinks are
-- only the first section. Every item keeps the same core (name, «يعني»,
-- explanation, image, clips, search terms) and adds ONE kind of details,
-- set by its section:
--
--   categories.detail_kind     recipe | story | usage (sections only)
--   categories.details_title_* what the details are called there
--                              («طريقة التحضير», «الحكاية», «إزاي تستخدمها»)
--   items.details              {kind, …}, checked by item_details_valid()
--   items.audio_spoken_path    the name as people say it (was the barista)
--   traits.calories / size_ml  drinks only, so they're traits now
--
-- Installed app versions still read recipe, audio_barista_path, calories,
-- size_ml and price_*: those columns stay, and a trigger keeps them in step
-- with the new ones (either side can be edited in Studio). They're dropped
-- in a later migration, once a forced update has moved every phone past
-- this version (docs/decisions/0005-generic-items.md).

-- 1..max_steps steps, each with a title in both languages.
create or replace function public.item_detail_steps_valid(steps jsonb, max_steps int)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(jsonb_typeof(steps) = 'array', false)
    and jsonb_array_length(steps) between 1 and max_steps
    and not exists (
      select 1 from jsonb_array_elements(steps) s
      where jsonb_typeof(s) <> 'object'
        or jsonb_typeof(s -> 'title_ar') is distinct from 'string'
        or jsonb_typeof(s -> 'title_en') is distinct from 'string'
        or char_length(s ->> 'title_ar') not between 1 and 60
        or char_length(s ->> 'title_en') not between 1 and 60
    );
$$;

-- 1..6 sections, each a title and 1..8 lines in both languages.
create or replace function public.item_detail_sections_valid(sections jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(jsonb_typeof(sections) = 'array', false)
    and jsonb_array_length(sections) between 1 and 6
    and not exists (
      select 1 from jsonb_array_elements(sections) s
      where jsonb_typeof(s) <> 'object'
        or jsonb_typeof(s -> 'title_ar') is distinct from 'string'
        or jsonb_typeof(s -> 'title_en') is distinct from 'string'
        or char_length(s ->> 'title_ar') not between 1 and 40
        or char_length(s ->> 'title_en') not between 1 and 40
        or jsonb_typeof(s -> 'lines_ar') is distinct from 'array'
        or jsonb_typeof(s -> 'lines_en') is distinct from 'array'
        or jsonb_array_length(s -> 'lines_ar') not between 1 and 8
        or jsonb_array_length(s -> 'lines_en') not between 1 and 8
        or exists (
          select 1 from jsonb_array_elements((s -> 'lines_ar') || (s -> 'lines_en')) l
          where jsonb_typeof(l) <> 'string' or char_length(l #>> '{}') not between 1 and 200
        )
    );
$$;

-- Is `d` a valid `items.details`? Pure and immutable, so a check constraint
-- can use it. Shapes per kind are in docs/content_guide.md.
create or replace function public.item_details_valid(d jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select d is null or (
    jsonb_typeof(d) = 'object'
    and pg_column_size(d) <= 16384
    and case d ->> 'kind'
      when 'recipe' then
        jsonb_typeof(d -> 'minutes') = 'number'
        and jsonb_typeof(d -> 'layers') = 'array'
        and jsonb_array_length(d -> 'layers') between 1 and 6
        and public.item_detail_steps_valid(d -> 'steps', 8)
      when 'story' then
        public.item_detail_steps_valid(d -> 'steps', 12)
        and (d -> 'sections' is null or public.item_detail_sections_valid(d -> 'sections'))
      when 'usage' then
        public.item_detail_sections_valid(d -> 'sections')
      else false
    end
  );
$$;

revoke all on function public.item_details_valid(jsonb) from public, anon, authenticated;
revoke all on function public.item_detail_steps_valid(jsonb, int) from public, anon, authenticated;
revoke all on function public.item_detail_sections_valid(jsonb) from public, anon, authenticated;

-- Sections: their kind of details and its name.
alter table public.categories
  add column if not exists detail_kind text
    check (detail_kind is null or detail_kind in ('recipe', 'story', 'usage')),
  add column if not exists details_title_ar text
    check (details_title_ar is null or char_length(details_title_ar) between 1 and 40),
  add column if not exists details_title_en text
    check (details_title_en is null or char_length(details_title_en) between 1 and 40);

alter table public.categories drop constraint if exists details_on_sections_only;
alter table public.categories add constraint details_on_sections_only check (
  parent_id is null
  or (detail_kind is null and details_title_ar is null and details_title_en is null)
);

update public.categories
set detail_kind = 'recipe',
  details_title_ar = 'طريقة التحضير',
  details_title_en = 'How it''s made'
where slug = 'cafe' and parent_id is null and detail_kind is null;

-- Items: details, the spoken clip.
alter table public.items
  add column if not exists details jsonb
    check (public.item_details_valid(details)),
  add column if not exists audio_spoken_path text
    check (audio_spoken_path is null or char_length(audio_spoken_path) <= 300);

comment on column public.items.recipe is
  'Deprecated: read by app versions before generic items. Kept in step with details by items_legacy_columns.';
comment on column public.items.audio_barista_path is
  'Deprecated: kept in step with audio_spoken_path.';
comment on column public.items.calories is
  'Deprecated: kept in step with traits.calories.';
comment on column public.items.size_ml is
  'Deprecated: kept in step with traits.size_ml.';
comment on column public.items.price_min_egp is
  'Deprecated: prices are not shown. Dropped with the other old columns.';

-- A whole number trait in range, else null (bad content never blocks a save).
create or replace function public.item_trait_int(traits jsonb, key text, lo int, hi int)
returns int
language sql
immutable
set search_path = ''
as $$
  select case
    when jsonb_typeof(traits -> key) = 'number'
      and (traits ->> key) ~ '^[0-9]{1,5}$'
      and (traits ->> key)::int between lo and hi
    then (traits ->> key)::int
  end;
$$;

-- Keeps the old columns and the new ones in step. On insert, and when the
-- new side changed, the old side follows; when only the old side changed
-- (an old script, a Studio edit), the new side follows.
create or replace function public.items_legacy_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  details_changed boolean := tg_op = 'INSERT' or new.details is distinct from old.details;
  recipe_changed boolean := tg_op = 'UPDATE' and new.recipe is distinct from old.recipe;
  spoken_changed boolean := tg_op = 'INSERT' or new.audio_spoken_path is distinct from old.audio_spoken_path;
  barista_changed boolean := tg_op = 'UPDATE' and new.audio_barista_path is distinct from old.audio_barista_path;
  traits_changed boolean := tg_op = 'INSERT' or new.traits is distinct from old.traits;
  numbers_changed boolean := tg_op = 'UPDATE'
    and (new.calories is distinct from old.calories or new.size_ml is distinct from old.size_ml);
begin
  -- details ↔ recipe
  if tg_op = 'INSERT' and new.details is null and new.recipe is not null then
    new.details := jsonb_build_object('kind', 'recipe') || new.recipe;
  elsif details_changed then
    new.recipe := case when new.details ->> 'kind' = 'recipe' then new.details - 'kind' end;
  elsif recipe_changed then
    new.details := case when new.recipe is not null
      then jsonb_build_object('kind', 'recipe') || new.recipe end;
  end if;

  -- audio_spoken_path ↔ audio_barista_path
  if tg_op = 'INSERT' and new.audio_spoken_path is null then
    new.audio_spoken_path := new.audio_barista_path;
  elsif spoken_changed then
    new.audio_barista_path := new.audio_spoken_path;
  elsif barista_changed then
    new.audio_spoken_path := new.audio_barista_path;
  end if;

  -- traits.calories / size_ml ↔ calories / size_ml
  if tg_op = 'INSERT' and not (new.traits ? 'calories' or new.traits ? 'size_ml') then
    new.traits := new.traits || jsonb_strip_nulls(
      jsonb_build_object('calories', new.calories, 'size_ml', new.size_ml));
  elsif traits_changed and not numbers_changed then
    new.calories := public.item_trait_int(new.traits, 'calories', 0, 3000);
    new.size_ml := public.item_trait_int(new.traits, 'size_ml', 1, 3000);
  elsif numbers_changed then
    new.traits := (new.traits - 'calories' - 'size_ml') || jsonb_strip_nulls(
      jsonb_build_object('calories', new.calories, 'size_ml', new.size_ml));
  end if;
  return new;
end;
$$;

revoke all on function public.items_legacy_columns() from public, anon, authenticated;
revoke all on function public.item_trait_int(jsonb, text, int, int) from public, anon, authenticated;

drop trigger if exists legacy_columns on public.items;
create trigger legacy_columns before insert or update on public.items
  for each row execute function public.items_legacy_columns();

-- Move what's there: the new side from the old one. The trigger then
-- keeps both in step, and touch bumps updated_at, so phones fetch every
-- item again with its details.
update public.items
set details = coalesce(details, case when recipe is not null
      then jsonb_build_object('kind', 'recipe') || recipe end),
  audio_spoken_path = coalesce(audio_spoken_path, audio_barista_path),
  traits = traits || jsonb_strip_nulls(jsonb_build_object(
    'calories', case when traits ? 'calories' then null else calories end,
    'size_ml', case when traits ? 'size_ml' then null else size_ml end))
where details is null and recipe is not null
   or audio_spoken_path is null and audio_barista_path is not null
   or not (traits ? 'calories') and calories is not null
   or not (traits ? 'size_ml') and size_ml is not null;
