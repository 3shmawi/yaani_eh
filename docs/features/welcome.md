# Feature: welcome

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
The first time the app opens, three pages on the header band say what it
does before Home: «منيو الكافيه… بس مفهوم» (every drink, and what it is),
«اسمعه، واعمله» (hear the name, see how it's made, offline), and «احفظ
اللي يهمك» (save with a heart, works offline with no account, new sections
coming). The last page's one button, «يلا بينا», opens Home. The menu downloads while you
read, so Home is usually ready at the end. It shows once.

Designed in https://claude.ai/artifact/PTwE3Ex87rG5og9jF8AS4c (Welcome 1–3).

## User flows
1. Fresh install → the welcome, page 1. Swipe, or «التالي».
2. «تخطّي» (pages 1 and 2) → Home.
3. Page 3: «يلا بينا» → Home.
4. Any later open → Home directly. A deep link on the first open (a drink,
   search) opens what it links to; the welcome waits for Home.
5. Offline on first open: the welcome works; Home then shows the first
   download's offline state, as before.

## Architecture
- Layers / main files: `lib/features/welcome/`
  - `domain/repositories/welcome_repository.dart`: `seen`, `markSeen()`.
  - `data/repositories/shared_prefs_welcome_repository.dart`:
    `welcome.seen` (bool); any other stored value means not seen.
  - `presentation/welcome_controller.dart`: `welcomeRepositoryProvider`,
    `welcomeSeenProvider` (`WelcomeSeen.finish(exit, page:)` flips it at
    once, saves, and sends analytics), `WelcomeExit {skip, start}`.
  - `presentation/welcome_page.dart` → `welcome_view.dart` (`WelcomeView`),
    pictures in `widgets/welcome_art.dart`. The page listens to
    `catalogSyncControllerProvider`, which starts the first download.
- State: Riverpod (`Notifier`).
- Routing: `AppRoutes.welcome` (`/welcome`). Home's route redirects there
  while `welcomeSeenProvider` is false; nothing else does.
- DI: `Dependencies.welcomeRepository` (`DependencyOverrides
  .welcomeRepository`; `DemoApp.start(welcomed: false)` for this demo, the
  other demos start past it).
- Shared pieces: `BandBackground` (header_band.dart), `AppButtonKind.bandText`.

## Analytics events
| Event | When | Properties |
|---|---|---|
| `welcome_skipped` | «تخطّي» | `page` (1–2) |
| `welcome_completed` | a button on the last page | `page` (3), `next` (`start`) |

## Feature flags
None.

## Tests
- Unit: `test/features/welcome/data/shared_prefs_welcome_repository_test.dart`
  (fresh install, saving, odd stored values such as `'true'`, `1`,
  `<script>`).
- Widget: `test/features/welcome/presentation/welcome_test.dart`: «التالي»
  through the pages, swiping (and RTL), «تخطّي» with its page, the last
  page's button, a small phone at 1.6× text, Reduce Motion, the download
  starting, saving, a failed save still letting you in, `expectAccessible`.
- Security: `test/security/deep_link_test.dart`: a fresh install lands on
  the welcome at `/` but a drink link still opens the drink; crafted
  queries are ignored; `/welcome/…` paths show not-found.
- Screens: `test/screens/screens_test.dart` (`13`–`15_welcome_*`).
- Integration (demo): `integration_test/welcome_test.dart`.

## Decisions & edge cases
- **Only Home waits for it.** A link someone shared opens on the first try.
- **Seen means finished or skipped**, saved at once. If saving fails, the
  app still goes on; the worst case is seeing the welcome once more.
- **The pictures are pictures:** hidden from screen readers (the title and
  text say it), fixed text size, the whole picture shrinking to fit a small
  phone or large text; the text never shrinks and scrolls if it must.
- **Drink names in the pictures** (Flat White, Affogato)
  are Latin in both languages, as menus print them; everything else is in
  the ARB files.

## Demo & post
**Hook (first 2 seconds):** «منيو الكافيه… بس مفهوم» / "Café menus that
make sense."

**Scenario (what the integration test shows, with beat() pauses):**
1. A fresh install opens on the welcome.
2. Swipe to «اسمعه، واعمله», then «التالي» to «احفظ اللي يهمك».
3. «يلا بينا»: Home is there, menu downloaded.
4. Opened again: straight to Home.

**Caption (English):** The first open says it all in three swipes: every
drink in plain words, hear it and make it, and save what matters to you, offline.
Then straight in, menu already downloaded.

**Caption (Egyptian Arabic):** أول ما تفتح التطبيق، تلات صفحات بيقولولك كل
حاجة: كل مشروب بكلام إنت عارفه، اسمعه واعمله، واحفظ اللي يهمك من غير نت. وبعدها على
المنيو على طول، ومتحمّل خلاص.

**Hashtags:** #flutter #buildinpublic #liquidglass #yaanieh
