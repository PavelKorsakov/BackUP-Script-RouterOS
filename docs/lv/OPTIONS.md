# Konfigurācija

[Atpakaļ uz pārskatu](../README_LV.md)

## Ievadam

Neobligātais fails `option.cfg` ļauj mainīt skripta noklusējuma iestatījumus.
Lai skripts izpildes laikā varētu ielādēt šajā failā norādītos iestatījumus,
`option.cfg` jābūt blakus `mikrotik-backup.sh` tajā pašā mapē.

Faila struktūra ir pavisam vienkārša: `Key=value` ierakstu saraksts. Tas nav čaulas skripts.
Mainīgie netiek izvērsti, un komandas netiek izpildītas.

## Kad konfigurācija ir izmantojama

Pat viena derīga un atpazīta rinda padara konfigurāciju izmantojamu.
Nav jānorāda visi iestatījumi: ja noklusējuma vērtība ir piemērota, attiecīgā opcija failā `option.cfg` nav jāiekļauj.

Ja fails ir tukšs vai satur tikai komentārus, nezināmas atslēgas vai nederīgas vērtības, skriptam no tā nav ko ielādēt.
Tādā gadījumā paliek spēkā noklusējuma iestatījumi.

**Un šeit ir loms!!!**
Ja šādā stāvoklī palaižat skriptu bez argumentiem, dublēšana netiek sākta. Tā vietā skripts mēģina atvērt konfigurācijas redaktoru.
Tas pats notiek, kad `option.cfg` neeksistē vispār.
Saglabājiet vajadzīgos iestatījumus un palaidiet skriptu vēlreiz.
*(Piezīme. Redaktoram ir vajadzīgs terminālis. Ja skripts palaists bez termināļa, piemēram, ar plānotāju, tas beidz darbu ar kļūdu `31`.
Pirms automātiskas palaišanas konfigurēšanas sagatavojiet `option.cfg`.)*

**Secība, kādā tiek nolasīti neobligātie parametri:**
Skripts izmanto parametru avotus prioritārā secībā. Ja `option.cfg` nav, tiek izmantotas skriptā iebūvētās noklusējuma vērtības.
Ja fails pastāv un ir veiksmīgi nolasīts, tajā ietvertie <mark>derīgie</mark> parametri aizstāj attiecīgās noklusējuma vērtības.

Un pats svarīgākais!!! Ja tas pats parametrs ir norādīts komandrindā, priekšroka ir komandrindas vērtībai.
Parastā vienas ierīces vai pakešrežīma palaišanā prioritāte ir šāda:
**Iebūvētās vērtības** → **Derīgās rindas no option.cfg** → **Komandrinda**

*(Piezīme. Neesošs fails nav tas pats, kas nelasāms fails.
Ja `option.cfg` pastāv, bet skripts to nevar nolasīt, izpilde beidzas ar
konfigurācijas kļūdu `21`; izpilde neturpinās ar noklusējuma vērtībām.)*

## Kā tiek nolasīts fails

Katra rinda tiek sadalīta pie pirmās `=` zīmes. Atslēgu nosaukumos lielie un mazie burti netiek atšķirti, taču defises un pasvītrojuma zīmes nav savstarpēji aizstājamas.
Tukšās rindas un rindas, kuru pirmā rakstzīme pēc atkāpēm ir `#`, tiek ignorētas. Nezināma vai nederīga rinda nepadara nederīgas blakus esošās pareizās rindas.
Ja atslēga atkārtojas, tiek izmantota pēdējā derīgā vērtība.

Parastajām vērtībām sākuma un beigu atstarpes tiek noņemtas.
**Svarīgi:** parametriem `Login`, `Password` un `encrypt` viss teksts pēc pirmās `=` zīmes tiek saglabāts burtiski.
Nelieciet vērtību pēdiņās čaulas sintakses dēļ: pēdiņas kļūs par vērtības daļu.
Nelieciet komentāru aiz paroles. Komentāram izmantojiet atsevišķu rindu.

Faila sākumā tiek atbalstīta viena BOM un CRLF rindas beigas.
Ir atļauta lasāma simboliska saite uz regulāru failu.
Piekļuves problēma vai nepiemērots objekta tips netiek uzskatīts par tukšu failu
un izraisa konfigurācijas kļūdu.

## option.cfg izveide, rediģēšana un saglabāšana

Vienkāršākais veids, kā izveidot failu, ir palaist skriptu ar `-e`:

```bash
./mikrotik-backup.sh -e
```

Tiek atvērts konfigurācijas redaktors ar galveno opciju sarakstu.
Ja visas rindas neietilpst termināļa logā, saraksts automātiski ritinās, kad pārvietojaties ar augšupvērsto un lejupvērsto bulttaustiņu.
Vienumi **Saglabāt** un **Atcelt** atrodas tā paša saraksta beigās.
Pārvietojieties pa izvēlni, ievadiet vajadzīgos iestatījumus → izvēlieties **Saglabāt** → un (jūs esat lieliski) fails ir izveidots.

Atcerieties, ka, strādājot interaktīvajā izvēlnē, redaktors maina iestatījumus tikai atmiņā.
Pilns *kanoniskais* fails tiek ierakstīts tikai pēc vienuma **Saglabāt** izvēles.

Ja `option.cfg` vēl nepastāv, redaktors sākotnēji aizpilda laukus ar noklusētajām vērtībām.
Ja fails jau eksistē un esat mainījis dažus parametrus, konfigurācijas redaktors aizpilda laukus ar jūsu vērtībām, nevis noklusētajām.

Otrs veids ir izveidot `option.cfg` manuāli. Jā: savām rokām atveriet iecienīto teksta redaktoru un ievadiet vajadzīgos iestatījumus.
Kur tos atrast? Tepat zemāk:

## Iestatījumi un noklusētie

| Atslēga | Noklusētais | Vērtība un mērķis |
|---|---|---|
| `Language` | `auto` | `auto` vai divi ASCII burti, piemēram, `ru`, `en` vai `de` |
| `SshPort` | `22` | Ports no `1` līdz `65535`; redaktorā nav redzams, BackUP Master ir redzams |
| `UseOxidized` | `false` | Importēt ierīces no Oxidized |
| `IgnoreOxiAccess` | `true` | Pēc Oxidized lasīšanas vai parsēšanas kļūdas atļaut izmantot iepriekšējo ierīču sarakstu; tikai failā |
| `OxidizedHome` | Tukšs | Direktorijs, kas satur `config` un `router.db` |
| `UseIdentityName` | `true` | Kā ierīces nosaukumu izmantot aktuālo RouterOS Identity vērtību |
| `backup_type` | `both` | `configuration`, `binary` vai `both` |
| `UseIncremental` | `true` | Salīdzināt jaunu pārbaudītu dublējumu ar iepriekšējo; ar `false` saglabāt katru jauno dublējumu bez salīdzināšanas |
| `export_format` | `compact` | `compact`, `terse` vai `verbose` |
| `show_sensitive` | `true` | Iekļaut sensitīvas vērtības `.rsc` |
| `encrypt` | Tukšs | `.backup` šifrēšanas parole; tukša vērtība nozīmē, ka šifrēšana netiek izmantota |
| `encrypt_type` | `aes-sha256` | Fiksēts algoritms; tikai fails |
| `clear_dns_cache` | `true` | Notīrīt DNS kešatmiņu pirms binārā dublējuma |
| `clear_console_history` | `true` | Notīrīt konsoles vēsturi pirms binārā dublējuma |
| `BackupRoot` | `backups` | Dublējumu glabāšanas saknes direktorijs |
| `UseNetFolder` | `false` | Pakešrežīmā pieprasīt atsevišķu montējumu |
| `MonthlyArchive` | `false` | Atslēgt arhivēšanu (`false`) vai iestatīt mēneša dienu no `1` līdz `28` |
| `LogLevel` | `2` | Līmenis `0`, `1`, `2` vai `3` |
| `MainLogPath` | Tukšs | Direktorijs tikai failam `main.log`; tukša vērtība nozīmē pašreizējo `BackupRoot` |
| `Login` | Tukšs | Kopīgais lietotājvārds, ko pārmanto tukšie ierīču saraksta lauki; tikai failā |
| `Password` | Tukšs | Kopīgā parole, ko pārmanto tukšie ierīču saraksta lauki; tikai failā |

Ar `Language=auto` operētājsistēmas lokalizācija izvēlas saskarni un žurnāla valodu.
Ārējam tulkojumam tiek izmantots lokalizācijas divu burtu valodas kods: piemēram, `de_DE.UTF-8` gadījumā blakus skriptam jābūt `de.lang`.
Ja nav pieejams piemērots tulkojums, tiek izmantota angļu valoda.

Parametram `MonthlyArchive` ir nedaudz citi noteikumi: `false`/`no`/`0`/`off` izslēdz arhivēšanu; `true`/`yes`/`1`/`on` nozīmē mēneša pirmo dienu; vērtības no `2` līdz `28` izvēlas attiecīgo mēneša dienu.

Kad konfigurācijas redaktors saglabā failu, tas raksta vai nu
`MonthlyArchive=false` vai izvēlēto numuru.

Būla parametri pieņem `true`/`false`, `yes`/`no`, `1`/`0` un `on`/`off`
neatkarīgi no burtu reģistra. Redaktors ieraksta `true`/`false`.

Tādi lauki kā `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` un `Password` konfigurācijas redaktorā netiek rādīti.

Saglabājot failu, redaktors raksta `IgnoreOxiAccess`, `encrypt_type` un `SshPort`.
Tas saglabā `Login` un `Password` tikai tad, ja šīs rindas jau bija iekļautas `option.cfg`, ieskaitot rindas ar tukšām vērtībām.

Lauki `SshPort`, `Login` un `Password` var noderēt, ja visās ierīcēs tiek izmantots viens SSH ports un viens lietotājs — tas pats lietotājvārds un parole. Tādā gadījumā katram `devicelist.cfg` ierakstam vajadzīgas tikai divas vērtības: ierīces **nosaukums** un tās **IP adrese**.

## Piemērs bez tīrīšanas vai paaugstināta riska eksporta

Šis ir izvēlētas politikas piemērs, **nevis rūpnīcas noklusējuma vērtību saraksts**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

Pirmās 19 atslēgas ir parādītas kanoniskā rakstīšanas kārtībā.
Pēc tam tiek saglabātas visas saderīgās esošās `Login` un `Password` līnijas.

Trūkstošie iestatījumi izmanto iebūvētās vērtības, nevis kaimiņu piemērā esošās vērtības.
Piemēram, fails, kurā ir tikai `Language=ru`, neizslēdz tīrīšanu un nemaina `show_sensitive=true`.

## Ceļi

```ini
BackupRoot=backups
MainLogPath=logs
```

Šie ieraksti nozīmē `backups` un `logs` direktorijas blakus skriptam.
Absolūtie ceļi saglabā savu nozīmi. `$HOME` un `~` netiek paplašināti
kā mainīgo lielumu vai mājas direktoriju.

Trūkstošs `BackupRoot` tiek izveidots izpildes laikā, ja to atļauj piekļuves tiesības.
Failu sistēmas saknes direktoriju `/` nedrīkst izmantot glabāšanai.
Esošajiem direktorijiem programma automātiski nelabo īpašnieku vai piekļuves tiesības.

Netukšai `MainLogPath` vērtībai jānorāda **esošs direktorijs ar rakstīšanas tiesībām**.
Pats `main.log` tiek izveidots tikai tad, kad tajā ieraksta pirmo ierakstu;
vecākdirektorijs šādi netiek izveidots. Ja žurnālā nevar rakstīt, dublējumu
apstrāde turpinās ar brīdinājumu. Šis iestatījums nepārvieto ierīču žurnālus.

<a id="network-storage"></a>
## Tīkls un atsevišķa krātuve

`UseNetFolder=true` tiek lietots pakešrežīmā. Ceļam jāatrodas zem montējuma
ieraksta, kas nav `/` ieraksts. Atsevišķā krātuve var būt tīkla krātuve,
lokāls disks vai saistītais montējums; opcijas nosaukums neierobežo failu sistēmas tipu.

Parasts direktorijs tajā pašā saknes failu sistēmā šai prasībai neatbilst.
Skripts pārbauda pieejamību un montējumu, bet neizsauc `mount`, `umount`
vai `sudo` un nemanāmi nepārslēdzas atpakaļ uz lokālo krātuvi.

## Saistītie parametri

Ar `UseIncremental=false` skripts nesalīdzina jauno dublējumu ar iepriekšējo un saglabā katru jauno failu, kas ir sekmīgi izveidots un pārbaudīts.
Šis iestatījums neietekmē pašu dublējuma izveidi vai ikmēneša arhivēšanu.
Noklusētais ir `UseIncremental=true`. Ja jūsu `option.cfg` vēl nesatur šo parametru, salīdzinājums paliek ieslēgts.

Ar `backup_type=configuration` netiek izmantota bināro dublējumu šifrēšana
vai tīrīšanas darbības pirms binārā dublējuma. Ar `backup_type=binary` netiek izmantoti `export_format`
un `show_sensitive`. Ar `UseOxidized=false` netiek izmantots `OxidizedHome`.

Ar `UseIdentityName=true` Identity nolasīšanas kļūmes gadījumā netiek izmantots
`--device-name` vai nosaukums no ierīču saraksta. Lai izmantotu norādīto nosaukumu, izslēdziet
`UseIdentityName`: skatiet [nosaukumu veidošanas noteikumus](DEVICES.md#device-names).

Ar `MonthlyArchive=true` arhivēšana notiek, kad skripts tiek palaists izvēlētajā mēneša dienā
pēc resursdatora vietējā laika. Diennakts laikam nav nozīmes.
Ja skripts šajā dienā netiek palaists, izlaistais arhivēšanas mēģinājums netiek panākts.

[BACKUPS.md](BACKUPS.md#monthly-archive) ir paskaidrots, kuri faili nonāk arhīvā, kur tas tiek izveidots un kā tas tiek nosaukts.
Datu periods, pārtraukšana un nokavēti mēģinājumi ir definēti arī
[BACKUPS.md](BACKUPS.md#monthly-archive).

Konfigurācijā var būt noslēpumi. Ierobežojiet piekļuvi tai un neiekļaujiet
to publiskā repozitorijā: [SECURITY.md](SECURITY.md).
