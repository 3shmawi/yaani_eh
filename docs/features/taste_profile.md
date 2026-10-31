# Feature: taste profile

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
«ذوقي»: four quick questions about what you like (hot or iced, how sweet,
with milk or not, how much coffee), one per screen, each a single tap.
After it, Home shows «على ذوقك», a row of the drinks that fit best with why
under each («ساقع · حلو · بلبن»), and search puts them higher. The answers
stay on the phone: no account, and nothing is sent.

Designed in https://claude.ai/artifact/PTwE3Ex87rG5og9jF8AS4c (picked: Quiz A,
Home row A).

## User flows
1. Home, under the drink of the day → «قولنا ذوقك» → «يلا بينا» → the quiz.
2. A question → tap an answer: a tick is felt and the next question slides
   in. «مش فارقة معايا» skips it. The back chevron goes one question back,
   keeping the answer. ✕ leaves without saving.
3. The last answer saves and goes back: Home now shows «على ذوقك», best
   first, with why under each card. Tap a card to open it; long-press it for
   the preview.
4. «غيّر ذوقك» reopens the quiz with the answers given before.
5. Nothing in the section fits: «مفيش حاجة هنا على ذوقك لسه», with «غيّر
   ذوقك».
6. Search: drinks close to your taste rank higher among the results.
7. A section without taste questions (desserts, for now) shows no row.
8. Offline: everything works (the questions come with the menu copy).

## Architecture
- Layers / main files: `lib/features/taste_profile/`
  - `domain/`:
    - `TasteQuestion`, `TasteOption`, `TasteKind`, `TasteProfile`.
    - `TasteQuestions` reads a section's `trait_schema`, which is content,
      so desserts can bring their own. Anything malformed is skipped, and
      there are at most 8 questions with 2 to 6 options each.
    - `MatchTaste` scores and ranks drinks: a choice fits when it's equal or
      either side is `both`; a scale fits by distance; yes / no when equal; a
      missing trait counts as half. The score is the average, and an answer
      that fits 2/3 or more is a reason in the why line.
    - `TasteRepository`.
  - `data/`: `SharedPrefsTasteRepository` (`taste.<section>` → JSON). A
    broken or odd-typed stored value is dropped, never a crash.
  - `presentation/`:
    - `taste_controller.dart`: `tasteProvider(section)`,
      `tasteQuestionsProvider`, `tasteMatchesProvider`,
      `defaultTasteSectionProvider`, `tasteBoostsProvider`.
    - `TastePage` → `TasteQuizView`.
    - `TasteRow` → `widgets/taste_row.dart` (`TasteRowView`).
- Wired into Home through `MenuView.forYou`. Search's `searchBoostsProvider`
  uses `tasteBoostsProvider`: up to +50% for a perfect fit, nothing before
  the quiz.
- DI: `Dependencies.tasteRepository` (`DependencyOverrides.tasteRepository`
  for demos).
- Routes / deep links: `/taste`, `/taste?section=<slug>`
  (docs/deep_links.md).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `taste_quiz_completed` | the last answer is saved | `section`, `answered` (how many weren't «مش فارقة») |
| `taste_quiz_closed` | ✕ before the end | `section`, `at` (question number) |
| `taste_match_opened` | a card in «على ذوقك» is opened | `drink` (slug), `rank` |

No answers in events: only how many.

## Feature flags
None.

## Tests
- Unit: `test/features/taste_profile/domain/taste_domain_test.dart`.
  - Reading questions: the real drinks' schema, plus hostile entries (no key,
    huge key, missing, one-language or oversized questions, unknown types,
    too few or too many options, mismatched labels), injection-like text
    staying text, at most 8 questions.
  - Matching: a perfect fit, the opposite, «both», distance, a missing
    trait, ranking with ties, wrong types.
- `test/features/taste_profile/data/shared_prefs_taste_repository_test.dart`:
  per section; every answer skipped still counts as a taken quiz; broken
  and hostile stored values are dropped.
- Widget: `test/features/taste_profile/presentation/taste_test.dart`.
  - The quiz: auto-advance, skip, back keeping the answer, starting from an
    old taste, ✕, haptics, Arabic, a small phone at 1.3× text,
    `expectAccessible`.
  - The page: saving, a failed save, falling back to the drinks section.
  - The row: invite, matches with why, opening one, nothing fits, a section
    with no questions.
  - Search ranking.
- Security: `test/security/deep_link_test.dart`: `/taste` with crafted
  `section` values opens the quiz with the default section, ✕ stays in the
  app, and `/taste/…` paths show not-found.
- Integration (demo): `integration_test/taste_profile_test.dart`.

## Decisions & edge cases
- **Quiz A, one question per screen**, so each answer is one tap and the
  whole thing takes seconds. B (one sheet) and C (pick drinks) are on the
  design canvas.
- **Questions are content.** They come from the section's `trait_schema`, the
  same one the trait pills use, so changing a question in Studio changes the
  quiz, and a new section with its own traits gets its own quiz.
- **«مش فارقة معايا» is an answer:** it removes that trait from the score.
  Skipping all four still saves, and Home then says nothing fits rather
  than inviting again.
- **On the phone only**, like favorites. The privacy policy says so.

## Demo & post
**Hook (first 2 seconds):** «قولنا ذوقك» / "Tell us your taste."

**Scenario (what the integration test shows, with beat() pauses):**
1. Home: the invite under the drink of the day; «يلا بينا».
2. Iced, sweet, with milk, and «مش فارقة معايا»: four taps.
3. Back on Home: «على ذوقك», the iced drinks first, with why under each.
4. Open the first one.

**Caption (English):** Four taps, and the menu knows what you like: iced or
hot, how sweet, with milk or not. The drinks that fit come first, each with
why. Your answers stay on your phone.

**Caption (Egyptian Arabic):** أربع دوسات، والمنيو يعرف ذوقك: سخن ولا ساقع،
حلو قد إيه، بلبن ولا من غير. اللي على ذوقك يطلع الأول، وتحته ليه. وإجاباتك
على موبايلك بس.

**Hashtags:** #flutter #buildinpublic #liquidglass #yaanieh
