# Dublējumi un arhīvi

[Atpakaļ uz pārskatu](../README_LV.md)

## Dublējumu formāti

Skripts var saglabāt ierīces konfigurāciju teksta formā, izveidot bināro dublējumu vai iegūt abus formātus.
Formātu izvēlas `option.cfg` parametrs `backup_type`:

| Vērtība | Kas tiek saglabāts |
|---|---|
| `configuration` | RouterOS konfigurācija `.rsc` failā |
| `binary` | Binārais dublējums `.backup` failā |
| `both` | Abi formāti: vispirms `.rsc`, pēc tam `.backup` |

Noklusējuma vērtība ir `both`. To var mainīt opciju failā, konfigurācijas redaktorā, BackUP Master vai ar `--backup-type`.

### Teksta konfigurācija: .rsc

Eksporta formātu izvēlas parametrs `export_format`. Derīgās vērtības ir `compact`, `terse` un `verbose`; noklusējums ir `compact`.

Parametrs `show_sensitive` nosaka, vai eksportā iekļauj sensitīvus datus, tostarp paroles. Pēc noklusējuma tas ir ieslēgts.
Lai to izslēgtu, pievienojiet failam `option.cfg`:

```ini
show_sensitive=false
```

### Binārais dublējums: .backup

Bināro dublējumu var šifrēt. Norādiet vajadzīgo paroli parametrā `encrypt`:

```ini
encrypt=MySuperPassword
```

Ja `encrypt=` vērtība ir tukša, fails tiek saglabāts bez šifrēšanas. Tas ir noklusējums.

*(Piezīme. AES-SHA256 šifrēšana attiecas tikai uz `.backup`. Tā nešifrē teksta konfigurācijas, žurnālus vai ZIP arhīvus.)*

Pēc noklusējuma skripts pirms binārā dublējuma izveides iztīra RouterOS DNS kešatmiņu un konsoles vēsturi. Ja šīs darbības nav vajadzīgas, izslēdziet attiecīgos parametrus:

```ini
clear_dns_cache=false
clear_console_history=false
```

Ja tiek iegūta tikai teksta konfigurācija, šīs tīrīšanas darbības netiek veiktas.

<br />

## Failu nosaukumi un atrašanās vietas

Pēc noklusējuma dublējumi tiek glabāti direktorijā `backups` blakus skriptam. Citu direktoriju norādiet opciju faila parametrā `BackupRoot`.

Vienas ierīces palaišanā faili tiek ievietoti tieši šajā direktorijā:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Pakešrežīmā katrai ierīcei ir savs apakšdirektorijs:

```text
backups/
├── main.log
└── Router-A/
    ├── Router-A_YYYY-MM-DD_HH-MM.rsc
    ├── Router-A_YYYY-MM-DD_HH-MM.backup
    ├── Router-A.log
    └── archive/
        └── DD.MM.YYYY.zip
```

Dublējuma faila nosaukumā ir ierīces nosaukums, kā arī skripta resursdatora pulksteņa datums un laiks. Abiem vienā dublēšanas darbībā iegūtajiem formātiem ir vienāds laikspiedols.
Ierīces nosaukuma veidošana aprakstīta [DEVICES.md](DEVICES.md#device-names).

**Pievērsiet uzmanību!!!**
Ja vienas minūtes laikā vienā direktorijā divreiz dublējat to pašu ierīci, failu nosaukumi sakrīt. Fails ar šo nosaukumu tiek aizstāts; otrajai palaišanai atsevišķa versija netiek izveidota.

Glabāšanai var izmantot arī tīkla direktoriju. Pakešrežīmā iestatiet `UseNetFolder=true`, lai skripts pārbaudītu krātuvi. Direktorija sagatavošana aprakstīta [INSTALL.md](INSTALL.md), bet ceļu iestatījumi — [OPTIONS.md](OPTIONS.md#network-storage).

Žurnālu atrašanās vietas un saturs detalizēti aprakstīts [LOGGING.md](LOGGING.md).

<br />

## Inkrementālie dublējumi

Šī funkcija ļauj nesaglabāt dublējumus, kuros nav konstatētas izmaiņas. To vada parametrs `UseIncremental`:

| Vērtība | Kā dublējumi tiek saglabāti |
|---|---|
| `true` (noklusējums) | Ja jaunais dublējums atzīts par dublikātu, tas tiek dzēsts, bet iepriekšējais dublējums paliek |
| `false` | Katrs jaunais derīgais dublējums tiek saglabāts bez salīdzināšanas ar iepriekšējo |

Ja ir konstatētas izmaiņas vai iepriekšēja dublējuma nav, jaunais fails tiek saglabāts. Ja salīdzināšanu nevar pabeigt, fails arī tiek saglabāts, taču skripts izdod brīdinājumu.

**Un te ir āķis!!!**
Salīdzināšana katram formātam atšķiras:

| Formāts | Kas tiek salīdzināts |
|---|---|
| `.rsc` | Faila saturs. Datums un laiks standarta RouterOS galvenē tiek ignorēts |
| `.backup` | Tikai faila izmērs baitos |

Tāpēc divi vienāda izmēra binārie faili tiek uzskatīti par dublikātiem pat tad, ja to saturs atšķiras. Ņemiet to vērā, izvēloties glabāšanas iestatījumus.

Skripts salīdzina jauno failu ar jaunāko agrāko tās pašas ierīces un formāta dublējumu ierīces direktorijā. ZIP arhīvā jau ievietotie dublējumi salīdzināšanā nepiedalās.

Skripts glabā parastus `.rsc` un `.backup` failus, nevis atsevišķus izmaiņu failus. `UseIncremental` izslēgšana neizslēdz dublējumu iegūšanu un pārbaudi, žurnalēšanu vai ikmēneša arhivēšanu.

<br />

<a id="monthly-archive"></a>
## Ikmēneša arhivēšana

Pēc noklusējuma šī funkcija ir izslēgta. Failā `option.cfg` iestatiet `MonthlyArchive`, lai izvēlētos dienu, kurā arhivēt uzkrātos dublējumus un žurnālus:

| Vērtība | Darbība |
|---|---|
| `false` (noklusējums) | Arhivēšana ir izslēgta |
| `true` vai `1` | Arhivēšana notiek mēneša pirmajā dienā |
| No `2` līdz `28` | Arhivēšana notiek norādītajā mēneša dienā |

Palaišanas laikam izvēlētajā dienā nav nozīmes. Grafiku konfigurējiet atsevišķi, kā aprakstīts [INSTALL.md](INSTALL.md#running-the-script-automatically).

### Kas nonāk arhīvā

Pakešrežīmā šajā dienā mainās darbību secība: skripts vispirms apkopo ierīces uzkrātos failus ZIP arhīvā un tikai pēc tam izveido jaunus dublējumus. Pašreizējā palaišanā izveidotie dublējumi paliek ārpus arhīva.

Arhīvā iekļauj parastos failus, kas atrodas tieši ierīces direktorijā, tostarp visu kumulatīvo ierīces žurnālu. Tas neaprobežojas ar `.rsc` un `.backup`: var tikt arhivēti arī citi parastie faili, ko ievietojat šajā direktorijā.

Apakšdirektoriji, simboliskās saites, pašreizējās palaišanas servisa objekti un skripta iepriekš izveidotie ZIP faili netiek iesaiņoti atkārtoti. **Galvenais žurnāls `main.log` netiek arhivēts.**

Kad pabeigtais ZIP arhīvs ir pārbaudīts un saglabāts, tajā iekļautie avota faili tiek dzēsti no ierīces direktorija. Ja nav ko arhivēt, tukšs ZIP netiek izveidots.

### Arhīva nosaukums un atrašanās vieta

ZIP nosaukumu veido pēc iepriekšējās kalendārās dienas formātā `DD.MM.YYYY.zip`. Piemēram, 2026. gada 1. oktobra palaišana izveido `30.09.2026.zip`, bet 15. oktobra palaišana — `14.10.2026.zip`.

| Režīms | Arhīva atrašanās vieta |
|---|---|
| Pakešrežīms | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Vienas ierīces komandrindas režīms | `<BackupRoot>/DD.MM.YYYY.zip` |

Atkārtota palaišana tajā pašā dienā atjaunina arhīvu ar tādu pašu nosaukumu.

### Vienas ierīces režīms un BackUP Master

Vienas ierīces komandrindas palaišanā secība ir pretēja: vispirms notiek dublēšana, pēc tam arhivēšana. Tāpēc ZIP arhīvā var nonākt arī pašreizējās palaišanas jaunais dublējums.

Šajā režīmā arhivē `.rsc`, `.backup` un `.log` failus, kas atrodas tieši `BackupRoot`, izņemot `main.log`. Ja vairāku ierīču vienas ierīces režīma rezultāti atrodas vienā direktorijā, to faili nonāk vienā arhīvā.

Izmantojot BackUP Master, ikmēneša arhivēšana nenotiek.

### Ja palaišana ir izlaista

Ja skripts izvēlētajā dienā netiek palaists, izlaistais arhivēšanas mēģinājums netiek panākts. Nākamais mēģinājums notiek nākamā mēneša norādītajā dienā.

Visi uzkrātie faili nonāk šajā vienā nākamajā arhīvā, pat ja tie attiecas uz diviem, trim vai vairākiem mēnešiem. Izlaistajiem mēnešiem atsevišķi ZIP faili netiek izveidoti.

### Ja arhivēšana neizdodas

Avota faili netiek dzēsti, kamēr nav saglabāts pārbaudīts ZIP arhīvs. Arī jau esošs bojāts arhīvs netiek pārrakstīts ar jaunu.

Ja ZIP jau ir saglabāts, bet dažus avota failus nevar izdzēst, gan pabeigtais arhīvs, gan neizdzēstie faili paliek savā vietā. Kļūdas cēloni meklējiet žurnālā.

*(Piezīme. Arhīvs tiek veidots lokālajā direktorijā `/tmp` arī tad, ja paši dublējumi tiek glabāti NAS. Tāpēc brīva vieta ir vajadzīga arī ārpus krātuves.)*

<br />

## Ja dublēšana neizdodas

Pēc nesekmīga faila iegūšanas mēģinājuma skripts pēc 2 sekundēm mēģina vēlreiz. `.rsc` un `.backup` atkārtošanas mēģinājumi tiek veikti atsevišķi.

Parasta kļūda viena formāta iegūšanā neatceļ mēģinājumu iegūt otru formātu. Ja viena ierīce nav pieejama, skripts turpina apstrādāt pārējās. Ja tiek zaudēta kopīgā krātuve, pakešapstrāde tiek apturēta.

Kļūdu ziņojumi un rezultātu kodi aprakstīti [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Glabāšana un atjaunošana

Vecie ZIP faili netiek dzēsti pēc vecuma vai skaita. To glabāšanas termiņu un ārējās rotācijas politiku nosakāt jūs.

Skripts izveido dublējumus, bet neatjauno RouterOS. Atjaunošanu pārbaudiet atsevišķi piemērotā ierīcē.

*(Piezīme. Dublējumos un arhīvos var būt paroles un citi konfidenciāli dati. Ierobežojiet piekļuvi krātuvei, kā aprakstīts [SECURITY.md](SECURITY.md).)*
