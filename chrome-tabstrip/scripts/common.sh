# Funzioni condivise dagli script della patch "tab strip in stile Chrome".
# shellcheck shell=bash

set -euo pipefail

PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_DIR="$PATCH_ROOT/patches"
BASE_FILE="$PATCH_ROOT/UPSTREAM_BASE"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/mozilla-firefox/firefox.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"

# Percorsi del sorgente di Firefox toccati dalla patch.
PATCH_PATHS=(mobile/android/fenix)

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
