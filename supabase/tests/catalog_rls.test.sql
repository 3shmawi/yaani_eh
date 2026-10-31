-- Catalog security and sync rules (pgTAP). Run: supabase test db
-- What anon can and cannot do with categories, items, item_terms and
-- catalog_tombstones; that hidden and deleted rows reach the app as ids
-- only; that hostile values are rejected.
begin;
create extension if not exists pgtap with schema extensions;
select plan(46);

-- RLS on every table.
select ok((select relrowsecurity from pg_class where oid = 'public.categories'::regclass), 'RLS on categories');
select ok((select relrowsecurity from pg_class where oid = 'public.items'::regclass), 'RLS on items');
select ok((select relrowsecurity from pg_class where oid = 'public.item_terms'::regclass), 'RLS on item_terms');
select ok((select relrowsecurity from pg_class where oid = 'public.catalog_tombstones'::regclass), 'RLS on catalog_tombstones');

-- Launch content is there.
select is((select count(*)::int from public.items where is_published), 41, '41 published drinks');
select is(
  (select count(*)::int from public.items where is_published and gist_ar is not null and gist_en is not null),
  41, 'every launch drink has its «يعني» line in both languages'
);
select is(
  (select count(*)::int from public.items
   where gist_ar ~ '(لاتيه|إسبريسو|موكا|فرابيه|ميلك شيك|ماكياتو|كابتشينو|ماتشا|سموذي|متخفوق)'
      or gist_en ~* '(latte|espresso|mocha|frapp|milkshake|macchiato|cappuccino|matcha|smoothie)'),
  0, 'no «يعني» line leans on another menu word'
);
select is(
  (select count(*)::int from public.categories where parent_id = (select id from public.categories where slug = 'cafe')),
  6, 'six categories under the Café section'
);
select ok(
  (select jsonb_array_length(trait_schema) = 4 from public.categories where slug = 'cafe'),
  'the Café section has the four taste traits'
);
select is(
  (select name_ar || ' / ' || name_en from public.categories where slug = 'cafe'),
  'مشروبات / Drinks', 'the drinks section is called «مشروبات»'
);
select is(
  (select count(*)::int from public.categories where parent_id is null and is_published),
  2, 'two sections: drinks and desserts'
);
select is(
  (select count(*)::int from public.items i join public.categories c on c.id = i.category_id
   where c.parent_id = (select id from public.categories where slug = 'desserts')),
  0, 'desserts has no items yet, so the app shows it as coming soon'
);
select is(
  (select count(*)::int from public.items where menu_name ilike '%oreo%' or menu_name ilike '%frappuccino%'),
  0, 'no trademarked item names (they may only be search terms)'
);

-- Fixtures (as the owner): one hidden item, one hidden category.
insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en, is_published)
select id, 'secret_drink', 'Secret', 'سر', 'لسه', 'Not yet', false from public.categories where slug = 'coffee';
insert into public.item_terms (item_id, term, lang)
select id, 'hidden term', 'en' from public.items where slug = 'secret_drink';
insert into public.categories (parent_id, slug, name_ar, name_en, is_published)
select id, 'draft_section', 'مسودة', 'Draft', false from public.categories where slug = 'cafe';

-- Sync rules (as the owner). now() is fixed inside a transaction, so each
-- check first ages the row (with the touch trigger off), then changes it.
create function pg_temp.age(item_slug text) returns void language sql as $$
  alter table public.items disable trigger touch;
  update public.items set updated_at = '2000-01-01' where slug = item_slug;
  alter table public.items enable trigger touch;
$$;

select pg_temp.age('latte');
update public.items set calories = 191 where slug = 'latte';
select ok(
  (select updated_at > '2000-01-02' from public.items where slug = 'latte'),
  'editing an item bumps updated_at'
);

select pg_temp.age('espresso');
insert into public.item_terms (item_id, term, lang)
select id, 'ristretto-ish', 'en' from public.items where slug = 'espresso';
select ok(
  (select updated_at > '2000-01-02' from public.items where slug = 'espresso'),
  'adding a search term bumps its item'
);

select pg_temp.age('espresso');
delete from public.item_terms where term = 'ristretto-ish';
select ok(
  (select updated_at > '2000-01-02' from public.items where slug = 'espresso'),
  'removing a search term bumps its item'
);

insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en)
select id, 'gone_drink', 'Gone', 'راح', 'هيتمسح', 'To be deleted' from public.categories where slug = 'coffee';
delete from public.items where slug = 'gone_drink';
select is(
  (select count(*)::int from public.catalog_tombstones where kind = 'item'),
  1, 'deleting an item leaves a tombstone'
);

-- Hostile or broken values are rejected.
select throws_ok(
  $$ insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en)
     select id, 'x', repeat('A', 81), 'س', 'ش', 'e' from public.categories where slug = 'coffee' $$,
  '23514', null, 'menu names longer than 80 are rejected'
);
select throws_ok(
  $$ insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en)
     select id, 'Robert''); drop table items;--', 'A', 'س', 'ش', 'e' from public.categories where slug = 'coffee' $$,
  '23514', null, 'injection-like slugs are rejected'
);
select throws_ok(
  $$ update public.items set price_min_egp = 200, price_max_egp = 100 where slug = 'latte' $$,
  '23514', null, 'a price range must not be upside down'
);
select throws_ok(
  $$ update public.items set price_min_egp = -5 where slug = 'latte' $$,
  '23514', null, 'negative prices are rejected'
);
select throws_ok(
  $$ update public.items set traits = '[1,2]' where slug = 'latte' $$,
  '23514', null, 'traits must be an object'
);
select throws_ok(
  $$ update public.items set explanation_ar = '' where slug = 'latte' $$,
  '23514', null, 'empty explanations are rejected'
);
select throws_ok(
  $$ insert into public.item_terms (item_id, term, lang)
     select id, 'x', 'klingon' from public.items where slug = 'latte' $$,
  '23514', null, 'unknown term languages are rejected'
);
select throws_ok(
  $$ update public.items set gist_ar = repeat('ق', 61) where slug = 'latte' $$,
  '23514', null, 'a «يعني» line longer than 60 is rejected'
);
select throws_ok(
  $$ update public.items set gist_en = '' where slug = 'latte' $$,
  '23514', null, 'an empty «يعني» line is rejected (null means none)'
);
select is(
  (select count(*)::int from public.items
   where is_published and jsonb_array_length(recipe -> 'steps') > 0),
  41, 'every drink has «طريقة التحضير»'
);
select throws_ok(
  $$ update public.items set recipe = '"steps"'::jsonb where slug = 'latte' $$,
  '23514', null, 'a recipe that is not an object is rejected'
);
select throws_ok(
  $$ update public.items set recipe = '{"layers": [], "steps": []}'::jsonb where slug = 'latte' $$,
  '23514', null, 'a recipe without layers or steps is rejected'
);

-- As anon (the app).
set local role anon;

select is((select count(*)::int from public.items), 41, 'anon sees only published items');
select is((select count(*)::int from public.items where slug = 'secret_drink'), 0, 'anon cannot see a hidden item');
select is((select count(*)::int from public.categories where slug = 'draft_section'), 0, 'anon cannot see a hidden category');
select is((select count(*)::int from public.item_terms where term = 'hidden term'), 0, 'anon cannot see terms of hidden items');
select ok((select count(*) > 300 from public.item_terms), 'anon can read search terms');
select is(
  (select gist_ar from public.items where slug = 'coffee_frappe'), 'قهوة باللبن والتلج في الخلاط',
  'anon can read the «يعني» line'
);
select is(
  (select recipe -> 'layers' -> 0 ->> 'tone' from public.items where slug = 'flat_white'), 'espresso',
  'anon can read a recipe'
);

select is(
  (select count(*)::int from public.catalog_removed_since('1970-01-01') where kind = 'item'),
  2, 'removed items (hidden + deleted) reach the app as ids'
);
select is(
  (select count(*)::int from public.catalog_removed_since('1970-01-01') where kind = 'category'),
  1, 'hidden categories reach the app as ids'
);
select is(
  (select count(*)::int from public.catalog_removed_since(now() + interval '1 day')),
  0, 'nothing is reported as removed after the cursor'
);

select throws_ok(
  $$ select * from public.catalog_tombstones $$,
  '42501', null, 'anon cannot read tombstones directly'
);
select throws_ok(
  $$ insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar, explanation_en)
     select id, 'evil', 'Evil', 'شر', 'شر', 'evil' from public.categories limit 1 $$,
  '42501', null, 'anon cannot add items'
);
select results_eq(
  $$ with changed as (update public.items set explanation_en = 'hacked' returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'anon cannot edit items'
);
select results_eq(
  $$ with changed as (update public.items set gist_ar = 'hacked' returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'anon cannot change a «يعني» line'
);
select results_eq(
  $$ with changed as (update public.items set recipe = '{"layers": [{}], "steps": [{}]}'::jsonb returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'anon cannot change a recipe'
);
select results_eq(
  $$ with gone as (delete from public.items returning 1) select count(*)::int from gone $$,
  $$ values (0) $$,
  'anon cannot delete items'
);
select throws_ok(
  $$ insert into public.item_terms (item_id, term, lang)
     select id, 'spam', 'en' from public.items limit 1 $$,
  '42501', null, 'anon cannot add search terms'
);

select * from finish();
rollback;
