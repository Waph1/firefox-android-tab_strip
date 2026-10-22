#!/usr/bin/env bash
# GitHub Actions: compila l'APK con build.sh. Se la compilazione fallisce per colpa di una patch facoltativa, la
# toglie e ricompila, così la Release esce lo stesso, senza quella funzione.
#
# Uso: ci-build.sh <cartella-firefox> <variante>
#
# Dagli errori di compilazione si risale ai file e da lì alle patch facoltative applicate che li modificano: quelle
# vengono tolte (unapply.sh) e si ricompila; le compilazioni successive sono molto più veloci della prima. Se gli
# errori non portano a nessuna patch facoltativa, si tolgono tutte quelle rimaste. Al massimo MAX_ATTEMPTS
# compilazioni: se anche l'ultima fallisce, fallisce lo script.

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
VARIANT="${2:-release}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
require_firefox_checkout "$FIREFOX_DIR"
FIREFOX_DIR="$(cd "$FIREFOX_DIR" && pwd)"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

load_series
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# Stampa i file del sorgente di Firefox (relativi a FIREFOX_DIR) citati negli errori del log di compilazione.
error_files() {
    local dir
    for dir in "$FIREFOX_DIR" "$(cd "$FIREFOX_DIR" && pwd -P)"; do
        grep -E '^e: |error' "$LOG" | grep -oE "$dir/[^ :\"']+" | sed "s#^$dir/##" || true
    done | sort -u
}

attempt=1
while true; do
    info "Compilazione, tentativo $attempt di $MAX_ATTEMPTS"
    if "$SCRIPTS/build.sh" "$FIREFOX_DIR" "$VARIANT" 2>&1 | tee "$LOG"; then
        exit 0
    fi

    load_applied "$FIREFOX_DIR"
    OPTIONAL=()
    for patch in ${APPLIED[@]+"${APPLIED[@]}"}; do
        [ "${SERIES_OPTIONAL[$(series_index "$patch")]}" = 1 ] && OPTIONAL+=("$patch")
    done
    [ ${#OPTIONAL[@]} -gt 0 ] || die "la compilazione è fallita e non ci sono patch facoltative da togliere"
    [ "$attempt" -lt "$MAX_ATTEMPTS" ] || die "la compilazione è fallita $MAX_ATTEMPTS volte"

    FILES="$(error_files)"
    info "File con errori di compilazione:"
    echo "${FILES:-(nessuno riconosciuto)}"
    DROP=()
    for patch in "${OPTIONAL[@]}"; do
        while IFS= read -r file; do
            if [ -n "$file" ] && grep -qF "diff --git a/$file b/$file" "$PATCHES_DIR/$patch"; then
                DROP+=("$patch")
                break
            fi
        done <<<"$FILES"
    done
    if [ ${#DROP[@]} -eq 0 ]; then
        info "Gli errori non riguardano i file di una patch facoltativa: le tolgo tutte"
        DROP=("${OPTIONAL[@]}")
    fi

    for patch in "${DROP[@]}"; do
        MSG="La patch facoltativa $patch non compila: la tolgo, la Release uscirà senza «$(feature_id "$patch")»."
        echo "$MSG"
        [ "${GITHUB_ACTIONS:-}" = true ] && echo "::warning::$MSG"
    done
    "$SCRIPTS/unapply.sh" "$FIREFOX_DIR" "${DROP[@]}"
    attempt=$((attempt + 1))
done
