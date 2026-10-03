# Problēmu novēršana

[Atpakaļ uz pārskatu](../README_LV.md)

## Kur sākt

Ja dublēšana netika sākta vai beidzās ar kļūdu, vispirms pārbaudiet žurnālus. `main.log` satur kopējos palaišanas posmus, bet informācija par konkrētas ierīces dublēšanu tiek ierakstīta tās atsevišķajā ierīces žurnālā.

Meklējiet ar `[ER]` un kļūdas kodu atzīmētus ierakstus. Kodi izskaidroti [zemāk](#result-codes), bet žurnālu atrašanās vietas — [LOGGING.md](LOGGING.md).

Izmantojiet šīs komandas, lai parādītu instalēto skripta versiju un opciju atsauci:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Lai atkārtotu jau konfigurētu pakešizpildi ar detalizētu izvadi:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

Otrā komanda rāda pabeigtās palaišanas rezultātu. Tā nemaina žurnalēšanas līmeni `option.cfg`.

<br />

## Skripts nesāk dublēšanu

### Dublēšanas vietā tika atvērts redaktors

Ja skripts tiek palaists bez opcijām, tas nozīmē, ka `option.cfg` nav pieejams skripta mapē vai arī tas nesatur izmantojamus iestatījumus. Tukšs fails, komentāri vieni paši vai nezināmi iestatījumi nemaina rezultātu.

Atveriet konfigurācijas redaktoru, izvēlieties nepieciešamos iestatījumus, saglabājiet failu un vēlreiz izpildiet skriptu:

```bash
mikrotik-backup.sh -e
```

Ierīces saglabāšana ar BackUP Master izveido `devicelist.cfg`, taču tā neaizstāj `option.cfg` sagatavošanu.

*(Piezīme. Ja šādu palaidi palaiž plānotājs, redaktors nevar atvērt un skripts iziet ar kodu `31`. Automātiskās palaišanas iestatījumi jāsagatavo iepriekš.)*

### Opciju līguma kļūda, kods 12

Pārbaudiet opciju nosaukumus, vērtības un darbību kombināciju. Iemesls var būt nezināma opcija, tukša vērtība, vienlaikus pieprasītas vairākas darbības vai nepilnīgi vienas ierīces savienojuma dati.

Vienas ierīces CLI izpildei vajadzīga adrese, lietotājvārds un parole. Trūkstošie savienojuma dati netiek papildināti no `option.cfg`.

Īsās savienojuma opcijas jālieto ar `=`: `-a=`, `-u=` un `-p=`. Ņemiet vērā, ka `-p` norāda paroli; SSH portam izmantojiet `--port`.

Visi pieņemtie risinājumi un piemēri ir uzskaitīti [CLI.md](CLI.md).

### Nevar nolasīt option.cfg, kods 21

Pārliecinieties, ka `option.cfg` ir parasts fails, ko lietotājs var nolasīt, darbinot skriptu. Ir atļauta arī lasāma simboliska saite uz šādu failu.

Trūkstošs fails un nelasāms fails ir dažādas situācijas. Ja fails pastāv, bet to nevar nolasīt, skripts neturpina noklusētos iestatījumus.

### Trūkstošā atkarība, kods 30

Pārbaudiet galvenās utilītas ar:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Pakešrežīmam ar `UseNetFolder=true` vajadzīgs arī `findmnt`. Ikmēneša arhivēšanas dienā ir vajadzīgi `zip`, `unzip` un GNU `mv`. Konsoles komandas kopēšanai no BackUP Master vajadzīgs GNU `base64` ar `--wrap=0` atbalstu.

**Nepietiek tikai ar instalētu utilītprogrammu.** Instalētajam OpenSSH jāatbalsta izmantotās opcijas un `scp -O`; GNU `timeout` jāatbalsta `--signal` un `--kill-after`.

Pilns atkarību saraksts un instalēšanas komandas atrodamas [INSTALL.md](INSTALL.md#dependencies).

### Izvēlne neatveras, kods 31

Izvēlnei, redaktoram un BackUP Master ir vajadzīgs terminālis un darbspējīga utilīta `stty`. Nedarbiniet tos konveijerā vai ar novirzītu standarta ievadi vai izvadi.

Ja ziņojumā norādīts, ka terminālis ir par mazu, palieliniet logu. Galvenajiem ekrāniem vajadzīgs vismaz 46 kolonnu platums, bet iebūvētajām instrukcijām — 80 kolonnu. Garie saraksti redaktorā un BackUP Master tiek ritināti ar bulttaustiņiem; visai veidlapai nav uzreiz jāietilpst ekrānā.

Saskarnes vadības ierīces ir aprakstītas [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Ierīces saraksts neielādējas

### Fails devicelist.cfg, kodi 22 un 23

Pārbaudiet faila atrašanās vietu un piekļuvi tai. `devicelist.cfg` jābūt blakus `mikrotik-backup.sh`, neatkarīgi no mapes, no kuras jūs sākat skriptu.

Laukus atdala īsta TAB rakstzīme, nevis atstarpes. Ierīcei vajadzīgs nosaukums, adrese, lietotājvārds, parole un derīgs SSH ports. Ja attiecīgie lauki ir tukši, kopīgos piekļuves datus var iegūt no `option.cfg`.

Nederīgs ieraksts tiek izlaists ar brīdinājumu. Ja nevienas atbilstošas ierīces paliek, nav ko dublēt un skripts iziet ar saraksta kļūdu.

Pārbaudiet arī dublētus savienojumus un dažādas ierīces ar vienādu nosaukumu. Faila formāts, piekļuves datu pārmantošana un dublikātu apstrāde aprakstīta [DEVICES.md](DEVICES.md).

### Importēšana no Oxidized, kodi 24 un 25

Kods `24` nozīmē, ka nevar nolasīt `OxidizedHome` failu `config` vai `router.db`. Kods `25` attiecas uz to saturu: neatbalstītu shēmu, nederīgiem datiem vai piemērotu MikroTik ierīču neesamību.

Pārbaudiet ceļu un piekļuvi abiem failiem, `csv` avotu, atdalītāju, kolonnu karti un modeļa `routeros` definīciju. Dati vienmēr tiek lasīti no `<OxidizedHome>/router.db`; Oxidized iestatījums `source.csv.file` šo ceļu nemaina.

Ar `IgnoreOxiAccess=true` skripts var turpināt darbu ar iepriekšējo derīgo sarakstu. Tomēr importa kļūda paliek palaišanas rezultātā. Ar `false` vecais saraksts šajā palaišanā netiek izmantots.

Importa konfigurācija aprakstīta [DEVICES.md](DEVICES.md#importējot-no-oxidized).

<br />

## Glabāšana un bloķēšana

### Bloķēšana ir aizņemta, kods 32

Pārbaudiet, vai cits uzdevums jau neizmanto to pašu rezerves kopiju mapi. Viena lietotāja pakešizpilde konfliktē ar citu pakešizpildi vai vienas ierīces izpildi, kas izmanto to pašu `BackupRoot`. Arī divas izpildes tai pašai ierīcei nevar darboties vienlaikus.

Sagaidiet aktīvā uzdevuma pabeigšanu un pēc tam palaidiet skriptu vēlreiz.

**Nedzēsiet bloķēšanas failus, lai „atbrīvotu“ krātuvi.** Tie paliek pēc skripta darbības beigām; bloķēšanu tur pats process. Faila esamība `/tmp/mikrotik-backup-${UID}/` nenozīmē, ka bloķēšana ir aizņemta.

### Nav piekļuves direktorijam

Pārbaudiet `BackupRoot` ceļu, lietotāja atļaujas, brīvo vietu un pašas krātuves pieejamību. Relatīvs ceļš tiek noteikts no skripta mapes. Failu sistēmas sakni `/` nedrīkst izmantot rezerves kopiju glabāšanai.

Ja skripts iepriekš darbināts kā root, bet tagad darbojas kā **bsmt**, šim lietotājam var nebūt piekļuves vecajiem direktorijiem un failiem. Tiesību sagatavošana aprakstīta [INSTALL.md](INSTALL.md#running-the-script-automatically).

Pakešrežīmam ar `UseNetFolder=true` vajadzīgs atsevišķs montējums. Pārbaudiet to ar:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Aizstājiet pirmo ceļu ar savu. Ja abi ceļi pieder vienam un tam pašam montējuma ierakstam, parasts direktorijs saknes failu sistēmā neatbilst `UseNetFolder=true` prasībai. Skripts pats krātuvi nemontē.

Kods `64` nozīmē, ka radās ierīces direktorija vai tā arhīva krātuves kļūda, kamēr kopīgā krātuve palika pieejama. Citu ierīču apstrāde var turpināties. Kods `65` nozīmē, ka kopīgā krātuve tika zaudēta vai tās stāvoklis kļuva nederīgs; atlikusī pakešapstrāde tiek apturēta.

Tīkla glabāšanas noteikumi ir aprakstīti [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Kļūdas strādājot ar ierīci

### SSH un failu pārsūtīšanas kodi 40–43

Pārbaudiet ierīces adresi, tās SSH pakalpojuma pieejamību, lietotājvārdu, paroli un portu. Ja `devicelist.cfg` nav norādīts ports, tiek izmantota `SshPort` vērtība no iestatījumiem; tā noklusē `22`.

RouterOS lietotājam jābūt tiesībām veikt izvēlētās darbības: eksportēt konfigurāciju, izveidot un lejupielādēt dublējumus, dzēst pagaidu failus un veikt visas ieslēgtās tīrīšanas darbības.

**Un te ir nianse!!!** Sekmīgs savienojums ar parastu SSH komandu nenozīmē, ka skripts izmanto tos pašus iestatījumus. Tas izmanto paroli un nelieto SSH aģentu, atslēgas vai parasto `~/.ssh/config`. Faili tiek iegūti ar `scp -O`.

Kods `40` attiecas uz savienojumu vai SSH/SCP transportu, `41` — uz autentifikāciju, `42` — uz RouterOS komandu vai gaidīto atbildi, bet `43` — uz faila pārsūtīšanu. Savienojuma iestatījumi izskaidroti [SECURITY.md](SECURITY.md#connecting-to-routeros).

### Nosaukuma kļūda, kodi 50 un 52

Kods `50` nozīmē, ka ierīces gala nosaukums nav derīgs. Pārbaudiet izvēlēto nosaukuma avotu un iekavās esošo saturu: pašreizējā versijā pirmais pabeigtais, netukšais fragments iekavās ir tas, kuru izmanto kā nosaukumu.

Pēc apstrādes nosaukumam jābūt no 1 līdz 32 rakstzīmēm garam. Pārāk garš nosaukums netiek saīsināts. Tiek noraidīti arī rezervētie nosaukumi, piemēram, `CON` un `NUL`.

Kods `52` nozīmē, ka gala nosaukums atkārto citas ierīces nosaukumu tajā pašā palaišanā. Salīdzinot lielie un mazie burti netiek atšķirti: `Router-A` un `router-a` uzskata par vienādiem.

Nosaukuma avots un apstrādes noteikumi aprakstīti [DEVICES.md](DEVICES.md#device-names).

### Dublējuma pārbaude neizdevās, kodi 51 un 53

Kods `51` attiecas uz `.rsc`, bet kods `53` — uz `.backup`. Iegūtais fails neizturēja pārbaudi, piemēram, tas ir tukšs vai tā izmērs neatbilst ierīcē esošajam failam.

Pārbaudiet posmu, kurā radās kļūda, kā arī brīvo vietu un tiesības gan resursdatorā, gan RouterOS ierīcē. Pēc nesekmīga mēģinājuma skripts pēc 2 sekundēm mēģina vēlreiz. Abu formātu mēģinājumi ir neatkarīgi, tāpēc vienu failu var sekmīgi iegūt, kamēr otrs pārbaudi neiztur.

Brīdinājums par nespēju dzēst pagaidu RouterOS failu pēc dublējuma sekmīgas iegūšanas pats par sevi nenozīmē, ka lokālais dublējums ir bojāts.

<br />

## Jauna dublējuma nav, bet nav arī kļūdas

Vispirms pārbaudiet `UseIncremental`. Ja salīdzināšana ir ieslēgta, jauno dublējumu var izdzēst kā dublikātu, saglabājot iepriekšējo. `.rsc` saturu salīdzina, neņemot vērā datumu standarta galvenē; `.backup` failiem salīdzina tikai izmēru.

Ar `UseIncremental=false` tiek saglabāta jauna derīga rezerves kopija bez šī salīdzinājuma.

Ņemiet vērā arī to, ka divas izpildes tai pašai ierīcei vienā mapē vienas minūtes laikā izmanto vienādu faila nosaukumu. Otrajai izpildei netiek izveidota atsevišķa versija.

Ja tajā dienā notika ikmēneša arhivēšana, pārbaudiet arī ZIP. Vienas ierīces komandrindas režīmā tajā var būt arī jaunais dublējums. Pilni glabāšanas noteikumi aprakstīti [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## Mēneša arhīvs neparādās

Pārbaudiet `MonthlyArchive` vērtību un palaišanas datumu datora lokālajā laikā. `false` izslēdz arhivēšanu; `true` vai `1` izvēlas pirmo dienu, bet skaitlis no `2` līdz `28` izvēlas to mēneša dienu.

Palaišanas laikam izvēlētajā dienā nav nozīmes. Ja šī diena ir izlaista, arhivēšana vēlāk netiek panākta; nākamais mēģinājums notiek tikai nākamā mēneša izvēlētajā dienā. BackUP Master ikmēneša arhivēšanu neveic.

Ja nav ko arhivēt, netiek radīts tukšs ZIP.

### Kur atrast ZIP

Arhīva nosaukums atbilst iepriekšējai kalendārajai dienai. Piemēram, 2026. gada 1. oktobra palaišana izveido `30.09.2026.zip`:

| Režīms | Vieta |
|---|---|
| Pakešrežīms | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Viena ierīce komandrindā | `<BackupRoot>/30.09.2026.zip` |

Direktorija nosaukums `archive/` ir rakstīts ar mazajiem burtiem. Vēl viena palaišana tajā pašā dienā atjaunina to pašu ZIP.

### Arhivēšana beidzās ar kļūdu

Kodu `70` un `71` gadījumā pārbaudiet ierīces žurnālu, piekļuvi arhīva direktorijam, brīvo vietu un esošā ZIP stāvokli. Brīva vieta vajadzīga gan krātuvē, gan lokālajā `/tmp`.

Lokālajā diskā direktorijam `archive/` jāpieder skripta lietotājam, un tā režīmam jābūt `0700`. Pakešrežīmā ar pārbaudītu tīkla krātuvi un `UseNetFolder=true` cits NAS piešķirts īpašnieks vai tiesības pašas par sevi nav kļūmes iemesls. Krātuves kļūdas arhivēšanas laikā var dot arī kodu `64` vai `65`.

Pārbaudiet esošu arhīvu ar šādu komandu, aizvietojot tās faktisko ceļu:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Avota faili netiek dzēsti, kamēr nav saglabāts pārbaudīts ZIP. Ja arhīvs ir saglabāts, bet dažus avota failus nevar izdzēst, paliek gan ZIP, gan neizdzēstie faili. Bojāts esošais arhīvs netiek automātiski aizstāts ar jaunu.

**Nedzēsiet atlikušos dublējumus vai žurnālus, kamēr neesat pārbaudījis arhīva saturu.** Arhivēšanas secība aprakstīta [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Nav žurnāla vai ekrāna izvada

Ar `LogLevel=0` un bez kļūdām jauni žurnāli netiek izveidoti. Pretējā gadījumā pārbaudiet izvēlēto `BackupRoot`, `MainLogPath` un rakstīšanas tiesības.

Tukša vērtība `MainLogPath=` atstāj `main.log` direktorijā `BackupRoot`. Ja norādīts atsevišķs direktorijs, tam jau jāpastāv un jābūt pieejamam skripta lietotājam. Ierīču žurnālus šis iestatījums nepārvieto.

Pēc ikmēneša arhivēšanas ierīces iepriekšējā vēsture ir ZIP. Turpmākais darbs tiek rakstīts jaunā žurnālā blakus dublējumiem.

Kad skripts darbojas no plānotāja vai ar novirzītu izvadi, ekrāna izvade ar indikatoru un krāsainajiem marķējumiem nav redzama. Žurnalēšana failos tādēļ netiek izslēgta.

Žurnāla rakstīšanas kļūda neaptur pašu dublēšanu, bet palaišanas rezultātā parādās kā brīdinājums. Plašāk skatiet [LOGGING.md](LOGGING.md).

<br />

<a id="language-problems"></a>
## Tulkojums netika piemērots

Pārbaudiet izvēlēto valodu un faila atrašanās vietu. Piemēram, `Language=de` vajadzīgs lasāms parasts fails `de.lang` blakus `mikrotik-backup.sh`, nevis direktorijā `lang/`. Simboliska saite netiek izmantota kā tulkojuma fails.

Ar `Language=auto` valodu nosaka operētājsistēmas vide. To var tieši izvēlēties vienai palaišanai, piemēram, apskatot palīdzību:

```bash
mikrotik-backup.sh --language=de --help
```

Netulkotie ziņojumi tiek rādīti angļu valodā. Kļūdainās faila rindas tiek izlaistas. Faili `ru.lang` un `en.lang` neaizstāj iebūvētos tulkojumus.

Rindu formāts, atslēgu nosaukumi un tulkojuma ielādes noteikumi aprakstīti [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Iestatījums nestājas spēkā

Pārbaudiet iestatījuma nosaukumu, pieņemamo vērtību un atkārtotus ierakstus failā `option.cfg`. Ja atslēga atkārtojas, uzvar pēdējā derīgā vērtība. Atslēgās lielie un mazie burti netiek atšķirti, bet defises un pasvītrojuma zīmes nav savstarpēji aizstājamas.

CLI opcija pārraksta attiecīgo faila vērtību. Parastai vienas ierīces un pakešizpildei secība ir:

**Iebūvētās vērtības** → **Derīgās option.cfg rindas** → **Komandrinda**

BackUP Master veidlapu aizpilda citādi: parastie lauki saņem iebūvētās un komandrindas vērtības, nevis opciju faila vērtības. `UseIncremental` ir izņēmums. Faila žurnalēšanas iestatījumi darbojas arī tad, ja dublēšanu palaiž no BackUP Master.

Iestatījumu nolasīšanas noteikumi aprakstīti [OPTIONS.md](OPTIONS.md), bet BackUP Master darbība — [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Rezultātu kodi

| Kods | Nozīme |
|---:|---|
| `0` | Sekmīga pabeigšana bez reģistrētām kļūdām vai brīdinājumiem |
| `1` | Pabeigts ar brīdinājumiem; izpildes kļūdas nav reģistrētas |
| `12` | Kļūda CLI opcijās, to vērtībās vai to kombinācijā |
| `21` | Nevar nolasīt `option.cfg` |
| `22` | Neizdevās iegūt ierīču sarakstu |
| `23` | Nederīgs ierīču saraksts vai nav atbilstošu ierakstu |
| `24` | Neizdevās nolasīt Oxidized failus |
| `25` | Neatbalstīta shēma vai nederīgi Oxidized dati; nav piemērotu MikroTik ierakstu |
| `30` | Vajadzīgā utilīta nav pieejama vai neatbalsta nepieciešamās iespējas |
| `31` | Terminālis nav pieejams, `stty` kļūda, vai loga izmērs ir nepietiekams |
| `32` | Vajadzīgo bloķēšanu tur cita palaišana |
| `33` | Nederīgs krātuves ceļš vai objekts vienas ierīces palaišanai |
| `34` | Neizdevās izveidot vai sagatavot vienas ierīces palaišanas direktoriju |
| `35` | Kļūda, piekļūstot lokālajam servisa objektam vai pārbaudot to, tostarp bloķēšanu |
| `36` | Vienas ierīces palaišanas krātuve neizturēja pieejamības pārbaudi pirms faila iegūšanas |
| `37` | Neizdevās ierakstīt vai aizstāt servisa failu |
| `40` | SSH/SCP savienojuma vai transportēšanas kļūda |
| `41` | Ierīces autentificēšanas kļūda |
| `42` | RouterOS komandas vai paredzamās atbildes kļūda |
| `43` | SCP failu pārsūtīšanas kļūda |
| `50` | Nederīgs ierīces gala nosaukums |
| `51` | `.rsc` fails neizturēja pārbaudi |
| `52` | Dublējas ierīču gala nosaukumi |
| `53` | `.backup` fails neizturēja pārbaudi |
| `61` | Kopīgā krātuve nav pieejama pakešrežīma palaišanas sagatavošanas laikā |
| `62` | Neizdevās pārbaudīt vai aktivizēt atsevišķu montējumu ar `UseNetFolder=true` |
| `63` | Kļūda, sagatavojot vai pārbaudot kopīgo pakešrežīma dublējumu direktoriju |
| `64` | Ierīces vai arhīva krātuves kļūda, kamēr kopīgā krātuve paliek pieejama |
| `65` | Koplietošanas krātuve tika pazaudēta vai kļuva nederīga palaišanas laikā; pakešapstrāde tiek pārtraukta |
| `70` | Kļūda izveidojot vai atjauninot arhīvu |
| `71` | ZIP vai mērķa arhīva objekts neizturēja pārbaudi |
| `80` | Iekšēja kļūda vai neizpildīta sistēmas prasība, tostarp `C.UTF-8` iespējas |
| `81` | Iekšēja MikroTik draivera kļūda |
| `129` | Darbība pārtraukta ar HUP signālu |
| `130` | Darbība pārtraukta ar INT signālu, piemēram, nospiežot Ctrl+C |
| `143` | Darbība pārtraukta ar TERM signālu |

Galīgais kods atspoguļo pirmo reģistrēto izpildes kļūdu. Brīdinājums `1` tiek aizstāts ar pirmo šādu kļūdu, un vēlāka veiksme to nedzēš. Tāpēc galīgais kods ne vienmēr atbilst pēdējam ierakstam žurnālā.

Ja atkārtotais faila lejupielādes mēģinājums izdodas, posms var beigties ar `[OK]`, lai gan pirmā mēģinājuma kļūda paliek žurnālā. Arī pakešizpildes galīgais kods, kas nav nulle, nenozīmē, ka neizdevās katra ierīce: pārbaudiet rezultātus atsevišķi.

Koda `80` gadījumā pievērsiet uzmanību sistēmas prasībām: GNU Bash 4.4 vai jaunāka versija un darbspējīga `C.UTF-8` lokalizācija. Skatiet [INSTALL.md](INSTALL.md#prasības-resursdatoram).

<br />

## Ja Jums nepieciešama palīdzība

Norādiet skripta versiju, operētājsistēmu un Bash versiju, palaišanas veidu, izejas kodu un attiecīgo žurnāla fragmentu. Vienas ierīces problēmai pievienojiet tās ierīces žurnālu; ja kļūda radās palaišanas sagatavošanas laikā, sāciet ar `main.log`.

**Nesūtiet īstas paroles vai pilnus darba konfigurācijas failus.** Pirms žurnālu, ekrānuzņēmumu vai komandu sūtīšanas pārbaudiet, vai tajos nav sensitīvu datu. Paroļu aizsardzības apsvērumi aprakstīti [SECURITY.md](SECURITY.md).

Ar autoru var sazināties, izmantojot [produkta aprakstā](../README_LV.md#contact-the-author) norādīto informāciju.
