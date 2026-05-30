#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app}"

if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="$(find build -path "*.xcarchive/Products/Applications/*.app" -type d -print -quit)"
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Signed iOS app not found."
  echo "Run this script after the IPA archive step or pass the signed .app path."
  exit 1
fi

INFO_PLIST="$APP_PATH/Info.plist"
ENTITLEMENTS="$(mktemp)"
trap 'rm -f "$ENTITLEMENTS"' EXIT

codesign -d --entitlements :- "$APP_PATH" >"$ENTITLEMENTS" 2>/dev/null

echo "=== Signed app ==="
echo "$APP_PATH"
echo
echo "=== Signed entitlements ==="
cat "$ENTITLEMENTS"
echo
echo "=== NFC Info.plist values ==="
/usr/libexec/PlistBuddy -c "Print :NFCReaderUsageDescription" "$INFO_PLIST"
/usr/libexec/PlistBuddy \
  -c "Print :com.apple.developer.nfc.readersession.iso7816.select-identifiers" \
  "$INFO_PLIST"

grep -q "com.apple.developer.nfc.readersession.formats" "$ENTITLEMENTS" || {
  echo "ERROR: signed app is missing NFC reader session formats entitlement."
  exit 1
}

grep -q "<string>TAG</string>" "$ENTITLEMENTS" || {
  echo "ERROR: signed app NFC entitlement does not include TAG."
  exit 1
}

/usr/libexec/PlistBuddy \
  -c "Print :com.apple.developer.nfc.readersession.iso7816.select-identifiers" \
  "$INFO_PLIST" | grep -q "D2760000850101" || {
  echo "ERROR: signed app Info.plist is missing the Type 4 NDEF AID."
  exit 1
}

echo
echo "NFC signing configuration looks correct."
