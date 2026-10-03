# MikroTik Backup Script

**MikroTik RouterOS ierīču rezerves kopiju veidošanai.**

Šis skripts veido RouterOS ierīču rezerves kopijas manuāli vai automātiski, izmantojot atsevišķi konfigurētu plānotāju.
`mikrotik-backup.sh` ir patstāvīgs skripts; daļu funkciju var papildus konfigurēt failā `option.cfg`.

<br>

## Skripta iespējas

| Iespēja | Darbība |
|---|---|
| Vienas ierīces režīms | Izveido vienas ierīces rezerves kopiju, izmantojot CLI opcijas |
| Pakešapstrāde | Secīgi apstrādā ierīču sarakstā norādītās ierīces; sarakstu var importēt no Oxidized |
| Rezerves kopiju formāti | Izveido `.rsc`, `.backup` vai abus formātus noteiktā secībā |
| Eksporta režīmi | Atbalsta `compact`, `terse` un `verbose` eksportu, kā arī bināro rezerves kopiju šifrēšanu |
| Inkrementālās rezerves kopijas | Var paturēt jaunu kopiju tikai tad, ja ir konstatētas izmaiņas |
| Ikmēneša arhīvi | Var arhivēt vecākas rezerves kopijas un žurnālus pie kalendārās robežas |
| Žurnalēšana | Ieraksta kopējās apstrādes darbības failā `main.log`, bet ierīces darbības — failā `devicename.log` |
| Konfigurācijas izvēlne | Nodrošina interaktīvu izvēlni ērtai konfigurēšanai un lietošanai |
| Lokalizācija | Ietver krievu un angļu valodu un atbalsta ārējus lokalizācijas failus |
| Rezerves kopiju krātuve | Ļauj izmantot jebkuru piemērotu mapi, tostarp NAS |
| Darbs ar NAS | Pirms rezerves kopijas veidošanas var pārbaudīt krātuves pieejamību |

<br>

## Sistēmas prasības un darba sākšana

**Obligāti:** GNU Bash 4.4 vai jaunāks, kā arī instalētas utilītas **SSH**, **SCP** un **SSHPass**.
**zip** ir nepieciešama tikai ikmēneša arhivēšanai. Visas nepieciešamās programmas un to instalēšanas komandas ir uzskaitītas sadaļā [Atkarības](lv/INSTALL.md#atkarības).
*(Piezīme. Ja trūkst obligātas utilītprogrammas, skripts beidz darbu ar kļūdu. Tā ir paredzētā darbība.)*

**Pēc izvēles:**
**autofs**, **davfs2**, **rclone** un citi ārējo krātuvju montēšanas rīki. **Instalēšana:**
Lejupielādes un konfigurēšanas norādījumus skatiet sadaļā [Instalēšana](lv/INSTALL.md).

Mapē ar lejupielādētajiem failiem izpildiet:

Tālāk redzamais komandu bloks paredzēts failiem no GitHub Release. Git pirmkoda klonā ģenerētā `SHA256SUMS` faila nav; šādā gadījumā sāciet ar `chmod 700 mikrotik-backup.sh` un turpiniet ar versijas un palīdzības pārbaudēm.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Ja kontrolsummu pārbaude neizdodas, **nekādā gadījumā nepalaidiet failu!!!**

<br>

## Skripta palaišanas veidi

**Faila palaišana BEZ papildu opcijām** *(ja `option.cfg` nav vai tā nav derīga)*
Ja blakus skriptam nav `option.cfg` vai failā nav izmantojamu iestatījumu, tiek atvērts konfigurācijas redaktors. Tajā var izveidot vai rediģēt `option.cfg`.

**Faila palaišana BEZ papildu opcijām** *(ja ir derīgi `option.cfg` un `devicelist.cfg`)*
Ja izmantojami iestatījumi jau ir sagatavoti, skripts sāk pakešapstrādi.

**Skripta palaišana ar opciju:**

| Uzdevums | Komanda |
|---|---|
| Atvērt interaktīvo izvēlni | `./mikrotik-backup.sh -i` |
| Atvērt BackUP Master | `./mikrotik-backup.sh -b` |
| Izveidot vai rediģēt `option.cfg` | `./mikrotik-backup.sh -e` |
| Parādīt pilnu CLI palīdzību | `./mikrotik-backup.sh -h` |
| Izveidot vienas ierīces rezerves kopiju | Norādīt pilnu CLI savienojuma trijnieku: ierīces adresi, lietotāju un paroli |

Svarīgākā opcija ir `-i`: tā atver interaktīvo izvēlni. No tās var:

- BackUP Master ievadīt ierīces parametrus, izveidot rezerves kopijas un pievienot izvēlēto ierīci failam `devicelist.cfg` vai izveidot šo failu;
- konfigurācijas redaktorā izveidot vai rediģēt `option.cfg`;
- atvērt CLI palīdzību;
- izlasīt īsu skripta iespēju aprakstu.

Pilnu CLI aprakstu, tostarp precīzās formas `-a=...`, `-u=...` un `-p=...`, skatiet [komandrindas atsaucē](lv/CLI.md).

<br>

## Kur ir rezultāti jeb „Kur ir manas rezerves kopijas???”

Pēc noklusējuma ierīču rezerves kopijas tiek glabātas mapē `backups` blakus skriptam. Ja mapes nav, skripts to izveido.
*(Piezīme. Relatīvais ceļš `backups` tiek noteikts no skripta mapes, nevis pašreizējās darba mapes!)*

Vienas ierīces izpildē atsevišķa ierīces apakšmape netiek veidota:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Pakešapstrādē katrai ierīcei ir sava mape:

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

Šīs struktūras ir piemēri, nevis solījums, ka pēc katras izpildes būs izveidots ikviens fails.
Žurnālfails rodas tikai tad, kad tajā tiek ierakstīts pirmais attiecīgais ieraksts.
Ar `MainLogPath` failā `option.cfg` var pārvietot `main.log` uz `/var/log/` vai citu piemērotu mapi.
Rezerves kopiju, arhīvu un žurnālu mapju konfigurēšana aprakstīta sadaļā [Konfigurācija](lv/OPTIONS.md).

<br>

## Ikmēneša arhivēšana

Šī funkcija pēc noklusējuma ir atspējota. Ja skripts darbojas pēc grafika, ar `MonthlyArchive=true|1...28` failā `option.cfg` izvēlieties dienu, kad tiek arhivētas uzkrātās iepriekšējā perioda rezerves kopijas.

Šajā dienā pakešizpildes darbību secība mainās: vispirms tiek arhivēti visi krātuvē uzkrātie atbilstošie dati, pēc tam tiek veidotas pašreizējās dienas rezerves kopijas.

Arhīva nosaukums atbilst iepriekšējai kalendārajai dienai. Piemēram, 1. oktobra izpilde izveido `30.09.YYYY.zip`.

*(Piezīme. Ja skripts NETIEK palaists katru dienu, vajadzīgajam datumam jāizveido atsevišķs plānotais uzdevums. Ja skripts darbojas katru dienu vai biežāk, papildu uzdevums nav vajadzīgs.)*

Neatkarīgi no iemesla izlaista ikmēneša izpilde netiek panākta ar vēlākām parastajām izpildēm.
Nākamā plānotā ikmēneša izpilde vienā arhīvā savāc visus uzkrātos vecos datus, pat ja tie aptver vairākus mēnešus. `main.log` netiek arhivēts.

Pilnus noteikumus, piemērus un kļūdu darbību skatiet sadaļā [Ikmēneša arhīvi](lv/BACKUPS.md#monthly-archive).

<br>

## Detalizēta dokumentācija

| Tēma | Lapa |
|---|---|
| Prasības, atkarības un failu izvietojums | [Instalēšana](lv/INSTALL.md) |
| Parametri un režīma izvēle | [CLI](lv/CLI.md) |
| Noklusējuma vērtības un `option.cfg` | [Konfigurācija](lv/OPTIONS.md) |
| Ierīču saraksts, nosaukumi un Oxidized | [Ierīces](lv/DEVICES.md) |
| Formāti, salīdzināšana, krātuve un ZIP arhīvi | [Rezerves kopijas](lv/BACKUPS.md) |
| Žurnalēšanas līmeņi, ceļi un ziņojumi | [Žurnalēšana](lv/LOGGING.md) |
| Izvēlne, redaktors un BackUP Master | [Interaktīvā saskarne](lv/INTERACTIVE.md) |
| Valodas izvēle un `.lang` faili | [Lokalizācija](lv/LOCALIZATION.md) |
| Piekļuves dati, SSH un atļaujas | [Drošība](lv/SECURITY.md) |
| Diagnostika pēc simptoma vai rezultāta koda | [Problēmu novēršana](lv/TROUBLESHOOTING.md) |
| Laidiena pārbaude un atjauninājumi | [Laidieni](lv/RELEASES.md) |
| Izstrādes vēsture un plāni | [Ceļvedis](lv/ROADMAP.md) |

<br>

## Darbības joma un ierobežojumi

Skripts veido rezerves kopijas, bet neatjauno RouterOS konfigurāciju.
Pašreizējā versija nesūta e-pasta vai ziņapmaiņas paziņojumus un nedzēš vecos ZIP failus pēc to vecuma.
Par atjaunošanas procedūrām, ārēju glabāšanu un rezultātu uzraudzību atbild administrators.

SSH profils izmanto paroles autentifikāciju un atspējo resursdatora atslēgas pārbaudi.
`.backup` faila šifrēšana nešifrē `.rsc` failus, konfigurācijas failus vai ZIP arhīvus.
Pirms izmantošanas produkcijas vidē izlasiet [drošības modeli](lv/SECURITY.md).

<br>

## Dokumentācija citās valodās

[English](../README.md).<br />
[Русский](README_RU.md).<br />
[Latviešu](README_LV.md).<br />
[Українська](README_UK.md).<br />
[Deutsch](README_DE.md).<br />
[Bahasa Indonesia](README_ID.md).<br />
[Português (Brasil)](README_PT-BR.md).<br />
[Tiếng Việt](README_VI.md).<br />
[Español](README_ES.md).<br />
[Polski](README_PL.md).<br />
[বাংলা](README_BN.md).

<a id="contact-the-author"></a>
## Saziņa ar autoru

Iespēju ierosinājumus, kļūdu ziņojumus un jautājumus par skriptu sūtiet uz [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev)
vai sazinieties ar autoru tieši Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
