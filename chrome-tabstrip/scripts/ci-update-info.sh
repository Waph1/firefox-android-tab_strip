#!/usr/bin/env bash
# GitHub Actions: scrive su stdout il file update.json pubblicato con l'APK in ogni Release. Firefox lo legge
# dall'ultima Release per sapere se c'è un aggiornamento da proporre (vedi SelfUpdater.kt nella patch).
#
# Uso: ci-update-info.sh <file.apk> <url-da-cui-scaricare-l-apk>

source "$(dirname "$0")/common.sh"

APK="${1:-}"
APK_URL="${2:-}"
[ -f "$APK" ] && [ -n "$APK_URL" ] || die "uso: $0 <file.apk> <url-da-cui-scaricare-l-apk>"

BUILD_TOOLS="$(find "${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}" -path '*/build-tools/*/apksigner' | sort -V | tail -1)"
[ -n "$BUILD_TOOLS" ] || die "build-tools non trovati nell'Android SDK"
BUILD_TOOLS="$(dirname "$BUILD_TOOLS")"

BADGING="$("$BUILD_TOOLS/aapt2" dump badging "$APK" | head -1)"
PACKAGE="$(echo "$BADGING" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
VERSION_CODE="$(echo "$BADGING" | sed -n "s/.* versionCode='\([0-9]*\)'.*/\1/p")"
VERSION_NAME="$(echo "$BADGING" | sed -n "s/.* versionName='\([^']*\)'.*/\1/p")"
CERTIFICATE="$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK" |
    sed -n 's/^.*[Ss]igner.* certificate SHA-256 digest: //p' | head -1 | tr -d ':' | tr '[:upper:]' '[:lower:]')"

[ -n "$PACKAGE" ] && [ -n "$VERSION_CODE" ] && [ -n "$VERSION_NAME" ] && [ -n "$CERTIFICATE" ] ||
    die "impossibile leggere pacchetto, versione e firma dell'APK"

python3 - "$PACKAGE" "$VERSION_NAME" "$VERSION_CODE" "$APK_URL" "$CERTIFICATE" <<'PY'
import json, sys

package, version_name, version_code, apk_url, certificate = sys.argv[1:]
print(json.dumps({
    "packageName": package,
    "versionName": version_name,
    "versionCode": int(version_code),
    "apkUrl": apk_url,
    "signingCertSha256": certificate,
}, indent=2))
PY
