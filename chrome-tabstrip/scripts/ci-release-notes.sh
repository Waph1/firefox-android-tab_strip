#!/usr/bin/env bash
# GitHub Actions: scrive su stdout la descrizione della Release, con le funzioni facoltative incluse e quelle mancanti
# (lette da update.json, vedi ci-update-info.sh).
#
# Uso: ci-release-notes.sh <update.json> <nome-del-file-apk> <versione-di-firefox>
#
# Variabili d'ambiente (impostate da GitHub): GITHUB_REPOSITORY, GITHUB_SHA.

source "$(dirname "$0")/common.sh"

UPDATE_INFO="${1:-}"
APK_NAME="${2:-}"
FX_VERSION="${3:-}"
[ -f "$UPDATE_INFO" ] && [ -n "$APK_NAME" ] && [ -n "$FX_VERSION" ] ||
    die "uso: $0 <update.json> <nome-del-file-apk> <versione-di-firefox>"

python3 - "$UPDATE_INFO" <<'PY'
import json, sys

info = json.load(open(sys.argv[1], encoding="utf-8"))
features = info.get("features", [])
missing = info.get("missingFeatures", [])
if missing:
    print("> [!WARNING]")
    print("> **Questa versione non include alcune funzioni della patch**, che non si applicano più a questa versione")
    print("> di Firefox (o non compilano):")
    for feature in missing:
        print(f"> - {feature['name']['it']}")
    print(">")
    print("> Torneranno con un aggiornamento successivo, appena la patch sarà sistemata. Firefox lo dice anche nella")
    print("> finestra dell'aggiornamento, così puoi decidere se aggiornare subito o aspettare.")
    print()
if features:
    print("**Funzioni incluse**")
    for feature in features:
        print(f"- {feature['name']['it']}")
    print()
PY

cat <<EOF
Firefox per Android **$FX_VERSION** (versione stabile) con la tab strip in stile Chrome, che compare e
scompare aprendo e chiudendo il telefono pieghevole, e con i siti che passano dalla versione desktop
(telefono aperto) a quella mobile (telefono chiuso).

**Come installarlo dal telefono**
1. Scarica qui sotto il file \`$APK_NAME\`.
2. Aprilo e consenti l'installazione di app da questa fonte se Android lo chiede.
3. Se hai il Firefox del Play Store, va prima disinstallato (firma diversa): sincronizza prima i dati
   con il tuo account Mozilla. Gli aggiornamenti successivi pubblicati qui si installano sopra questo.
4. Una volta al giorno Firefox controlla se qui c'è una versione nuova e propone di installarla: la prima
   volta Android chiede di consentire a Firefox di installare app.

Patch: [chrome-tabstrip](https://github.com/${GITHUB_REPOSITORY:-Waph1/firefox-android-tab_strip}/tree/${GITHUB_SHA:-main}/chrome-tabstrip)
EOF
