#!/usr/bin/env bash
# Rigenera la patch a partire dalle modifiche presenti in un checkout del sorgente di Firefox.
#
# Da usare dopo aver risolto i conflitti lasciati da apply.sh (o dopo aver modificato a mano il codice):
# il contenuto di patches/ viene sostituito con le differenze tra l'ultimo commit di Firefox (HEAD)
# e la working copy, limitatamente a mobile/android/fenix.
#
# Uso: refresh.sh <cartella-firefox>

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
require_firefox_checkout "$FIREFOX_DIR"

cd "$FIREFOX_DIR"

CONFLICTS="$(git grep -lE '^(<<<<<<<|>>>>>>>)( |$)' -- "${PATCH_PATHS[@]}" || true)"
[ -z "$CONFLICTS" ] || die "ci sono ancora marcatori di conflitto (<<<<<<< / >>>>>>>) in:" "$CONFLICTS"

# Eventuali file ancora segnati come in conflitto nell'indice sono ora risolti.
UNMERGED="$(git diff --name-only --diff-filter=U)"
if [ -n "$UNMERGED" ]; then
    echo "$UNMERGED" | xargs git add --
fi

# Rende visibili nel diff anche i file nuovi (poi l'indice torna com'era).
git add --intent-to-add -- "${PATCH_PATHS[@]}"

OUT="$PATCHES_DIR/0001-fenix-chrome-like-adaptive-tab-strip.patch"
TMP="$(mktemp)"
git diff --binary HEAD -- "${PATCH_PATHS[@]}" >"$TMP"
git reset -q -- "${PATCH_PATHS[@]}"
[ -s "$TMP" ] || die "nessuna modifica trovata in ${PATCH_PATHS[*]}: la patch non è applicata?"

rm -f "$PATCHES_DIR"/*.patch
mv "$TMP" "$OUT"
git rev-parse HEAD >"$BASE_FILE"

info "Patch rigenerata: $OUT"
info "Base upstream: $(cat "$BASE_FILE")"
git apply --stat "$OUT"
