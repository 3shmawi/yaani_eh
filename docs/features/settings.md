# Feature: settings (language & theme)

## What it does
Lets the user choose the app language (Arabic, English, or the phone's
language). Choices apply instantly and are saved on the device. Arabic
switches the whole UI to right-to-left.

**Defaults:** a first launch opens in **Arabic** (the app is for Egyptian
Arabic speakers, whatever the phone's language) and **dark**. «زي لغة
الموبايل» is stored as its own choice (`system`), so it isn't mistaken for a
first launch.

**Theme:** the light palette isn't finished, so the app always runs dark
and the theme section is hidden (`AppTheme.lightModeReady = false`;
`AppTheme.modeFor` ignores the stored theme until then). The choice is still
stored and the light theme still built and tested, so setting the flag to
`true` brings the section back.

## Architecture (layered, state: riverpod)
- Model: `lib/features/settings/domain/entities/app_settings.dart`
- Repository: `lib/features/settings/domain/repositories/settings_repository.dart` (SharedPreferences)
- State holder: `lib/features/settings/presentation/` (Riverpod (Notifier))
- UI: `settings_view.dart` is pure UI (state in, callbacks out);
  `settings_page.dart` connects it to the state holder.
- Route: `/settings` (`AppRoutes.settings`).

## Tests
- Repository: `test/features/settings/data/`
- State holder: `test/features/settings/presentation/`
- View: `test/features/settings/presentation/settings_view_test.dart`
- Integration: `integration_test/app_test.dart` (home → settings)
