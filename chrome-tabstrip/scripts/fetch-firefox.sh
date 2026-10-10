#!/usr/bin/env bash
# Scarica il sorgente di Firefox (mozilla-firefox/firefox) o lo aggiorna all'ultima versione.
#
# Uso:
#   fetch-firefox.sh <cartella>            clona il sorgente (circa 6 GB) o aggiorna un clone esistente
#   fetch-firefox.sh <cartella> --fenix    clona solo mobile/android/fenix (basta per applicare/verificare
#                                          la patch, non per compilare)
#
# Variabili d'ambiente:
#   UPSTREAM_BRANCH   ramo da usare (predefinito: main = Nightly; ad es. "release" o "beta")
#
# L'aggiornamento rifiuta di procedere se la patch è applicata o ci sono modifiche locali in
# mobile/android/fenix: rimuovila prima con unapply.sh (o rigenerala con refresh.sh se l'hai modificata).

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
MODE="${2:-full}"
[ -n "$FIREFOX_DIR" ] || die "uso: $0 <cartella> [--fenix]"

if [ ! -d "$FIREFOX_DIR/.git" ]; then
    info "Clono $UPSTREAM_URL ($UPSTREAM_BRANCH) in $FIREFOX_DIR"
    # Clone "blobless" e senza storia: scarica solo i file dell'ultima versione.
    if [ "$MODE" = "--fenix" ]; then
        git clone --depth=1 --filter=blob:none --sparse --branch "$UPSTREAM_BRANCH" "$UPSTREAM_URL" "$FIREFOX_DIR"
        git -C "$FIREFOX_DIR" sparse-checkout set "${PATCH_PATHS[@]}"
    else
        git clone --depth=1 --filter=blob:none --branch "$UPSTREAM_BRANCH" "$UPSTREAM_URL" "$FIREFOX_DIR"
    fi
else
    require_firefox_checkout "$FIREFOX_DIR"
    cd "$FIREFOX_DIR"
    if ! git diff --quiet HEAD -- "${PATCH_PATHS[@]}" ||
        [ -n "$(git ls-files --others --exclude-standard -- "${PATCH_PATHS[@]}")" ]; then
        die "ci sono modifiche locali in ${PATCH_PATHS[*]} (la patch è applicata?)." \
            "Esegui prima: $(dirname "$0")/unapply.sh $FIREFOX_DIR"
    fi
    info "Aggiorno $FIREFOX_DIR all'ultima versione di $UPSTREAM_BRANCH"
    git fetch --depth=1 origin "$UPSTREAM_BRANCH"
    git checkout -q -B "$UPSTREAM_BRANCH" FETCH_HEAD
fi

info "Sorgente pronto: $(git -C "$FIREFOX_DIR" log -1 --format='%h %cd %s' --date=short)"
