# Drošība

[Atpakaļ uz pārskatu](../README_LV.md)

## Konti

Skriptam nav vajadzīgas **root** privilēģijas. Parastam lietotājam nepieciešama tikai piekļuve konfigurācijas failiem un rakstīšanas tiesības izvēlētajā krātuvē un žurnālu mapēs.

Atsevišķa lietotāja **bsmt** izveidošana un skripta palaišana ar šo kontu aprakstīta [INSTALL.md](INSTALL.md#running-the-script-automatically).

Arī RouterOS ierīcē ieteicams izveidot atsevišķu rezerves kopiju lietotāju un atļaut tam pieteikties tikai no skripta resursdatora IP adreses. Kontam jābūt tiesībām veikt izvēlētās darbības: eksportēt konfigurāciju, izveidot un lejupielādēt rezerves kopijas, dzēst pagaidu failus un veikt iespējotās tīrīšanas darbības.

<br />

<a id="connecting-to-routeros"></a>
## Savienojums ar RouterOS

Skripts savienojas pa SSH, izmantojot paroles autentifikāciju. SSH atslēgas un SSH aģents netiek izmantots. Faili tiek lejupielādēti ar klasisko SCP protokolu, proti, `scp -O`.

Skripts izmanto savus savienojuma iestatījumus. Tas nelasa lietotāja `~/.ssh/config` vai sistēmas SSH konfigurāciju, jo klients tiek palaists ar `-F /dev/null`. Aģenta, X11 un portu pārsūtīšana ir atspējota.

**Lūdzu, ievērojiet!!! Resursdatora atslēgas pārbaude ir atspējota.**

Pašreizējais profils izmanto šādus iestatījumus:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Parastie `known_hosts` faili netiek ne lasīti, ne mainīti. Tādēļ skripts nepārbauda, vai atbild tieši gaidītā ierīce, nevis uzbrucējs. Ņemiet to vērā, organizējot tīkla piekļuvi maršrutētājiem.

<br />

<a id="secrets"></a>
## Paroles skripta palaišanas laikā

Parole, kas nodota ar `--password` vai `-p=`, kļūst par palaišanas komandas daļu. Tā var būt redzama procesa argumentos un saglabāties čaulas vēsturē. Tas pats attiecas uz šifrēšanas paroli, kas nodota ar `--encrypt`.

### Paroļu ievadīšana BackUP Master

Lai SSH parole nebūtu jāievieto komandrindā, palaidiet BackUP Master:

```bash
mikrotik-backup.sh -b
```

Ievadiet ierīces piekļuves datus veidlapā un izvēlieties vajadzīgo darbību. Abas paroles tiek rādītas kā zvaigznītes; ievadītās vērtības nenonāk čaulas komandu vēsturē.

Savienojuma laikā skripts pats nodod SSH paroli `sshpass` pa faila deskriptoru (`-d`), nevis argumentā `sshpass -p` vai vides mainīgajā `SSHPASS`.

### `.backup` šifrēšanas parole

Šifrēšanas parole ir daļa no RouterOS komandas, kas tiek nodota `ssh` apakšprocesam. Tāpēc resursdatora lietotājs ar pietiekamām tiesībām skatīt procesa argumentus binārās rezerves kopijas veidošanas laikā var redzēt šo paroli.

Tas nemainās atkarībā no tā, vai parole ievadīta BackUP Master vai saglabāta `option.cfg`. Faila šifrēšana neaizsargā paroli no paša rezerves kopiju resursdatora administratora.

### Konsoles komandas kopēšana

BackUP Master darbība **3. Kopēt konsoles komandu** ievieto starpliktuvē komandu ar savienojuma datiem un, ja binārajai rezerves kopijai tā ir iestatīta, arī šifrēšanas paroli.

Ņemiet to vērā, izmantojot starpliktuves vēsturi un ielīmējot komandu čaulā. Zvaigznītes veidlapā nenozīmē, ka parole ir maskēta arī nokopētajā komandā.

<br />

## Faili ar sensitīviem datiem

| Fails | Iespējamais saturs |
|---|---|
| `devicelist.cfg` | Ierīču adreses, lietotājvārdi un SSH paroles atklātā tekstā |
| `option.cfg` | Kopīgās `Login` un `Password` vērtības un šifrēšanas parole `encrypt` |
| `.rsc` un `.backup` | Ierīces konfigurācija, paroles un citi sensitīvi dati |
| Ikmēneša ZIP arhīvs | Tās pašas rezerves kopijas un žurnāli vienā arhīvā |

Neievietojiet darba konfigurācijas failus vai rezerves kopijas publiskā repozitorijā vai publiski pieejamā mapē.

### Sensitīvi dati `.rsc` failos

Pēc noklusējuma ir spēkā `show_sensitive=true`, tādēļ sensitīvās vērtības tiek iekļautas teksta eksportā. Lai to izslēgtu, failā `option.cfg` norādiet:

```ini
show_sensitive=false
```

Arī tad fails joprojām ir ierīces konfigurācija: tajā paliek adreses, tīkla uzbūve, komentāri un citas lietotāja ievadītas teksta virknes.

### Bināro rezerves kopiju šifrēšana

Pēc noklusējuma `encrypt` ir tukšs un `.backup` tiek saglabāts nešifrēts.

```ini
encrypt=MySuperPassword
```

Tiek izmantots AES-SHA256 algoritms. Tas šifrē **tikai `.backup`**, nevis `.rsc`, `option.cfg`, ierīču sarakstu, žurnālus vai pašu ZIP arhīvu. Tādēļ piekļuve ikmēneša arhīvam jāierobežo tikpat rūpīgi kā piekļuve tajā ievietotajiem failiem.

<br />

## Failu un krātuves atļaujas

Skripts darbojas ar `umask 077`. Jaunām lokālās krātuves mapēm, ko tas izveido, tiek piešķirts režīms `0700`; programmiski saglabātiem `option.cfg` un `devicelist.cfg` — režīms `0600`.

Esošu, administratora izveidotu krātuves mapju īpašnieks un atļaujas netiek mainītas automātiski. Ja mapi sagatavojat pats, jums pašam jākonfigurē piekļuve tai.

Lokālajai ikmēneša arhīvu mapei `archive/` jābūt režīmam `0700`, un tai jāpieder lietotājam, kas palaiž skriptu. Tas attiecas arī uz jau esošu mapi. Skripta izveidotajiem lokālajiem arhīva failiem ir režīms `0600`.

Pakešapstrādē ar pārbaudītu tīkla krātuvi un `UseNetFolder=true` NAS serveris var noteikt arhīva objektu īpašniekus un atļaujas. Atšķirība no lokālajām vērtībām pati par sevi neaptur arhivēšanu. Konfigurējiet tīkla krātuves piekļuvi operētājsistēmā un NAS.

Mapju sagatavošanas un piekļuves piešķiršanas piemēri lietotājam **bsmt** sniegti [INSTALL.md](INSTALL.md).

*(Piezīme. Skripts nolasa konfigurāciju, ierīču sarakstu, tulkojumus un izmantotos Oxidized iestatījumus kā datus; tas neizpilda tos kā čaulas skriptus.)*

<br />

## Izmaiņas ierīcē

Pēc noklusējuma pirms binārā dublējuma izveides tiek iztīrīta RouterOS DNS kešatmiņa un konsoles vēsture. Ja šīs darbības nav vajadzīgas, izslēdziet tās failā `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Abas darbības var atspējot konfigurācijas redaktorā, BackUP Master vai ar attiecīgajām CLI opcijām. Ja tiek lejupielādēts tikai `.rsc`, šīs tīrīšanas darbības netiek veiktas.

<br />

## Žurnāli un diagnostikas informācijas kopīgošana

Detalizācijas līmenis `LogLevel=3` pievieno informāciju par apstrādes posmiem; tas neizvada paroles vai pilnas savienojuma komandas.

Apstrādātā SSH diagnostika maskē precīzi zināmās adreses, lietotājvārda, SSH paroles un šifrēšanas paroles vērtības. Tas negarantē ne rezerves kopiju satura sanitizēšanu, ne visu noslēpumu izņemšanu no patvaļīga teksta.

Pagaidu faili ar neapstrādātu diagnostiku var saturēt sensitīvus datus. Tie tiek izveidoti režīmā `0600` un parastās tīrīšanas laikā noņemti.

Pirms žurnālu, ekrānattēlu vai komandu izvades nosūtīšanas pārbaudiet to saturu. Pilns `devicelist.cfg` saturs, procesu saraksts vai starpliktuves saturs var atklāt datus, kuru parastajā žurnālā nav.

Vairāk par žurnāla ierakstiem skatiet [LOGGING.md](LOGGING.md); kļūdu izmeklēšanai — [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Vienlaicīgas izpildes

Viena lietotāja izpildēm ar vienādu `BackupRoot` tiek izmantotas šādas bloķēšanas:

| Vienlaicīgas izpildes | Darbība |
|---|---|
| Pakešizpilde un cita pakešizpilde vai vienas ierīces izpilde | Otrā izpilde bloķēšanu neiegūst |
| Divas vienas ierīces izpildes tai pašai ierīcei | Otrā izpilde bloķēšanu neiegūst |
| Vienas ierīces izpildes dažādām ierīcēm | Tās var darboties vienlaikus |

Ja bloķēšana ir aizņemta, skripts beidz darbu ar kodu `32`. Dažādas krātuves saknes netiek koordinētas kā viena krātuves zona, pat ja viena atrodas otras iekšienē.

Bloķēšanas faili atrodas `/tmp/mikrotik-backup-${UID}/` un paliek tur arī pēc skripta beigām. To esamība pati par sevi nenozīmē, ka skripts vēl darbojas.

**Nedzēsiet šos failus, lai „notīrītu novecojušu bloķēšanu“.** Bloķēšana ir piesaistīta procesa atvērtam faila deskriptoram, nevis faila esamībai. Turklāt šīs bloķēšanas neaizsargā datus no citas programmas, kas tos maina tieši.

<br />

## Atjaunošanas pārbaude

Skripta kontrolsummas pārbaude un sekmīga rezerves kopijas faila lejupielāde neaizstāj atjaunošanas pārbaudi.

Skripts pats RouterOS neatjauno. Jums atsevišķi jāpārbauda, vai rezerves kopijas var izmantot piemērotā ierīcē, un jānosaka to glabāšanas ilgums. Plašāk skatiet [BACKUPS.md](BACKUPS.md).
