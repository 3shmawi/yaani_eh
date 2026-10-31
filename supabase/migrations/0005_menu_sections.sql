-- Home's sections switch («مشروبات | حلويات»): the root categories are the
-- sections. The Café section becomes «مشروبات / Drinks» (it holds every
-- drink, not just café ones), and «حلويات / Desserts» is added with no
-- items yet, so the app shows it as «قريبًا» until its first dessert is
-- published. Names only change if nobody edited them in Studio.

update public.categories
set name_ar = 'مشروبات', name_en = 'Drinks'
where slug = 'cafe' and parent_id is null
  and name_ar = 'الكافيه' and name_en = 'Café';

insert into public.categories (slug, name_ar, name_en, icon, sort_order)
values ('desserts', 'حلويات', 'Desserts', 'cake', 1)
on conflict (slug) do nothing;
