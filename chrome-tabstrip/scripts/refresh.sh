#!/usr/bin/env bash
# Rigenera una patch a partire dalle modifiche presenti in un checkout del sorgente di Firefox.
#
# Da usare dopo aver risolto i conflitti lasciati da apply.sh, o dopo aver modificato a mano il codice di una patch.
# La patch rigenerata è l'ultima applicata: contiene le differenze tra il codice di Firefox (HEAD) con le patch
# applicate prima di lei e la working copy, limitatamente a mobile/android/fenix.
#
# Per lavorare su una patch, quindi, applicala per ultima: per una facoltativa basta
#   apply.sh <cartella-firefox> <patch>    (applica le obbligatorie e solo quella facoltativa)
# Per una obbligatoria, togli prima con unapply.sh le patch applicate dopo di lei.
#
# Uso:
#   refresh.sh <cartella-firefox>                      rigenera l'ultima patch applicata
#   refresh.sh <cartella-firefox> NNNN-nome.patch      crea una patch nuova con le modifiche fatte sopra le patch
#                                                      applicate (poi va aggiunta a patches/series)

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
require_firefox_checkout "$FIREFOX_DIR"
NEW_PATCH="${2:-}"

load_series
cd "$FIREFOX_DIR"
FIREFOX_DIR="$(pwd)"
load_applied "$FIREFOX_DIR"
# Checkout preparato con una versione precedente degli script, quando c'era una sola patch.
if [ ${#APPLIED[@]} -eq 0 ] && [ -z "$NEW_PATCH" ]; then
    APPLIED=("${SERIES_FILES[0]}")
fi

CONFLICTS="$(git grep -lE '^(<<<<<<<|>>>>>>>)( |$)' -- "${PATCH_PATHS[@]}" || true)"
[ -z "$CONFLICTS" ] || die "ci sono ancora marcatori di conflitto (<<<<<<< / >>>>>>>) in:" "$CONFLICTS"

# Le patch sopra cui è costruita quella da rigenerare.
if [ -n "$NEW_PATCH" ]; then
    case "$NEW_PATCH" in
        [0-9][0-9][0-9][0-9]-*.patch) ;;
        *) die "il nome della nuova patch deve essere del tipo NNNN-nome.patch (es. 0010-new-tab-focus.patch)" ;;
    esac
    is_applied "$NEW_PATCH" && die "$NEW_PATCH è già applicata: per rigenerarla, ometti il nome"
    [ ! -f "$PATCHES_DIR/$NEW_PATCH" ] || die "$NEW_PATCH esiste già in $PATCHES_DIR"
    PATCH="$NEW_PATCH"
    BASE=(${APPLIED[@]+"${APPLIED[@]}"})
else
    PATCH="${APPLIED[${#APPLIED[@]} - 1]}"
    BASE=("${APPLIED[@]:0:${#APPLIED[@]}-1}")
fi
OUT="$PATCHES_DIR/$PATCH"

# Codice di Firefox con le patch di base, costruito in un indice temporaneo.
TMP_INDEX="$(mktemp)"
TMP="$(mktemp)"
trap 'rm -f "$TMP_INDEX" "$TMP"' EXIT
rm -f "$TMP_INDEX"
GIT_INDEX_FILE="$TMP_INDEX" git read-tree HEAD
for base in ${BASE[@]+"${BASE[@]}"}; do
    GIT_INDEX_FILE="$TMP_INDEX" git apply --cached "$PATCHES_DIR/$base" 2>/dev/null ||
        GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --3way "$PATCHES_DIR/$base" >/dev/null 2>&1 ||
        die "$base non si applica al codice di Firefox: rigenerala prima di $PATCH"
done
BASE_TREE="$(GIT_INDEX_FILE="$TMP_INDEX" git write-tree --missing-ok)"

# Eventuali file ancora segnati come in conflitto nell'indice sono ora risolti.
UNMERGED="$(git diff --name-only --diff-filter=U)"
if [ -n "$UNMERGED" ]; then
    echo "$UNMERGED" | xargs git add --
fi

# Rende visibili nel diff anche i file nuovi (poi l'indice torna com'era). Il file generato con le funzioni incluse
# non fa parte di nessuna patch.
git add --intent-to-add -- "${PATCH_PATHS[@]}"
git diff --binary "$BASE_TREE" -- "${PATCH_PATHS[@]}" ":(exclude)$GENERATED_FEATURES_FILE" >"$TMP"
git reset -q -- "${PATCH_PATHS[@]}"
[ -s "$TMP" ] || die "nessuna modifica trovata per $PATCH in ${PATCH_PATHS[*]}"

mv "$TMP" "$OUT"
git rev-parse HEAD >"$BASE_FILE"

if [ -n "$NEW_PATCH" ]; then
    APPLIED+=("$NEW_PATCH")
    printf '%s\n' "${APPLIED[@]}" >"$(applied_file "$FIREFOX_DIR")"
    series_index "$NEW_PATCH" >/dev/null ||
        info "Ricordati di aggiungere $NEW_PATCH a $SERIES_FILE (di solito come facoltativa)."
fi

info "Patch rigenerata: $OUT"
info "Base upstream: $(cat "$BASE_FILE")"
git apply --stat "$OUT"
