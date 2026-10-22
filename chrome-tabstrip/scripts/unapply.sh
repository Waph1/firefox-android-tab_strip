#!/usr/bin/env bash
# Rimuove le patch "tab strip in stile Chrome" da un checkout del sorgente di Firefox.
#
# Uso:
#   unapply.sh <cartella-firefox>              rimuove tutte le patch applicate
#   unapply.sh <cartella-firefox> <patch>...   rimuove solo le patch indicate, per nome del file o della funzione
#                                              (es. una facoltativa che non compila più)

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
require_firefox_checkout "$FIREFOX_DIR"
shift

load_series
cd "$FIREFOX_DIR"
FIREFOX_DIR="$(pwd)"
load_applied "$FIREFOX_DIR"
# Checkout preparato con una versione precedente degli script, quando c'era una sola patch.
if [ ${#APPLIED[@]} -eq 0 ] && git apply --check -R "$PATCHES_DIR/${SERIES_FILES[0]}" 2>/dev/null; then
    APPLIED=("${SERIES_FILES[0]}")
fi
[ ${#APPLIED[@]} -gt 0 ] || die "nessuna patch risulta applicata a $FIREFOX_DIR"

# Le patch da togliere, nell'ordine in cui sono state applicate.
REMOVE=()
if [ $# -eq 0 ]; then
    REMOVE=("${APPLIED[@]}")
else
    for arg in "$@"; do
        i="$(series_index "$arg")" || die "patch sconosciuta: $arg (vedi $SERIES_FILE)"
        is_applied "${SERIES_FILES[$i]}" || die "${SERIES_FILES[$i]} non è applicata"
    done
    for patch in "${APPLIED[@]}"; do
        for arg in "$@"; do
            [ "$(series_index "$arg")" = "$(series_index "$patch")" ] && REMOVE+=("$patch")
        done
    done
    # Una patch obbligatoria si può togliere da sola solo se è l'ultima applicata: le successive si appoggiano a lei.
    for patch in "${REMOVE[@]}"; do
        if [ "${SERIES_OPTIONAL[$(series_index "$patch")]}" = 0 ] && [ "$patch" != "${APPLIED[${#APPLIED[@]} - 1]}" ]; then
            die "$patch è obbligatoria e dopo di lei sono state applicate altre patch: rimuovi prima quelle"
        fi
    done
fi

# Le patch vanno tolte in ordine inverso.
for ((i = ${#REMOVE[@]} - 1; i >= 0; i--)); do
    patch="${REMOVE[$i]}"
    if git apply --check -R "$PATCHES_DIR/$patch" 2>/dev/null; then
        info "Rimuovo $patch"
        git apply -R "$PATCHES_DIR/$patch"
    else
        die "$patch non risulta applicata (o i file sono stati modificati a mano)." \
            "Per tornare al codice originale: git -C $FIREFOX_DIR checkout HEAD -- ${PATCH_PATHS[*]}" \
            "&& git -C $FIREFOX_DIR clean -fd -- ${PATCH_PATHS[*]} && rm -f $(applied_file "$FIREFOX_DIR")"
    fi
    REMAINING=()
    for applied in "${APPLIED[@]}"; do
        [ "$applied" = "$patch" ] || REMAINING+=("$applied")
    done
    APPLIED=(${REMAINING[@]+"${REMAINING[@]}"})
    save_applied "$FIREFOX_DIR"
done

if [ ${#APPLIED[@]} -eq 0 ]; then
    info "Patch rimosse."
else
    info "Patch ancora applicate: ${APPLIED[*]}"
fi
