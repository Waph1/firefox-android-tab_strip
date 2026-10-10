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

Quando si apre o si chiude il telefono la tab strip appare/scompare **senza riavviare l'activity**, con
un'animazione, e tutto il resto si adatta subito: altezza della toolbar e dell'area della pagina, pulsanti della
toolbar (avanti/indietro/ricarica sugli schermi larghi), gradiente della status bar, barra di navigazione.

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

## Uso rapido

Serve Linux o macOS con `git`, `python3` e circa **25 GB** liberi (sorgente ~6 GB, file di build, cache di Gradle e
`~/.mozbuild`). Al primo avvio `mach` scarica JDK e Android SDK in `~/.mozbuild` (anche un emulatore: se non ti serve
puoi cancellare `~/.mozbuild/android-device` e `~/.mozbuild/android-sdk-linux/{emulator,system-images}`).
Non serve compilare Gecko: si usa l'"artifact build" (vengono scaricati i binari di Mozilla).

```bash
# 1. Scarica il sorgente di Firefox (Nightly, ramo main) — ~6 GB
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox

# 2. Applica la patch
chrome-tabstrip/scripts/apply.sh ~/firefox

# 3. Compila l'APK (prima volta ~30-60 minuti, poi molto meno)
chrome-tabstrip/scripts/build.sh ~/firefox nightly

# 4. Installa sul telefono (debug USB attivo)
adb install -r ~/firefox/objdir-chrome-tabstrip/gradle/build/mobile/android/fenix/app/outputs/apk/nightly/*arm64-v8a*.apk
```

Varianti di `build.sh`:

- `nightly` (consigliata): ottimizzata, si installa come "Firefox Nightly" (`org.mozilla.fenix`). Non si può
  installare sopra la Nightly del Play Store (firma diversa): disinstallala prima o usa `debug`.
- `debug`: più lenta, si installa accanto alle altre versioni (`org.mozilla.fenix.debug`).

Le build sono firmate con la chiave di debug di Android (`~/.android/debug.keystore`). **Conserva quel file**:
con una chiave diversa gli aggiornamenti non si installano sopra la versione precedente (bisognerebbe
disinstallare, perdendo i dati).

## Quando esce una nuova versione di Firefox

```bash
chrome-tabstrip/scripts/unapply.sh ~/firefox        # toglie la patch
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox  # aggiorna il sorgente
chrome-tabstrip/scripts/apply.sh ~/firefox          # riapplica la patch
chrome-tabstrip/scripts/build.sh ~/firefox nightly  # ricompila
```

`apply.sh` prova prima ad applicare la patch così com'è e poi, se il codice di Firefox è cambiato attorno alle
modifiche, con un **merge a 3 vie**. Se restano conflitti:

1. apri i file elencati e risolvi le parti tra `<<<<<<<` e `>>>>>>>`;
2. esegui `chrome-tabstrip/scripts/refresh.sh ~/firefox`, che rigenera `patches/*.patch` e aggiorna
   `UPSTREAM_BASE` (il commit di Firefox su cui la patch è stata verificata l'ultima volta);
3. fai commit della patch aggiornata in questo repository.

Per verificare senza modificare nulla: `chrome-tabstrip/scripts/apply.sh ~/firefox --check`.

Per eseguire i test unitari della patch (dopo `build.sh`):

```bash
cd ~/firefox
MOZCONFIG=$PWD/mozconfig-chrome-tabstrip ./mach gradle fenix:testDebugUnitTest \
    --tests 'org.mozilla.fenix.browser.tabstrip.*' --tests 'org.mozilla.fenix.theme.StatusBarColorManagerTest'
```

Per seguire Beta o Release invece di Nightly: `UPSTREAM_BRANCH=beta chrome-tabstrip/scripts/fetch-firefox.sh ...`
(i rami disponibili sono quelli di [mozilla-firefox/firefox](https://github.com/mozilla-firefox/firefox/branches)).

## Automazione con GitHub Actions

Il workflow [`.github/workflows/chrome-tabstrip.yml`](../.github/workflows/chrome-tabstrip.yml):

- **ogni giorno** verifica che la patch si applichi ancora all'ultima versione di Firefox: se fallisce, GitHub
  ti avvisa via e-mail e sai che è ora di aggiornarla;
- su richiesta (**Actions → Chrome-like tab strip → Run workflow**, opzione *build*) compila anche l'APK e lo
  allega all'esecuzione come artifact da scaricare.

Note:

- GitHub mostra il pulsante *Run workflow* e avvia le esecuzioni pianificate solo per i workflow presenti nel ramo
  predefinito: porta il workflow e la cartella `chrome-tabstrip/` su `main` (finché stanno solo su un altro ramo, il
  controllo parte comunque a ogni push che li modifica);
- per avere APK aggiornabili l'uno sopra l'altro, salva la tua chiave di debug come secret
  `ANDROID_DEBUG_KEYSTORE_BASE64` (`base64 -w0 ~/.android/debug.keystore`, su macOS `base64 -i ~/.android/debug.keystore`);
  senza secret ogni build ha una chiave diversa.

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
- `HomeActivity.kt` — aggiorna `AdaptiveTabStrip` in `onCreate` e in `onConfigurationChanged` (prima dei fragment).
- `BrowserToolbarComposable.kt`, `HomeToolbarComposable.kt`, `BrowserNavigationBar.kt`, `HomeNavigationBar.kt` —
  ricalcolano la visibilità della strip quando cambia la finestra e la mostrano/nascondono con un'animazione.
- `BaseBrowserFragment.kt` — la strip in alto con toolbar in basso viene creata anche a telefono chiuso.
- `components/toolbar/BrowserToolbarMiddleware.kt`, `home/toolbar/BrowserToolbarMiddleware.kt` — ricostruiscono i
  pulsanti della toolbar anche quando la finestra cambia senza ruotare (tipico del Fold).
- `StatusBarColorManager.kt`, `TabStripStatusBarView.kt` — il gradiente della status bar segue la strip.
- `CustomizationFragment.kt` — l'interruttore nelle impostazioni usa la preferenza utente.
- `TabStrip.kt` (usa `ChromeStyleTabStripContent`), `TabStripState.kt` (stato di caricamento), `dimens.xml`
  (altezza 40dp), `StatusBarColorManagerTest.kt` e `FragmentTest.kt` (adeguati alle modifiche).

## Differenze rispetto a Chrome

- Chrome riavvia l'activity quando il Fold passa da "telefono" a "tablet"; qui il passaggio avviene al volo.
- Colori, icone e caratteri sono quelli di Firefox, non di Google.
- Non ci sono i gruppi di schede di Chrome nella strip (Firefox ha una propria barra dei gruppi, che resta come
  upstream) né le anteprime al passaggio del mouse.
