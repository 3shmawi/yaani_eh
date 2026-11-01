-- Generic items (pgTAP). Run: supabase test db
-- Sections carry a kind of details; items.details is checked per kind;
-- hostile details are rejected; the old columns that installed app
-- versions still read stay in step with the new ones; anon can read
-- details but never write them.
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

-- The move: every drink kept its recipe, clip and numbers.
select is(
  (select detail_kind || ' / ' || details_title_ar from public.categories where slug = 'cafe'),
  'recipe / طريقة التحضير', 'the drinks section carries recipes, called «طريقة التحضير»'
);
select is(
  (select count(*)::int from public.items where recipe is not null and details - 'kind' = recipe and details ->> 'kind' = 'recipe'),
  (select count(*)::int from public.items where recipe is not null),
  'every recipe moved into details'
);
select is(
  (select count(*)::int from public.items where calories is not null and (traits ->> 'calories')::int = calories),
  (select count(*)::int from public.items where calories is not null),
  'calories moved into traits'
);
select is(
  (select count(*)::int from public.items where audio_spoken_path is distinct from audio_barista_path),
  0, 'the spoken clip is the barista clip'
);

-- Valid details of every kind are accepted.
insert into public.categories (slug, name_ar, name_en, detail_kind, details_title_ar, details_title_en)
values ('history', 'تاريخ', 'History', 'story', 'الحكاية', 'The story'),
       ('terms', 'مصطلحات', 'Terms', 'usage', 'إزاي تستخدمها', 'How to use it');
insert into public.categories (parent_id, slug, name_ar, name_en)
select id, 'egypt', 'مصر', 'Egypt' from public.categories where slug = 'history';

create function pg_temp.add(item_slug text, cat text, d jsonb) returns void language sql as $$
  insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en, details)
  select id, item_slug, item_slug, 'س', 'ش', 'e', d from public.categories where slug = cat;
$$;

select lives_ok(
  $$ select pg_temp.add('october_1973', 'egypt', '{"kind":"story",
       "steps":[{"title_ar":"العبور","title_en":"The crossing","date_ar":"٦ أكتوبر ١٩٧٣","date_en":"6 October 1973"}],
       "sections":[{"title_ar":"النتايج","title_en":"Results","lines_ar":["سطر"],"lines_en":["A line"]}]}') $$,
  'a story is accepted'
);
select lives_ok(
  $$ select pg_temp.add('bureaucracy', 'terms', '{"kind":"usage",
       "sections":[{"title_ar":"في جملة","title_en":"In a sentence","lines_ar":["سطر"],"lines_en":["A line"]}]}') $$,
  'usage is accepted'
);
select ok(
  (select recipe is null from public.items where slug = 'october_1973'),
  'a story leaves the old recipe column empty (old apps show no recipe)'
);

-- Hostile or broken details are rejected.
select throws_ok($$ select pg_temp.add('x1', 'terms', '"<script>"') $$, '23514', null, 'details must be an object');
select throws_ok($$ select pg_temp.add('x2', 'terms', '{"kind":"quiz"}') $$, '23514', null, 'an unknown kind is rejected');
select throws_ok($$ select pg_temp.add('x3', 'terms', '{"steps":[]}') $$, '23514', null, 'a kind is required');
select throws_ok(
  $$ select pg_temp.add('x4', 'terms', '{"kind":"usage","sections":[]}') $$,
  '23514', null, 'usage needs a section'
);
select throws_ok(
  $$ select pg_temp.add('x5', 'egypt', '{"kind":"story","steps":[{"title_ar":"س"}]}') $$,
  '23514', null, 'a step needs a title in both languages'
);
select throws_ok(
  $$ select pg_temp.add('x6', 'terms', jsonb_build_object('kind', 'usage', 'sections', jsonb_build_array(
       jsonb_build_object('title_ar', 'ع', 'title_en', 't', 'lines_ar', jsonb_build_array(repeat('ق', 201)), 'lines_en', '["l"]')))) $$,
  '23514', null, 'a line longer than 200 is rejected'
);
select throws_ok(
  $$ select pg_temp.add('x7', 'terms', '{"kind":"usage","sections":[{"title_ar":"ع","title_en":"t","lines_ar":[42],"lines_en":["l"]}]}') $$,
  '23514', null, 'a line must be text'
);
select throws_ok(
  $$ select pg_temp.add('x8', 'egypt', jsonb_build_object('kind', 'story', 'steps',
       (select jsonb_agg(jsonb_build_object('title_ar', 'س', 'title_en', 's')) from generate_series(1, 13)))) $$,
  '23514', null, 'a story has at most 12 steps'
);
select throws_ok(
  $$ select pg_temp.add('x9', 'egypt', jsonb_build_object('kind', 'story', 'steps', '[{"title_ar":"س","title_en":"s"}]'::jsonb,
       'padding', repeat('x', 20000))) $$,
  '23514', null, 'details larger than 16 KB are rejected'
);
select throws_ok(
  $$ update public.categories set detail_kind = 'recipe' where slug = 'egypt' $$,
  '23514', null, 'only sections carry a kind of details'
);
select throws_ok(
  $$ update public.categories set detail_kind = 'map' where slug = 'history' $$,
  '23514', null, 'a section''s kind must be one the app knows'
);

-- Old and new columns stay in step, from either side.
update public.items set details = '{"kind":"recipe","minutes":3,"layers":[{"tone":"milk","ml":100,"ar":"لبن","en":"Milk"}],
  "steps":[{"icon":"pour","title_ar":"صب","title_en":"Pour"}]}' where slug = 'latte';
select is(
  (select recipe ->> 'minutes' from public.items where slug = 'latte'), '3',
  'a new recipe in details reaches the old column'
);
update public.items set recipe = jsonb_set(recipe, '{minutes}', '4') where slug = 'latte';
select is(
  (select details ->> 'minutes' from public.items where slug = 'latte'), '4',
  'a recipe edited in the old column reaches details'
);
update public.items set traits = traits || '{"calories": 222}' where slug = 'latte';
select is((select calories from public.items where slug = 'latte'), 222, 'calories in traits reach the old column');
update public.items set calories = 111 where slug = 'latte';
select is((select (traits ->> 'calories')::int from public.items where slug = 'latte'), 111, 'old calories reach traits');
update public.items set audio_spoken_path = 'drinks/latte.m4a' where slug = 'latte';
select is(
  (select audio_barista_path from public.items where slug = 'latte'), 'drinks/latte.m4a',
  'the spoken clip reaches the old column'
);

-- anon reads details, never writes them.
set local role anon;
select ok(
  (select details ->> 'kind' = 'story' from public.items where slug = 'october_1973'),
  'anon reads a published item''s details'
);
select results_eq(
  $$ with changed as (update public.items set details = null returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'anon cannot change details'
);
select results_eq(
  $$ with changed as (update public.categories set detail_kind = null returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'anon cannot change a section''s kind of details'
);
reset role;

select * from finish();
rollback;
