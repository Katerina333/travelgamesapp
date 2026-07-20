#!/usr/bin/env bash
# Fastlane-free TestFlight upload — mirrors the proven Tarot App recipe
# (docs/RELEASING.md in that project). Pure xcodebuild + xcrun altool, so it
# does not depend on fastlane's Ruby gem stack.
#
# Usage:  Tools/upload_testflight.sh [build_number]
#   build_number defaults to a UTC timestamp (always unique, always increasing).
#
# Requires: the ASC .p8 key present in keys/ AND at
#   ~/.appstoreconnect/private_keys/  (this script copies it there).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# --- config (matches Config/AppConfig.xcconfig + fastlane/.env) ---------------
SCHEME="MileQuest"
PROJECT="MileQuest.xcodeproj"
BUNDLE_ID="com.itpmgroup.travelgames"
KEY_ID="6H9473YC84"
ISSUER_ID="43e2c7c8-f457-4d02-8704-a3bb3575b3c3"
KEY_FILE="keys/AuthKey_${KEY_ID}.p8"
BUILD_NO="${1:-$(date -u +%Y%m%d%H%M)}"

[ -f "$KEY_FILE" ] || { echo "ERROR: $KEY_FILE not found (owner adds it)."; exit 1; }

# altool locates the key automatically here.
mkdir -p ~/.appstoreconnect/private_keys
cp "$KEY_FILE" ~/.appstoreconnect/private_keys/

echo "▸ Regenerating project (build number $BUILD_NO)…"
xcodegen generate >/dev/null

echo "▸ Archiving (Release, manual distribution signing)…"
rm -rf build/MileQuest.xcarchive build/export
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/MileQuest.xcarchive \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ROOT/$KEY_FILE" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" \
  CURRENT_PROJECT_VERSION="$BUILD_NO" archive

echo "▸ Exporting .ipa…"
xcodebuild -exportArchive \
  -archivePath build/MileQuest.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ROOT/$KEY_FILE" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID"

IPA="build/export/${SCHEME}.ipa"
echo "▸ Validating $IPA…"
xcrun altool --validate-app -f "$IPA" -t ios --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "▸ Uploading to TestFlight…"
xcrun altool --upload-app -f "$IPA" -t ios --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "✅ UPLOAD SUCCEEDED — build $BUILD_NO. Appears in TestFlight after ~5–15 min processing."
