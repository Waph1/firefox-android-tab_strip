#!/usr/bin/env bash
# Prepara la chiave con cui vengono firmati gli APK e il testo da salvare come secret di GitHub.
#
# Uso: signing-key.sh
#
# - Se esiste già ~/.android/debug.keystore (creato dalla prima compilazione), usa quello: è la chiave con cui
#   sono firmati gli APK che hai già installato, quindi va mantenuta.
# - Altrimenti ne crea uno nuovo (serve "keytool", incluso in qualsiasi JDK, anche quello scaricato da mach).
#
# Scrive la chiave codificata in base64 in ~/.android/debug.keystore.base64: il contenuto di quel file va
# incollato nel secret ANDROID_DEBUG_KEYSTORE_BASE64 del repository (vedi chrome-tabstrip/README.md).

source "$(dirname "$0")/common.sh"

KEYSTORE="${ANDROID_USER_HOME:-$HOME/.android}/debug.keystore"
OUT="$KEYSTORE.base64"

if [ -f "$KEYSTORE" ]; then
    info "Uso la chiave esistente: $KEYSTORE"
else
    KEYTOOL="$(command -v keytool || true)"
    if [ -z "$KEYTOOL" ]; then
        KEYTOOL="$(find "${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/jdk" -path '*/bin/keytool' 2>/dev/null | head -1 || true)"
    fi
    [ -n "$KEYTOOL" ] || die "keytool non trovato: installa un JDK (o esegui prima build.sh, che lo scarica)"

    info "Creo una nuova chiave: $KEYSTORE"
    mkdir -p "$(dirname "$KEYSTORE")"
    # Alias e password sono quelli standard della chiave di debug di Android, che la build si aspetta.
    "$KEYTOOL" -genkeypair -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey -keypass android \
        -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
fi

# "base64" su Linux va a capo ogni 76 caratteri, su macOS no: togliamo comunque gli a capo.
base64 <"$KEYSTORE" | tr -d '\n' >"$OUT"
chmod 600 "$OUT"

info "Chiave codificata in: $OUT"
echo
echo "Salvala come secret del repository GitHub:"
echo "  1. apri https://github.com/<utente>/<repository>/settings/secrets/actions/new"
echo "  2. Name: ANDROID_DEBUG_KEYSTORE_BASE64"
echo "  3. Secret: incolla l'intero contenuto di $OUT"
echo
echo "Oppure, con la GitHub CLI (gh) già autenticata:"
echo "  gh secret set ANDROID_DEBUG_KEYSTORE_BASE64 --repo <utente>/<repository> < $OUT"
echo
echo "Poi cancella $OUT e tieni una copia di sicurezza di $KEYSTORE: senza quel file"
echo "gli aggiornamenti non si installano sopra la versione già presente sul telefono."
