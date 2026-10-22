#!/usr/bin/env bash
# Applica le patch "tab strip in stile Chrome" a un checkout del sorgente di Firefox
# (https://github.com/mozilla-firefox/firefox).
#
# Le patch sono elencate, nell'ordine, in patches/series: prima le obbligatorie (la tab strip e l'infrastruttura
# comune), poi le facoltative, una per funzione, ognuna delle quali si applica sopra le sole obbligatorie.
#
# Uso:
#   apply.sh <cartella-firefox>                 applica tutte le patch
#   apply.sh <cartella-firefox> <patch>...      applica le obbligatorie e solo le facoltative indicate, per nome del
#                                               file o della funzione (es. 0080-tab-groups.patch o tab-groups)
#   apply.sh <cartella-firefox> --best-effort   applica tutte le patch, ma salta le facoltative che non si applicano
#                                               (su GitHub: la Release esce lo stesso, senza quelle funzioni)
#   apply.sh <cartella-firefox> --check         verifica soltanto che le patch si applichino: le obbligatorie, ogni
#                                               facoltativa da sola sopra le obbligatorie e tutte insieme
#
# Le patch già applicate restano come sono, così si può aggiungere una facoltativa a quelle già applicate.
#
# Se una patch non si applica in modo pulito (il codice di Firefox è cambiato nello stesso punto), lo script ripiega
# su un merge a 3 vie: i conflitti restano marcati nei file (<<<<<<< / >>>>>>>). Dopo averli risolti, rigenera la
# patch con refresh.sh e rilancia apply.sh per applicare le patch rimanenti.
#
# Le funzioni facoltative incluse vengono scritte in un file Kotlin generato (GeneratedPatchFeatures.kt), così
# Firefox sa quali funzioni contiene.

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
require_firefox_checkout "$FIREFOX_DIR"
shift

MODE=apply
SELECTED=()
for arg in "$@"; do
    case "$arg" in
        --check) MODE=check ;;
        --best-effort) MODE=best-effort ;;
        -*) die "opzione sconosciuta: $arg" ;;
        *) SELECTED+=("$arg") ;;
    esac
done

load_series
if [ ${#SELECTED[@]} -gt 0 ]; then
    [ "$MODE" = apply ] || die "le patch da applicare si possono scegliere solo senza --check e --best-effort"
    for patch in "${SELECTED[@]}"; do
        i="$(series_index "$patch")" || die "patch sconosciuta: $patch (vedi $SERIES_FILE)"
        [ "${SERIES_OPTIONAL[$i]}" = 1 ] ||
            info "$patch è obbligatoria: viene comunque applicata insieme alle altre obbligatorie"
    done
fi

# Le patch da applicare: tutte le obbligatorie e le facoltative scelte (tutte, se non ne è stata scelta nessuna).
TARGET=()
for i in "${!SERIES_FILES[@]}"; do
    patch="${SERIES_FILES[$i]}"
    if [ "${SERIES_OPTIONAL[$i]}" = 1 ] && [ ${#SELECTED[@]} -gt 0 ]; then
        wanted=0
        for selected in "${SELECTED[@]}"; do
            [ "$(series_index "$selected")" = "$i" ] && wanted=1
        done
        [ $wanted = 1 ] || continue
    fi
    TARGET+=("$patch")
done

cd "$FIREFOX_DIR"
FIREFOX_DIR="$(pwd)"
info "Sorgente di Firefox: $(git log -1 --format='%h %cd %s' --date=short)"

is_optional() {
    [ "${SERIES_OPTIONAL[$(series_index "$1")]}" = 1 ]
}

if [ "$MODE" = check ]; then
    # Le patch vengono provate su un indice temporaneo, senza toccare i file. Il merge a 3 vie viene provato solo
    # se la patch non si applica così com'è.
    TMP_INDEX="$(mktemp)"
    trap 'rm -f "$TMP_INDEX"' EXIT
    reset_index() {
        rm -f "$TMP_INDEX"
        GIT_INDEX_FILE="$TMP_INDEX" git read-tree "$1"
    }
    # Applica $1 all'indice temporaneo e dice com'è andata.
    check_patch() {
        local patch="$PATCHES_DIR/$1" conflicts
        if GIT_INDEX_FILE="$TMP_INDEX" git apply --cached "$patch" 2>/dev/null; then
            info "OK: $1 si applica in modo pulito"
        elif GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --3way "$patch" >/dev/null 2>&1; then
            info "OK (merge a 3 vie): $1 si applica, ma conviene rigenerarla con refresh.sh"
        else
            echo "KO: $1 non si applica più. File in conflitto:" >&2
            conflicts="$(GIT_INDEX_FILE="$TMP_INDEX" git ls-files --unmerged | cut -f2 | sort -u)"
            # Senza la versione di Firefox da cui è stata generata la patch (ad es. in un clone senza storia, come
            # su GitHub) il merge a 3 vie non parte nemmeno: elenca i file in cui la patch non si applica così com'è.
            [ -n "$conflicts" ] || conflicts="$(GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --check "$patch" 2>&1 |
                sed -n 's/^error: patch failed: \(.*\):[0-9]*$/\1/p' | sort -u || true)"
            echo "$conflicts" >&2
            return 1
        fi
    }
    annotate() {
        echo "$2" >&2
        [ "${GITHUB_ACTIONS:-}" = true ] && echo "::$1::$2"
        return 0
    }

    status=0
    reset_index HEAD
    for i in "${!SERIES_FILES[@]}"; do
        [ "${SERIES_OPTIONAL[$i]}" = 0 ] || continue
        check_patch "${SERIES_FILES[$i]}" || {
            annotate error "La patch obbligatoria ${SERIES_FILES[$i]} non si applica: va aggiornata."
            exit 1
        }
    done
    BASE_TREE="$(GIT_INDEX_FILE="$TMP_INDEX" git write-tree --missing-ok)"

    APPLYING=()
    for i in "${!SERIES_FILES[@]}"; do
        [ "${SERIES_OPTIONAL[$i]}" = 1 ] || continue
        patch="${SERIES_FILES[$i]}"
        reset_index "$BASE_TREE"
        if check_patch "$patch"; then
            APPLYING+=("$patch")
        else
            annotate warning "La patch facoltativa $patch non si applica: va aggiornata. Fino ad allora le Release escono senza «$(feature_id "$patch")»."
        fi
    done

    if [ ${#APPLYING[@]} -gt 1 ]; then
        info "Provo insieme le patch facoltative che si applicano"
        reset_index "$BASE_TREE"
        for patch in "${APPLYING[@]}"; do
            if ! GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --3way "$PATCHES_DIR/$patch" >/dev/null 2>&1; then
                annotate error "La patch facoltativa $patch si applica da sola ma non insieme alle altre: le patch facoltative non devono modificare le stesse righe."
                status=1
            fi
        done
        [ $status = 0 ] && info "OK: le patch facoltative si applicano anche tutte insieme"
    fi
    exit $status
fi

load_applied "$FIREFOX_DIR"
# Checkout preparato con una versione precedente degli script, quando c'era una sola patch.
if [ ${#APPLIED[@]} -eq 0 ] && git apply --check -R "$PATCHES_DIR/${SERIES_FILES[0]}" 2>/dev/null; then
    APPLIED=("${SERIES_FILES[0]}")
fi

SKIPPED=()
for patch in "${TARGET[@]}"; do
    if is_applied "$patch"; then
        info "$patch è già applicata"
        continue
    fi

    info "Applico $patch"
    if git apply --whitespace=nowarn "$PATCHES_DIR/$patch"; then
        APPLIED+=("$patch")
        continue
    fi

    if [ "$MODE" = best-effort ] && is_optional "$patch"; then
        # Il merge a 3 vie si usa solo se riesce senza conflitti: provato prima su un indice temporaneo.
        TMP_INDEX="$(mktemp)"
        cp "$(git rev-parse --git-path index)" "$TMP_INDEX"
        if GIT_INDEX_FILE="$TMP_INDEX" git apply --cached --3way "$PATCHES_DIR/$patch" >/dev/null 2>&1 &&
            git apply --3way --whitespace=nowarn "$PATCHES_DIR/$patch" >/dev/null 2>&1; then
            rm -f "$TMP_INDEX"
            git reset -q -- "${PATCH_PATHS[@]}"
            info "$patch applicata con il merge a 3 vie"
            APPLIED+=("$patch")
        else
            rm -f "$TMP_INDEX"
            info "SALTATA: $patch non si applica, la funzione «$(feature_id "$patch")» non sarà inclusa"
            SKIPPED+=("$patch")
        fi
        continue
    fi

    info "Applicazione diretta fallita, provo con il merge a 3 vie..."
    THREE_WAY_STATUS=0
    git apply --3way --whitespace=nowarn "$PATCHES_DIR/$patch" || THREE_WAY_STATUS=$?
    CONFLICTS="$(git diff --name-only --diff-filter=U)"
    # "git apply --3way" aggiunge le modifiche all'indice: le togliamo, così la patch resta solo nei file
    # (come con l'applicazione diretta) e unapply.sh / fetch-firefox.sh funzionano allo stesso modo.
    git reset -q -- "${PATCH_PATHS[@]}"
    if [ "$THREE_WAY_STATUS" != 0 ] && [ -z "$CONFLICTS" ]; then
        # Il merge a 3 vie non è nemmeno partito (ad es. manca la versione dei file da cui è stata generata la patch)
        # e git non ha applicato nulla. La patch resta segnata come applicata, così refresh.sh rigenera proprio lei
        # una volta applicata a mano.
        APPLIED+=("$patch")
        save_applied "$FIREFOX_DIR"
        die "$patch non si applica e il merge a 3 vie non è possibile: non è stato applicato nulla." \
            "Applicala a mano nella cartella di Firefox con: git apply --reject $PATCHES_DIR/$patch," \
            "sistema le parti rifiutate (file .rej, poi cancellali) ed esegui $(dirname "$0")/refresh.sh $FIREFOX_DIR."
    fi
    # La patch, applicata almeno in parte, è quella che refresh.sh rigenera.
    APPLIED+=("$patch")
    save_applied "$FIREFOX_DIR"
    if [ -z "$CONFLICTS" ] && ! git grep -qE '^(<<<<<<<|>>>>>>>)( |$)' -- "${PATCH_PATHS[@]}"; then
        continue
    fi

    echo >&2
    echo "$patch è stata applicata solo in parte: risolvi i conflitti (<<<<<<< / >>>>>>>) nei file seguenti," >&2
    echo "poi esegui $(dirname "$0")/refresh.sh $FIREFOX_DIR e rilancia apply.sh per le patch rimanenti." >&2
    echo "$CONFLICTS" >&2
    exit 1
done

save_applied "$FIREFOX_DIR"
if [ ${#SKIPPED[@]} -gt 0 ]; then
    info "Patch facoltative saltate: ${SKIPPED[*]}"
fi
info "Patch applicate: ${APPLIED[*]}"
info "Per compilare: $(dirname "$0")/build.sh $FIREFOX_DIR"
