#!/usr/bin/env bash
# GitHub Actions: prepara la chiave con cui vengono firmati gli APK pubblicati.
#
# La chiave (un keystore Android) è salvata nel repository solo cifrata, in chrome-tabstrip/signing/, con
# AES-256 e la password del secret APK_SIGNING_PASSWORD: senza quella password il file è inutilizzabile.
# Alla prima esecuzione la chiave non esiste: viene generata qui, cifrata e salvata con un commit, così tutte le
# build successive sono firmate con la stessa chiave e si installano come aggiornamenti.
#
# Variabili d'ambiente:
#   APK_SIGNING_PASSWORD   il secret (obbligatorio, almeno 20 caratteri)
#   ANDROID_USER_HOME      dove scrivere debug.keystore (predefinito: ~/.android), letto dalla build di Android

source "$(dirname "$0")/common.sh"

ENCRYPTED="$PATCH_ROOT/signing/debug.keystore.enc"
KEYSTORE="${ANDROID_USER_HOME:-$HOME/.android}/debug.keystore"
OPENSSL_ARGS=(-aes-256-cbc -pbkdf2 -iter 600000 -md sha256)

[ -n "${APK_SIGNING_PASSWORD:-}" ] || die "manca il secret APK_SIGNING_PASSWORD"
[ "${#APK_SIGNING_PASSWORD}" -ge 20 ] ||
    die "il secret APK_SIGNING_PASSWORD è troppo corto: usa almeno 20 caratteri casuali"

mkdir -p "$(dirname "$KEYSTORE")"

if [ -f "$ENCRYPTED" ]; then
    info "Decifro la chiave di firma salvata nel repository"
    openssl enc -d "${OPENSSL_ARGS[@]}" -in "$ENCRYPTED" -out "$KEYSTORE" -pass env:APK_SIGNING_PASSWORD ||
        die "impossibile decifrare $ENCRYPTED: il secret APK_SIGNING_PASSWORD non è quello usato per crearla"
    exit 0
fi

info "Prima esecuzione: genero una nuova chiave di firma"
# Alias e password sono quelli standard della chiave di debug di Android, che la build di Firefox usa per firmare.
# La protezione è la cifratura del file con APK_SIGNING_PASSWORD.
keytool -genkeypair -keystore "$KEYSTORE" -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 4096 -validity 36500 -dname "CN=Firefox tab strip,O=Waph1,C=IT" >/dev/null

mkdir -p "$(dirname "$ENCRYPTED")"
openssl enc -e "${OPENSSL_ARGS[@]}" -salt -in "$KEYSTORE" -out "$ENCRYPTED" -pass env:APK_SIGNING_PASSWORD

info "Salvo la chiave cifrata nel repository"
cd "$PATCH_ROOT"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add "$ENCRYPTED"
git commit -m "chrome-tabstrip: aggiungi la chiave di firma cifrata degli APK"
git pull --rebase -q origin "${GITHUB_REF_NAME:?}"
git push origin "HEAD:$GITHUB_REF_NAME"
