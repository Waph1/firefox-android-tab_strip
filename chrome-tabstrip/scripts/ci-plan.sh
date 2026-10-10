#!/usr/bin/env bash
# GitHub Actions: decide se compilare e pubblicare l'APK in questa esecuzione.
#
# Variabili d'ambiente (impostate dal workflow):
#   MODE          "release" (pubblica nelle Release del repository) o "test" (solo artifact, chiave temporanea)
#   FORCE         "true" per ricompilare anche se la release di questa versione esiste già
#   HAS_KEY       "true" se il secret APK_SIGNING_PASSWORD è configurato
#   EVENT         nome dell'evento GitHub (schedule, workflow_dispatch, ...)
#   GH_TOKEN      token per interrogare le release con la GitHub CLI
#
# Scrive in $GITHUB_OUTPUT: build=true|false, version=<x.y.z>, tag=<tag della release>.

source "$(dirname "$0")/common.sh"

output() {
    echo "$1=$2" >>"${GITHUB_OUTPUT:-/dev/stdout}"
}

summary() {
    echo "$*" >>"${GITHUB_STEP_SUMMARY:-/dev/stdout}"
}

if [ "${MODE:-release}" = "test" ]; then
    info "Modalità test: compilo con una chiave temporanea, senza pubblicare."
    output build true
    exit 0
fi

REF="$(resolve_firefox_ref)"
case "$REF" in
    FIREFOX-ANDROID_*_RELEASE) ;;
    *) die "in modalità release si pubblicano solo versioni stabili (FIREFOX_VERSION=stable), non '$REF'" ;;
esac
VERSION="$(echo "$REF" | sed 's/^FIREFOX-ANDROID_//; s/_RELEASE$//; s/_/./g')"
TAG="firefox-$VERSION-tabstrip"
output version "$VERSION"
output tag "$TAG"
info "Ultima versione stabile di Firefox per Android: $VERSION ($REF)"

if gh release view "$TAG" >/dev/null 2>&1 && [ "${FORCE:-false}" != "true" ]; then
    info "La release $TAG esiste già: niente da fare."
    summary "✅ Firefox $VERSION con la tab strip è già pubblicato nelle Release."
    output build false
    exit 0
fi

if [ "${HAS_KEY:-false}" != "true" ]; then
    MSG="Manca il secret APK_SIGNING_PASSWORD: crealo (Settings → Secrets and variables → Actions → New repository secret) con una password lunga e casuale. Vedi chrome-tabstrip/README.md, sezione «Senza PC»."
    summary "⚠️ $MSG"
    if [ "${EVENT:-}" = "schedule" ]; then
        # Le esecuzioni giornaliere non falliscono, per non mandare un'e-mail al giorno.
        echo "::warning::$MSG"
        output build false
        exit 0
    fi
    die "$MSG"
fi

info "Compilo e pubblico Firefox $VERSION con la patch."
output build true
