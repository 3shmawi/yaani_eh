# Feature: pronunciation

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Hear a drink's name before saying it at the counter. The drink page has the
pronounce pill on its photo: «زي الباريستا» (how baristas in Egypt say it),
«الأصلي» (the original Italian or English), and `0.75×` to slow it down.
Home cards and the drink of the day have a round speaker button that plays
the barista version (or the original when that's the only one). One name
plays at a time; tapping the playing one stops it. A name heard once (or
whose drink page was opened online) plays offline afterwards.

## User flows
1. Drink page → «زي الباريستا» → the segment fills with moving bars → it
   ends and goes back to normal.
2. `0.75×` → «الأصلي» → the original, slower (pitch kept).
3. Home → the speaker on a card or the drink of the day → the name plays,
   the card stays (no navigation).
4. Offline, a name never heard on this phone → a note under the pill:
   «إنت أوفلاين، والاسم ده متسمعش على الموبايل ده قبل كده.» (cards show the
   wifi-off icon and say it to screen readers). Clears after 4 seconds.
5. A drink with no clips: no pill, no button. One clip: only its segment.

## Architecture
- Layers / main files: `lib/features/pronunciation/`
  - `domain/entities/pronunciation.dart` — `Voice` (barista, original),
    `PlaybackSpeed` (1×, 0.75×), `Clip`, `Playback` (idle / loading /
    playing / failed, per item + voice), `PronunciationState`.
  - `domain/usecases/clips_for.dart` — `ClipsFor`: an item's clips, barista
    first; blank paths have none.
  - `domain/repositories/pronunciation_repository.dart` —
    `PronunciationRepository` (`clipFile(path)` → a local file,
    `prefetch(paths)`) and `ClipPlayer` (`play(file, speed)`, `stop()`).
  - `data/repositories/pronunciation_repository_impl.dart` — the
    `item-audio` bucket through `AudioCache`
    (`data/datasources/audio_cache.dart`: 400 files, a year after last
    use). A fresh copy plays as is; a stale one is checked again online and
    used as is offline; a 4xx answer is `NotFoundFailure` (no stale copy of
    a removed clip). One retry, 15 s timeout.
  - `data/datasources/just_audio_clip_player.dart` — just_audio on local
    files only (no streaming proxy, no cleartext). Audio session: speech,
    ducks other apps' music instead of stopping it, deactivated after each
    name so the music comes back.
  - `presentation/pronunciation_controller.dart` — `pronunciationProvider`
    (one app-wide player): `toggle(item, voice)`, `toggleFirst(item)`
    (cards), `stop()`, `toggleSpeed()`, `prefetch(item)`. A newer tap
    always wins (older downloads never play).
  - `presentation/widgets/pronounce_pill.dart` (`PronouncePill`,
    `SoundBars`, `PronounceFailureNote`) and `play_name_button.dart`
    (`PlayNameButton`) are views (data + callbacks);
    `presentation/pronounce.dart` wires them: `ItemPronounce(item)` (drink
    page, prefetches its clips) and `ItemPlayButton(item)` (cards).
- Where it shows: `DrinkView(pronounce:)` puts the pill on the photo just
  above the sheet (it scrolls with the sheet); `MenuView(cardAction:)`
  puts the button in the drink of the day's top-end corner (Home artboard)
  and in each grid card's top-start corner (top-end is the heart's, coming
  with `favorites`). Not on compact cards (similar drinks) or search rows.
- State: Riverpod (Notifier); speed is kept for the session, not saved.
- Data sources: `items.audio_barista_path` / `audio_original_path` (synced
  by `catalog_sync`), files in the public `item-audio` bucket
  (docs/content.md → Pronunciation clips).
- DI: `Dependencies.pronunciationRepository` / `clipPlayer`, overridable in
  `DependencyOverrides` (the demo app uses fakes).
- Routes / deep links: none.

## Analytics events
| Event | When | Properties |
|---|---|---|
| `pronunciation_played` | a clip starts playing | `drink` (slug), `voice` (`barista` / `original`), `speed` (`1` / `0.75`) |
| `pronunciation_failed` | a clip can't play | `drink`, `voice`, `reason` (`offline` / `missing` / `other`) |

No personal data.

## Feature flags
None.

## Tests
- Unit: `test/features/pronunciation/domain/usecases/clips_for_test.dart`;
  `data/repositories/pronunciation_repository_impl_test.dart` (fresh /
  stale / offline copies, 4xx vs network, no Supabase, prefetch; hostile
  paths: traversal refused, others encoded inside the bucket);
  `presentation/pronunciation_controller_test.dart` (play → idle, stop,
  one at a time, overtaken downloads, speed, cards' voice, failures clear
  after 4 s, player errors, prefetch).
  `test/core/backend/media_test.dart` — paths that could leave a bucket
  give no URL. `test/core/network/result_test.dart` — HTTP status mapping.
- Widget: `test/features/pronunciation/presentation/pronounce_test.dart` —
  segments and speed, hidden voices, screen-reader labels, playing / bars
  (still with Reduce Motion), loading, failure messages, Arabic RTL with an
  LTR `0.75×`, dark + 1.3× text on a small phone, hostile names,
  `PlayNameButton` states, wired flows (prefetch, play, slow, offline note,
  card stop, one at a time), `expectAccessible`. Plus a case each in
  `menu_page_test.dart` (buttons on cards, no navigation) and
  `drink_page_test.dart` (pill on the photo, prefetch, play).
- Integration (demo): `integration_test/pronunciation_test.dart`.

## Decisions & edge cases
- Clips are downloaded to the phone and played from a file (not streamed),
  so the same code path works offline and just_audio needs no local proxy.
- Opening a drink page prefetches its clips (a few KB each) so a later
  café visit without internet still has them. Cards don't prefetch.
- just_audio 0.10.6 + audio_session 0.2.4 (checked 2026-10-30): slowing
  down keeps the pitch on both platforms (iOS time-domain algorithm,
  Android `PlaybackParameters`). Plays even with the iPhone's silent
  switch on, since the reader tapped it.
- Upload M4A (AAC) or MP3: the bucket also accepts Ogg, which iPhones
  can't play (it would show «مقدرناش نشغّل الاسم»).
- Changing speed applies to the next clip, not the one playing.
- The speed label is LTR-isolated (`Bidi.ltr`), so RTL never shows `×0.75`.

## Demo & post
**Hook (first 2 seconds):** «بيتقال إزاي؟» / "How do you even say it?"

**Scenario (what the integration test shows, with beat() pauses):**
1. Home → the speaker on the drink of the day → its name plays.
2. Open Flat White → «زي الباريستا» → the bars move.
3. `0.75×` → «الأصلي», slower.
4. Airplane mode → Flat White still plays (it's on the phone).
5. Back → a drink never opened → the offline note says why.
6. Back online → it plays.

**Caption (English):** Afraid of mispronouncing it at the counter? Tap the
speaker: hear it the way Egyptian baristas say it, or the original, and
slow it down to 0.75×. Names you've heard keep working offline.

**Caption (Egyptian Arabic):** خايف تنطق اسم المشروب غلط قدام الكاشير؟
دوس على السماعة واسمعه زي ما الباريستا بيقوله، أو نطقه الأصلي، وبطّأه لـ
0.75×. والأسامي اللي سمعتها بتشتغل من غير نت كمان.

**Hashtags:** #flutter #buildinpublic #arabic #a11y #yaanieh
