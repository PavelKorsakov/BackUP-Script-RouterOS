# Komandrinda

[Atpakaļ uz pārskatu](../README_LV.md)

## Sintakse

```text
mikrotik-backup.sh [action] [parameters]
```

Komandrindas parametriem var izmantot garu formu: `--parameter value` vai `--parameter=value`.
Var izmantot arī īso formu `-p=value`. Ja **vērtība** sākas ar `-`, ir pieļaujama tikai forma ar `=`: `--parameter=-value`.

Nezināms parametrs, pozicionāls arguments vai trūkstoša, tieši tukša vai nederīga vērtība izraisa kļūdas kodu `12` un aptur skriptu.

<br />

## Darbības

| Darbība | Mērķis |
|---|---|
| `-i` | Galvenā interaktīvā izvēlne |
| `-b` | BackUP Master |
| `-e` | Konfigurācijas redaktors (`option.cfg`) |
| `-h`, `--help` | CLI opciju palīdzība |
| `-v`, `--version` | Skripta versija |

Skripts vienlaicīgi nepieļauj vairāk kā vienu darbības opciju. Piemēram, `mikrotik-backup.sh -i -b` apstājas ar kļūdas kodu `12`.

<br />

## Parametri

| Parametrs | Vērtība | Mērķis |
|---|---|---|
| `--device-name` | Nosaukums | Ierīces nosaukums, kad `UseIdentityName=false` |
| `--address` | Adrese vai DNS nosaukums | RouterOS ierīces adrese |
| `--user` | Lietotājvārds | RouterOS ierīces lietotājs |
| `--password` | Parole | RouterOS ierīces parole |
| `--port` | `1`–`65535` | Ierīces SSH ports; noklusējums `22` |
| `--language` | `auto` vai divi ASCII burti | Pašreizējās saskarnes un skripta žurnālu valoda |
| `--use-oxidized` | Bula vērtība* | Importēt ierīču sarakstu no Oxidized |
| `--oxidized-home` | Ceļš | Oxidized iestatījumu direktorija, kas satur `config` un `router.db` |
| `--use-identity-name` | Būla vērtība* | Iegūt nosaukumu no RouterOS Identity |
| `--backup-root` | Ceļš | Dublējumu glabāšanas saknes direktorijs |
| `--use-net-folder` | Būla vērtība* | Pārbaudīt montējumu pakešrežīmā |
| `--monthly-archive` | `false` vai skaitlis no `1` līdz `28`* | Ieslēgt kalendāro ikmēneša arhivēšanu |
| `--log-level` | `0`, `1`, `2`, `3` | Žurnāla un termināļa izvades detalizācijas līmenis |
| `--main-log-path` | Ceļš | Direktorijs tikai failam `main.log` |
| `--backup-type` | `configuration`, `binary`, `both` | Iegūstamie dublējumu formāti |
| `--export-format` | `compact`, `terse`, `verbose` | Teksta eksportēšanas formāts |
| `--show-sensitive` | Būla vērtība* | Eksportā iekļaut sensitīvās vērtības |
| `--encrypt` | Netukša parole | Šifrēt `.backup` ar AES-SHA256 |
| `--clear-dns-cache` | Būla vērtība* | Notīrīt DNS kešatmiņu pirms binārā dublējuma |
| `--clear-console-history` | Būla vērtība* | Notīrīt konsoles vēsturi pirms binārā dublējuma |

`*` Būla vērtības ir `true` vai `false`; skripts pieņem arī `yes`/`no`, `1`/`0` un `on`/`off` neatkarīgi no burtu reģistra.
Opcijai `backup-type` vērtības `config` un `conf` ir `configuration` sinonīmi.

Īsas savienojuma formas:

```text
-a=VĒRTĪBA    atbilst --address VĒRTĪBA
-u=VĒRTĪBA    atbilst --user VĒRTĪBA
-p=VĒRTĪBA    atbilst --password VĒRTĪBA
```

<br />

<a id="execution-mode"></a>
## Skripta darbināšana no komandrindas

Skripts var izveidot vienas ierīces dublējumu, taču šādai palaišanai vajadzīgi vismaz trīs parametri:
ierīces **IP adrese**, **lietotājvārds** un **parole**. Tātad šī komanda jau ir pilnīga:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Visi pārējie iepriekš uzskaitītie parametri šeit nav obligāti.
*(Piezīme. Ļoti svarīgi: šo savienojuma parametru trijnieku NAV paredzēts apvienot ar **darbības opciju**.)*

**Vēl viena nianse!!!**
Vienas ierīces izpildei visi trīs savienojuma parametri jānodod ar CLI. Skripts neņem trūkstošu lietotājvārdu vai paroli no `option.cfg`.

<br />

## Prioritātes noteikšana

Parastās vienas ierīces un pakešrežīma palaišanas izmanto [OPTIONS.md](OPTIONS.md) aprakstīto secību:
**Iebūvētās vērtības** → **derīgās `option.cfg` rindas** → **komandrinda**

Ja parametrs jau norādīts `option.cfg`, bet konkrētai palaišanai vajadzīga cita vērtība, to var nodot komandrindā. Konfigurācijas fails nav jāpārraksta.

Vienas ierīces palaišana neizmanto ierīču sarakstu vai Oxidized importu. Citi `option.cfg` iestatījumi joprojām tiek lietoti, ja vien tos neaizstāj komandrindas parametri.

**BackUP Master veidlapas aizpildīšanai ir sava secība.**
Parastie lauki izmanto iebūvētās vērtības un nodotos CLI parametrus, nevis `option.cfg`. `UseIncremental` ir izņēmums: tas tiek mantots no faila vai saņem noklusējuma vērtību.
Izvēlētie `LogLevel` un `MainLogPath` tiek saglabāti darbībai, bet ikmēneša arhivēšana ir atslēgta. Skatīt [INTERACTIVE.md](INTERACTIVE.md) informācijai par pašu BackUP Master.

<br />

## Komandrindas parametri pēc mērķa

### Pieslēguma un ierīces nosaukums

| Opcija | Vērtība | Mērķis |
|---|---|---|
| `--address` | IP adrese vai DNS nosaukums | RouterOS ierīces adrese |
| `--user` | Lietotājvārds | RouterOS ierīces lietotājs |
| `--password` | Parole | RouterOS ierīces parole |
| `--port` | `1` līdz `65535` | Ierīces SSH ports; noklusējums `22` |
| `--device-name` | Nosaukums | Ierīces nosaukums, kad `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Iegūt nosaukumu no RouterOS Identity |

Lai izmantotu paša norādītu nosaukumu, kopā norādiet `--use-identity-name false` un `--device-name NAME`.

<br />

### Dublējuma formāts un saturs

| Opcija | Vērtība | Mērķis |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Iegūstamie dublējumu formāti |
| `--export-format` | `compact`, `terse`, `verbose` | Teksta eksportēšanas formāts |
| `--show-sensitive` | `true` / `false` | Eksportā iekļaut sensitīvās vērtības |
| `--encrypt` | Netukša parole | Šifrēt `.backup` ar AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Notīrīt DNS kešatmiņu pirms binārā dublējuma |
| `--clear-console-history` | `true` / `false` | Notīrīt konsoles vēsturi pirms binārā dublējuma |

Opcijai `--backup-type` vērtības `config` un `conf` arī nozīmē `configuration`.

*(Piezīme. `UseIncremental` nav atsevišķas CLI opcijas. Iestatiet to `option.cfg`, konfigurācijas redaktorā vai BackUP Master. Iestatījuma nozīme aprakstīta [OPTIONS.md](OPTIONS.md).)*

<br />

### Krātuve, arhivēšana un žurnāli

| Opcija | Vērtība | Mērķis |
|---|---|---|
| `--backup-root` | Ceļš | Dublējumu glabāšanas saknes direktorijs |
| `--use-net-folder` | `true` / `false` | Pārbaudīt montāžu pakešrežīmā |
| `--monthly-archive` | `false` vai skaitlis no `1` līdz `28` | Ieslēgt kalendāro ikmēneša arhivēšanu |
| `--log-level` | `0`, `1`, `2`, `3` | Žurnāla un termināļa izvades detalizācijas līmenis |
| `--main-log-path` | Direktorija ceļš | Direktorijs tikai failam `main.log` |

Opcijai `--monthly-archive` ir savi noteikumi: `true`/`yes`/`1`/`on` nozīmē mēneša pirmo dienu, bet `false`/`no`/`0`/`off` izslēdz arhivēšanu. Vērtības no `2` līdz `28` izvēlas attiecīgo dienu.

Opcija izvēlas arhivēšanas dienu; tā nesāk arhivēšanu uzreiz. Šī režīma noteikumus skatiet [BACKUPS.md](BACKUPS.md#monthly-archive).

Opcijai `--main-log-path` norādiet direktoriju, nevis pilnu ceļu, kas beidzas ar `main.log`. Šis iestatījums neietekmē ierīču žurnālus.

<br />

### Ierīces saraksta avots un valoda

| Opcija | Vērtība | Mērķis |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Importēt ierīču sarakstu no Oxidized |
| `--oxidized-home` | Ceļš | Oxidized iestatījumu direktorija, kas satur `config` un `router.db` |
| `--language` | `auto` vai divu burtu kods | Pašreizējās saskarnes un skripta žurnālu valoda |

Ar `--language auto` valodu nosaka operētājsistēmas vide. Var skaidri izvēlēties, piemēram, `ru`, `en` vai `de`. Krievu un angļu valodai atsevišķi tulkojuma faili nav vajadzīgi; citi tulkojumi tiek ielādēti no failiem blakus skriptam. Ja piemērota tulkojuma nav, tiek izmantota angļu valoda.
Plašāk skatiet [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Piemēri

**Uzmanību!!!**
Pēc noklusējuma sensitīvo datu eksports, DNS kešatmiņas tīrīšana un konsoles vēstures tīrīšana pirms binārā dublējuma ir ieslēgta. Turpmākajos vienas ierīces piemēros tīrīšana un sensitīvo datu eksports ir izslēgts.

*(Piezīme. Ar CLI nodotās paroles var būt redzamas čaulas vēsturē un procesa argumentos. Tas attiecas arī uz `.backup` šifrēšanas paroli, kas var būt redzama `ssh` apakšprocesa argumentos. Plašāk skatiet [SECURITY.md](SECURITY.md).)*

### `.rsc` konfigurācija, tikai bez sensitīviem datiem

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Abi formāti, paša norādīts ierīces nosaukums un bez tīrīšanas

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Šifrēts binārais dublējums

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Pakešrežīma palaišana ar atsevišķu direktoriju un detalizētu žurnalēšanu

Šis piemērs pieņem, ka `option.cfg` un ierīču saraksts jau ir sagatavots:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Pārējos šīs pakešrežīma palaišanas iestatījumus nodrošina `option.cfg` un iebūvētās vērtības.

<br />

## Ja komanda tiek noraidīta

Nezināma opcija, papildu pozicionāls arguments, trūkstoša vai nederīga vērtība izraisa kļūdu `12`. Dublēšana netiek sākta. Izmantojiet `-h`, lai pārbaudītu opcijas rakstību.

**Tukšas vērtības nevar nodot ar CLI.**
`--encrypt=''` un `--main-log-path=''` tiek noraidīti. Iestatiet tukšas `encrypt=` un `MainLogPath=` vērtības `option.cfg` vai ar konfigurācijas redaktora starpniecību.

Rezultātu kodi un to nozīme uzskaitīta sadaļā [Problēmu novēršana](TROUBLESHOOTING.md#result-codes).
