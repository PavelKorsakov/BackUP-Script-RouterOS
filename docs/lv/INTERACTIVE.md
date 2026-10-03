# Interaktīvā saskarne

[Atpakaļ uz pārskatu](../README_LV.md)

## Galvenā izvēlne

Galvenajā izvēlnē var konfigurēt skriptu, veidot rezerves kopijas, sagatavot ierīču sarakstu vai atvērt iebūvēto palīdzību. Lai to atvērtu, izpildiet:

```bash
mikrotik-backup.sh -i
```

| Punkts | Darbība |
|---|---|
| `1` | BackUP Master darbam ar vienu ierīci |
| `2` | Pakešveida rezerves kopija no ierīču saraksta |
| `3` | Konfigurācijas redaktors `option.cfg` izveidošanai vai mainīšanai |
| `4` | CLI opciju atsauce |
| `5` | Skripta lietošanas pamācība |
| `6` | Iziet uz konsoli |

Punkts `2` tiek rādīts, ja `devicelist.cfg` satur vismaz vienu derīgu ierakstu. Ja saraksta vēl nav vai tajā nav piemērotu ierīču, šis punkts ir paslēpts. Pārējo punktu numuri nemainās.

Pēc pakešizpildes tiek parādīts rezultāts, un skripts atgriežas konsolē.

*(Piezīme. Skripta palaišana bez opcijām neatver galveno izvēlni. Ja `option.cfg` trūkst vai tajā nav izmantojamu iestatījumu, tiek atvērts konfigurācijas redaktors; ar sagatavotiem iestatījumiem skripts sāk pakešapstrādi.)*

<br />

## Vadība

Pārvietojieties ar bulttaustiņiem **Uz augšu** un **Uz leju**, bet izvēli apstipriniet ar **Enter**. Ja darbībai blakus ir skaitlis, to var izvēlēties arī ar atbilstošo cipara taustiņu.

Redaktorā un Master virs saraksta tiek rādīts izvēlētā lauka apraksts. Ja visas rindas neietilpst termināļa logā, saraksts ritina līdzi navigācijai. Virsraksts un apraksts paliek redzami, un izvēlētā rinda paliek logā.

Saglabāšanas, izpildes un iziešanas darbības atrodas tā paša saraksta beigās. Aptumšotās rindas ar pašreizējiem iestatījumiem nav pieejamas un navigācijas laikā tiek izlaistas.

Vajadzīgs terminālis un utilītprogramma `stty`; gan standarta ievadei, gan izvadei jābūt pieslēgtai terminālim. Galvenajiem ekrāniem nepieciešams vismaz 46 kolonnu platums, iebūvētajām pamācībām — 80. Ja logs ir par mazu, skripts ziņo kļūdu `31`; palieliniet logu un palaidiet vēlreiz.

<br />

## Konfigurācijas redaktors

Atveriet redaktoru ar punktu `3` galvenajā izvēlnē vai tieši:

```bash
mikrotik-backup.sh -e
```

Ja `option.cfg` jau ir sagatavots, veidlapa tiek aizpildīta ar jūsu iestatījumiem. Ja faila vēl nav, tiek izmantotas noklusējuma vērtības.

Redaktorā var izvēlēties valodu, ierīču saraksta avotu, rezerves kopiju iestatījumus, krātuvi, ikmēneša arhivēšanu un žurnalēšanu. Iestatījumi un pieņemtās vērtības aprakstītas [OPTIONS.md](OPTIONS.md).

### Iestatījumu mainīšana

Jā/nē slēdžus, rezerves kopijas tipu, eksporta formātu un žurnāla līmeni mainiet, attiecīgajā rindā nospiežot **Enter**. Izvēloties ceļu vai ikmēneša arhivēšanas dienu, tiek atvērts vērtības ievades lauks.

Lauks **Izmantot inkrementālo salīdzināšanu** (`UseIncremental`) atrodas uzreiz pēc dublējuma tipa. **Jā** iespējo salīdzināšanu; **Nē** patur katru jaunu derīgu dublējumu bez salīdzināšanas ar iepriekšējo.

Ikmēneša arhivēšanai ievadiet `false`, lai to atspējotu, vai skaitli no `1` līdz `28`. Veidlapa atspējotu stāvokli rāda kā „Nē“, bet iespējotu — kā izvēlēto mēneša dienu.

Lauki, kas izvēlētajā režīmā nav piemērojami, tiek aptumšoti. Ja izvēlēts tikai `.rsc`, nav pieejama binārās rezerves kopijas šifrēšana un pirms tās veicamās tīrīšanas darbības; ja izvēlēts tikai `.backup`, nav pieejami teksta eksporta iestatījumi. Pārslēdzot režīmus, nepiemērojamie iestatījumi tiek atjaunoti uz noklusējuma vērtībām.

Šifrēšanas parole tiek rādīta kā zvaigznītes.

### Saglabāšana un atcelšana

Izvēlieties vajadzīgos iestatījumus → pārejiet uz **Saglabāt** → nospiediet **Enter**. Izvēlētie iestatījumi tiek izmantoti, lai izveidotu vai pārrakstītu `option.cfg`.

Līdz saglabāšanai izmaiņas pastāv tikai atmiņā. **Atcelt** atstāj esošo failu nemainītu. Ja kaut kas ir mainīts, redaktors lūdz apstiprināt izmaiņu atmešanu.

No galvenās izvēlnes atvērts redaktors atgriežas tajā. Ja redaktors palaists atsevišķi ar `-e`, aizvēršana atgriež konsolē.

*(Piezīme. `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` un `Password` veidlapā netiek rādīti. To iestatījumi un saglabāšanas noteikumi aprakstīti [OPTIONS.md](OPTIONS.md).)*

### Valodas izvēle

Valodas rindā katrs **Enter** spiediens izvēlas nākamo iespēju:

```text
auto → ru → en → atrastās ārējās valodas alfabētiskā secībā → auto
```

Veidlapas valoda mainās uzreiz, lai varētu redzēt priekšskatījumu. **Saglabāt** ieraksta izvēlēto valodu `option.cfg`; **Atcelt** atjauno iepriekšējo saskarnes valodu. Ja palaišanas laikā tieši norādīts `--language`, pēc iziešanas no redaktora atkal darbojas šī komandrindas opcija.

Ārējo tulkojumu pievienošana aprakstīta [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master ļauj aizpildīt vienas ierīces datus un iestatījumus, izveidot tās rezerves kopijas, saglabāt ierīci sarakstā vai sagatavot komandu izpildei konsolē.

Izvēlieties punktu `1` galvenajā izvēlnē vai izpildiet:

```bash
mikrotik-backup.sh -b
```

Atšķirībā no konfigurācijas redaktora Master parastos laukus neaizpilda no `option.cfg`. To vērtības nāk no iebūvētajiem noklusējumiem un skaidri nodotām CLI opcijām. `UseIncremental` ir izņēmums: tā vērtība tiek ņemta no opciju faila vai, ja iestatījuma nav, ir `true`.

Arī esošie `devicelist.cfg` ieraksti veidlapā netiek ielādēti. Izvēlētās ierīces nosaukumu, adresi, lietotājvārdu un paroli ievadāt pats.

### BackUP Master lauki

Lauki ir šādā secībā:

| Lauks | Nozīme |
|---|---|
| Ierīces nosaukums | Nosaukums ierīču sarakstam un rezerves kopijām, ja RouterOS Identity iegūšana ir atspējota |
| IP adrese | Ierīces IP adrese vai DNS nosaukums |
| Lietotājs | RouterOS ierīces lietotājvārds |
| Parole | RouterOS lietotāja parole |
| SSH ports | Savienojuma ports; pēc noklusējuma `22` |
| Rezerves kopijas tips | `.rsc` konfigurācija, binārs `.backup` vai abi formāti |
| Izmantot inkrementālo salīdzināšanu | Salīdzināt jauno rezerves kopiju ar iepriekšējo vai paturēt to bez salīdzināšanas |
| Eksporta formāts | `compact`, `terse` vai `verbose` |
| Sensitīvie dati | Iekļaut sensitīvās vērtības teksta eksportā |
| Šifrēšanas parole | Šifrēt bināro rezerves kopiju; tukša vērtība šifrēšanu atspējo |
| Tīrīt DNS kešatmiņu | Pirms binārā dublējuma notīrīt DNS kešatmiņu |
| Tīrīt konsoles vēsturi | Pirms binārā dublējuma notīrīt konsoles vēsturi |
| Dublējumu direktorijs | Direktorijs, kurā saglabāt failus |
| Šis ir tīkla direktorijs | `UseNetFolder` vērtība; montējuma pārbaude attiecas uz pakešapstrādi |
| Izmantot RouterOS Identity | Iegūt nosaukumu no ierīces, nevis izmantot veidlapā ievadīto |

Slēdžus, rezerves kopijas tipu un eksporta formātu maina ar **Enter**; pārējās vērtības ievada laukos. Abas paroles tiek maskētas ar zvaigznītēm.

**Lūdzu, ievērojiet!!!**
Sensitīvie dati teksta eksportā, DNS kešatmiņas tīrīšana un konsoles vēstures tīrīšana pirms binārās rezerves kopijas pēc noklusējuma ir iespējota. Pirms rezerves kopijas palaišanas izvēlieties vajadzīgos iestatījumus.

Master nav lauku `MonthlyArchive`, `LogLevel` vai `MainLogPath`. Ja rezerves kopija tiek palaista no Master, ikmēneša arhivēšana ir atspējota. Žurnalēšanas iestatījumi savukārt nāk no `option.cfg` un izpildei nodotajām CLI opcijām.

### 1. Izveidot rezerves kopiju

Ievadiet adresi, lietotājvārdu un paroli, pārbaudiet portu un rezerves kopijas iestatījumus → izvēlieties **1. Izveidot rezerves kopiju**.

Ja RouterOS Identity iegūšana ir iespējota, rezerves kopijas nosaukums tiek ņemts no ierīces. Ja tā ir atspējota, jāaizpilda lauks **Ierīces nosaukums**.

Sākas vienas ierīces izpilde. Pēc tās beigām tiek parādīts rezultāts un kods, un skripts atgriežas konsolē. Neatkarīgi no iznākuma tas neatgriežas Master veidlapā.

Failu atrašanās vietas un glabāšanas noteikumi aprakstīti [BACKUPS.md](BACKUPS.md), progresa ziņojumi — [LOGGING.md](LOGGING.md).

### 2. Saglabāt ierīci `devicelist.cfg`

Saglabāšanai nepieciešams ierīces nosaukums, adrese, lietotājvārds, parole un SSH ports. Kamēr nav aizpildīti visi obligātie lauki, attiecīgā darbība nav pieejama.

Master izveido failu, pievieno jaunu ierakstu vai atjaunina esošu ierakstu ar tādu pašu nosaukumu. Ja ieraksti konfliktē vai saglabāšana neizdodas, iepriekšējais saraksts paliek nemainīts. Pēc saglabāšanas veidlapa paliek atvērta.

**Failā `devicelist.cfg` tiek saglabāti tikai ierīces dati.** Veidlapas rezerves kopiju iestatījumi netiek ierakstīti `option.cfg`, un šī darbība nesāk rezerves kopijas veidošanu.

*(Piezīme. Ports `22` tiek saglabāts kā tukšs lauks. Vēlākā pakešizpildē šāds ieraksts izmanto `SshPort` no skripta iestatījumiem. Nestandarta ports tiek ierakstīts tieši.)*

Saraksta formāts un atjaunināšanas noteikumi aprakstīti [DEVICES.md](DEVICES.md).

### 3. Kopēt konsoles komandu

Master no aizpildītās veidlapas izveido palaišanas komandu un ievieto to starpliktuvē. Rezerves kopija netiek sākta; Master beidz darbu un atgriežas konsolē.

Šai funkcijai vajadzīgs GNU `base64` ar `--wrap=0` atbalstu un terminālis, kas atbalsta OSC 52. Ja izmantojat termināļa multipleksoru, arī tam komanda jāpārsūta. Ja starpliktuves pārsūtīšana netiek atbalstīta, komanda netiek izvadīta ekrānā atklātā tekstā.

Komandā var nebūt parametru, kas atbilst iebūvētajām vērtībām. Palaižot komandu vēlāk, joprojām darbojas `option.cfg` iestatījumi, tāpēc rezultāts var atšķirties no rezerves kopijas, kas palaista tieši no Master.

`UseIncremental` komandā netiek iekļauts, jo tam nav atsevišķas CLI opcijas. Palaižot nokopēto komandu, vērtība nāk no `option.cfg` vai noklusējuma iestatījuma.

*(Piezīme. Starpliktuvē ievietotā komanda satur paroles. Ņemiet to vērā, izmantojot starpliktuves vēsturi un ielīmējot komandu čaulā. Plašāk skatiet [SECURITY.md](SECURITY.md).)*

### 0. Atgriezties galvenajā izvēlnē

Rezultāts atkarīgs no Master atvēršanas veida:

| Atvēršanas veids | Atgriešanās vieta |
|---|---|
| No galvenās izvēlnes ar `-i` | Galvenā izvēlne |
| Kā atsevišķa izpilde ar `-b` | Konsole |

Nesaglabātās veidlapas vērtības tiek atmestas. Ieraksts, kas jau saglabāts `devicelist.cfg`, paliek failā.

<br />

## Palīdzība un pamācības

Galvenās izvēlnes punkts `4` atver komandrindas opciju atsauci, bet punkts `5` — īsu skripta lietošanas pamācību.

Ja teksts vertikāli neietilpst logā, tas tiek sadalīts lapās. Pārvietojieties ar **PageUp / PageDown**; ekrānā tiek rādīts pašreizējās lapas numurs.

Punkts `0` atgriež galvenajā izvēlnē, bet punkts `6` beidz skriptu. Darbību var izvēlēties ar bulttaustiņiem un **Enter** vai ar atbilstošo cipara taustiņu.

Tā pati CLI palīdzība ir pieejama tieši konsolē:

```bash
mikrotik-backup.sh -h
```
