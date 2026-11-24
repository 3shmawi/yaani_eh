-- «زي الباريستا» clips for every drink (supabase/content/media/item-audio/,
-- source in supabase/content/media/SOURCES.md). The Supabase deploy workflow
-- uploads the files (scripts/upload_media.sh) before it runs this migration.
--
-- Only empty paths are filled, so a clip already set in Studio is kept.
-- Setting audio_spoken_path also sets audio_barista_path (the trigger in
-- 0009_generic_items.sql), so installed app versions get the clip too. Each
-- update bumps updated_at, so phones pick it up on their next sync.
update public.items i
set audio_spoken_path = v.path
from (values
  ('espresso', 'espresso.barista.m4a'),
  ('doppio', 'doppio.barista.m4a'),
  ('americano', 'americano.barista.m4a'),
  ('macchiato', 'macchiato.barista.m4a'),
  ('cortado', 'cortado.barista.m4a'),
  ('flat_white', 'flat_white.barista.m4a'),
  ('cappuccino', 'cappuccino.barista.m4a'),
  ('latte', 'latte.barista.m4a'),
  ('spanish_latte', 'spanish_latte.barista.m4a'),
  ('mocha', 'mocha.barista.m4a'),
  ('caramel_macchiato', 'caramel_macchiato.barista.m4a'),
  ('white_mocha', 'white_mocha.barista.m4a'),
  ('turkish_coffee', 'turkish_coffee.barista.m4a'),
  ('french_coffee', 'french_coffee.barista.m4a'),
  ('affogato', 'affogato.barista.m4a'),
  ('iced_americano', 'iced_americano.barista.m4a'),
  ('iced_latte', 'iced_latte.barista.m4a'),
  ('iced_spanish_latte', 'iced_spanish_latte.barista.m4a'),
  ('iced_mocha', 'iced_mocha.barista.m4a'),
  ('cold_brew', 'cold_brew.barista.m4a'),
  ('iced_caramel_macchiato', 'iced_caramel_macchiato.barista.m4a'),
  ('coffee_frappe', 'coffee_frappe.barista.m4a'),
  ('caramel_frappe', 'caramel_frappe.barista.m4a'),
  ('mocha_frappe', 'mocha_frappe.barista.m4a'),
  ('vanilla_cream_frappe', 'vanilla_cream_frappe.barista.m4a'),
  ('green_tea', 'green_tea.barista.m4a'),
  ('earl_grey', 'earl_grey.barista.m4a'),
  ('chai_latte', 'chai_latte.barista.m4a'),
  ('matcha_latte', 'matcha_latte.barista.m4a'),
  ('hibiscus', 'hibiscus.barista.m4a'),
  ('mint_tea', 'mint_tea.barista.m4a'),
  ('mango_juice', 'mango_juice.barista.m4a'),
  ('strawberry_juice', 'strawberry_juice.barista.m4a'),
  ('orange_juice', 'orange_juice.barista.m4a'),
  ('lemon_mint', 'lemon_mint.barista.m4a'),
  ('fruit_cocktail', 'fruit_cocktail.barista.m4a'),
  ('hot_chocolate', 'hot_chocolate.barista.m4a'),
  ('sahlab', 'sahlab.barista.m4a'),
  ('cookies_milkshake', 'cookies_milkshake.barista.m4a'),
  ('berry_smoothie', 'berry_smoothie.barista.m4a'),
  ('virgin_mojito', 'virgin_mojito.barista.m4a')
) as v(slug, path)
where i.slug = v.slug
  and i.audio_spoken_path is null
  and i.audio_barista_path is null;
