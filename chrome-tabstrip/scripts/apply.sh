#!/usr/bin/env bash
# Applica la patch "tab strip in stile Chrome" a un checkout del sorgente di Firefox
# (https://github.com/mozilla-firefox/firefox).
#
# Uso:
#   apply.sh <cartella-firefox>           applica la patch alla working copy
#   apply.sh <cartella-firefox> --check   verifica soltanto che la patch si applichi
#
# Se la patch non si applica in modo pulito (il codice di Firefox è cambiato nello stesso punto),
# lo script ripiega su un merge a 3 vie: i conflitti restano marcati nei file (<<<<<<< / >>>>>>>).
# Dopo averli risolti, rigenera la patch con refresh.sh.

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
MODE="${2:-apply}"
require_firefox_checkout "$FIREFOX_DIR"

shopt -s nullglob
PATCHES=("$PATCHES_DIR"/*.patch)
[ ${#PATCHES[@]} -gt 0 ] || die "nessuna patch trovata in $PATCHES_DIR"

cd "$FIREFOX_DIR"
info "Sorgente di Firefox: $(git log -1 --format='%h %cd %s' --date=short)"

if [ "$MODE" = "--check" ]; then
    # Il merge a 3 vie viene provato su una copia dell'indice, senza toccare i file.
    TMP_INDEX="$(mktemp)"
    trap 'rm -f "$TMP_INDEX"' EXIT
    cp "$(git rev-parse --git-path index)" "$TMP_INDEX"
    status=0
    for patch in "${PATCHES[@]}"; do
        if git apply --check "$patch" 2>/dev/null; then
            info "OK: $(basename "$patch") si applica in modo pulito"
        elif GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --3way "$patch" >/dev/null 2>&1; then
            info "OK (merge a 3 vie): $(basename "$patch") si applica, ma conviene rigenerarla con refresh.sh"
        else
            echo "KO: $(basename "$patch") non si applica più. File in conflitto:" >&2
            CONFLICTS="$(GIT_INDEX_FILE="$TMP_INDEX" git ls-files --unmerged | cut -f2 | sort -u)"
            # Senza la versione di Firefox da cui è stata generata la patch (ad es. in un clone senza storia, come su
            # GitHub) il merge a 3 vie non parte nemmeno: elenca i file in cui la patch non si applica così com'è.
            [ -n "$CONFLICTS" ] || CONFLICTS="$(git apply --check "$patch" 2>&1 |
                sed -n 's/^error: patch failed: \(.*\):[0-9]*$/\1/p' | sort -u || true)"
            echo "$CONFLICTS" >&2
            status=1
        fi
    done
    exit $status
fi

if git apply --check -R "${PATCHES[0]}" 2>/dev/null; then
    info "La patch risulta già applicata: niente da fare."
    exit 0
fi

for patch in "${PATCHES[@]}"; do
    info "Applico $(basename "$patch")"
    if git apply --whitespace=nowarn "$patch"; then
        continue
    fi

    info "Applicazione diretta fallita, provo con il merge a 3 vie..."
    git apply --3way --whitespace=nowarn "$patch" || true
    CONFLICTS="$(git diff --name-only --diff-filter=U)"
    # "git apply --3way" aggiunge le modifiche all'indice: le togliamo, così la patch resta solo nei file
    # (come con l'applicazione diretta) e unapply.sh / fetch-firefox.sh funzionano allo stesso modo.
    git reset -q -- "${PATCH_PATHS[@]}"
    if [ -z "$CONFLICTS" ] && ! git grep -qE '^(<<<<<<<|>>>>>>>)( |$)' -- "${PATCH_PATHS[@]}"; then
        continue
    fi

    echo >&2
    echo "La patch è stata applicata solo in parte: risolvi i conflitti (<<<<<<< / >>>>>>>) nei file seguenti," >&2
    echo "poi esegui: $(dirname "$0")/refresh.sh $FIREFOX_DIR" >&2
    echo "$CONFLICTS" >&2
    exit 1
done

info "Patch applicata. Per compilare: $(dirname "$0")/build.sh $FIREFOX_DIR"
