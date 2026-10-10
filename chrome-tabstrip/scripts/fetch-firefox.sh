#!/usr/bin/env bash
# Scarica il sorgente di Firefox (mozilla-firefox/firefox) o lo aggiorna all'ultima versione stabile.
#
# Uso:
#   fetch-firefox.sh <cartella>            clona il sorgente (circa 6 GB) o aggiorna un clone esistente
#   fetch-firefox.sh <cartella> --fenix    clona solo mobile/android/fenix (basta per applicare/verificare
#                                          la patch, non per compilare)
#
# Variabili d'ambiente:
#   FIREFOX_VERSION   "stable" (predefinito: l'ultima versione stabile di Firefox per Android, es. 157.0.1),
#                     "beta", "main" (Nightly) o un tag preciso, es. FIREFOX-ANDROID_157_0_RELEASE
#
# L'aggiornamento rifiuta di procedere se la patch è applicata o ci sono modifiche locali in
# mobile/android/fenix: rimuovila prima con unapply.sh (o rigenerala con refresh.sh se l'hai modificata).

source "$(dirname "$0")/common.sh"

FIREFOX_DIR="${1:-}"
MODE="${2:-full}"
[ -n "$FIREFOX_DIR" ] || die "uso: $0 <cartella> [--fenix]"

REF="$(resolve_firefox_ref)"

if [ ! -d "$FIREFOX_DIR/.git" ]; then
    info "Clono $UPSTREAM_URL ($REF) in $FIREFOX_DIR"
    # Clone "blobless" e senza storia: scarica solo i file della versione scelta.
    if [ "$MODE" = "--fenix" ]; then
        git clone --depth=1 --filter=blob:none --sparse --branch "$REF" "$UPSTREAM_URL" "$FIREFOX_DIR"
        git -C "$FIREFOX_DIR" sparse-checkout set "${PATCH_PATHS[@]}"
    else
        git clone --depth=1 --filter=blob:none --branch "$REF" "$UPSTREAM_URL" "$FIREFOX_DIR"
    fi
else
    require_firefox_checkout "$FIREFOX_DIR"
    cd "$FIREFOX_DIR"
    if ! git diff --quiet HEAD -- "${PATCH_PATHS[@]}" ||
        [ -n "$(git ls-files --others --exclude-standard -- "${PATCH_PATHS[@]}")" ]; then
        die "ci sono modifiche locali in ${PATCH_PATHS[*]} (la patch è applicata?)." \
            "Esegui prima: $(dirname "$0")/unapply.sh $FIREFOX_DIR"
    fi
    info "Aggiorno $FIREFOX_DIR a $REF"
    git fetch --depth=1 origin "$REF"
    git checkout -q --detach FETCH_HEAD
fi

info "Sorgente pronto: Firefox $(cat "$FIREFOX_DIR/mobile/android/version.txt") ($REF)"
info "Ultimo commit: $(git -C "$FIREFOX_DIR" log -1 --format='%h %cd %s' --date=short)"
