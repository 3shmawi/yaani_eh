# Feature: settings (language & theme)

## What it does
Lets the user choose the app language (Arabic, English, or the phone's
language). Choices apply instantly and are saved on the device. Arabic
switches the whole UI to right-to-left. Settings is the third tab
(«الإعدادات»), not a button on Home's band (docs/decisions/0004-home-header.md).

**Defaults:** a first launch opens in **Arabic** (the app is for Egyptian
Arabic speakers, whatever the phone's language) and **dark**. «زي لغة
الموبايل» is stored as its own choice (`system`), so it isn't mistaken for a
first launch.

**Layout** (2026-11-16, like gym_tracker's settings): groups of compact
rows on cards, each group's name above it in small muted bold
(`SettingsSectionHeader`, `SettingsGroup`, `SettingsRow` in
`widgets/settings_tiles.dart`). A row has an icon, its label at the start,
the current value at the end and a chevron (mirrors in RTL) when it opens
something.
- **الشكل / Appearance:** «اللغة» shows the current language and opens a
  glass sheet to pick (`showSettingsChoice`, `SettingsChoiceRow` with a
  check). Closing the sheet changes nothing. The theme row joins it when
  light mode is ready.
- **عن التطبيق / About:** the version (reads left to right in Arabic too,
  `1.2.3 (45)`), «سياسة الخصوصية» and «شروط الاستخدام» (the website pages,
  `LegalLinks` in `lib/core/legal/legal_links.dart`, opened in the browser
  through `openLinkProvider`), and «تراخيص المصادر المفتوحة» (Flutter's
  licenses page: fonts and packages).

**Theme:** the light palette isn't finished, so the app always runs dark
and the theme row is hidden (`AppTheme.lightModeReady = false`;
`AppTheme.modeFor` ignores the stored theme until then). The choice is still
stored and the light theme still built and tested, so setting the flag to
`true` brings the section back.

Layout (the iOS settings look): groups of compact rows on cards, each
group's name above it in small muted bold (`SettingsSectionHeader`,
`SettingsGroup`, `SettingsRow` in `widgets/settings_tiles.dart`). A row has
an icon, its label at the start, the current value at the end and a chevron
(mirrors in RTL) when it opens something.
- **Appearance:** Language and Theme show the current choice and open a
  sheet to pick (`showSettingsChoice`, `SettingsChoiceRow` with a check).
  Closing the sheet changes nothing.
- **About:** the version (reads left to right in Arabic too, `1.2.3 (45)`),
  the privacy policy and terms (the `website/` pages, `LegalLinks` in
  `lib/core/legal/legal_links.dart`, opened through `openLinkProvider`) and
  open-source licenses (Flutter's licenses page).

## Architecture (layered, state: riverpod)
- Model: `lib/features/settings/domain/entities/app_settings.dart`
- Repository: `lib/features/settings/domain/repositories/settings_repository.dart` (SharedPreferences)
- State holder: `lib/features/settings/presentation/` (Riverpod (Notifier))
- UI: `settings_view.dart` is pure UI (state in, callbacks out);
  `settings_page.dart` connects it to the state holder.
- Route: `/settings` (`AppRoutes.settings`), the third branch of the tab
  shell in `app_router.dart`.

## Tests
- Repository: `test/features/settings/data/`
- State holder: `test/features/settings/presentation/`
- View: `test/features/settings/presentation/settings_view_test.dart`
- Page (legal links): `test/features/settings/presentation/settings_page_test.dart`, `test/core/legal/legal_links_test.dart`
- Integration: `integration_test/app_test.dart` (home → the Settings tab → English → Arabic)
