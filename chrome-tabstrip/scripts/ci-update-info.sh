#!/usr/bin/env bash
# GitHub Actions: scrive su stdout il file update.json pubblicato con l'APK in ogni Release. Firefox lo legge
# dall'ultima Release per sapere se c'è un aggiornamento da proporre e quali funzioni facoltative della patch mancano
# (vedi SelfUpdater.kt nella patch). Contiene anche l'impronta delle patch, che ci-plan.sh usa per ricompilare una
# Release incompleta quando le patch vengono sistemate.
#
# Uso: ci-update-info.sh <file.apk> <url-da-cui-scaricare-l-apk> <cartella-firefox>

source "$(dirname "$0")/common.sh"

APK="${1:-}"
APK_URL="${2:-}"
FIREFOX_DIR="${3:-}"
[ -f "$APK" ] && [ -n "$APK_URL" ] && [ -n "$FIREFOX_DIR" ] ||
    die "uso: $0 <file.apk> <url-da-cui-scaricare-l-apk> <cartella-firefox>"
FEATURES="$(python3 "$(dirname "$0")/patch_features.py" json "$SERIES_FILE" "$(applied_file "$FIREFOX_DIR")")"

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

python3 - "$PACKAGE" "$VERSION_NAME" "$VERSION_CODE" "$APK_URL" "$CERTIFICATE" "$FEATURES" "$(patches_hash)" <<'PY'
import json, sys

package, version_name, version_code, apk_url, certificate, features, patches_hash = sys.argv[1:]
features = json.loads(features)
print(json.dumps({
    "packageName": package,
    "versionName": version_name,
    "versionCode": int(version_code),
    "apkUrl": apk_url,
    "signingCertSha256": certificate,
    "features": features["features"],
    "missingFeatures": features["missingFeatures"],
    "patchesHash": patches_hash,
}, indent=2, ensure_ascii=False))
PY
