# MileQuest — Road Trip Family Games

iOS 17+ universal app (iPhone + iPad). Screen-light travel games for kids —
the phone is a game master, not a screen to stare at. Fully offline.

## Structure

- `App/` — composition root (SwiftUI, SwiftData container, theming)
- `Packages/CoreKit` — models, SwiftData schema, shared types
- `Packages/DesignSystem` — Light/Night/Auto themes, tokens, components
- `Packages/GameEngine` — `TripGame` protocol, `GameRegistry`, sessions, eligibility
- `Packages/TripKit` — trip state machine, game board generator
- `Packages/ContentKit` — locale × age-band JSON content packs
- `Packages/PaywallKit` — PlaytimeMeter (10-min free gate), parental gate
- `Packages/Games/` — one package per game (plugin architecture)
- `Config/` — xcconfig (bundle `com.itpmgroup.travelgames`, team `635LDGUSAA`)
- `fastlane/` — build/beta/release lanes

## Building

```sh
xcodegen generate          # produces MileQuest.xcodeproj (not committed)
open MileQuest.xcodeproj
```

Run package tests: `swift test` inside any `Packages/*` directory.

## Signing & release

The owner places the App Store Connect API key at `keys/AuthKey_<KEYID>.p8`
(gitignored) and copies `fastlane/.env.template` → `fastlane/.env`.
Lanes: `bundle exec fastlane build | beta | release` (§8.3 of the dev plan).

Development plan: see `docs/DEVELOPMENT_PLAN.md`.
