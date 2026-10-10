# Funzioni condivise dagli script della patch "tab strip in stile Chrome".
# shellcheck shell=bash

set -euo pipefail

PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_DIR="$PATCH_ROOT/patches"
BASE_FILE="$PATCH_ROOT/UPSTREAM_BASE"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/mozilla-firefox/firefox.git}"
# Versione di Firefox da usare: "stable" (predefinito) = l'ultima versione stabile pubblicata di Firefox per
# Android; oppure "beta", "main" (Nightly) o un tag preciso, ad es. FIREFOX-ANDROID_157_0_1_RELEASE.
# UPSTREAM_BRANCH è accettata come sinonimo per compatibilità.
FIREFOX_VERSION="${FIREFOX_VERSION:-${UPSTREAM_BRANCH:-stable}}"

# Percorsi del sorgente di Firefox toccati dalla patch.
PATCH_PATHS=(mobile/android/fenix)

# Traduce FIREFOX_VERSION in un ramo o un tag di $UPSTREAM_URL ("stable" -> ultimo tag FIREFOX-ANDROID_*_RELEASE).
resolve_firefox_ref() {
    if [ "$FIREFOX_VERSION" != "stable" ]; then
        echo "$FIREFOX_VERSION"
        return
    fi
    local tag
    tag="$(git ls-remote --tags --refs "$UPSTREAM_URL" 'refs/tags/FIREFOX-ANDROID_*_RELEASE' |
        sed -n 's#.*refs/tags/\(FIREFOX-ANDROID_[0-9][0-9_]*_RELEASE\)$#\1#p' |
        awk '{ v = $0; sub(/^FIREFOX-ANDROID_/, "", v); sub(/_RELEASE$/, "", v); gsub(/_/, ".", v); print v " " $0 }' |
        sort -V | tail -1 | cut -d' ' -f2)"
    [ -n "$tag" ] || die "impossibile trovare l'ultima versione stabile di Firefox per Android su $UPSTREAM_URL"
    echo "$tag"
}

die() {
    echo "ERRORE: $*" >&2
    exit 1
}

info() {
    echo "==> $*"
}

# Verifica che $1 sia un checkout git del sorgente di Firefox.
require_firefox_checkout() {
    local dir="$1"
    [ -n "$dir" ] || die "specifica la cartella del sorgente di Firefox"
    [ -d "$dir/.git" ] || die "'$dir' non è un repository git"
    [ -f "$dir/mach" ] && [ -d "$dir/mobile/android/fenix" ] ||
        die "'$dir' non sembra il sorgente di Firefox (manca mach o mobile/android/fenix)"
}
