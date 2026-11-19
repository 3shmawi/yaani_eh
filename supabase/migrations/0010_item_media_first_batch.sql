-- First photos and «الأصلي» clips (supabase/content/media/, sources in
-- supabase/content/media/SOURCES.md). The Supabase deploy workflow uploads
-- the files (scripts/upload_media.sh) before it runs this migration.
--
-- Only empty paths are filled, so a photo or clip already set in Studio is
-- kept. Each update bumps updated_at, so phones pick the change up on their
-- next sync, no app release.

-- Photos: <slug>.webp, with <slug>.thumb.webp next to it in item-images.
update public.items i
set image_path = v.path
from (values
  ('espresso', 'espresso.webp'),
  ('americano', 'americano.webp'),
  ('cappuccino', 'cappuccino.webp'),
  ('latte', 'latte.webp'),
  ('flat_white', 'flat_white.webp'),
  ('iced_latte', 'iced_latte.webp'),
  ('mocha', 'mocha.webp'),
  ('matcha_latte', 'matcha_latte.webp'),
  ('berry_smoothie', 'berry_smoothie.webp'),
  ('strawberry_juice', 'strawberry_juice.webp'),
  ('lemon_mint', 'lemon_mint.webp'),
  ('mango_juice', 'mango_juice.webp'),
  ('mint_tea', 'mint_tea.webp'),
  ('orange_juice', 'orange_juice.webp')
) as v(slug, path)
where i.slug = v.slug and i.image_path is null;

-- «الأصلي»: the original Italian / Spanish / English name, in item-audio.
update public.items i
set audio_original_path = v.path
from (values
  ('espresso', 'espresso.original.m4a'),
  ('doppio', 'doppio.original.m4a'),
  ('americano', 'americano.original.m4a'),
  ('macchiato', 'macchiato.original.m4a'),
  ('cortado', 'cortado.original.m4a'),
  ('flat_white', 'flat_white.original.m4a'),
  ('cappuccino', 'cappuccino.original.m4a'),
  ('latte', 'latte.original.m4a'),
  ('mocha', 'mocha.original.m4a'),
  ('affogato', 'affogato.original.m4a'),
  ('cold_brew', 'cold_brew.original.m4a')
) as v(slug, path)
where i.slug = v.slug and i.audio_original_path is null;

-- Browsers (and so Studio's uploader) label .m4a files audio/x-m4a, which
-- the bucket refused: allow it next to audio/mp4.
update storage.buckets
set allowed_mime_types = array_append(allowed_mime_types, 'audio/x-m4a')
where id = 'item-audio'
  and not ('audio/x-m4a' = any (allowed_mime_types));
