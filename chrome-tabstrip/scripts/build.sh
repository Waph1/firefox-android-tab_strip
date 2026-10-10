#!/usr/bin/env bash
# Compila Firefox per Android (Fenix) con la patch applicata, in "artifact mode": Gecko non viene
# compilato, mach scarica i binari già pronti di Mozilla e compila solo la parte Android (Kotlin).
#
# Uso: build.sh <cartella-firefox> [nightly|debug|release]
#
#   nightly (predefinito)  build ottimizzata, id app org.mozilla.fenix ("Firefox Nightly")
#   debug                  build di debug, più lenta, id app org.mozilla.fenix.debug
#   release                build ottimizzata, id app org.mozilla.firefox (in conflitto con Firefox del Play Store)
#
# Le build vengono firmate con la chiave di debug di Android (~/.android/debug.keystore): conserva quel file,
# altrimenti le build successive non si installeranno sopra le precedenti.
#
# Variabili d'ambiente:
#   MOZBUILD_STATE_PATH   dove mach installa JDK e Android SDK (predefinito: ~/.mozbuild)
#   TARGET                architettura (predefinito: aarch64-linux-android, quella del Galaxy Z Fold)

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
VARIANT="${2:-nightly}"
TARGET="${TARGET:-aarch64-linux-android}"
require_firefox_checkout "$FIREFOX_DIR"

case "$VARIANT" in
    nightly | debug | release) ;;
    *) die "variante sconosciuta '$VARIANT' (usa nightly, debug o release)" ;;
esac

cd "$FIREFOX_DIR"
export MOZBUILD_STATE_PATH="${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}"

if [ -z "${MOZCONFIG:-}" ]; then
    export MOZCONFIG="$FIREFOX_DIR/mozconfig-chrome-tabstrip"
    cat >"$MOZCONFIG" <<EOF
# Generato da chrome-tabstrip/scripts/build.sh
ac_add_options --enable-project=mobile/android
ac_add_options --enable-artifact-builds
ac_add_options --target=$TARGET
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/objdir-chrome-tabstrip
EOF
fi
info "mozconfig: $MOZCONFIG"

info "Preparo l'ambiente di compilazione (JDK, Android SDK)..."
./mach --no-interactive bootstrap \
    --application-choice="GeckoView/Firefox for Android Artifact Mode" \
    --no-system-changes

info "Scarico i binari di Gecko e preparo il build (./mach build)..."
./mach build

# Es. "nightly" -> "fenix:assembleNightly" (senza ${VARIANT^}, che non esiste nella bash 3 di macOS).
TASK="fenix:assemble$(printf '%s' "${VARIANT:0:1}" | tr '[:lower:]' '[:upper:]')${VARIANT:1}"
info "Compilo Fenix ($TASK)..."
./mach gradle "$TASK"

OBJDIR="$(./mach environment --format=json | python3 -c 'import json,sys; print(json.load(sys.stdin)["topobjdir"])')"
APK_DIR="$OBJDIR/gradle/build/mobile/android/fenix/app/outputs/apk/$VARIANT"
info "APK generati:"
find "$APK_DIR" -name '*.apk' -print
echo
info "Per installarlo sul telefono (con debug USB attivo): adb install -r <file arm64-v8a.apk>"
