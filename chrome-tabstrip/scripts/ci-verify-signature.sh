#!/usr/bin/env bash
# GitHub Actions: verifica che l'APK sia firmato con la chiave preparata da ci-signing-key.sh, prima di pubblicarlo.
# Un APK firmato con una chiave diversa non si installerebbe come aggiornamento sopra le versioni precedenti.
#
# Uso: ci-verify-signature.sh <file.apk>

source "$(dirname "$0")/common.sh"

APK="${1:-}"
[ -f "$APK" ] || die "APK non trovato: $APK"
KEYSTORE="${ANDROID_USER_HOME:-$HOME/.android}/debug.keystore"
[ -f "$KEYSTORE" ] || die "chiave non trovata: $KEYSTORE"

APKSIGNER="$(find "${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}" -path '*/build-tools/*/apksigner' | sort -V | tail -1)"
[ -n "$APKSIGNER" ] || die "apksigner non trovato nell'Android SDK"

EXPECTED="$(keytool -list -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey |
    sed -n 's/^[[:space:]]*SHA256: //p' | tr -d ':' | tr '[:upper:]' '[:lower:]')"
ACTUAL="$("$APKSIGNER" verify --print-certs "$APK" |
    sed -n 's/^.*[Ss]igner.* certificate SHA-256 digest: //p' | head -1 | tr '[:upper:]' '[:lower:]')"

info "Impronta della chiave: $EXPECTED"
info "Impronta dell'APK:     $ACTUAL"
[ -n "$EXPECTED" ] && [ "$EXPECTED" = "$ACTUAL" ] ||
    die "l'APK non è firmato con la chiave del repository: non lo pubblico"
info "Firma corretta."
