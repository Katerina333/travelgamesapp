# Releasing MileQuest to TestFlight / App Store

Command-line only; no Xcode GUI. Mirrors the proven recipe from the sibling
Tarot App project on this same Mac (same team, same ASC API key).

## App Store Connect identity

| Thing | Value |
| --- | --- |
| App name | MileQuest: Road Trip Games |
| Bundle ID | `com.itpmgroup.travelgames` |
| ASC app ID | `6792571996` |
| Apple Team ID | `635LDGUSAA` (ITPM GROUP) |
| Distribution profile | `MileQuest AppStore` (App Store distribution, created via fastlane sigh) |
| ASC API Key ID | `6H9473YC84` |
| ASC API Issuer ID | `43e2c7c8-f457-4d02-8704-a3bb3575b3c3` |
| `.p8` key | `keys/AuthKey_6H9473YC84.p8` (gitignored; also copied to `~/.appstoreconnect/private_keys/` for altool) |

## ⚠️ The #1 gotcha: keep the Mac awake during upload

`xcrun altool --upload-app` **hangs silently and never times out if the Mac
sleeps mid-transfer** — it will sit "uploading" for hours. The actual transfer
of this build is ~1–2 seconds. Always wrap the upload in `caffeinate` and keep
the machine plugged in and awake until "UPLOAD SUCCEEDED" prints.

## Signing (pinned in project.yml)

- **Release = manual** distribution signing on the **app target only**:
  `CODE_SIGN_STYLE=Manual`, `CODE_SIGN_IDENTITY="Apple Distribution"`,
  `PROVISIONING_PROFILE_SPECIFIER="MileQuest AppStore"`. Automatic signing
  resolves to a *development* profile (needs a registered device) and breaks
  headless CLI archives.
- **SPM resource bundles must stay on default signing** — do NOT push the
  manual identity onto them or the archive fails with "requires a development
  team" (ContentKit_ContentKit was the offender).
- **Debug = automatic** so simulator/device runs need zero setup.
- `ITSAppUsesNonExemptEncryption=false` in Info.plist skips the
  export-compliance prompt on every upload.

## Bump the build number every upload

ASC rejects a duplicate build number for the same version. The tooling uses a
UTC-timestamp build number (`date -u +%Y%m%d%H%M`) so it is always unique and
increasing. Marketing version lives in `Config/AppConfig.xcconfig`
(`APP_MARKETING_VERSION`).

## Upload a build — fastlane-free (recommended, most robust)

```bash
cd "/Users/macbookpro/Documents/Travel Games App/travelgamesapp"
caffeinate -is Tools/upload_testflight.sh        # archive → export → validate → upload
```

Or drive fastlane (works, but the Homebrew fastlane install is fragile — see
below):

```bash
LC_ALL=en_US.UTF-8 caffeinate -is fastlane beta
```

After "UPLOAD SUCCEEDED" the build appears in TestFlight after ~5–15 min of
Apple-side processing.

## Upload localised store metadata (all 9 locales)

```bash
LC_ALL=en_US.UTF-8 caffeinate -is fastlane metadata
```

Pushes name/subtitle/description/keywords/promotional text for en-US, en-GB,
en-AU, es-MX, pt-BR, uk, fr-FR, fr-CA, zh-Hans from `fastlane/metadata/<locale>/`.

**Known benign error:** the `metadata` lane exits non-zero with
`review_attachment_file … No data (RuntimeError)`. This is a fastlane/deliver
bug in `fetch_app_store_review_detail` for a version that has no App Review
detail yet. **All localized metadata is already uploaded before this trailing
step runs** (verified in the deliver log: every locale logs "Uploading metadata
… for localized version/info" before the crash), so the listing IS updated. The
error disappears once App Review contact info exists on the version (set it once
in the ASC UI, or add `fastlane/metadata/review_information/`).

## Homebrew fastlane fragility

If fastlane dies with `Could not find '<gem>'` (e.g. sysrandom, digest-crc,
nkf) after a Ruby upgrade, the native gem extensions are built for the wrong
Ruby ABI. Fix: `brew reinstall fastlane`. fastlane also requires a UTF-8 locale
(`LC_ALL=en_US.UTF-8`). The `Tools/upload_testflight.sh` path avoids all of this.

## History

- v1.0 build 1 — first TestFlight upload 2026-07-20 (Delivery UUID
  ee7637d8-bf01-4c9b-bf10-71ba074a6341). 9-locale metadata uploaded same day.
