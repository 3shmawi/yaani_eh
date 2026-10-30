# Design

The UI is designed first in Claude (Design System + Design artifacts), then
built to match. Code never invents its own look.

| Source | Link |
|---|---|
| Design System (tokens, components, guidelines) | https://claude.ai/artifact/5t4sEcMC4r4eSLwJ8CntK8 |
| Screens (Design canvas) | https://claude.ai/artifact/BwpKY5KbUnvoSsaiyLq1DB |
| App icon / store screenshots | the canvas: `Icon`, `IconForeground`, `Store1…5`, `Social` artboards |

Read the Design System's `project/README.md` and `project/tokens.json`, the
component READMEs under `project/components/`, and the screen's
`project/<Screen>.dc.html` artboard before building a screen.

## Tokens → code
| Design System token | Code |
|---|---|
| Colors that change with the theme | `AppPalette` (light/dark) in `app_colors.dart`, read with `context.palette`; Material roles are overridden from it in `AppTheme` |
| Colors that never change (header band, clear glass, selected) | `AppColors` in `app_colors.dart` |
| Type scale (Latin + Arabic) | `app_text_styles.dart`: `context.text(TextRole.x)` for UI copy, `AppTextStyles.forText(string, role)` for content (picks the font by the string's script) |
| Spacing, radius, blur, sizes | `app_dimens.dart` (`space1…space10`, `radiusSm…Pill`, `touchTarget`, `controlHeight`, `chipHeight`…); blur sigma = CSS value ÷ 2 |
| Icons (Phosphor, Regular + Fill) | `app_icons.dart` (`AppIcons`, `AppIconsFill`) — fonts bundled in `assets/fonts/Phosphor` |
| Glass (clear / frosted, tone, lite) | `AppGlass` in `lib/core/ui/app_ui.dart` (+ `glass_tone.dart`) |
| Button, IconButton, Card | `AppButton`, `AppIconButton`, `AppCard` in `app_ui.dart` |
| DrinkCard ("caption below": photo tile, glass controls, text on the surface) | `core/widgets/drink_card.dart`; type `TextRole.cardTitle` / `cardBody` |
| Motion (durations, curves, press scale, list stagger) | `AppMotion` in `app_dimens.dart`; `AppReveal` (list entry) and `AppPressable` (card press) in `app_ui.dart` |
| HeaderBand, EmptyState, ErrorState, OfflineBanner | `lib/core/widgets/` (`header_band.dart`, `state_views.dart`, `offline_banner.dart`) |
| Bidi (ranges, `0.75×`, Latin names in Arabic) | `Bidi.range(min, max)`, `Bidi.ltr(text)` in `lib/core/text/bidi.dart` |

When the Design System changes, update these files first, then screens.

## UI style: glass
Screens use `lib/core/ui/app_ui.dart` (`AppScaffold`, `AppGlass`, `AppCard`,
`AppIconButton`, `AppButton`). With **glass** (Liquid Glass, iOS 26/27 look via
`liquid_glass_widgets`):
- **Clear** glass is for controls (icon buttons, chips, search, tab bar,
  pronounce pill); its tone follows the photo behind it (`GlassTone.auto` +
  `backdrop:`). **Frosted** glass is for reading (card labels, answer card,
  sheets, dialogs).
- Glass needs content behind it: a drink photo, the `HeaderBand`, or the
  brand gradient (`AppBackground`). `AppScaffold` defaults to the flat
  `surface`, where text sits on solid colors.
- Lite mode (no blur, no drop shadow, `glass-fill-lite` + rim) turns on by itself with Reduce
  Transparency / Increase Contrast and on devices too slow for the shader
  (`adaptiveQuality`); the header band turns flat espresso there too.
- At most two glass layers on top of each other; lists of many cards use
  `GlassQuality.minimal` to keep scrolling smooth on mid-range Android.
- Text on glass must stay ≥ 4.5:1 — test on the busiest photo, in light and
  dark, and with iOS 27's transparency slider at "clear".
- Accessibility: Reduce Motion and Increase Contrast are respected
  automatically; tests run with solid surfaces (`AppUi.testWrap`).
- When Flutter ships official Cupertino Liquid Glass, swap the
  implementation inside `app_ui.dart` only.

## Fonts
`AppFonts.latin` + `AppFonts.arabic` (lib/core/theme/app_fonts.dart), bundled
from Google Fonts in `assets/fonts/` (static TTF per weight, licenses shown on
the app's licenses page). Arabic characters fall back to the Arabic font
automatically. To change fonts: run
`python3 <kit>/kit_tools/fetch_fonts.py assets/fonts "<Latin>" "<Arabic>"`,
update the `fonts:` section in pubspec.yaml and the two constants.

## App icon & splash
`assets/branding/` holds the icon and splash rendered from the canvas
artboards `Icon` and `IconForeground` by `node tool/render_branding.js`
(Playwright, bundled Readex Pro, so the «؟» is exact): `icon.png` (1024, no
transparency), `icon_background.png` + `icon_foreground.png` (adaptive icon;
the mark already sits in the safe zone, so the inset is 0), `splash.png`
(768), `splash_android12.png` (1152, mark inside the central circle) and
`splash_background.png` (the header gradient). After changing them:
```bash
dart run flutter_native_splash:create
dart run flutter_launcher_icons            # single-flavor projects
dart run flutter_flavorizr -p android:icons,ios:icons   # projects with flavors
```

## Screen checklist (each screen in the design → code)
- Matches the design at 375×812, and still works on a small phone (320 wide),
  a large phone and a tablet.
- Has all states: loading (skeleton/adaptive spinner), empty, error with
  retry, success, offline.
- Arabic RTL and dark mode checked.
- Touch targets ≥ 48×48, text contrast ≥ 4.5:1, works with large text
  (system font scale 1.3+), every icon button has a semantics label/tooltip.
- Motion: short (150–300 ms), purposeful; respects "reduce motion".
- Platform-adaptive: iOS look on iOS (Cupertino), Material on Android.
