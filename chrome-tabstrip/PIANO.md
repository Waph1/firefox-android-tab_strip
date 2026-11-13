# Piano: nuove funzioni per gli schermi grandi

Questo documento raccoglie le funzioni da aggiungere alla patch, le decisioni prese e l'ordine di lavoro. Serve da
riferimento durante lo sviluppo; man mano che le funzioni vengono completate, la loro descrizione passa nel
[README](README.md) e qui si segna lo stato.

Base di partenza: Firefox per Android 158 (`UPSTREAM_BASE`). Le note su "cosa c'è già upstream" si riferiscono a
quella versione.

**"Schermo grande"** vuol dire, in tutto il documento, la stessa regola con cui compare la tab strip: schermo da
tablet (lato corto ≥ 600dp) e finestra larga almeno 412dp. Sul Fold: telefono aperto. Tutto ciò che vale "solo a
schermo grande" compare e sparisce **al volo** aprendo e chiudendo il telefono, come la tab strip.

## Stato

| #  | Funzione                                          | Patch                        | Tipo        | Stato        |
|----|---------------------------------------------------|------------------------------|-------------|--------------|
| 0  | Patch divise e avviso negli aggiornamenti         | base + `0002`                | obbligatoria | fatto       |
| 1  | Nuova scheda con la barra degli indirizzi attiva  | `0010-new-tab-focus`         | facoltativa | fatto        |
| 2  | Scorciatoie da tastiera fisica                    | `0020-keyboard-shortcuts`    | facoltativa | fatto        |
| 3  | Menu ⋮ a tendina                                  | `0030-dropdown-menu`         | facoltativa | fatto        |
| 4  | Zoom della pagina come su desktop                 | `0040-page-zoom`             | facoltativa | fatto        |
| 5  | Barra dei segnalibri                              | `0050-bookmarks-bar`         | facoltativa | fatto        |
| 6  | Mouse e trackpad                                  | `0060-mouse`                 | facoltativa | fatto        |
| 7  | Icona audio sulle schede                          | `0070-tab-audio`             | facoltativa | fatto        |
| 8  | Gruppi di schede nella tab strip                  | `0080-tab-groups`            | facoltativa | fatto        |
| 9  | Segnalazioni dei crash su GitHub                  | `0090-crash-reports`         | facoltativa | fatto        |

L'ordine della tabella è l'ordine di lavoro: prima l'infrastruttura, poi dal più semplice e utile al più complesso e
fragile. I nomi dei file sono indicativi.

Scartato: **Ctrl+N** (nuova finestra). Firefox per Android ha una sola finestra (`launchMode="singleTask"`) e un
solo elenco di schede con una sola scheda selezionata; più finestre vorrebbero dire riscrivere mezza app.
Rimandato: **schede fissate**.

---

## 0. Patch divise e avviso negli aggiornamenti

### Patch divise

Oggi c'è una sola patch (`0001-fenix-chrome-like-adaptive-tab-strip.patch`). Le nuove funzioni vanno in patch
separate, così se un aggiornamento di Firefox ne rompe una si sistema solo quella e, nel frattempo, le altre
continuano ad arrivare.

- **Obbligatorie**: la `0001` attuale (tab strip, siti desktop/mobile, aggiornamenti dall'app) e una
  nuova `0002` con l'infrastruttura comune descritta sotto. Se non si applicano o non compilano, la build fallisce
  come oggi e resta l'ultima Release buona.
- **Facoltative**: tutte le altre. Se una non si applica o non compila, viene **saltata** e la Release esce lo
  stesso, senza quella funzione.
- Un elenco nella cartella `patches/` dice, per ogni patch, se è obbligatoria e il nome della funzione in italiano
  (quello mostrato nell'app e nella Release).

**Regola di progetto:** ogni patch facoltativa deve applicarsi e compilare **sopra le sole patch obbligatorie**, a
prescindere dalle altre facoltative. Per riuscirci:

- la `0002` contiene i "punti di aggancio" condivisi: le righe nei file di Firefox (es. in `HomeActivity`, nella
  tab strip, nel menu) chiamano un piccolo registro, e ogni funzione facoltativa si registra lì da file suoi;
- le patch facoltative aggiungono soprattutto **file nuovi** e toccano il meno possibile i file di Firefox, mai le
  stesse righe di un'altra patch facoltativa;
- una funzione non chiama mai direttamente il codice di un'altra facoltativa, ma passa dal registro. Ad esempio
  Ctrl + / − chiede lo zoom al registro: se la patch dello zoom è stata saltata, non succede niente.

Nella `0002` va anche il **menu contestuale della scheda** nella tab strip (pressione lunga, e tasto destro col
mouse) con le voci di base (Ricarica, Chiudi scheda, Chiudi le altre schede): audio e gruppi vi aggiungono le
proprie voci tramite il registro.

### Compilazione su GitHub

1. Si applicano le patch obbligatorie: se falliscono, la build si ferma (come oggi).
2. Si prova ogni patch facoltativa: quelle che non si applicano vengono saltate.
3. Si compila. Se la compilazione fallisce, dagli errori si risale ai file e da lì alle patch facoltative che li
   toccano: si tolgono quelle e si ricompila (la seconda compilazione è molto più veloce della prima, i binari di
   Gecko sono già scaricati). Al massimo 2–3 tentativi, poi la build fallisce.
4. Lo script che applica le patch scrive nel sorgente l'elenco delle funzioni incluse, così l'app sa cosa contiene.
5. `update.json` riceve un nuovo campo con le funzioni mancanti (`missingFeatures`), e la descrizione della
   Release le elenca.
6. Se qualcosa è stato saltato, **dopo** aver pubblicato la Release il workflow si chiude come fallito, così arriva
   l'e-mail di GitHub che avvisa di aggiornare la patch.
7. Il controllo giornaliero ricompila la stessa versione di Firefox se l'ultima Release ha funzioni mancanti **e**
   ora tutte le patch si applicano (cioè dopo che la patch è stata sistemata). Se invece le patch continuano a non
   applicarsi, non fa niente e non manda e-mail ogni giorno.
8. Il controllo delle patch già presente nel workflow diventa: ogni facoltativa da sola sopra le obbligatorie, e
   tutte insieme.

Da verificare: che una seconda compilazione della stessa versione di Firefox abbia un `versionCode` maggiore (Fenix
lo calcola dall'ora della build), altrimenti l'app non la proporrebbe come aggiornamento.

### Nell'app

- La finestra **«Aggiornamento disponibile»** dice se la nuova versione è incompleta:
  - se manca una funzione che hai nella versione installata, lo dice in evidenza, ad es. «⚠️ Questa versione non
    include: Gruppi di schede nella tab strip, che hai nella versione installata. Tornerà con un aggiornamento
    successivo.»;
  - se manca una funzione che non avevi già, lo dice come semplice informazione;
  - se la nuova versione rimette una funzione che ti mancava, lo dice («Questa versione ripristina: …»).
- Quando mancano funzioni, oltre ad **Aggiorna** e **Più tardi** c'è **Salta questa versione**: non la propone
  più, ma propone la prossima (anche la stessa versione di Firefox ricompilata con la patch sistemata).
- **Informazioni su Firefox** mostra le funzioni della patch incluse in questa versione, e quelle mancanti.
- Le Release vecchie, senza il campo `missingFeatures`, vengono trattate come complete.

---

## 1. Nuova scheda con la barra degli indirizzi attiva

**Upstream:** il "+" della tab strip seleziona la barra solo con certe combinazioni di impostazioni («homepage come
nuova scheda», «ricerche di tendenza»), quindi spesso non succede.

**Cosa fa:**

- il **"+" della tab strip** (dalla home e dalle pagine) e **Ctrl+T** aprono sempre la nuova scheda con la barra
  degli indirizzi già selezionata, pronta per scrivere un indirizzo o una ricerca;
- con la tastiera fisica collegata, la tastiera a schermo non compare; toccando "+" col dito, sì;
- mentre la barra è attiva si vede il pannello dei suggerimenti al posto della home (come upstream quando si tocca
  la barra);
- in navigazione privata la nuova scheda è privata.

**Fatto:** il "+" della tab strip, con il punto di aggancio `PatchFeatureHooks.openNewTab` della `0002`. Ctrl+T arriva
con le scorciatoie (punto 2) e passerà dallo stesso punto di aggancio, così senza questa patch apre la nuova scheda
come Firefox.

---

## 2. Scorciatoie da tastiera fisica

**Upstream:** nessuna scorciatoia Ctrl, solo il tasto Menu e i tasti Avanti/Indietro.

**Come:** i tasti si intercettano in `HomeActivity.dispatchKeyEvent`, che li riceve **prima della pagina web**:
Ctrl+T e Ctrl+W funzionano anche mentre si scrive in un sito, come in Chrome. Si intercettano solo combinazioni con
Ctrl o Alt (più F5, F6, F10), mai i tasti semplici. Le scorciatoie compaiono anche nella schermata di aiuto di
Android (Meta+/, Android 14 e successivi). Valgono anche a telefono chiuso, tranne quelle legate a funzioni solo
per schermo grande.

| Tasti                                   | Azione                                                                   |
|-----------------------------------------|--------------------------------------------------------------------------|
| Ctrl+T                                  | nuova scheda con la barra attiva (privata se sei in navigazione privata) |
| Ctrl+W                                  | chiude la scheda; sull'ultima scheda va alla home                        |
| Ctrl+Shift+T                            | riapre l'ultima scheda chiusa                                            |
| Ctrl+Tab / Ctrl+Shift+Tab               | scheda successiva / precedente, in ordine di tab strip, ciclico; salta le schede dei gruppi chiusi |
| Ctrl+PagGiù / Ctrl+PagSu                | come Ctrl+Tab / Ctrl+Shift+Tab                                           |
| Ctrl+1 … Ctrl+8, Ctrl+9                 | va alla scheda N; Ctrl+9 all'ultima                                      |
| Ctrl+L, Alt+D, F6                       | seleziona la barra degli indirizzi                                       |
| Ctrl+R, F5                              | ricarica                                                                 |
| Ctrl+Shift+R, Ctrl+F5                   | ricarica ignorando la cache                                              |
| Alt+← / Alt+→                           | indietro / avanti                                                        |
| Ctrl+F                                  | trova nella pagina                                                       |
| Ctrl+D                                  | aggiunge ai segnalibri                                                   |
| Ctrl + / Ctrl = , Ctrl −, Ctrl+0        | zoom avanti, indietro, ripristina (solo schermo grande, funzione 4)      |
| Ctrl+Shift+B                            | mostra/nasconde la barra dei segnalibri cambiando l'impostazione (solo schermo grande, funzione 5) |
| Alt (premuto e rilasciato da solo), F10 | apre il menu ⋮                                                           |
| Ctrl+Q                                  | chiude Firefox **senza conferma**; le schede restano per la prossima apertura |

Limite noto: i siti che usano le stesse combinazioni (ad es. Ctrl+F in un editor online) non le ricevono, perché
Firefox le prende prima. Se dà fastidio, in seguito si possono lasciare alla pagina le scorciatoie non essenziali.

**Fatto**, con i punti di aggancio `PatchFeatureHooks.onKeyEvent` e `keyboardShortcuts` della `0002`. Da completare
con le altre funzioni, ognuna nella propria patch: Ctrl + / − / 0 con lo zoom (4), Ctrl+Shift+B con la barra dei
segnalibri (5), Ctrl+Tab che salta le schede dei gruppi chiusi con i gruppi (8).

---

## 3. Menu ⋮ a tendina

**Upstream:** il menu è sempre un pannello che sale dal basso, anche sul Fold aperto.

**Cosa fa:**

- a schermo grande lo stesso contenuto compare in una **tendina ancorata al pulsante ⋮**, come in Chrome per
  tablet, sia sulle pagine sia nella home;
- con la barra degli indirizzi in basso, la tendina si apre verso l'alto;
- i sottomenu (Estensioni, Strumenti, Salva…) si aprono dentro la stessa tendina, come upstream;
- altezza massima pari alla finestra meno un margine, con scorrimento; si chiude toccando fuori o con Esc;
- con la tastiera: frecce, Invio, Esc; Alt o F10 la aprono;
- a schermo piccolo resta il pannello dal basso.

**Come:** si riusa il contenuto del menu di upstream e si cambia solo il "contenitore", così le novità che Mozilla
aggiunge al menu arrivano anche nella tendina.

**Fatto**, con il punto di aggancio `PatchFeatureHooks.menuDialog` della `0002`. La posizione è calcolata dalle
altezze di tab strip e barra degli indirizzi (il pulsante ⋮ è all'estremità della barra), non letta dal pulsante.
Con la tastiera si naviga con Tab e frecce, come nel resto di Firefox.

---

## 4. Zoom della pagina come su desktop

**Upstream:** solo dimensione del testo (globale, solo testo) e zoom con le dita (ingrandisce senza riorganizzare
la pagina). Il motore (GeckoView) non offre lo zoom pagina del desktop e, dato che la build scarica Gecko già
compilato, non possiamo aggiungerlo lì.

**Come:** un'estensione interna, inclusa nell'APK e invisibile, che applica alla pagina la proprietà CSS `zoom`: la
pagina si ridimensiona e si riorganizza come col zoom del desktop. L'app decide lo zoom di ogni scheda e lo comunica
all'estensione.

**Cosa fa (solo a schermo grande):**

- **zoom predefinito** in Impostazioni → Personalizza (con l'indicazione "solo schermo grande");
- **zoom per sito**, ricordato per dominio, come su desktop; nelle schede private non viene salvato;
- livelli come su desktop: 30, 50, 67, 80, 90, 100, 110, 120, 133, 150, 170, 200, 240, 300%;
- nel menu ⋮ una riga **Zoom `− 110% +`**;
- Ctrl + / − / 0 (funzione 2);
- quando lo zoom del sito è diverso da quello predefinito, la barra degli indirizzi mostra la percentuale; toccarla
  riporta allo zoom predefinito;
- piegando il telefono la pagina torna al 100%, riaprendolo torna lo zoom scelto, al volo;
- un pulsante per azzerare tutti gli zoom per sito.

Non vale per: visualizzatore PDF (ha il suo zoom), modalità lettura, pagine interne di Firefox. Limite noto: su
qualche sito particolare (editor, mappe) lo zoom CSS può dare piccoli difetti; si risolve rimettendo quel sito al
100%.

**Fatto**, con i punti di aggancio `onActivityCreated`, `MainMenuItems` e `addCustomizationPreferences` della
`0002`. Differenza dal piano: **niente percentuale nella barra degli indirizzi**, perché richiederebbe di modificare
a fondo la costruzione della toolbar di Firefox (il codice che upstream cambia più spesso). Al suo posto: la
percentuale è sempre nella riga Zoom del menu (toccandola si torna allo zoom predefinito) e Ctrl + / − / 0 mostrano
per un attimo il nuovo zoom.

---

## 5. Barra dei segnalibri

**Upstream:** non esiste. Esiste però la cartella **«Barra dei segnalibri»** di Firefox desktop, sincronizzata con
Sync: la barra mostra quella, quindi è la stessa del PC.

**Cosa fa (solo a schermo grande):**

- una riga accanto alla barra degli indirizzi (sotto, se la barra è in alto; sopra, se è in basso), **sia sulle
  pagine sia nella home**;
- quando la barra degli indirizzi si nasconde scorrendo la pagina, si nasconde anche la barra dei segnalibri;
- ogni segnalibro: icona del sito + titolo accorciato; le cartelle si aprono a tendina (anche annidate);
- i segnalibri che non ci stanno finiscono in un pulsante **»** a tendina, come su desktop;
- tocco: apre nella scheda corrente; Ctrl+tocco o clic centrale: apre in una nuova scheda in background;
- pressione lunga / tasto destro: Apri in nuova scheda, Apri in scheda privata, Modifica, Elimina;
- si aggiorna da sola quando i segnalibri cambiano (anche da Sync);
- cartella vuota o Sync non usato: messaggio «Aggiungi segnalibri alla cartella "Barra dei segnalibri" per vederli
  qui»;
- interruttore in Impostazioni → Personalizza; Ctrl+Shift+B lo cambia.

Salvataggio: Ctrl+D e la stellina salvano in «Segnalibri mobile» come upstream; con **Modifica** si sceglie la
cartella «Barra dei segnalibri» (già possibile upstream).

**Fatto**, con i nuovi punti di aggancio `AddressBarRow` e `addressBarRowHeight` della `0002` (la riga accanto alla
barra degli indirizzi e lo spazio che le pagine le lasciano). In più rispetto al piano: i separatori della cartella
compaiono come righe verticali (e come linee nei menu). Il menu con la pressione lunga c'è per i segnalibri della
barra, non per quelli dentro i menu delle cartelle né per le cartelle; la barra è visibile anche mentre si scrive
nella barra degli indirizzi (ad es. nella nuova scheda), come sul desktop.

---

## 6. Mouse e trackpad

- clic centrale su una scheda: la chiude;
- tasto destro su una scheda: apre il menu contestuale della scheda (lo stesso della pressione lunga);
- rotella del mouse / scorrimento verticale col trackpad sulla tab strip: scorre le schede in orizzontale;
- passando sopra una scheda: suggerimento con il titolo completo, e schede e pulsante di chiusura evidenziati;
- sulla barra dei segnalibri: clic centrale o Ctrl+clic aprono in una nuova scheda in background, tasto destro apre
  il menu del segnalibro.

**Fatto**, con i nuovi punti di aggancio `TabStripTab` e `tabStripModifier` della `0002`. La barra dei segnalibri
gestisce il mouse da sé, nella `0050`. L'evidenziazione sotto il mouse c'era già in Firefox; il suggerimento mostra
anche il sito della scheda, come in Chrome.

---

## 7. Icona audio sulle schede

- una scheda che sta riproducendo audio mostra un **altoparlante** accanto al titolo; se è silenziata, un
  altoparlante barrato;
- toccare l'icona silenzia o riattiva l'audio della scheda;
- nel menu contestuale della scheda: «Disattiva audio della scheda» / «Riattiva audio della scheda»;
- sulle schede strette, l'icona audio ha la precedenza sul titolo.

**Come:** con lo stato "media session" che Firefox tiene già per ogni scheda (riproduzione in corso, silenziata).
Limite noto: i siti che producono suoni senza un elemento audio/video (alcuni giochi) potrebbero non mostrare
l'icona.

**Fatto**, con il nuovo punto di aggancio `TabStripTabIcons` della `0002` (e `tabStripMenuItems` per il menu). La voce
del menu compare solo per le schede con audio o video, le sole che si possono silenziare.

---

## 8. Gruppi di schede nella tab strip

**Upstream:** i gruppi esistono già (archivio dati, colori, creazione e modifica), si vedono solo nella panoramica
delle schede e si attivano da Impostazioni → Schede → Gruppi di schede; il valore predefinito lo decide Mozilla da
remoto. È la parte di upstream che cambia più spesso, quindi è la patch più fragile: per questo è l'ultima e
facoltativa.

**Cosa fa (versione "media"):**

- gruppi **attivi per impostazione predefinita** (restano disattivabili da Impostazioni → Schede);
- nella tab strip, prima delle schede di un gruppo, un'**etichetta colorata** col nome del gruppo (o solo un pallino
  colorato se il gruppo non ha nome); le schede del gruppo hanno una linea del colore del gruppo e stanno sempre
  vicine;
- toccando l'etichetta il gruppo **si chiude o si riapre**; se si chiude un gruppo che contiene la scheda attiva, si
  passa alla scheda più vicina fuori dal gruppo (se non ce ne sono, il gruppo non si chiude);
- menu contestuale della scheda: **Aggiungi a nuovo gruppo**, **Aggiungi al gruppo ▸** (elenco dei gruppi),
  **Rimuovi dal gruppo**; aggiungendo una scheda a un gruppo, la scheda si sposta accanto alle altre del gruppo;
- pressione lunga (o tasto destro) sull'etichetta: **Modifica** nome e colore (con la schermata di upstream),
  **Separa il gruppo**, **Chiudi il gruppo** (chiude le sue schede);
- i gruppi creati nella panoramica delle schede compaiono nella strip e viceversa;
- Ctrl+Tab salta le schede dei gruppi chiusi.

Non in questa versione: trascinare una scheda dentro o fuori da un gruppo nella strip; nuove schede aperte da una
scheda del gruppo che entrano automaticamente nel gruppo. Da verificare: come upstream gestisce le schede private
nei gruppi.

**Fatto**, con i nuovi punti di aggancio `tabStripEntries` e `isTabHidden` della `0002` (e `TabStripTab`,
`tabStripMenuItems`). Differenze dal piano:

- nel menu della scheda c'è una sola voce, **Aggiungi la scheda a un gruppo**, che apre la scelta del gruppo di
  Firefox (elenco dei gruppi e creazione di uno nuovo) invece di «Aggiungi a nuovo gruppo» e «Aggiungi al gruppo ▸»;
- **Chiudi il gruppo** lo chiude come la panoramica delle schede di Firefox: il gruppo e le sue schede spariscono
  dalla tab strip e si riaprono dalla panoramica (non chiude le schede, così non si perde nulla);
- chiudere/riaprire il gruppo dall'etichetta è solo della tab strip (ricordato tra un avvio e l'altro); un gruppo
  chiuso così mostra quante schede ha;
- le schede private non hanno gruppi, come upstream; trascinando una scheda fuori dal suo gruppo, torna vicino alle
  altre del gruppo.

---

## Per ogni funzione

- test automatici come quelli della patch attuale;
- testi in italiano e in inglese;
- sezione nel README (che diventa la descrizione ufficiale) e aggiornamento di questa tabella;
- prova sul Fold, aperto e chiuso, con e senza tastiera e mouse, con barra degli indirizzi in alto e in basso.

---

# Fase 2: cosa manca rispetto a Firefox per computer

Confronto fatto sul sorgente di Firefox 160 (`FIREFOX-ANDROID_160_0_RELEASE`) e sui dati di compatibilità di MDN del
12 novembre 2026. **Verificato** vuol dire letto nel sorgente; **da provare** vuol dire plausibile, ma va provato sul
telefono prima di contarci. Niente di questa fase è ancora stato scritto.

## In breve

- Il **motore è lo stesso** di Firefox per computer (Gecko 160): HTML, CSS e JavaScript sono praticamente identici.
  Le differenze vere sono una ventina di API (elenco sotto).
- Mancano soprattutto **pezzi di interfaccia** da computer (finestre, menu col tasto destro, strumenti per
  sviluppatori, barra laterale) e buona parte delle **API per le estensioni**.
- Tre cose verificate nel sorgente rendono fattibile molto più del previsto **senza compilare Gecko**:
  1. `about:config` nella versione stabile è solo spento: una riga in `GeckoProvider.kt`
     (`aboutConfigEnabled(Config.channel.isBeta || ...)`);
  2. l'app può leggere e cambiare qualsiasi preferenza del motore (`GeckoPreferenceController`, in Fenix
     `BrowserPreferencesRuntime.setBrowserPref`);
  3. un'estensione interna dell'APK è «privilegiata»: può portare con sé codice che gira **dentro il motore**
     (`experiment_apis`, come fa l'estensione interna di Mozilla `webcompat-reporter`). Da lì si raggiungono, ad
     esempio, lo zoom vero delle pagine (`BrowsingContext.fullZoom`), la piattaforma dichiarata ai siti
     (`customPlatform`) e gli eventi touch (`touchEventsOverride`). La patch dello zoom (`0040`) installa già
     un'estensione interna, ma senza questa parte.

## Elenco di ciò che manca

🟢 patch piccola, come quelle già fatte · 🟡 fattibile ma grande, fragile o da provare · 🔴 non fattibile da qui
(serve Mozilla, bisogna compilare Gecko, lo impedisce Android, o vorrebbe dire riscrivere l'app)

### Finestre e schede

| Manca                                                              |    | Note |
|--------------------------------------------------------------------|----|------|
| Più finestre (Ctrl+N, trascinare una scheda fuori, finestra privata, «Mini Window» di Firefox 160) | 🔴 | Verificato: `HomeActivity` è `singleTask`, un solo elenco di schede. Già scartato |
| Vista affiancata: due schede una accanto all'altra (Firefox 149)   | 🟡 | Grande: Firefox per Android mostra una sola pagina alla volta |
| Schede fissate                                                     | 🟡 | Rimandato nella fase 1. Media: l'elenco delle fissate lo tiene la patch |
| Anteprima della pagina passando il mouse su una scheda             | 🟢 | Le miniature esistono già (panoramica delle schede) |
| Menu della scheda completo: Duplica, Chiudi le schede a destra, Aggiungi ai segnalibri, Invia a dispositivo, Riapri scheda chiusa | 🟢 | Si aggiungono al menu della `0002` |
| Selezione di più schede nella tab strip (Ctrl+clic, Shift+clic)     | 🟡 | Media. Nella panoramica delle schede c'è già |
| Trascinare una scheda dentro/fuori da un gruppo, o un link sulla tab strip | 🟡 | Media |
| Barra laterale (segnalibri, cronologia, schede di altri dispositivi) e schede verticali | 🟡 | Grande |
| Contenitori (Multi-Account Containers)                             | 🟡 | Grande. Il motore li supporta (`contextId`) e c'è un componente inutilizzato (`feature-containers`), ma manca tutta l'interfaccia |
| Profili                                                            | 🔴 | Un'app Android ha un solo profilo. Ripiego: la variante `nightly` installata accanto |

### Tastiera

Scorciatoie di Firefox per computer che la `0020` non ha ancora (tutte 🟢): Ctrl+Shift+P (scheda privata), Ctrl+H
(cronologia), Ctrl+J (download), Ctrl+Shift+O (segnalibri), Ctrl+P (stampa), Ctrl+S (salva come PDF), Ctrl+U
(sorgente della pagina), F11 (schermo intero), F3 / Ctrl+G / Shift+F3 (trova successivo/precedente), Esc (ferma il
caricamento), Ctrl+Shift+Canc (cancella dati), Ctrl+Shift+A (estensioni), Ctrl+K (cerca), Alt+Invio (apre l'indirizzo
in una nuova scheda), Ctrl+Invio (aggiunge www. e .com), Ctrl+Shift+PagSu/PagGiù (sposta la scheda), Ctrl+M
(silenzia la scheda), Alt+Home (pagina iniziale).

Non fattibile: F12 (strumenti per sviluppatori, vedi sotto). Da provare con le preferenze: F7 (navigazione con
cursore) e la ricerca rapida con `/` (verificato: `accessibility.typeaheadfind` è `false` su Android).

### Mouse sulle pagine

| Manca                                                              |    | Note |
|--------------------------------------------------------------------|----|------|
| Menu col tasto destro completo (sfondo della pagina, testo, campi: Indietro, Ricarica, Seleziona tutto, Copia/Incolla, Sorgente…) | 🟡 | Verificato: il motore avvisa l'app solo per link, immagini e video. Serve l'estensione interna |
| Indirizzo del link in basso mentre il mouse ci passa sopra         | 🟡 | Serve l'estensione interna |
| Ctrl+rotella per lo zoom                                           | 🟢 | Serve un punto di aggancio in più nella `0002` per la rotella |
| Barre di scorrimento da trascinare col mouse                       | 🟡 | Verificato: `apz.drag.enabled` è `false` su Android. Da provare con le preferenze |
| Scorrimento automatico col clic centrale                           | 🟡 | È fatto dall'interfaccia di Firefox per computer: andrebbe riscritto. Poco utile |
| Clic centrale / Ctrl+clic su un link → nuova scheda in background   | ?  | Il motore lo gestisce (`OPEN_NEWTAB_BACKGROUND`); da provare cosa fa l'app |

### Barra degli indirizzi e ricerca nella pagina

| Manca                                                              |    | Note |
|--------------------------------------------------------------------|----|------|
| Trova nella pagina: maiuscole/minuscole, parole intere, evidenzia tutto | 🟡 | Verificato: il motore li ha (`FINDER_FIND_MATCH_CASE`…), i componenti Android passano solo avanti/indietro |
| Percentuale di zoom nella barra                                    | 🟡 | Limite noto della `0040` |
| Parole chiave dei segnalibri, calcolatrice e conversioni nella barra | 🔴 | Poco utili; la barra è il codice che Mozilla cambia più spesso |

### Strumenti

| Manca                                                              |    | Note |
|--------------------------------------------------------------------|----|------|
| `about:config`                                                     | 🟢 | Verificato: spento solo nella versione stabile |
| Strumenti per sviluppatori (F12: ispettore, console, rete)         | 🔴 | Verificato: nell'APK c'è solo la parte «server» (`MOZ_DEVTOOLS=server`). Resta il debug da un PC via USB |
| Sorgente della pagina (Ctrl+U)                                     | 🟢 | Da provare: aprire `view-source:` in una nuova scheda |
| Schermata di tutta la pagina                                       | 🟡 | Con l'estensione interna (`drawSnapshot`) |
| Salva pagina completa (HTML)                                       | 🔴 | C'è solo «Salva come PDF» |
| Video in finestrella (Picture-in-Picture) per qualsiasi video, con i controlli | 🔴 | Android lo dà solo ai video a schermo intero |
| Controllo ortografico nei campi di testo                           | 🟡 | Verificato: `layout.spellcheckDefault` è `0`. Da provare: servono anche i dizionari |
| Proxy manuale, impostazioni di rete avanzate                       | 🟢 | Nessuna schermata, ma con `about:config` si possono impostare (`network.proxy.*`) |
| Esportare le password, importare da altri browser                  | 🟡 | Verificato: l'importazione dei segnalibri da file esiste ma è spenta (`importBookmarksFeatureFlagEnabled`) |
| Password principale, gestione certificati, criteri aziendali, temi, `userChrome.css`, personalizzazione libera della barra | 🔴 | Non esistono su Android |
| VPN integrata, chatbot nella barra laterale, anteprime dei link, note delle schede | 🔴 | Novità recenti del solo Firefox per computer, legate ai servizi di Mozilla |

### Estensioni

Verificato (`ext-android.json`): su Android ci sono solo `browserAction`, `pageAction`, `tabs`, `browsingData` più le
API comuni (`webRequest`, `storage`, `scripting`, `cookies`, `declarativeNetRequest`, `notifications`, `proxy`…).

Mancano (🔴, stanno nel motore già compilato): `menus`/`contextMenus` (voci nel menu col tasto destro), `commands`
(scorciatoie delle estensioni), `sidebarAction`, `windows`, `bookmarks`, `history`, `sessions`, `tabGroups`,
`devtools`, `omnibox`, `search`, `find`, `topSites`, `theme`, `identity`, i contenitori e la sostituzione della pagina
Nuova scheda. Le estensioni che ne dipendono non funzionano o perdono quelle parti.

### Compatibilità con i siti

Presenti in Firefox 160 per computer e assenti su Android (dati MDN):

| Manca                                                              |    | Note |
|--------------------------------------------------------------------|----|------|
| Condivisione dello schermo (`getDisplayMedia`, videochiamate)      | 🟡 | Verificato: spenta da una preferenza (`media.getdisplaymedia.enabled`). Da provare |
| WebCodecs (editor video, alcune videochiamate)                     | 🟡 | Verificato: su Android accesa solo in Nightly (`dom.media.webcodecs.enabled`). Da provare |
| WebGPU                                                             | 🟡 | Verificato: spenta (`dom.webgpu.enabled`). Da provare, dipende dalla scheda grafica |
| Web MIDI                                                           | 🟡 | Verificato: spenta da una preferenza (`dom.webmidi.enabled`). Da provare |
| Web Serial, scelta dell'uscita audio (`setSinkId`)                 | 🔴 | Per l'uscita audio MDN indica un limite di Android |
| Picture-in-Picture chiesto dal sito, riconoscimento vocale del sito (novità 153 e 160) | 🔴 | |
| Ridimensionare le caselle di testo (`resize`), tacche dei cursori (`<input type=range list>`) | 🔴 | Dettagli |

Come ci vedono i siti con «sito desktop» (verificato): lo user agent diventa «X11; Linux x86_64» e la pagina è
disposta su una larghezza di 980 px (`browser.viewport.desktopWidth`). Restano però gli eventi touch e
`navigator.platform` non viene cambiato, quindi qualche sito capisce lo stesso che è un telefono (versione tablet,
«scarica l'app»). 🟡 con l'estensione interna si può dichiarare un PC vero, anche solo per i siti che lo richiedono.

### Prestazioni

| Differenza                                                         |    | Note |
|--------------------------------------------------------------------|----|------|
| Isolamento dei siti (ogni sito nel suo processo)                   | 🟡 | Verificato: su computer isola tutto; qui il valore predefinito della versione stabile è non isolare niente (`isolationStrategy: 0`), in Nightly solo i siti importanti (`2`); Mozilla può cambiarlo da remoto. È un'impostazione dell'app in `Core.kt`. Più sicurezza, più memoria: da provare |
| Schede in background                                               | 🔴 | Android ferma Firefox quando non è in primo piano e chiude i processi se serve memoria: le schede si ricaricano. Può aiutare togliere a Firefox l'ottimizzazione della batteria |
| Velocità del motore                                                | —  | Stesso motore, stesse ottimizzazioni: dipende dal processore |

## Ordine proposto

**A. Piccole, con la tecnica di oggi**

| Passo | Cosa                                                        | Dove |
|-------|-------------------------------------------------------------|------|
| A1    | `about:config` attivo                                       | nuova patch facoltativa + aggancio nella `0002` |
| A2    | Le scorciatoie mancanti                                     | `0020` |
| A3    | Menu della scheda completo                                  | `0002` |
| A4    | Ctrl+rotella per lo zoom                                    | `0040` + aggancio nella `0002` |
| A5    | Anteprima della scheda sotto il mouse                       | `0060` |
| A6    | Schede fissate                                              | nuova patch facoltativa |

**B. Estensione interna privilegiata** (un'infrastruttura nuova, poi una patch per funzione)

| Passo | Cosa                                                        |
|-------|-------------------------------------------------------------|
| B0    | Prova: un'estensione interna con una sola funzione dentro il motore. Se non funziona, la fase B cade |
| B1    | Zoom vero al posto dello zoom CSS (dovrebbe valere anche per PDF e pagine interne) |
| B2    | Menu col tasto destro completo                              |
| B3    | Trova nella pagina con le opzioni                           |
| B4    | Indirizzo del link sotto il mouse                           |
| B5    | Dichiararsi un PC vero ai siti, per sito                    |
| B6    | Sorgente della pagina, schermata di tutta la pagina         |

**C. «Laboratorio»**: una schermata in Impostazioni con gli interruttori del motore da provare (isolamento dei siti,
WebCodecs, WebGPU, condivisione dello schermo, barre di scorrimento trascinabili, controllo ortografico, ricerca
rapida). Con A1 si provano prima a mano in `about:config`: nel Laboratorio entrano solo quelli che funzionano.

**D. Grandi, uno alla volta e solo se servono**: vista affiancata, barra laterale, contenitori. Più finestre resta
scartato.

Rischio della fase B: il codice dentro il motore usa parti interne di Gecko, che possono cambiare tra una versione e
l'altra. Per questo ogni funzione resta in una patch facoltativa.
