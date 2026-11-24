# Design: menu scanner («صوّر المنيو»)

Status: **draft, waiting for approval** · 2026-11-22

## Goal
Point the phone at a café menu, take one photo, and get a card for every
name on it that Yaani Eh can explain. It's the app's promise ("explains
cafe menus") in one step: no typing names you can't spell.

## What the user sees
1. Home header and search page: a camera button «صوّر المنيو» (key
   `scan_button`). Route `/scan` (name `menu_scan`, deep link
   `yaanieh://scan`).
2. The system camera opens (or "pick a photo" for one already taken).
3. «بنقرا المنيو…» (loading), then «لقينا ٧ حاجات في المنيو»: the photo
   thumbnail on top, then the matched items as `ItemCard`s in menu order.
   Tap one → `/item/:slug`; back returns to the results.
4. Nothing matched → empty state «مالقيناش حاجة نعرفها» + tips (closer, more
   light, straight) + «صوّر تاني». The camera was refused → a message
   with «افتح الإعدادات». Recognition failed → `ErrorView` + retry.
5. Works offline: recognition and matching both run on the phone.

## How it works
- **Photo:** `image_picker` 1.2.4 (camera or gallery). No live camera
  preview in v1: one photo is simpler, cheaper and enough for a menu.
- **Text recognition, on the phone:**
  - Android: ML Kit Text Recognition v2, Latin model through Google Play
    services (≈ 260 KB in the app, model downloaded by Play services).
  - iOS: Apple's Vision framework (`VNRecognizeTextRequest`, built into
    iOS, adds nothing) through a small method channel in
    `core/text_recognition/`. ML Kit's iOS pod adds ≈ 38 MB, so it's not used.
  - Latin script only. Menus print the names we explain in Latin letters;
    Arabic lines are ignored in v1.
- **Matching:** each recognized line (and every 1–3-word window in it) is
  looked up with the existing `SearchItems` index (one typo allowed, names
  only, no description matches). An item counts once, in the order it first
  appears. Lines are capped (200 lines, 60 chars each) so a huge photo
  can't stall the phone.
- **Layers:** `features/menu_scan/` (layered). Domain: `TextRecognizer`
  interface + `ScanMenu` use case (lines → items) — pure Dart and unit
  tested with fixed lines. Data: `MlKitTextRecognizer` / `VisionTextRecognizer`.
  Presentation: `scan_page.dart` → `scan_view.dart`.

## Privacy and stores
- The photo never leaves the phone, isn't saved by the app, and is dropped
  when the results page closes. Recognized text isn't logged or sent.
- iOS `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` in
  Arabic and English. Android: no new permission (the system camera takes
  the photo).
- Privacy policy (`website/`): one line on the camera, on-device only.
  Play "Data safety": unchanged (nothing collected).

## Flag, analytics, errors
- `FeatureFlags.isEnabled(Flags.menuScanner)`, off until it's checked on
  real menus.
- Events: `menu_scan_started {source: camera|gallery}`,
  `menu_scan_finished {matched_count, line_count, ms}`,
  `menu_scan_item_opened {position}`. No text, no item names from the photo.
- Recognition errors → `Monitoring.captureException` (no image attached).

## Tests
- Unit: `ScanMenu` with real menu lines (typos, prices, "Latte ...... 45",
  Arabic + Latin on one line, duplicates, 0 matches, 1,000 lines, hostile
  strings).
- Widget: every state (loading, results, empty, permission denied, error,
  offline) with `expectAccessible()`; RTL and dark.
- Integration: demo flow with a fake recognizer returning a sample menu.
- Security: deep link `yaanieh://scan` case.

## Open questions for you
1. iOS through Apple Vision (no size cost, a bit of native Swift) vs ML Kit
   everywhere (one code path, +38 MB on iOS). **Recommended: Vision.**
2. v1 photo-only vs live camera with boxes drawn on the names (nicer, ~2×
   the work). **Recommended: photo first.**
3. Recognize Arabic lines later (Apple Vision reads Arabic on recent iOS;
   Android would need another engine).
