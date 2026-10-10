# Tab strip in stile Chrome per Firefox Android

Questa cartella contiene una **patch** per il sorgente ufficiale di Firefox per Android (Fenix) che rende la
barra delle schede (tab strip) uguale, nel comportamento, a quella di **Chrome per Android**, e la fa
**comparire e sparire in tempo reale** quando si apre o si chiude un pieghevole come il **Samsung Galaxy Z Fold**.

La patch è pensata per essere **riapplicata a ogni aggiornamento di Firefox**: quasi tutto il codice sta in file
nuovi e le modifiche ai file esistenti sono poche righe, così i conflitti con le nuove versioni di Firefox sono rari
e, quando capitano, facili da risolvere.

> ⚠️ Il codice di Firefox per Android non vive più in questo repository (archiviato nel 2024, fermo a Firefox 125),
> ma in [`mozilla-firefox/firefox`](https://github.com/mozilla-firefox/firefox) sotto `mobile/android/`. La patch va
> quindi applicata a quel repository; gli script qui sotto lo scaricano per te.

## Cosa cambia

### Comparsa automatica, come in Chrome (pieghevoli, tablet, multi-finestra)

| Situazione                                   | Tab strip |
|----------------------------------------------|-----------|
| Z Fold **aperto** (schermo interno)          | ✅ visibile |
| Z Fold **chiuso** (schermo esterno), anche in orizzontale | ❌ nascosta, toolbar da telefono |
| Tablet                                       | ✅ visibile |
| Finestra divisa / pop-up più stretta di 412dp | ❌ nascosta |
| Telefono                                     | ❌ nascosta |

Le regole sono quelle di Chrome: la tab strip si mostra quando lo schermo su cui gira l'app è un "tablet"
(lato corto ≥ 600dp, la stessa soglia di `DeviceFormFactor` di Chrome) **e** la finestra è larga almeno 412dp.

Quando si apre o si chiude il telefono:

- con la **barra degli indirizzi in alto**, la tab strip appare/scompare **al volo**, con un'animazione, e tutto il
  resto si adatta subito: altezza della toolbar e dell'area della pagina, pulsanti della toolbar
  (avanti/indietro/ricarica sugli schermi larghi), gradiente della status bar;
- con la **barra degli indirizzi in basso** (sul telefono chiuso), aprendolo la barra deve salire in alto insieme
  alla tab strip, come in Chrome: Firefox ricostruisce la schermata (si riavvia l'activity, le schede restano dove
  sono), esattamente come fa Chrome quando un pieghevole passa da "telefono" a "tablet".

Upstream, invece, Firefox **disabilita** la tab strip sui pieghevoli (controllo della cerniera in
`Settings.isTabStripEligible`) e decide una sola volta all'avvio.

### Aspetto e comportamento delle schede, come in Chrome

- **Scheda "folio"**: la scheda selezionata ha gli angoli superiori arrotondati e i "piedini" concavi in basso
  che la fondono con la toolbar sottostante; le altre schede sono trasparenti e separate da **divisori verticali**
  (nascosti accanto alla scheda selezionata).
- **Larghezza dinamica**: le schede si dividono lo spazio disponibile tra **108dp e 265dp**; sotto il minimo la
  strip scorre orizzontalmente. Le variazioni di larghezza sono animate (150 ms).
- **Pulsante di chiusura**: sempre visibile sulla scheda selezionata, nascosto sulle altre quando sono più strette
  di 156dp.
- **Chiusura rapida di più schede**: dopo aver chiuso una scheda le altre mantengono la larghezza per 1,5 secondi,
  così la ✕ della scheda successiva finisce sotto il dito (come Chrome); poi si ridimensionano.
- **Animazioni**: le nuove schede salgono dal basso nella strip, quelle chiuse scendono e svaniscono (150 ms).
- **Pulsante "+"** subito dopo l'ultima scheda, che resta agganciato al bordo quando le schede non ci stanno.
- **Indicatore di caricamento** al posto della favicon mentre la pagina carica.
- **Pulsante navigazione privata** in fondo alla strip (come il selettore "Incognito" di Chrome) quando esistono
  schede dell'altra modalità: un tocco passa all'ultima scheda usata dell'altra modalità.
- **Titoli sfumati** alla fine invece che troncati, altezza della strip di **40dp** come in Chrome.
- Restano: trascinamento con pressione prolungata per riordinare, scroll automatico alla scheda selezionata/nuova,
  accessibilità (azione "Chiudi scheda" per TalkBack).

Colori e icone restano quelli di Firefox (tema chiaro/scuro/privato e sfondi della home compresi).

La preferenza **Impostazioni → Personalizza → Tab strip** continua a funzionare: se attiva (predefinito), la strip
compare automaticamente quando c'è spazio; se disattivata non compare mai.

## Versione di Firefox

La patch segue le **versioni stabili** di Firefox per Android: gli script scaricano automaticamente l'ultima
versione stabile pubblicata, cioè il tag `FIREFOX-ANDROID_<versione>_RELEASE` più recente (oggi **157.0.1**), che è
esattamente il codice da cui Mozilla compila Firefox per il Play Store. Il file [`UPSTREAM_BASE`](UPSTREAM_BASE)
indica il commit di Firefox su cui la patch è stata verificata l'ultima volta.

Per provare un'altra versione basta la variabile `FIREFOX_VERSION`: `beta`, `main` (Nightly) o un tag preciso, ad es.
`FIREFOX_VERSION=FIREFOX-ANDROID_157_0_RELEASE chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox`.

## Uso rapido

Serve Linux o macOS con `git`, `python3` e circa **25 GB** liberi (sorgente ~6 GB, file di build, cache di Gradle e
`~/.mozbuild`). Al primo avvio `mach` scarica JDK e Android SDK in `~/.mozbuild`. Non serve compilare Gecko: si usa
l'"artifact build" (vengono scaricati i binari già compilati da Mozilla per quella versione).

```bash
# 1. Scarica il sorgente dell'ultima versione stabile di Firefox — ~6 GB
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox

# 2. Applica la patch
chrome-tabstrip/scripts/apply.sh ~/firefox

# 3. Compila l'APK (prima volta ~30-60 minuti, poi molto meno)
chrome-tabstrip/scripts/build.sh ~/firefox

# 4. Installa sul telefono (debug USB attivo)
adb install -r ~/firefox/objdir-chrome-tabstrip/gradle/build/mobile/android/fenix/app/outputs/apk/release/*arm64-v8a*.apk
```

`mach` scarica anche un emulatore Android (~7 GB) che per l'APK non serve: se sei corto di spazio, lancia
`build.sh` con `PRUNE_EMULATOR=1` per cancellarlo a fine preparazione (verrà però riscaricato alla build successiva).

Varianti di `build.sh` (secondo argomento):

- `release` (predefinita): si installa come **Firefox** (`org.mozilla.firefox`), identico a quello del Play Store
  ma con la patch. Android non permette di installarlo sopra il Firefox del Play Store (firma diversa): prima
  sincronizza i dati con il tuo account Mozilla (o esporta i segnalibri), poi disinstalla Firefox del Play Store.
- `nightly`: stesso codice stabile, ma si installa come app separata "Firefox Nightly" (`org.mozilla.fenix`),
  utile per provare la patch tenendo il Firefox del Play Store.
- `debug`: più lenta, si installa come app separata (`org.mozilla.fenix.debug`), per sviluppo.

## Chiave di firma e secret di GitHub

Android accetta un aggiornamento solo se è firmato con la **stessa chiave** della versione installata. Gli APK sono
firmati con la chiave di debug di Android, `~/.android/debug.keystore`, creata automaticamente alla prima
compilazione: **conservala** (fanne una copia di sicurezza), altrimenti per aggiornare dovrai disinstallare
l'app perdendo i dati.

Se compili con GitHub Actions, la stessa chiave va salvata come *secret* del repository, così anche gli APK
compilati da GitHub si installano sopra quelli precedenti:

1. Sul computer dove hai compilato (o su qualsiasi computer con un JDK, se non hai ancora compilato) esegui:

   ```bash
   chrome-tabstrip/scripts/signing-key.sh
   ```

   Usa `~/.android/debug.keystore` se esiste (altrimenti ne crea una nuova) e scrive la chiave in formato testo
   (base64) nel file `~/.android/debug.keystore.base64`.

2. Su GitHub apri il repository → **Settings** → **Secrets and variables** → **Actions** →
   **New repository secret** (per questo repository:
   <https://github.com/Waph1/firefox-android-tab_strip/settings/secrets/actions/new>).

3. In **Name** scrivi `ANDROID_DEBUG_KEYSTORE_BASE64`, in **Secret** incolla **tutto** il contenuto di
   `~/.android/debug.keystore.base64` (su macOS: `pbcopy < ~/.android/debug.keystore.base64` lo copia negli
   appunti; su Linux aprilo con un editor di testo), poi **Add secret**.

   In alternativa, con la [GitHub CLI](https://cli.github.com/) già autenticata:

   ```bash
   gh secret set ANDROID_DEBUG_KEYSTORE_BASE64 --repo Waph1/firefox-android-tab_strip < ~/.android/debug.keystore.base64
   ```

4. Cancella `~/.android/debug.keystore.base64` (il secret è salvato cifrato su GitHub e non è più leggibile,
   nemmeno da te: per questo serve la copia di sicurezza del file `debug.keystore`).

Il workflow ripristina la chiave dal secret prima di compilare; se il secret manca, compila comunque ma con una
chiave nuova a ogni esecuzione (e te lo segnala con un avviso).

## Quando esce una nuova versione di Firefox

Firefox stabile si aggiorna ogni 4 settimane (più eventuali versioni correttive, es. 157.0.1):

```bash
chrome-tabstrip/scripts/unapply.sh ~/firefox        # toglie la patch
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox  # passa all'ultima versione stabile
chrome-tabstrip/scripts/apply.sh ~/firefox          # riapplica la patch
chrome-tabstrip/scripts/build.sh ~/firefox          # ricompila
```

`apply.sh` prova prima ad applicare la patch così com'è e poi, se il codice di Firefox è cambiato attorno alle
modifiche, con un **merge a 3 vie**. Se restano conflitti:

1. apri i file elencati e risolvi le parti tra `<<<<<<<` e `>>>>>>>`;
2. esegui `chrome-tabstrip/scripts/refresh.sh ~/firefox`, che rigenera `patches/*.patch` e aggiorna
   `UPSTREAM_BASE`;
3. fai commit della patch aggiornata in questo repository.

Per verificare senza modificare nulla: `chrome-tabstrip/scripts/apply.sh ~/firefox --check`.

Per eseguire i test unitari della patch (dopo `build.sh`):

```bash
cd ~/firefox
MOZCONFIG=$PWD/mozconfig-chrome-tabstrip ./mach gradle fenix:testDebugUnitTest \
    --tests 'org.mozilla.fenix.browser.tabstrip.*' --tests 'org.mozilla.fenix.theme.StatusBarColorManagerTest'
```

## Automazione con GitHub Actions

Il workflow [`.github/workflows/chrome-tabstrip.yml`](../.github/workflows/chrome-tabstrip.yml):

- **ogni giorno** verifica che la patch si applichi ancora all'ultima versione stabile di Firefox: quando esce una
  nuova versione che la rompe, GitHub ti avvisa via e-mail e sai che è ora di aggiornarla;
- su richiesta (**Actions → Chrome-like tab strip → Run workflow**, opzione *build*) compila anche l'APK e lo
  allega all'esecuzione come artifact da scaricare (`firefox-<versione>-chrome-tabstrip-release`).

GitHub mostra il pulsante *Run workflow* e avvia le esecuzioni pianificate solo per i workflow presenti nel ramo
predefinito: porta il workflow e la cartella `chrome-tabstrip/` su `main` (finché stanno solo su un altro ramo, il
controllo parte comunque a ogni push che li modifica).

## Cosa tocca la patch

File nuovi (`mobile/android/fenix/app/src/...`):

- `browser/tabstrip/AdaptiveTabStrip.kt` — decide, come Chrome, se la finestra attuale è abbastanza grande per la
  tab strip; è uno stato Compose aggiornato da `HomeActivity` a ogni cambio di configurazione (piega/apertura,
  rotazione, multi-finestra), così l'interfaccia si ricompone da sola.
- `browser/tabstrip/ChromeStyleTabStrip.kt` — la nuova tab strip in stile Chrome.
- `test/.../browser/tabstrip/AdaptiveTabStripTest.kt`, `TabStripModeToggleTest.kt` — test unitari.

Modifiche piccole ai file esistenti:

- `utils/Settings.kt` — `isTabStripEnabled` = preferenza utente (`isTabStripPreferenceEnabled`) **e** finestra
  abbastanza grande; rimosso il blocco per i pieghevoli.
- `HomeActivity.kt` — aggiorna `AdaptiveTabStrip` in `onCreate` e in `onConfigurationChanged` (prima dei fragment)
  e ricostruisce l'interfaccia se la barra degli indirizzi deve cambiare posizione.
- `BrowserToolbarComposable.kt`, `HomeToolbarComposable.kt` — ricalcolano la visibilità della strip quando cambia
  la finestra e la mostrano/nascondono con un'animazione.
- `components/toolbar/BrowserToolbarMiddleware.kt`, `home/toolbar/BrowserToolbarMiddleware.kt` — ricostruiscono i
  pulsanti della toolbar anche quando la finestra cambia senza ruotare (tipico del Fold).
- `StatusBarColorManager.kt`, `TabStripStatusBarView.kt` — il gradiente della status bar segue la strip.
- `CustomizationFragment.kt` — l'interruttore nelle impostazioni usa la preferenza utente.
- `TabStrip.kt` (usa `ChromeStyleTabStripContent`), `TabStripState.kt` (stato di caricamento), `dimens.xml`
  (altezza 40dp), `StatusBarColorManagerTest.kt` (adeguato alle modifiche).

## Differenze rispetto a Chrome

- Chrome riavvia sempre l'activity quando il Fold passa da "telefono" a "tablet"; qui succede solo se la barra
  degli indirizzi deve cambiare posizione, altrimenti il passaggio avviene al volo.
- Colori, icone e caratteri sono quelli di Firefox, non di Google.
- Non ci sono i gruppi di schede di Chrome nella strip (Firefox ha una propria barra dei gruppi, che resta come
  upstream) né le anteprime al passaggio del mouse.
