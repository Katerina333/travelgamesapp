# Road Trip Family Games — Technical Development Plan

**Platform:** iOS native (iPhone + iPad universal build)
**Minimum target:** iOS 17+
**Working title:** MileQuest (placeholder)
**Core promise:** Keep kids busy on car trips *without* screen watching — the phone is a game master, not a screen to stare at. Fully offline.

---

## 1. Product Scope (MVP)

### 1.1 Game roster (20 games)

Games are grouped by interaction model. Note the charades change: **all charade-type games use only fingers and face** (no standing, no body movement — everyone is belted in a car seat).

| # | Game | Interaction | Screen time |
|---|------|-------------|-------------|
| 1 | Smart Road Bingo | Look outside, tap to mark | Minimal |
| 2 | License Plate Collector | Look outside, tap to collect | Minimal |
| 3 | Alphabet Race | Look outside | Minimal |
| 4 | Color Hunt | Voice prompt, look outside | None |
| 5 | Spotting Missions | Voice prompt, look outside | None |
| 6 | 20 Questions (AI referee) | Voice/audio | None |
| 7 | Kids Trivia (voice mode) | Audio, spoken answers | None |
| 8 | Would You Rather — Kids | Audio | None |
| 9 | Story Chain Recorder | Voice recording | None |
| 10 | Sound Guess | Audio playback | None |
| 11 | Categories | Audio + timer | None |
| 12 | Karaoke Roulette | Audio prompt, singing | None |
| 13 | Finger & Face Charades | 2-sec peek at prompt, then show with **fingers/facial expressions only** (e.g. "cat" = whiskers gesture, "3 elephants" = fingers + trunk face) | 2 seconds |
| 14 | Forehead Guess | Phone on forehead (screen faces others) | Indirect |
| 15 | Pass-the-Phone Doodle | 30-sec finger drawing | Short burst |
| 16 | Emoji Riddles | 1 kid sees 3 emojis, describes | Short burst |
| 17 | Hot Potato Word Bomb | Pass phone fast; hidden timer "explodes" while naming category items | Pass-around |
| 18 | Memory Chain | App flashes an icon sequence to one player; repeat it, pass on, sequence grows | Pass-around |
| 19 | Finish the Drawing | Each player adds 15 sec to a shared doodle, then guess what it became | Pass-around |
| 20 | Secret Word (Taboo-style) | Describe the shown word without saying 3 forbidden words, pass phone | Pass-around |
| 21 | Milestone Missions | Time-triggered challenges (every N minutes) | None |
| 22 | Trip Leaderboard & Rewards | Score hub across all games | Parent-managed |
| 23 | Route Facts / Where Are We? | GPS pop-up facts about places along the A→B route + progress view (car mode, §1.3); AI-narrated in Stage 3 | Minimal |

### 1.3 Route Facts & "Where Are We?" — Stage 1 feature
The user enters travel points **A and B** at trip setup; the app downloads interesting facts/history along the route from Wikipedia and pops them up by GPS during the drive — fully offline in the car.

**Setup (one online moment):**
1. User enters origin (A) and destination (B); MapKit geocodes both and fetches the route polyline (requires network — done at trip creation, then cached).
2. The app builds a **route corridor** (polyline + ~10 km buffer) and downloads a **Route Pack**: POIs inside the corridor from Wikidata/Wikipedia (towns, landmarks, rivers, castles) with coords + 2–3 verified facts each, plus distance-along-route markers. Versioned, typically 3–15 MB.
3. If the user schedules the trip for later, the 1-h-before notification reminds them to download the Route Pack on Wi-Fi (auto-download attempted at scheduling time).

**In the car (fully offline):**
- `CLLocationManager` (no internet needed) matches position against the polyline. When a POI is ~1–2 min ahead, a **fact pop-up** appears: read on screen or "Read aloud" via TTS (driver-safe: passengers tap, or audio plays for everyone). Optional quiz question per fact for leaderboard points.
- **"Where Are We?" view** — a schematic offline route line (custom Canvas, no map tiles needed): A→B with the car's live dot, % completed, distance left, passed/upcoming POI dots, and nearest town name from the pack. Kids can check progress anytime — a friendly answer to "are we there yet?" without needing the dashboard.
- Facts are age-filtered from the pack (kid-fact vs full-fact variants where available); attribution screen for Wikipedia (CC BY-SA).
- If no Route Pack was downloaded, the feature hides for that trip; everything else in the app remains 100% offline-from-install.
- Location permission (While Using) is requested contextually when the user first enters A/B points.

**Stage 3 upgrade — Passing-By Stories (AI):** Apple **Foundation Models framework (iOS 26+, on-device, offline)** retells the same pack facts as an age-styled narrated story + generated quiz — *strictly grounded in pack facts, never free generation*. Template narration (Stage 1 behaviour) remains the fallback on non–Apple Intelligence devices and unsupported languages.

### 1.2 Driver safety rule
- During traveler setup, one traveler is **marked as Driver**.
- The Driver is automatically excluded from: any game requiring looking at the screen, drawing, holding the phone, or peeking prompts (games 13–16, board-tapping in 1–3).
- The Driver **can** participate in pure audio games (20 Questions, Would You Rather, Categories, Story Chain, Karaoke, Trivia — answering verbally while a passenger judges).
- Game engine filters eligible players per game via a `driverSafe: Bool` flag in the game manifest.

### 1.4 Airplane travel mode
Selected at trip creation; the same game engine, different filtering and pacing:

- **Game manifest gains `travelModes: [.car, .plane]`.** Road-spotting games (Road Bingo, License Plate Collector, Alphabet Race, Color Hunt, Spotting Missions) are replaced by plane variants: **Cabin Bingo** (drink cart, seatbelt sign, cloud shapes, wing view), **Cloud Shapes** ("find a cloud that looks like…"), and **Airport I-Spy** (for the terminal wait).
- **Quiet Mode is on by default** for plane trips: no loud TTS through the speaker (prompts shown on screen for a parent to read aloud, or optional shared earbuds), no Karaoke Roulette / Sound Guess at volume — replaced by whisper-level variants (hum the tune instead of singing it).
- **No driver concept** — everyone plays; instead, an optional "sleeping passengers nearby" toggle further limits noisy games.
- **Milestones by time in both modes** — Milestone Missions trigger every N minutes; no GPS anywhere in the app.
- **True airplane-mode safe:** the whole app already works offline; a pre-flight check reminds users everything is downloaded (it always is in MVP).

### 1.5 Age-adaptive gameplay (core requirement)
Every game must feel attractive at the ages actually in the car/plane:

- **Age bands:** 3–5, 6–8, 9–12, 13+ (teen), adult. Set per traveler at onboarding.
- **Game Board generator** only recommends games whose manifest `ageRange` overlaps the travelers onboard, and orders them by fit (e.g. Memory Chain shines at 6–12; Secret Word at 9+).
- **Two-mode content selection (critical rule):**
  - **Guessing games** (Charades, Secret Word, 20 Questions, Emoji Riddles, Forehead Guess, Sound Guess): the prompt must be guessable by *everyone playing the round* — so the word pool is capped at the **youngest participating player's band**. A 5-year-old in the round means "cat," "pizza," "airplane" — never "influencer." Teens still have fun because performing "cat" for a laughing 5-year-old is the fun.
  - **Solo-performance games** (Trivia questions directed at one player, Memory Chain sequence length, timers, Hot Potato categories): difficulty scales to the **active player's** band — each person gets a challenge that fits them.
  - Manifest field: `contentScope: .youngestInRound | .activePlayer` per game; enforced by GameEngine, covered by unit tests.
- **Kids can sit out:** a parent can mark a traveler "napping" for a while; scope recalculates so older players get harder content until the youngest rejoins.
- **Handicap scoring:** optional "fair play" toggle gives younger kids point multipliers so the leaderboard stays exciting for everyone.
- Content packs are therefore keyed by **locale × age band** in `ContentKit`.

---

## 2. User Flows

### 2.1 Onboarding (first launch)
1. **Welcome** — value proposition, 2–3 swipe screens.
2. **Personalisation questions** — builds the first game trip:
   - **Travel type: Car or Airplane** (determines game filtering, milestone logic, and quiet mode — see §1.3).
   - Who is travelling? Add travelers: name, avatar, **age**.
   - **Mark the driver** (car trips only; required, exactly one).
   - Trip length estimate (short <1h / medium 1–3h / long 3h+).
   - **Start: "Travel now" or "Schedule start time"** — scheduled trips fire a local notification at start time ("Your trip starts now — ready to play? 🚗"), plus an optional reminder 1 h before ("Download your region pack while on Wi-Fi"). Scheduled trips sit on the home screen as "Upcoming" until started.
   - Destination name (optional, free text — used for "Are We There Yet?").
   - Interests per kid (animals, music, drawing, trivia…) → seeds game recommendations and content packs.
3. **Trip generation** — app assembles a personalised **Game Board** for the trip: recommended game sequence, age-filtered content packs, milestone missions spaced by trip length.
4. **Permissions** — microphone (voice games), notifications (optional). Location (While Using) is requested **only** if the user enables Passing-By Stories.
5. **Paywall (last step)** — see §3. Has a visible **close (X) button**; closing proceeds into the app on the free tier.

### 2.2 Trips, scheduling & pause/resume
- **Trip entity** is the core container: travelers, game board, scores, recordings, photos, trip stats, and a `status`: `scheduled → active → paused → completed`.
- **Scheduling:** trips created with a future start time are `scheduled`; a `UNUserNotificationCenter` local notification fires at start time and (optionally) 1 h before. Tapping it deep-links straight into the trip's game board.
- **Pause/close anytime:** all state (current game, round, scores, PlaytimeMeter seconds) is persisted to SwiftData on every state change — killing the app loses nothing. Home screen shows a prominent **"Continue trip"** card; games resume at the exact round. A trip pauses automatically when the app is backgrounded >5 min, and can be paused manually (rest stop, hotel night on a multi-day trip).
- **History:** past trips list with leaderboard results, story recordings, doodles, bingo boards; **create new trip** re-uses saved traveler profiles (only driver/duration/start need confirming).

### 2.3 Monetisation flow
- Onboarding paywall (dismissible).
- **Free play window: 10 minutes** of cumulative game time per trip session.
- At 10:00 a **blocking paywall pop-up** appears; user must subscribe to continue playing (trip data is never lost — history stays viewable free).
- Countdown handled by a `PlaytimeMeter` service (accumulates only while a game is active, survives app relaunch via persisted timestamp deltas — not wall clock, to avoid cheating via backgrounding but also not punishing rest stops).

---

## 3. Paywall & Subscriptions

- **StoreKit 2** with async/await purchase flow; local receipt validation + `Transaction.currentEntitlements`.
- Products: **Weekly** (with or without trial — A/B testable) and **Yearly** (badge "Best value — save X%").
- Layout: benefit list, plan selector (yearly pre-selected), CTA, restore purchases, terms/privacy links, **X to close** (onboarding variant only; the 10-minute pop-up variant is blocking).
- Remote-configurable copy/pricing display via a bundled + updatable JSON config (works offline with last-cached values; defaults shipped in bundle).
- Analytics events: paywall_shown (placement), plan_selected, purchase_success/fail, close_tapped.
- Consider RevenueCat as an optional wrapper to speed up A/B paywall testing; otherwise pure StoreKit 2 keeps zero third-party dependencies.

---

## 4. Architecture

### 4.1 High-level
- **Language/UI:** Swift 5.10+, **SwiftUI**, Observation framework (`@Observable`).
- **Pattern:** MVVM + lightweight Coordinator for navigation; feature-first modularisation via **Swift Package Manager local packages**.
- **Concurrency:** Swift Concurrency (async/await, actors for shared services).
- **Persistence:** **SwiftData** (iOS 17+) for Trips, Travelers, Scores, GameSessions. FileManager for audio recordings/doodles/photos (referenced by ID from SwiftData).
- **No backend required for MVP** — 100% offline. Optional later: CloudKit sync for trip history across family devices.

### 4.2 Module map
```
App (composition root, DI container)
├── CoreKit          — models, SwiftData schema, utilities
├── DesignSystem     — tokens, themes, components (see §5)
├── GameEngine       — game protocol, session runtime, scoring, player eligibility
├── Games/           — one package per game (plugin architecture, see §4.3)
├── TripKit          — trip lifecycle, game board generator, history
├── AudioKit         — TTS (AVSpeechSynthesizer), sound packs, recording (AVAudioEngine)
├── PlacesKit        — A/B geocoding + route corridor, Route Pack downloader, offline GPS/polyline matching, Where-Are-We view model
├── StoryAI          — Foundation Models wrapper, grounded story/quiz generation, template fallback
├── PaywallKit       — StoreKit 2, PlaytimeMeter, entitlement gate
├── ContentKit       — question/word/bingo packs, age filtering, pack loader
└── LocalizationKit  — string catalogs, content-pack localisation
```

### 4.3 Easy-to-add games (plugin architecture)
Every game conforms to a single protocol and ships as a self-contained package:

```swift
protocol TripGame {
    var manifest: GameManifest { get }   // id, name key, icon, min/max players,
                                          // ageRange, driverSafe, screenLevel,
                                          // requiredCapabilities (mic, gps, camera)
    func makeSetupView(session: GameSession) -> AnyView
    func makePlayView(session: GameSession) -> AnyView
    func score(_ event: GameEvent, into session: inout GameSession)
}
```
- Games are registered in a `GameRegistry`; the Game Board generator and library UI read only manifests.
- Adding a new game = new package + registry entry + localised content pack. No changes to core flows.
- Content (questions, words, bingo items, sounds) lives in versioned JSON packs in `ContentKit`, keyed by locale and age band — so new content can ship without touching game code (and later, be downloaded server-side).

### 4.4 Localisation from day one
**Launch locales (v1.0):** en-US, en-GB, en-AU, es-MX, pt-BR, uk (Ukrainian), fr-FR, fr-CA, zh-Hans.

- **String Catalogs (.xcstrings)** for all UI; no hardcoded strings — enforced by a SwiftLint custom rule. Regional variants override only strings that differ (en-GB/en-AU fall back to en, fr-CA → fr).
- **Content packs are locale-keyed JSON** (`words_en-US.json`, `words_uk.json`, …) with regional fallback chains — culturally localised, not just translated: "truck" vs "lorry", local animals/foods per market, license-plate game adapted to each country's plate system, trivia with locally relevant questions. Age-band keys inside each pack per §1.5.
- **TTS voices per exact region:** en-AU voice for Australians, fr-CA for Québec, zh-CN for Simplified Chinese; QA voice quality early — Ukrainian and Chinese voices need explicit verification per device.
- **Layout:** no fixed-width containers (French runs ~20% longer than English; Cyrillic glyphs are wider), pseudo-localisation testing, RTL-ready structure for the future.
- **Passing-By Stories:** Foundation Models supports a limited language set — verify per locale; where unsupported (likely uk at minimum), use the template-narration fallback in that language. Region-pack facts sourced from the corresponding-language Wikipedia where available.
- **App Store metadata** for all nine locales in `fastlane/metadata/<locale>/`; keyword research re-run per market later (Astro supports country-level data).

### 4.5 iPad adaptation
- Universal target, SwiftUI adaptive layouts: `NavigationSplitView` on iPad (trip sidebar + game area), size-class–driven grids for the game library and bingo boards.
- Bingo/doodle games get larger canvases on iPad; multi-column leaderboard.
- Supports all orientations on iPad; iPhone portrait-primary (landscape allowed in doodle/bingo).

---

## 5. Design System

### 5.1 Theming — Auto / Light / Night
- Three modes: **Light**, **Night**, and **Auto** (follows system appearance; optionally auto-switches to Night by local sunset time — nice touch for evening drives).
- Implemented as a `Theme` environment object resolving **semantic tokens**, not raw colors:
  - `background.primary/secondary`, `surface.card`, `content.primary/secondary`, `accent.primary`, `accent.success/warning`, `game.categoryColors[…]`
- Night theme is a true dark theme tuned for in-car use: near-black backgrounds (#0D0F14 range), reduced saturation, larger glow-free contrasts — avoids lighting up the cabin.
- All colors defined once in Asset Catalog with light/dark variants + token layer in `DesignSystem` package.

### 5.2 Foundations
- **Typography:** SF Pro / SF Rounded for kid-friendly warmth; full **Dynamic Type** support; display styles for game titles.
- **Spacing/radius scale:** 4-pt grid; radius tokens (s=8, m=16, l=24).
- **Components:** buttons (primary/secondary/ghost), player avatar chip, score badge, game card, timer ring, voice-wave indicator, paywall plan card, empty states.
- **Motion:** SwiftUI spring animations; confetti/celebration on wins; Reduce Motion respected.
- **Accessibility:** VoiceOver labels everywhere, min 44-pt targets, WCAG AA contrast in both themes, haptics for game events.
- **Icons/illustration:** SF Symbols + a small custom illustration set for game icons (consistent flat style, both themes).
- Documented in-repo: token reference + SwiftUI preview catalog (component gallery target) so designers/devs stay in sync.

### 5.3 Kid-friendly rules
- Large tap targets, minimal text for pre-readers (icons + TTS reads everything aloud).
- No external links, ads, or chat. Parent gate (math question) in front of settings/paywall/history deletion.

---

## 6. Key Technical Notes per Feature

- **Voice/TTS:** `AVSpeechSynthesizer` for prompts (offline). Sound packs bundled (CAF/AAC). Recording via `AVAudioEngine` → m4a files.
- **Milestone timer:** simple monotonic-clock scheduler paused when the trip is paused.
- **Passing-By Stories:** region packs as SQLite/JSON bundles keyed by geohash tiles; POI matching against heading + lookahead radius so stories arrive ~1–2 min *before* the landmark. Foundation Models via guided generation (`@Generable` structs: story ≤ 90 words, 1 quiz Q, 3 answers) with the pack facts injected as the only knowledge source; deterministic template fallback on unsupported devices. Requires device check at runtime (`SystemLanguageModel.default.availability`). Content licensing: Wikipedia/Wikidata (CC BY-SA) with attribution screen.
- **Doodle canvas:** SwiftUI `Canvas`/PencilKit (PencilKit gives free Apple Pencil support on iPad).
- **Playtime metering:** actor-based `PlaytimeMeter`, persists accumulated seconds per trip session in SwiftData; entitlement check via `PaywallKit` gate before each game start and on a 30-sec heartbeat.
- **App Intents (later):** "Start road trip" shortcut, CarPlay is explicitly out of scope (games are for passengers).

---

## 7. Development Plan — Stages (no time estimates; each stage ends with a working, testable build)

**Stage 1 — Submittable v1.0 (App Store–ready)**
Goal: a complete, localised, monetised game app that passes App Review.
- Foundations: workspace, SPM modules, `.xcconfig`, `.gitignore` (incl. `/keys/`), fastlane skeleton, DesignSystem tokens with Light/Night/Auto themes, SwiftData schema, `TripGame` protocol + `GameRegistry`, String Catalogs pipeline.
- Onboarding: travel type (car/plane), travelers + ages, driver marking, travel-now/scheduled start with notifications, personalised game board, permissions, dismissible paywall as last step.
- Trips: create/save/history, pause/close/resume with zero data loss, "Continue trip" card, trip state machine.
- **Launch game set (10 games)** covering every interaction type and both travel modes: Smart Road Bingo, Cabin Bingo (plane), 20 Questions, Kids Trivia (voice), Would You Rather, Finger & Face Charades, Forehead Guess, Hot Potato Word Bomb, Secret Word, Trip Leaderboard & Rewards. Age-adaptive rules (§1.5) fully enforced, driver exclusion enforced, quiet mode for plane.
- **Subscriptions live:** StoreKit 2 weekly + yearly, 10-minute free gate with 2-minute warning, blocking pop-up paywall, parental gate, restore purchases.
- **All nine locales shipped:** UI strings, content packs for the 10 games, TTS voices verified, localised App Store metadata in fastlane.
- **Route Facts & Where Are We?:** A/B point entry, route corridor + Route Pack download pipeline, offline GPS fact pop-ups with TTS, schematic progress view, quiz points integration.
- Release readiness: accessibility pass, offline/airplane-mode test matrix, performance targets (cold start <2s, 60fps), TestFlight beta, App Store assets from keyword research, `lane :release` submission. **Category decision: standard (Family/Games) with parental gate** — not the official Kids Category, which restricts analytics and paywall placement.

**Stage 2 — Full roster update (v1.1)**
Remaining 13 games as plugin packages (Memory Chain, Finish the Drawing, Pass-the-Phone Doodle, Emoji Riddles, Story Chain Recorder with audio recording, Sound Guess, Categories, Karaoke Roulette, Color Hunt, Spotting Missions, Alphabet Race, License Plate Collector, Milestone Missions), localised content packs for all of them, "napping" toggle, handicap scoring.

**Stage 3 — Passing-By Stories AI upgrade (v1.2, marquee feature)**
StoryAI grounded generation on Foundation Models turns Stage 1 Route Facts into narrated, age-styled stories with generated quizzes; per-language availability checks with template fallback. Strong ASO differentiator and Apple feature-pitch material.

**Stage 4 — Growth**
CloudKit family sync of trip history, Photo Safari + Lie Detector Trivia, additional locales/region packs, paywall A/B experiments, seasonal content packs.

**Parental gate spec (Stage 1):** shown before paywall, settings, subscription management, and trip-history deletion. Implementation: random spoken-number or simple math challenge ("Enter 7 × 4") with rotating variants, 3-attempt lockout for 60 seconds, never bypassable by relaunch. Purchases additionally protected by Ask to Buy / Face ID at the StoreKit level.

### Definition of Done — Stage 1 (submission build)
10 games playable fully offline · Route Facts with offline GPS pop-ups and Where-Are-We view · car + airplane modes · age-adaptive content with youngest-in-round rule · driver exclusion enforced · trip scheduling with start notification · pause/close/resume with zero data loss · trip history · weekly/yearly subscriptions with 10-min free gate and parental gate · Light/Night/Auto themes · iPhone + iPad · all nine locales (en-US, en-GB, en-AU, es-MX, pt-BR, uk, fr-FR, fr-CA, zh-Hans) with localised content packs and store metadata · `lane :release` uploads the build with the owner's .p8 key.

---

## 8. Repository, Git Workflow, Signing & App Store Release

Designed so a coding agent on the owner's Mac can build and ship end-to-end.

### 8.1 Repository & project identity
- **Git remote:** https://github.com/Katerina333/travelgamesapp (repo exists, empty — first push comes from Stage 1 scaffolding).
- **Bundle ID:** `com.itpmgroup.travelgames`
- **Team ID:** `635LDGUSAA` (ITPM GROUP)
- **App Store Connect API Issuer ID:** `43e2c7c8-f457-4d02-8704-a3bb3575b3c3` (account-wide for the API key)
- **API Key (.p8):** placed by the owner locally at **`/keys/AuthKey_<KEYID>.p8`** — the Key ID is read from the filename. Never committed, printed, or logged.
- All identity values live in `Config/AppConfig.xcconfig` + `fastlane/.env` (`ASC_KEY_ID`, `ASC_ISSUER_ID=43e2c7c8-f457-4d02-8704-a3bb3575b3c3`, `ASC_KEY_PATH=./keys/AuthKey_<KEYID>.p8`, `APP_IDENTIFIER=com.itpmgroup.travelgames`, `TEAM_ID=635LDGUSAA`).

### 8.2 Git workflow
- **Branches:** `main` (protected, always releasable) ← PRs from `feature/<stage>-<name>` (e.g. `feature/s1-onboarding`, `feature/s1-game-roadbingo`). One feature/game per branch.
- **First commit** must include `.gitignore` covering: `/keys/`, `fastlane/.env`, `*.p8`, `xcuserdata/`, `DerivedData/`, `.DS_Store`, `fastlane/report.xml`, build artifacts. Verify with `git check-ignore keys/AuthKey_test.p8` before anything else is committed.
- **Commits:** conventional commits (`feat:`, `fix:`, `chore:`, `l10n:`); small and buildable — every commit on `main` must compile and pass tests.
- **PR checks:** unit tests + SwiftLint (incl. the no-hardcoded-strings rule) must pass before merge; agent self-reviews the diff for accidental secrets before each push.
- **Releases:** tag on `main` as `v1.0.0` (SemVer); build number auto-incremented by fastlane. Tag → release lane → App Store.
- **Never** force-push `main`; never commit anything from `/keys/`.

### 8.3 Fastlane lanes
- `lane :build` — resolve packages, run tests, build Release archive.
- `lane :beta` — increment build number, archive, upload to **TestFlight** via `app_store_connect_api_key` + `pilot`.
- `lane :release` — archive, upload build + localised metadata (from `fastlane/metadata/<locale>/` for all nine locales) via `deliver`.
- Signing: Xcode automatic (cloud-managed) signing with the API key and Team `635LDGUSAA` — no manual certificates.

### 8.4 Release steps (repeatable checklist)
1. Confirm `/keys/AuthKey_<KEYID>.p8` exists locally and `fastlane/.env` points to it (owner adds the key; agent never asks for its contents).
2. `git checkout main && git pull` — ensure clean, tests green (`lane :build`).
3. Bump marketing version in `AppConfig.xcconfig`; update release notes in `fastlane/metadata/<locale>/release_notes.txt` (all nine locales).
4. `bundle exec fastlane beta` → verify the build appears in TestFlight, smoke-test on device (offline mode, paywall, one game per interaction type).
5. Tag: `git tag v1.x.x && git push origin main --tags`.
6. `bundle exec fastlane release` → uploads build + metadata to App Store Connect for `com.itpmgroup.travelgames`.
7. In App Store Connect: attach the build to the version, answer export compliance (app uses only standard HTTPS — "No" to proprietary encryption), submit for review. First submission: manual review of screenshots, privacy labels (no data collected — everything on-device), parental-gate demo notes for the reviewer.
8. After approval: phased release ON; monitor crashes; hotfixes branch from the release tag as `hotfix/v1.x.y`.

### 8.5 Handoff notes for the coding agent
Build order = stage order (§7). Concretely:
1. Stage 1 scaffolding first: clone https://github.com/Katerina333/travelgamesapp, initial commit with `.gitignore` (incl. `/keys/`), workspace, SPM packages, `AppConfig.xcconfig` (bundle `com.itpmgroup.travelgames`, team `635LDGUSAA`), fastlane skeleton with the values from §8.1, DesignSystem tokens with Light/Night/Auto, SwiftData schema, `TripGame` protocol + `GameRegistry`, String Catalogs (no hardcoded strings — SwiftLint rule).
2. Implement one vertical slice end-to-end before scaling: onboarding → trip creation → Road Bingo → leaderboard → pause/resume. Prove persistence by force-quitting mid-round.
3. Every game = separate SPM package conforming to `TripGame`; content in locale × age-band JSON packs in `ContentKit`.
4. Unit tests required for: PlaytimeMeter (10-min gate, 2-min warning, relaunch survival), youngest-in-round vs active-player content scoping, driver-eligibility filtering, trip state machine (`scheduled/active/paused/completed`), paywall entitlement gate, route-corridor POI matching.
5. Foundation Models code guarded by availability checks; template fallback path always compiles and runs.
6. Run `lane :beta` / `lane :release` only after confirming the .p8 key is present in `/keys/`.

## 9. Risks & Mitigations
- **App Review (subscriptions for kids' content):** clear parent gate before purchase; transparent free-tier description on paywall.
- **TTS quality across languages:** test AVSpeech voices per locale early; fall back to on-screen text + parent reads aloud.
- **Motion sickness:** keep screen-burst games short by design (already the product philosophy); add a settings note.
- **10-min meter frustration:** show a gentle 2-minute warning before the blocking paywall so a game round isn't cut mid-play.
