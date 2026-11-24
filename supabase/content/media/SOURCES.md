# Media sources

Where every photo and clip in this folder comes from. Keep it in step with the
files: `test/content/media_test.dart` fails when a file is missing here.

## Photos (`item-images/`)

All CC0 1.0 (public domain dedication): no credit is required, credit is given
here anyway. Found through Openverse, downloaded from the WordPress Photo
Directory, cropped to 3:4 and checked by eye for logos, branded cups, text
and faces (none). Picked and processed on 2026-11-18.

| File | Source | Photographer | License |
|---|---|---|---|
| `americano.webp` | https://wordpress.org/photos/photo/12369e7c9d/ | Yam B Chhetri | CC0 1.0 |
| `berry_smoothie.webp` | https://wordpress.org/photos/photo/21767d1477/ | Anis | CC0 1.0 |
| `cappuccino.webp` | https://wordpress.org/photos/photo/77269f708f/ | Vishnu Chandra | CC0 1.0 |
| `espresso.webp` | https://wordpress.org/photos/photo/508698dfe0/ | Ajit KC | CC0 1.0 |
| `flat_white.webp` | https://wordpress.org/photos/photo/81269f89df/ | Maruti Mohanty | CC0 1.0 |
| `iced_latte.webp` | https://wordpress.org/photos/photo/4336618f4e/ | Roberto Vazquez | CC0 1.0 |
| `latte.webp` | https://wordpress.org/photos/photo/6667fb9e77/ | season321 | CC0 1.0 |
| `lemon_mint.webp` | https://wordpress.org/photos/photo/25697c4e9b/ | Abishkaar Chettri | CC0 1.0 |
| `mango_juice.webp` | https://wordpress.org/photos/photo/65465bb767/ | Balu B | CC0 1.0 |
| `matcha_latte.webp` | https://wordpress.org/photos/photo/24661c2123/ | Louie Sonugan | CC0 1.0 |
| `mint_tea.webp` | https://wordpress.org/photos/photo/13269f6f1d/ | Vishnu Chandra | CC0 1.0 |
| `mocha.webp` | https://wordpress.org/photos/photo/589692bc66/ | Alina Kakshapati | CC0 1.0 |
| `orange_juice.webp` | https://wordpress.org/photos/photo/1996a70dcc/ | Dilip Modhavadiya | CC0 1.0 |
| `strawberry_juice.webp` | https://wordpress.org/photos/photo/6416a57141/ | diegolopez97 | CC0 1.0 |

## Pronunciation clips (`item-audio/`)

The «الأصلي» (original name) clips are computer-generated with
[Piper](https://github.com/OHF-Voice/piper1-gpl) 1.8.0 (GPL-3.0; the
generated audio isn't covered by it) on 2026-11-18, then trimmed and
encoded to AAC mono 64 kbps with ffmpeg. Each clip was checked with a speech
recognizer (Whisper small); names it heard wrong (Earl Grey) were dropped.
The «زي الباريستا» clips are below.

| Voice | Training data license |
|---|---|
| `it_IT-paola-medium` | CC0 (OHF-Voice voice-datasets), fine-tuned from the `hifi_tts_92` base voice (Hi-Fi TTS, CC BY 4.0: Cori Samuel) |
| `es_ES-davefx-medium` | CC0 (OHF-Voice voice-datasets) |
| `en_US-ljspeech-high` | Public domain (LJ Speech) |

| File | Voice |
|---|---|
| `espresso.original.m4a` | `it_IT-paola-medium` |
| `doppio.original.m4a` | `it_IT-paola-medium` |
| `americano.original.m4a` | `it_IT-paola-medium` |
| `macchiato.original.m4a` | `it_IT-paola-medium` |
| `cappuccino.original.m4a` | `it_IT-paola-medium` |
| `latte.original.m4a` | `it_IT-paola-medium` |
| `affogato.original.m4a` | `it_IT-paola-medium` |
| `cortado.original.m4a` | `es_ES-davefx-medium` |
| `flat_white.original.m4a` | `en_US-ljspeech-high` |
| `cold_brew.original.m4a` | `en_US-ljspeech-high` |
| `mocha.original.m4a` | `en_US-ljspeech-high` |

Voice model cards: https://huggingface.co/rhasspy/piper-voices

### «زي الباريستا» (`<slug>.barista.m4a`)

Generated with [ElevenLabs](https://elevenlabs.io) text to speech on
2026-11-20, voice "Haytham - Energetic, Warm and Cheerful" (Egyptian Arabic,
ElevenLabs Voice Library), from all 41 Arabic menu names read in one take
in `drinks.csv` order. The take was split at its pauses with ffmpeg
(`silencedetect`, -35 dB), trimmed and encoded to AAC mono 64 kbps. Each
clip was checked against its name with a speech recognizer (Whisper small);
it heard 38 of 41, and missed only very short clips (espresso, hot_chocolate,
virgin_mojito) whose neighbours matched, so the split is in order. Commercial use of ElevenLabs output needs a paid plan at the time
it is generated (ElevenLabs Terms of Service).

| File | Voice |
|---|---|
| `espresso.barista.m4a` | ElevenLabs "Haytham" |
| `doppio.barista.m4a` | ElevenLabs "Haytham" |
| `americano.barista.m4a` | ElevenLabs "Haytham" |
| `macchiato.barista.m4a` | ElevenLabs "Haytham" |
| `cortado.barista.m4a` | ElevenLabs "Haytham" |
| `flat_white.barista.m4a` | ElevenLabs "Haytham" |
| `cappuccino.barista.m4a` | ElevenLabs "Haytham" |
| `latte.barista.m4a` | ElevenLabs "Haytham" |
| `spanish_latte.barista.m4a` | ElevenLabs "Haytham" |
| `mocha.barista.m4a` | ElevenLabs "Haytham" |
| `caramel_macchiato.barista.m4a` | ElevenLabs "Haytham" |
| `white_mocha.barista.m4a` | ElevenLabs "Haytham" |
| `turkish_coffee.barista.m4a` | ElevenLabs "Haytham" |
| `french_coffee.barista.m4a` | ElevenLabs "Haytham" |
| `affogato.barista.m4a` | ElevenLabs "Haytham" |
| `iced_americano.barista.m4a` | ElevenLabs "Haytham" |
| `iced_latte.barista.m4a` | ElevenLabs "Haytham" |
| `iced_spanish_latte.barista.m4a` | ElevenLabs "Haytham" |
| `iced_mocha.barista.m4a` | ElevenLabs "Haytham" |
| `cold_brew.barista.m4a` | ElevenLabs "Haytham" |
| `iced_caramel_macchiato.barista.m4a` | ElevenLabs "Haytham" |
| `coffee_frappe.barista.m4a` | ElevenLabs "Haytham" |
| `caramel_frappe.barista.m4a` | ElevenLabs "Haytham" |
| `mocha_frappe.barista.m4a` | ElevenLabs "Haytham" |
| `vanilla_cream_frappe.barista.m4a` | ElevenLabs "Haytham" |
| `green_tea.barista.m4a` | ElevenLabs "Haytham" |
| `earl_grey.barista.m4a` | ElevenLabs "Haytham" |
| `chai_latte.barista.m4a` | ElevenLabs "Haytham" |
| `matcha_latte.barista.m4a` | ElevenLabs "Haytham" |
| `hibiscus.barista.m4a` | ElevenLabs "Haytham" |
| `mint_tea.barista.m4a` | ElevenLabs "Haytham" |
| `mango_juice.barista.m4a` | ElevenLabs "Haytham" |
| `strawberry_juice.barista.m4a` | ElevenLabs "Haytham" |
| `orange_juice.barista.m4a` | ElevenLabs "Haytham" |
| `lemon_mint.barista.m4a` | ElevenLabs "Haytham" |
| `fruit_cocktail.barista.m4a` | ElevenLabs "Haytham" |
| `hot_chocolate.barista.m4a` | ElevenLabs "Haytham" |
| `sahlab.barista.m4a` | ElevenLabs "Haytham" |
| `cookies_milkshake.barista.m4a` | ElevenLabs "Haytham" |
| `berry_smoothie.barista.m4a` | ElevenLabs "Haytham" |
| `virgin_mojito.barista.m4a` | ElevenLabs "Haytham" |
