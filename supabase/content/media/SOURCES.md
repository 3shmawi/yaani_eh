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
«زي الباريستا» clips are not generated: those stay own recordings.

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
