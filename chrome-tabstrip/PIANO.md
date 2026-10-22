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
| 7  | Icona audio sulle schede                          | `0070-tab-audio`             | facoltativa | da fare      |
| 8  | Gruppi di schede nella tab strip                  | `0080-tab-groups`            | facoltativa | da fare      |

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

- **Obbligatorie**: la `0001` attuale (tab strip, siti desktop/mobile, status bar, aggiornamenti dall'app) e una
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

---

## Per ogni funzione

- test automatici come quelli della patch attuale;
- testi in italiano e in inglese;
- sezione nel README (che diventa la descrizione ufficiale) e aggiornamento di questa tabella;
- prova sul Fold, aperto e chiuso, con e senza tastiera e mouse, con barra degli indirizzi in alto e in basso.
