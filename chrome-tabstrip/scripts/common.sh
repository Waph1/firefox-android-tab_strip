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

# --- Elenco delle patch (patches/series) -------------------------------------------------------------------------

SERIES_FILE="$PATCHES_DIR/series"
# File Kotlin generato con le funzioni facoltative incluse: non fa parte di nessuna patch. I tipi che usa sono
# definiti dalle patch obbligatorie, in PATCH_FEATURES_API_FILE.
PATCH_FEATURES_DIR="mobile/android/fenix/app/src/main/java/org/mozilla/fenix/patchfeatures"
GENERATED_FEATURES_FILE="$PATCH_FEATURES_DIR/GeneratedPatchFeatures.kt"
PATCH_FEATURES_API_FILE="$PATCH_FEATURES_DIR/PatchFeatures.kt"

# Legge patches/series. Imposta, nell'ordine delle patch: SERIES_FILES (nomi dei file) e SERIES_OPTIONAL (1 se la
# patch è facoltativa, 0 se è obbligatoria). Controlla che l'elenco e i file in patches/ corrispondano.
load_series() {
    SERIES_FILES=()
    SERIES_OPTIONAL=()
    [ -f "$SERIES_FILE" ] || die "manca l'elenco delle patch: $SERIES_FILE"
    local line file type rest
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in '' | '#'*) continue ;; esac
        IFS='|' read -r file type rest <<<"$line"
        file="$(trim "$file")"
        type="$(trim "$type")"
        [ -f "$PATCHES_DIR/$file" ] || die "$SERIES_FILE: la patch $file non esiste"
        case "$type" in
            obbligatoria) SERIES_OPTIONAL+=(0) ;;
            facoltativa) SERIES_OPTIONAL+=(1) ;;
            *) die "$SERIES_FILE: tipo '$type' non valido per $file (obbligatoria o facoltativa)" ;;
        esac
        SERIES_FILES+=("$file")
    done <"$SERIES_FILE"
    [ ${#SERIES_FILES[@]} -gt 0 ] || die "nessuna patch elencata in $SERIES_FILE"

    local patch
    for patch in "$PATCHES_DIR"/*.patch; do
        series_index "$(basename "$patch")" >/dev/null ||
            die "$(basename "$patch") non è elencata in $SERIES_FILE: aggiungila (obbligatoria o facoltativa)"
    done
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    echo "${s%"${s##*[![:space:]]}"}"
}

# Stampa la posizione della patch $1 (nome del file o della funzione, es. 0080-tab-groups.patch o tab-groups) in
# SERIES_FILES; fallisce se non c'è.
series_index() {
    local i
    for i in "${!SERIES_FILES[@]}"; do
        if [ "${SERIES_FILES[$i]}" = "$1" ] || [ "$(feature_id "${SERIES_FILES[$i]}")" = "$1" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# Nome della funzione di una patch: il nome del file senza numero ed estensione (0080-tab-groups.patch -> tab-groups).
feature_id() {
    local id="${1%.patch}"
    echo "${id#[0-9][0-9][0-9][0-9]-}"
}

# Impronta di tutte le patch e dell'elenco: cambia quando una patch viene modificata (vedi ci-plan.sh).
patches_hash() {
    local sha=sha256sum
    command -v sha256sum >/dev/null || sha="shasum -a 256"
    (cd "$PATCHES_DIR" && cat series ./*.patch) | $sha | cut -d' ' -f1
}

# --- Patch applicate a un checkout di Firefox -------------------------------------------------------------------
# L'elenco, nell'ordine in cui sono state applicate, sta in un file dentro .git del checkout.

applied_file() {
    echo "$(git -C "$1" rev-parse --absolute-git-dir)/chrome-tabstrip-applied"
}

# Imposta APPLIED con le patch applicate al checkout $1.
load_applied() {
    APPLIED=()
    local file line
    file="$(applied_file "$1")"
    [ -f "$file" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] && APPLIED+=("$line")
    done <"$file"
}

# Salva APPLIED e aggiorna il file Kotlin con le funzioni incluse, se è applicata la patch che ne definisce i tipi
# (PATCH_FEATURES_API_FILE); senza patch applicate cancella entrambi.
save_applied() {
    local dir="$1" file
    file="$(applied_file "$dir")"
    rm -f "$dir/$GENERATED_FEATURES_FILE"
    if [ ${#APPLIED[@]} -eq 0 ]; then
        rm -f "$file"
        return
    fi
    printf '%s\n' "${APPLIED[@]}" >"$file"
    if [ -f "$dir/$PATCH_FEATURES_API_FILE" ]; then
        python3 "$(dirname "${BASH_SOURCE[0]}")/patch_features.py" kotlin "$SERIES_FILE" "$file" \
            >"$dir/$GENERATED_FEATURES_FILE"
    fi
}

is_applied() {
    local patch
    for patch in ${APPLIED[@]+"${APPLIED[@]}"}; do
        [ "$patch" = "$1" ] && return 0
    done
    return 1
}
