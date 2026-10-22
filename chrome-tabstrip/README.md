# Tab strip in stile Chrome per Firefox Android

Questa cartella contiene delle **patch** per il sorgente ufficiale di Firefox per Android (Fenix) che rendono la
barra delle schede (tab strip) uguale, nel comportamento, a quella di **Chrome per Android**, e la fa
**comparire e sparire in tempo reale** quando si apre o si chiude un pieghevole come il **Samsung Galaxy Z Fold**.
Allo stesso modo i siti passano **al volo** dalla versione desktop (telefono aperto) a quella mobile (telefono chiuso)
e la status bar sparisce a telefono aperto, con le schede a filo del bordo superiore, per tornare a telefono chiuso.

Le patch sono pensate per essere **riapplicate a ogni aggiornamento di Firefox**: quasi tutto il codice sta in file
nuovi e le modifiche ai file esistenti sono poche righe, così i conflitti con le nuove versioni di Firefox sono rari
e, quando capitano, facili da risolvere. Le funzioni aggiuntive hanno ognuna la propria patch **facoltativa**: se un
aggiornamento di Firefox ne rompe una, la nuova versione esce lo stesso senza quella funzione, e te lo dice (vedi
«Patch obbligatorie e facoltative»). Le funzioni in programma sono descritte in [`PIANO.md`](PIANO.md).

> ⚠️ Il codice di Firefox per Android non vive più in questo repository (archiviato nel 2024, fermo a Firefox 125),
> ma in [`mozilla-firefox/firefox`](https://github.com/mozilla-firefox/firefox) sotto `mobile/android/`. La patch va
> quindi applicata a quel repository; gli script qui sotto lo scaricano per te.

## Senza PC: APK pronti da scaricare dal telefono

Non serve un computer: GitHub compila l'APK da solo e lo pubblica nelle
[**Release**](https://github.com/Waph1/firefox-android-tab_strip/releases) di questo repository. Ogni giorno
controlla se è uscita una nuova versione stabile di Firefox per Android e, se sì, pubblica la nuova versione con la
patch (la compilazione richiede circa un'ora).

**Configurazione (una volta sola, dal browser del telefono):** gli APK devono essere firmati sempre con la stessa
chiave, altrimenti gli aggiornamenti non si installano. La chiave viene generata da GitHub alla prima compilazione e
salvata nel repository **cifrata**; per cifrarla e decifrarla serve una password che conosce solo GitHub:

1. apri <https://github.com/Waph1/firefox-android-tab_strip/settings/secrets/actions/new> (se sul telefono non si
   apre, usa «Visualizza sito desktop» nel browser);
2. **Name:** `APK_SIGNING_PASSWORD`;
3. **Secret:** una password lunga e casuale, **almeno 20 caratteri** (ad es. quella suggerita dal gestore di password
   del telefono). Non devi ricordarla, ma non cancellare né cambiare il secret: senza quella password la chiave non
   è più utilizzabile e per aggiornare bisognerebbe disinstallare l'app;
4. **Add secret**.

Dal giorno dopo (o subito: **Actions → Chrome-like tab strip → Run workflow → Run workflow**) compare la prima
Release. Per installarla dal telefono: apri la Release, scarica il file `.apk`, aprilo e consenti l'installazione.
Il Firefox del Play Store va prima disinstallato (ha una firma diversa): sincronizza prima i dati con il tuo account
Mozilla. Gli aggiornamenti successivi si installano **dall'app stessa** (vedi «Aggiornamenti dall'app»).

Se una nuova versione di Firefox cambia il codice toccato da una patch, GitHub ti manda un'e-mail: la patch va
aggiornata (vedi «Quando esce una nuova versione di Firefox»). Se è una patch obbligatoria la compilazione fallisce e
resta disponibile l'ultima Release funzionante; se è facoltativa la nuova Release esce lo stesso, senza quella
funzione, e l'app te lo dice prima di aggiornare.

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
- con la **barra degli indirizzi in basso** o con la **tab strip in basso** (da Firefox 158 la posizione di entrambe
  si sceglie in **Impostazioni → Personalizza**), Firefox ricostruisce la schermata (si riavvia l'activity, le
  schede restano dove sono), esattamente come fa Chrome quando un pieghevole passa da "telefono" a "tablet". La barra
  degli indirizzi resta dove l'hai messa; la tab strip compare in alto o in basso secondo la preferenza.

Upstream, invece, Firefox **disabilita** la tab strip sui pieghevoli (controllo della cerniera in
`Settings.isTabStripEligible`) e decide una sola volta all'avvio.

### Siti in versione desktop o mobile, seguendo lo schermo

Come per la tab strip, con le impostazioni predefinite Firefox mostra i siti nella **versione desktop** sugli schermi
grandi e nella **versione mobile** su quelli piccoli, e passa dall'una all'altra **al volo** quando si apre o si
chiude il telefono:

| Situazione                                                              | Siti                |
|-------------------------------------------------------------------------|---------------------|
| Z Fold **aperto**, tablet (gli stessi casi in cui compare la tab strip) | 🖥️ versione desktop |
| Z Fold **chiuso**, telefono, finestra divisa / pop-up stretta           | 📱 versione mobile  |

- La scheda che stai guardando si **ricarica subito** nella nuova versione (passando, ad es., da `m.sito.com` a
  `sito.com` quando torna desktop); le altre schede si ricaricano quando le selezioni, così aprire o chiudere il
  telefono non ricarica decine di pagine tutte insieme.
- **Impostazioni → Impostazioni dei siti web → Richiedi sempre sito desktop** viene ricordata **separatamente per lo
  schermo grande e per quello piccolo**: l'interruttore mostra e modifica il valore dello schermo che stai usando. Per
  avere i siti desktop anche a telefono chiuso, ad esempio, basta attivarlo dallo schermo esterno. Predefinito: attivo
  sullo schermo grande, disattivo su quello piccolo (come upstream). Cambiarlo aggiorna anche le schede già aperte.
- Se per una scheda scegli dal menu **Sito desktop** la versione opposta a quella predefinita, quella scheda la
  **mantiene** anche aprendo e chiudendo il telefono (e dopo un riavvio di Firefox); se dal menu rimetti la versione
  predefinita, la scheda torna a seguire lo schermo.

Upstream, invece, Firefox sceglie la versione predefinita una sola volta, in base allo schermo su cui si avvia, e le
schede aperte restano nella versione con cui sono state aperte.

### Status bar nascosta insieme alla tab strip

Per un aspetto più immersivo, mentre la tab strip è visibile Firefox **nasconde la status bar** (orologio, icone delle
notifiche, batteria) e le schede stanno **a filo del bordo superiore** dello schermo. Quando la tab strip sparisce, la
status bar torna; il passaggio avviene **al volo** aprendo e chiudendo il telefono:

| Situazione                                                              | Status bar                           |
|-------------------------------------------------------------------------|--------------------------------------|
| Z Fold **aperto**, tablet (gli stessi casi in cui compare la tab strip) | ❌ nascosta, schede a filo del bordo |
| Z Fold **chiuso**, telefono                                             | ✅ visibile                          |
| Finestra divisa / pop-up, schede aperte da altre app (custom tab)       | ✅ visibile                          |
| Preferenza «Tab strip» disattivata                                      | ✅ visibile                          |

- Vale per tutta l'app (home, pagine, impostazioni...), non solo per la schermata con le schede.
- Per vedere la status bar un attimo basta **trascinare il dito dal bordo superiore verso il basso** (un secondo
  trascinamento apre le notifiche): compare sopra le schede, senza spostare nulla. Il menu principale e le finestre
  di dialogo la lasciano nascosta; se qualche menu a comparsa la fa riapparire, anche lei si sovrappone alle schede
  senza spostare l'interfaccia.
- I video a schermo intero funzionano come prima; uscendone, la status bar resta nascosta.
- Se lo schermo ha un foro per la fotocamera in alto, le schede ci passano sotto, come nelle app a schermo intero.
- Serve Android 13 o successivo (prima, la status bar resta sempre visibile).

Upstream, invece, la status bar è sempre visibile e la tab strip parte sotto di essa.

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
- **Menu della scheda**: tenendo premuta una scheda si apre il suo menu, come in Chrome: **Aggiorna**, **Chiudi
  scheda**, **Chiudi le altre schede** (quelle normali o private, come la scheda; compare il messaggio con
  **Annulla**) e le voci delle funzioni facoltative. Se invece la scheda viene trascinata, il menu si chiude e la
  scheda si sposta.
- Restano: trascinamento con pressione prolungata per riordinare, scroll automatico alla scheda selezionata/nuova,
  accessibilità (azione "Chiudi scheda" per TalkBack).

Colori e icone restano quelli di Firefox (tema chiaro/scuro/privato e sfondi della home compresi).

La preferenza **Impostazioni → Personalizza → Tab strip** continua a funzionare: se attiva (predefinito), la strip
compare automaticamente quando c'è spazio; se disattivata non compare mai. Quando è attiva si può scegliere anche la
**posizione della tab strip** (in alto o in basso), pure dallo schermo esterno.

### Aggiornamenti dall'app

Gli APK pubblicati nelle Release si aggiornano da soli, come le app installate fuori dal Play Store:

- una volta al giorno, all'apertura, Firefox legge il file `update.json` dell'ultima Release di questo repository;
- se c'è una versione più recente, firmata con la stessa chiave, chiede **«Aggiornamento disponibile… Vuoi
  aggiornare ora?»**: con **Aggiorna** scarica l'APK (con la barra di avanzamento) e apre l'installazione di Android,
  che chiede l'ultima conferma; con **Più tardi** lo richiede il giorno dopo;
- per controllare subito, senza aspettare il giorno dopo: **Impostazioni → Informazioni su Firefox → Cerca
  aggiornamenti** (dice anche se Firefox è già aggiornato o se questa versione non si aggiorna da GitHub);
- la prima volta Android chiede di **consentire a Firefox di installare app** (Impostazioni → Installa app
  sconosciute): basta attivare l'interruttore e tornare indietro;
- se nella nuova versione **mancano funzioni facoltative** (la loro patch non si applica ancora alla nuova versione
  di Firefox), la finestra lo dice: in evidenza quelle che hai nella versione installata e che perderesti
  aggiornando, poi le altre. Così decidi subito se aggiornare o aspettare la versione corretta; con **Salta questa
  versione** il controllo giornaliero non la propone più (te la mostra solo «Cerca aggiornamenti») e propone la
  prossima, anche la stessa versione di Firefox ricompilata con la patch sistemata, che ripristina le funzioni
  («Questa versione ripristina: …»);
- **Impostazioni → Informazioni su Firefox → Funzioni della patch** elenca le funzioni facoltative incluse nella
  versione installata e quelle mancanti (con ⚠️ se ne manca qualcuna). La voce compare quando esiste almeno una
  funzione facoltativa.

Le build compilate sul computer (firmate con un'altra chiave) e le varianti `nightly`/`debug` non propongono mai
aggiornamenti. Chi usa un fork con le proprie Release deve cambiare `UPDATE_INFO_URL` in `SelfUpdater.kt`.

### Funzioni facoltative

Ognuna ha la propria patch (vedi «Patch obbligatorie e facoltative»); le funzioni incluse nella versione installata
sono elencate in **Impostazioni → Informazioni su Firefox → Funzioni della patch**.

- **Nuova scheda con la barra degli indirizzi attiva** (`0010`): il pulsante **"+"** della tab strip, dalle pagine
  e dalla home, apre la nuova scheda con la barra degli indirizzi **già selezionata**, pronta per scrivere un
  indirizzo o una ricerca (con la tastiera a schermo, se non c'è una tastiera fisica). La scheda nuova è privata se
  la tab strip mostra le schede private. Upstream la barra viene selezionata solo con alcune impostazioni della home
  (ad es. non quando la home è mostrata in una scheda propria).
- **Scorciatoie da tastiera fisica** (`0020`), come in Chrome e in Firefox per computer. Firefox le riceve **prima
  della pagina**, così funzionano anche mentre si scrive in un sito; l'elenco compare anche nella schermata delle
  scorciatoie di Android (**Meta+/**).

  | Tasti                               | Azione                                                                  |
  |-------------------------------------|-------------------------------------------------------------------------|
  | Ctrl+T                              | nuova scheda (con la barra attiva, se c'è anche la funzione `0010`)     |
  | Ctrl+W, Ctrl+F4                     | chiude la scheda; sull'ultima torna alla home                           |
  | Ctrl+Shift+T                        | riapre l'ultima scheda chiusa                                           |
  | Ctrl+Tab / Ctrl+Shift+Tab           | scheda successiva / precedente, in giro (tenendo premuto continua)      |
  | Ctrl+PagGiù / Ctrl+PagSu            | come Ctrl+Tab / Ctrl+Shift+Tab                                          |
  | Ctrl+1 … Ctrl+8, Ctrl+9             | va alla scheda N; Ctrl+9 all'ultima                                     |
  | Ctrl+L, Alt+D, F6                   | seleziona la barra degli indirizzi                                      |
  | Ctrl+R, F5                          | aggiorna la pagina                                                      |
  | Ctrl+Shift+R, Ctrl+F5               | aggiorna ignorando la cache                                             |
  | Alt+← / Alt+→                       | indietro / avanti                                                       |
  | Ctrl+F                              | trova nella pagina                                                      |
  | Ctrl+D                              | aggiunge la pagina ai segnalibri                                        |
  | Alt (premuto e rilasciato da solo), F10 | apre il menu                                                        |
  | Ctrl+Q                              | chiude Firefox **senza conferma**: le schede restano per la prossima apertura |

  Ctrl+T e Ctrl+Q funzionano ovunque, le altre sulle pagine e sulla home (non, ad es., nelle impostazioni). Ctrl+Shift+T
  riapre subito le schede appena chiuse (anche private, come «Annulla»), poi l'ultima delle schede chiuse di recente
  (solo normali). AltGr (usato per scrivere caratteri come @ o [) e il tasto Meta non attivano scorciatoie. Limite:
  i siti che usano le stesse combinazioni (ad es. Ctrl+F in un editor online) non le ricevono.
- **Menu a tendina sugli schermi grandi** (`0030`): a schermo grande il menu **⋮** delle pagine e della home scende
  dal pulsante, in alto a destra, come in Chrome per tablet, invece di salire dal basso; con la barra degli indirizzi
  in basso si apre verso l'alto. Il contenuto è quello di Firefox (sottomenu compresi), cambia solo la finestra: se è
  più alto dello schermo scorre, si chiude toccando fuori, con Indietro/Esc o ripremendo F10 o il tasto Menu. A
  schermo piccolo, e per le schede aperte da altre app, resta il pannello dal basso. La tendina si posiziona in base
  all'altezza di tab strip e barra degli indirizzi; se si apre o si chiude il telefono con il menu aperto, resta
  com'è fino alla chiusura.
- **Zoom delle pagine come su computer** (`0040`), **solo a schermo grande**: la pagina si ingrandisce e si
  riorganizza come con lo zoom di Firefox per computer (livelli 30–300%).
  - **Zoom predefinito** in Impostazioni → Personalizza → «Zoom delle pagine (schermo grande)», dove si può anche
    azzerare lo zoom di tutti i siti.
  - **Zoom per sito**, ricordato per ogni sito; nelle schede private vale solo finché restano aperte.
  - Si cambia dal menu ⋮, con la riga **Zoom − 110% +** (toccando la percentuale si torna allo zoom predefinito), o
    con **Ctrl + / Ctrl − / Ctrl 0**, che mostrano per un attimo il nuovo zoom.
  - Chiudendo il telefono le pagine tornano al 100%; riaprendolo torna lo zoom scelto, al volo.

  GeckoView non offre lo zoom delle pagine di Firefox per computer: lo applica un'estensione interna e invisibile
  (la proprietà CSS `zoom`), quindi il PDF, la modalità lettura e le pagine interne di Firefox non si ingrandiscono, e
  su qualche sito particolare (editor, mappe) possono esserci piccoli difetti: basta rimettere quel sito al 100%.
- **Barra dei segnalibri** (`0050`), **solo a schermo grande**: una riga accanto alla barra degli indirizzi (sotto
  se la barra è in alto, sopra se è in basso), sulle pagine e nella home, con i segnalibri della cartella **«Barra
  dei segnalibri»**, quella della barra dei segnalibri di Firefox per computer: con Sync è la stessa del PC.
  - Ogni segnalibro mostra l'icona del sito e il titolo; le cartelle si aprono a tendina (le sottocartelle di
    fianco), i separatori sono righe verticali e i segnalibri che non ci stanno finiscono nel pulsante **»**.
  - Tocco o clic: apre il segnalibro nella scheda corrente (dalla home, come i segnalibri della home); **Ctrl+clic**
    o **clic centrale**: in una nuova scheda in background.
  - **Pressione prolungata** o **clic destro** su un segnalibro della barra: Apri in nuova scheda, Apri in scheda
    privata, Modifica (l'editor dei segnalibri di Firefox, dove si può anche cambiare cartella), Elimina.
  - Scorrendo la pagina si nasconde insieme alla barra degli indirizzi; rilegge i segnalibri quando compare e dopo
    ogni sincronizzazione. Se la cartella è vuota, la barra spiega come riempirla.
  - Si mostra e si nasconde in Impostazioni → Personalizza → «Barra dei segnalibri (schermo grande)» o con
    **Ctrl+Shift+B**, che cambia la stessa impostazione.
  - Ctrl+D e la stellina salvano i segnalibri in «Segnalibri mobile», come sempre: per metterli nella barra,
    Modifica → cartella «Barra dei segnalibri».
- **Mouse e trackpad** (`0060`) sulla tab strip, come in Chrome:
  - **clic centrale** su una scheda: la chiude;
  - **clic destro** su una scheda: apre il suo menu (lo stesso della pressione prolungata), senza selezionarla;
  - **rotella** (anche quella verticale) o scorrimento del trackpad: fa scorrere le schede;
  - tenendo il mouse fermo su una scheda compare un **suggerimento** con il titolo completo e il sito.

  Le schede e il pulsante di chiusura si evidenziano già sotto il mouse in Firefox. Per la barra dei segnalibri
  (clic centrale, Ctrl+clic, clic destro) vedi la funzione `0050`.

## Versione di Firefox

La patch segue le **versioni stabili** di Firefox per Android: gli script scaricano automaticamente l'ultima
versione stabile pubblicata, cioè il tag `FIREFOX-ANDROID_<versione>_RELEASE` più recente (oggi **158.0.2**), che è
esattamente il codice da cui Mozilla compila Firefox per il Play Store. Il file [`UPSTREAM_BASE`](UPSTREAM_BASE)
indica il commit di Firefox su cui la patch è stata verificata l'ultima volta.

Per provare un'altra versione basta la variabile `FIREFOX_VERSION`: `beta`, `main` (Nightly) o un tag preciso, ad es.
`FIREFOX_VERSION=FIREFOX-ANDROID_158_0_RELEASE chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox`.

## Patch obbligatorie e facoltative

Le patch sono in [`patches/`](patches) ed elencate, nell'ordine, in [`patches/series`](patches/series), con il nome
della funzione in italiano e in inglese (quello che compare nell'app e nelle Release):

- **obbligatorie**: `0001` (tab strip, siti desktop/mobile, status bar, aggiornamenti dall'app) e `0002`
  (funzioni facoltative e menu delle schede). Se non si applicano o non compilano, la compilazione su GitHub
  fallisce e resta disponibile l'ultima Release buona;
- **facoltative**: una per funzione. Su GitHub, quelle che non si applicano o non compilano vengono **saltate**: la
  Release esce lo stesso, ne elenca le funzioni mancanti e l'app lo dice prima di aggiornare.

Regole per le patch facoltative, che permettono di saltarne una senza toccare le altre:

- ognuna si applica e compila **sopra le sole patch obbligatorie**, qualunque altra facoltativa manchi; due
  facoltative non modificano mai le stesse righe (`apply.sh --check` lo verifica);
- ognuna definisce l'oggetto Kotlin `org.mozilla.fenix.patchfeatures.<Nome>Feature`, dove `<Nome>` viene dal nome del
  file (es. `0080-tab-groups.patch` → `TabGroupsFeature`), che implementa `PatchFeatureHooks`: è il suo punto di
  ingresso. Il codice delle patch obbligatorie chiama le funzioni facoltative solo attraverso `PatchFeatureHooks`
  (es. le voci del menu della scheda); se a una funzione serve un nuovo punto di aggancio, va aggiunto alla `0002`;
- `apply.sh` scrive in `patchfeatures/GeneratedPatchFeatures.kt` le funzioni incluse e mancanti e l'elenco dei loro
  oggetti: è generato, non fa parte di nessuna patch e non va modificato.

Per lavorare su una patch, applicala **per ultima** e rigenerala con `refresh.sh`, che rigenera sempre l'ultima
patch applicata:

```bash
chrome-tabstrip/scripts/apply.sh ~/firefox tab-groups                 # obbligatorie + solo quella facoltativa
# ... modifica il codice, compila, prova ...
chrome-tabstrip/scripts/refresh.sh ~/firefox                          # rigenera patches/0080-tab-groups.patch

chrome-tabstrip/scripts/refresh.sh ~/firefox 0090-nuova-funzione.patch  # crea una patch nuova con le modifiche
                                                                        # fatte sopra le patch applicate
chrome-tabstrip/scripts/unapply.sh ~/firefox tab-groups               # toglie solo quella facoltativa
```

Per modificare una patch obbligatoria, togli prima con `unapply.sh` quelle applicate dopo di lei.

## Uso rapido

Serve Linux o macOS con `git`, `python3` e circa **25 GB** liberi (sorgente ~6 GB, file di build, cache di Gradle e
`~/.mozbuild`). Al primo avvio `mach` scarica JDK e Android SDK in `~/.mozbuild`. Non serve compilare Gecko: si usa
l'"artifact build" (vengono scaricati i binari già compilati da Mozilla per quella versione).

```bash
# 1. Scarica il sorgente dell'ultima versione stabile di Firefox — ~6 GB
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox

# 2. Applica le patch (tutte; per scegliere le funzioni facoltative: apply.sh ~/firefox tab-groups ...)
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

## Chiave di firma

Android accetta un aggiornamento solo se è firmato con la **stessa chiave** della versione installata.

- **APK compilati da GitHub** (sezione «Senza PC»): la chiave è in `chrome-tabstrip/signing/debug.keystore.enc`,
  cifrata con AES-256 e la password del secret `APK_SIGNING_PASSWORD`; il file da solo non serve a nulla.
- **APK compilati sul tuo computer**: sono firmati con la chiave di debug di Android, `~/.android/debug.keystore`,
  creata automaticamente alla prima compilazione. Conservala (fanne una copia di sicurezza). Le due chiavi sono
  diverse: non mescolare APK compilati da GitHub e dal computer sullo stesso telefono.

## Quando esce una nuova versione di Firefox

Firefox stabile si aggiorna ogni 4 settimane (più eventuali versioni correttive, es. 157.0.1):

```bash
chrome-tabstrip/scripts/unapply.sh ~/firefox        # toglie le patch
chrome-tabstrip/scripts/fetch-firefox.sh ~/firefox  # passa all'ultima versione stabile
chrome-tabstrip/scripts/apply.sh ~/firefox          # riapplica le patch
chrome-tabstrip/scripts/build.sh ~/firefox          # ricompila
```

`apply.sh` applica le patch nell'ordine di `patches/series`, ognuna prima così com'è e poi, se il codice di Firefox
è cambiato attorno alle modifiche, con un **merge a 3 vie**. Se restano conflitti, si ferma su quella patch:

1. apri i file elencati e risolvi le parti tra `<<<<<<<` e `>>>>>>>`;
2. esegui `chrome-tabstrip/scripts/refresh.sh ~/firefox`, che rigenera quella patch e aggiorna `UPSTREAM_BASE`;
3. rilancia `apply.sh ~/firefox` per applicare le patch rimanenti (quelle già applicate restano come sono);
4. fai commit delle patch aggiornate in questo repository.

Per verificare senza modificare nulla: `chrome-tabstrip/scripts/apply.sh ~/firefox --check` (le obbligatorie, ogni
facoltativa da sola sopra le obbligatorie, e tutte insieme).

Per eseguire i test unitari della patch (dopo `build.sh`):

```bash
cd ~/firefox
MOZCONFIG=$PWD/mozconfig-chrome-tabstrip ./mach gradle fenix:testDebugUnitTest \
    --tests 'org.mozilla.fenix.browser.tabstrip.*' --tests 'org.mozilla.fenix.browser.desktopmode.*' \
    --tests 'org.mozilla.fenix.theme.StatusBarColorManagerTest' --tests 'org.mozilla.fenix.selfupdate.*' \
    --tests 'org.mozilla.fenix.patchfeatures.*'
```

## Automazione con GitHub Actions

Il workflow [`.github/workflows/chrome-tabstrip.yml`](../.github/workflows/chrome-tabstrip.yml):

- **ogni giorno** controlla l'ultima versione stabile di Firefox per Android: se una patch obbligatoria non si
  applica più, GitHub ti avvisa via e-mail; altrimenti, se quella versione non è ancora nelle Release, compila l'APK
  e lo pubblica insieme a `update.json` (versione, firma e indirizzo dell'APK, funzioni incluse e mancanti, letti da
  Firefox per aggiornarsi);
- le patch **facoltative** che non si applicano vengono saltate; se una non compila, `ci-build.sh` risale dagli
  errori alla patch, la toglie e ricompila (al massimo 3 compilazioni; se gli errori non portano a nessuna patch
  facoltativa, le toglie tutte). La Release esce lo stesso, con l'elenco delle funzioni mancanti, e poi l'esecuzione
  finisce in errore, così arriva l'e-mail che avvisa di sistemare la patch;
- una Release con funzioni mancanti viene **ricompilata** (stessa versione di Firefox, `versionCode` più alto, quindi
  proposta come aggiornamento) appena le patch cambiano, cioè dopo che sono state sistemate; finché restano uguali
  non si ricompila, così non arriva un'e-mail al giorno;
- prima di pubblicare controlla che il `versionCode` del nuovo APK (le ore passate dal 2014 all'ora della
  compilazione) superi quello dell'ultima Release, altrimenti l'app non lo proporrebbe come aggiornamento: due
  compilazioni nella stessa ora si fermano qui, e basta rilanciare il workflow un'ora dopo;
- a ogni push che modifica le patch o gli script verifica che le patch si applichino;
- a mano (**Actions → Chrome-like tab strip → Run workflow**) fa le stesse cose; con *mode = test* compila con una
  chiave temporanea e allega l'APK all'esecuzione invece di pubblicarlo (utile per provare una versione diversa
  con *version*, es. `beta`).

GitHub esegue le attività pianificate solo dal ramo predefinito (`main`) e le sospende dopo 60 giorni senza
modifiche al repository: in quel caso ti manda un'e-mail e basta riattivarle da **Actions**.

## Cosa toccano le patch

### `0001`: tab strip, siti desktop/mobile, status bar, aggiornamenti

File nuovi (`mobile/android/fenix/app/src/...`):

- `browser/tabstrip/AdaptiveTabStrip.kt` — decide, come Chrome, se la finestra attuale è abbastanza grande per la
  tab strip (e per i siti desktop); è uno stato Compose aggiornato da `HomeActivity` a ogni cambio di configurazione
  (piega/apertura, rotazione, multi-finestra), così l'interfaccia si ricompone da sola.
- `browser/tabstrip/ChromeStyleTabStrip.kt` — la nuova tab strip in stile Chrome.
- `browser/tabstrip/ImmersiveTabStrip.kt` — nasconde la status bar mentre la tab strip è visibile (anche nelle
  finestre di dialogo) e adatta gli insets passati all'interfaccia: status bar e foro della fotocamera in alto non
  occupano spazio, così le schede stanno a filo del bordo e nulla si sposta se la status bar ricompare per un attimo.
- `browser/desktopmode/AdaptiveDesktopModeMiddleware.kt` — fa sì che la versione desktop/mobile dei siti segua la
  finestra (al posto di `DesktopModeMiddleware`) e aggiorna le schede aperte quando cambia;
  `AdaptiveDesktopModeRepository.kt` salva la preferenza per schermo grande e piccolo e le schede con una versione
  scelta dal menu.
- `selfupdate/SelfUpdater.kt` — gli aggiornamenti dall'app, dalle Release di GitHub; `res/values/` e
  `res/values-it/self_update_strings.xml` — i testi delle finestre.
- `test/.../browser/tabstrip/AdaptiveTabStripTest.kt`, `ImmersiveTabStripTest.kt`, `TabStripModeToggleTest.kt`,
  `test/.../browser/desktopmode/AdaptiveDesktopModeMiddlewareTest.kt`, `AdaptiveDesktopModeRepositoryTest.kt`,
  `test/.../selfupdate/SelfUpdaterTest.kt` — test unitari.

Modifiche piccole ai file esistenti:

- `utils/Settings.kt` — `isTabStripEnabled` = preferenza utente (`isTabStripPreferenceEnabled`) **e** finestra
  abbastanza grande; rimosso il blocco per i pieghevoli.
- `HomeActivity.kt` — aggiorna `AdaptiveTabStrip` in `onCreate` e in `onConfigurationChanged` (prima dei fragment)
  e ricostruisce l'interfaccia quando la strip compare/scompare con la barra degli indirizzi o la strip in basso;
  avvia e aggiorna `ImmersiveTabStrip`; avvia `SelfUpdater`.
- `BrowserToolbarComposable.kt`, `HomeToolbarComposable.kt` — ricalcolano la visibilità della strip quando cambia
  la finestra e la mostrano/nascondono con un'animazione.
- `components/toolbar/BrowserToolbarMiddleware.kt`, `home/toolbar/BrowserToolbarMiddleware.kt` — ricostruiscono i
  pulsanti della toolbar anche quando la finestra cambia senza ruotare (tipico del Fold).
- `StatusBarColorManager.kt`, `TabStripStatusBarView.kt` — il gradiente della status bar segue la strip.
- `components/Core.kt` — usa `AdaptiveDesktopModeMiddleware`; `SiteSettingsFragment.kt` — l'interruttore «Richiedi
  sempre sito desktop» si aggiorna se si apre/chiude il telefono con la schermata aperta.
- `CustomizationFragment.kt` — l'interruttore e la posizione della strip nelle impostazioni usano la preferenza
  utente.
- `settings/about/AboutFragment.kt`, `AboutItem.kt` — la voce «Cerca aggiornamenti» in Informazioni su Firefox.
- `TabStrip.kt` (usa `ChromeStyleTabStripContent`), `TabStripState.kt` (stato di caricamento), `dimens.xml`
  (altezza 40dp), `StatusBarColorManagerTest.kt` (adeguato alle modifiche).

### `0002`: funzioni facoltative e menu delle schede

File nuovi:

- `patchfeatures/PatchFeatures.kt` — le funzioni facoltative incluse e mancanti (`PatchFeatures`), il confronto con
  quelle di un aggiornamento (`PatchFeatureChanges`) e i punti di aggancio delle funzioni (`PatchFeatureHooks`);
  `PatchFeaturesDialog.kt` — la voce «Funzioni della patch» di Informazioni su Firefox.
- `browser/tabstrip/TabStripTabMenu.kt` — il menu della scheda nella tab strip.
- `res/values/` e `res/values-it/patch_features_strings.xml` — i testi.
- `test/.../patchfeatures/PatchFeaturesTest.kt`, `test/.../browser/tabstrip/TabStripTabMenuTest.kt` — test unitari.

Modifiche ai file della `0001`: `SelfUpdater.kt` (funzioni mancanti nella finestra dell'aggiornamento, «Salta
questa versione»), `ChromeStyleTabStrip.kt` (menu con la pressione prolungata), `AboutFragment.kt`, `AboutItem.kt`
(voce «Funzioni della patch»).

Modifiche piccole ai file esistenti: `TabStrip.kt` (azioni del menu; il "+" lascia aprire la nuova scheda alle
funzioni facoltative, con `PatchFeatureHooks.openNewTab`), `BaseBrowserFragment.kt`, `HomeFragment.kt`
(messaggio «Schede chiuse» con Annulla dopo «Chiudi le altre schede»), `HomeActivity.kt` (i tasti passano prima dalle
funzioni facoltative, `PatchFeatureHooks.onKeyEvent`, che compaiono anche nella schermata delle scorciatoie di
Android, `PatchFeatureHooks.keyboardShortcuts`), `MenuDialogFragment.kt` (una funzione facoltativa può mostrare il
menu in un'altra finestra, `PatchFeatureHooks.menuDialog`: in quel caso niente maniglia e angoli tutti arrotondati), `MainMenu.kt` (voci
delle funzioni facoltative in cima al menu, `PatchFeatureHooks.MainMenuItems`), `CustomizationFragment.kt`
(preferenze delle funzioni facoltative in Impostazioni → Personalizza, `PatchFeatureHooks.addCustomizationPreferences`);
in `HomeActivity.kt` anche l'avvio delle funzioni facoltative (`PatchFeatureHooks.onActivityCreated`).
`ChromeStyleTabStrip.kt` (della `0001`) lascia aggiungere qualcosa a ogni scheda (`PatchFeatureHooks.TabStripTab`, con
le azioni chiudi e mostra il menu) e alla lista delle schede (`PatchFeatureHooks.tabStripModifier`).
`BrowserToolbarComposable.kt` e `HomeToolbarComposable.kt` mostrano accanto alla barra degli indirizzi le righe delle
funzioni facoltative (`PatchFeatureHooks.AddressBarRow`), `ext/Fragment.kt` ne conta l'altezza nello spazio che le
pagine lasciano alle barre (`PatchFeatureHooks.addressBarRowHeight`) e `BaseBrowserFragment.kt` lo ricalcola quando
cambia (`PatchFeatureHooks.onAddressBarRowsChanged`).

### `0010`: nuova scheda con la barra degli indirizzi attiva (facoltativa)

Solo file nuovi: `patchfeatures/NewTabFocusFeature.kt` apre la nuova scheda come Firefox (una scheda con la home, se
la home è mostrata in una scheda propria) e poi mostra la home con la barra degli indirizzi selezionata
(`focusOnAddressBar`, lo stesso argomento che Firefox usa altrove); `test/.../NewTabFocusFeatureTest.kt`.

### `0020`: scorciatoie da tastiera fisica (facoltativa)

Solo file nuovi: `patchfeatures/KeyboardShortcuts.kt` (dai tasti alla scorciatoia, scelta della scheda, Alt premuto da
solo), `KeyboardShortcutsFeature.kt` (le azioni, fatte come le fa Firefox: ad es. il segnalibro come il pulsante della
toolbar, il menu come il tasto Menu), `res/values/` e `res/values-it/keyboard_shortcuts_strings.xml`,
`test/.../KeyboardShortcutsTest.kt`.

### `0030`: menu a tendina sugli schermi grandi (facoltativa)

Solo file nuovi: `patchfeatures/DropdownMenuFeature.kt` (la finestra a tendina e la sua posizione) e
`test/.../DropdownMenuFeatureTest.kt`.

### `0040`: zoom delle pagine come su computer (facoltativa)

Solo file nuovi: `assets/extensions/chrome-tabstrip-zoom/` (l'estensione interna: lo script in background riceve gli
zoom dall'app e li manda alle pagine, lo script delle pagine applica `zoom` all'elemento radice),
`patchfeatures/PageZoom.kt` (livelli, zoom per sito, scorciatoie), `PageZoomFeature.kt` (installazione
dell'estensione, impostazioni salvate, riga del menu, preferenze, Ctrl + / − / 0), `res/values/` e
`res/values-it/page_zoom_strings.xml`, `test/.../PageZoomTest.kt`.

### `0050`: barra dei segnalibri (facoltativa)

Solo file nuovi: `patchfeatures/BookmarksBar.kt` (cosa mostrare, quanti segnalibri entrano, Ctrl+Shift+B),
`BookmarksBarContent.kt` (la barra, i menu delle cartelle e del pulsante », il menu del segnalibro, i clic del mouse),
`BookmarksBarFeature.kt` (lettura della cartella «Barra dei segnalibri» di Places e aggiornamento dopo ogni
sincronizzazione, apertura dei segnalibri come fa la home, impostazione), `res/values/` e
`res/values-it/bookmarks_bar_strings.xml`, `test/.../BookmarksBarTest.kt`.

### `0060`: mouse e trackpad (facoltativa)

Solo file nuovi: `patchfeatures/Mouse.kt` (scorrimento con la rotella, posizione del suggerimento, sito della scheda),
`MouseFeature.kt` (clic centrale e destro e suggerimento sulle schede, rotella sulla tab strip),
`test/.../MouseTest.kt`.

## Differenze rispetto a Chrome

- Chrome riavvia sempre l'activity quando il Fold passa da "telefono" a "tablet"; qui succede solo se la barra
  degli indirizzi deve cambiare posizione, altrimenti il passaggio avviene al volo.
- Colori, icone e caratteri sono quelli di Firefox, non di Google.
- Chrome mostra sempre la status bar; qui, a telefono aperto e sui tablet, è nascosta insieme alla tab strip.
- Non ci sono i gruppi di schede di Chrome nella strip (Firefox ha una propria barra dei gruppi, che resta come
  upstream) né le anteprime al passaggio del mouse.
