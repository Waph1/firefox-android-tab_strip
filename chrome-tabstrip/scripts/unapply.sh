#!/usr/bin/env bash
# Rimuove la patch "tab strip in stile Chrome" da un checkout del sorgente di Firefox.
#
# Uso: unapply.sh <cartella-firefox>

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
require_firefox_checkout "$FIREFOX_DIR"

shopt -s nullglob
PATCHES=("$PATCHES_DIR"/*.patch)
[ ${#PATCHES[@]} -gt 0 ] || die "nessuna patch trovata in $PATCHES_DIR"

cd "$FIREFOX_DIR"

# Le patch vanno tolte in ordine inverso.
for ((i = ${#PATCHES[@]} - 1; i >= 0; i--)); do
    patch="${PATCHES[$i]}"
    if git apply --check -R "$patch" 2>/dev/null; then
        info "Rimuovo $(basename "$patch")"
        git apply -R "$patch"
    else
        die "$(basename "$patch") non risulta applicata (o i file sono stati modificati a mano)." \
            "Per tornare al codice originale: git -C $FIREFOX_DIR checkout HEAD -- ${PATCH_PATHS[*]}" \
            "&& git -C $FIREFOX_DIR clean -fd -- ${PATCH_PATHS[*]}"
    fi
done

info "Patch rimossa."
