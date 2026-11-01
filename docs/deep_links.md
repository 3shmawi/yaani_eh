# Deep links

Routing uses go_router; every route in `lib/core/router/app_routes.dart` is
also a deep link.

| Path | Screen |
|---|---|
| `/` | Home |
| `/item/<slug>` | One item: a drink today, later a term or a history page (e.g. `/item/flat_white`); unknown or malformed slugs show not-found |
| `/search?q=<text>` | Search, optionally pre-filled (`q` is cleaned: control/direction characters removed, trimmed, max 60) |
| `/settings` | Settings |
| `/welcome` | The first-open welcome. `/` redirects here until it's been seen (finished or skipped); other links open what they link to. Query parameters are ignored |
| `/item/<slug>/steps` | An item's «طريقة التحضير», one step at a time, over the drink page; a drink without a recipe (or unknown) says so with a way back |
| `/favorites` | The Favorites tab (the items saved on the phone) |
| `/drink/<rest>` | Old links from earlier versions: redirected to `/item/<rest>` (query kept), so shared links keep working. `/drinks/...` and other look-alikes are not-found |

## Custom scheme (works now)
`yaanieh://settings` — test with:
```bash
adb shell am start -a android.intent.action.VIEW -d "yaanieh://settings"
xcrun simctl openurl booted "yaanieh://settings"
```

## https links (App Links / Universal Links)
Host: `example.com`. Needs, once:
1. The website served from that domain (root), including
   `website/.well-known/assetlinks.json` and
   `website/.well-known/apple-app-site-association`.
2. `assetlinks.json`: replace the SHA-256 with Play Console → Setup →
   App signing → "App signing key certificate" fingerprint.
3. `apple-app-site-association`: check the Team ID (`9RA43G2P63`).
4. Apple Developer → Identifiers → `com.mohager.yaanieh` → enable
   **Associated Domains** (then CI regenerates the profile).

If no domain was chosen at creation, add later: intent filter in
`AndroidManifest.xml` (`android:autoVerify="true"`, scheme https) and
`ios/Runner/Runner.entitlements` with `applinks:<domain>`.
