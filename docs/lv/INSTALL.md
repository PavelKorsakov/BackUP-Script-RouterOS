# Uzstādīšana

[Atpakaļ uz pārskatu](../README_LV.md)

## Prasības resursdatoram

Skriptam ir vajadzīga Linux sistēma ar GNU Bash **4.4 vai jaunāku versiju** un standarta GNU failu utilītām.
Pašam skriptam nav nepieciešama kompilācija, Python, konteiners vai datubāze.
Tomēr tam ir vajadzīgas sadaļā [Atkarības](#dependencies) uzskaitītās utilītas.

Ierīču nosaukumu apstrādei vajadzīga darbspējīga **`C.UTF-8`** lokalizācija, kas ļauj skaitīt daudzbaitu rakstzīmes, atpazīt burtus un mainīt burtu reģistru.
Pirms darba ar ierīcēm skripts pārbauda šīs iespējas. Tā ir sistēmas prasība, nevis atsevišķa programma ar nosaukumu `C.UTF-8`.

Resursdatoram, protams, jābūt tīkla piekļuvei RouterOS SSH pakalpojumam un rakstīšanas tiesībām izvēlētajā krātuvē.

**Stingri ieteicams!!!**
Skripts savienojas ar RouterOS ierīcēm pa SSH, izmantojot paroles autentifikāciju, nevis autentifikāciju ar atslēgu.
(*Precīzu transporta politiku skatiet [SECURITY.md](SECURITY.md).*)
Tāpēc ierīcē ieteicams izveidot atsevišķu lietotāju un atļaut tam pieteikties tikai no tā resursdatora IP adreses, kurā darbojas skripts.

<br />

<a id="dependencies"></a>
## Atkarības

### Dublēšanai obligātās utilītas

Lai izveidotu dublējumus, ir vajadzīgas **visas** šīs utilītas:

| Utilītas | Mērķis |
|---|---|
| `ssh`, `scp`, `sshpass` | Savienoties ar RouterOS, izpildīt komandas un iegūt failus |
| GNU `timeout`, `sleep` | Ierobežot darbību ilgumu un ieviest pauzes |
| `sha256sum` | Aprēķināt kontrolsummas |
| `realpath` | Noteikt absolūtos ceļus |
| `flock` | Bloķēšana, kas novērš vienlaicīgu palaišanu konfliktus |

**Ja trūkst obligātas utilītas, skripts ziņo par neizpildītām atkarībām
un aptur dublēšanas mēģinājumu.
Atkarību kļūdas kods ir `30`. Tā ir paredzētā darbība.**

Saraksts ir vienāds gan vienas ierīces, gan pakešrežīma dublēšanai neatkarīgi no tā, vai
skripts izveido `.rsc`, `.backup` vai abus formātus.

Ar komandām, kurām ir tikai šādi nosaukumi, nepietiek. Instalētajam OpenSSH jāatbalsta
skripta izmantotās opcijas, tostarp mantotais SCP režīms, ko izvēlas `scp -O`.
GNU `timeout` jāatbalsta `--signal` un `--kill-after`.
Šīs iespējas tiek pārbaudītas lokāli, neveidojot savienojumu ar maršrutētāju.

<br />

### Atsevišķām funkcijām vajadzīgās utilītas

Šie rīki nav iekļauti vispārējā obligāto utilītu sarakstā. Tie ir vajadzīgi tikai tad,
ja izmantojat attiecīgo funkciju.

| Funkcija | Prasība | Kas notiek, ja tās nav |
|---|---|---|
| Pakešrežīms ar `UseNetFolder=true` | `findmnt` | Dublēšana šajā režīmā netiek sākta; atkarību kļūda `30` |
| Palaišana, kurā jāveic ikmēneša arhivēšana | Info-ZIP `zip`, `unzip`, GNU `mv` | Palaišana apstājas atkarību pārbaudē pirms dublēšanas; kļūda `30` |
| Interaktīva izvēlne, konfigurācijas redaktors un BackUP Master | `stty` un terminālis uz standarta ieejas un izejas | Interaktīvais ekrāns neatveras; termināla kļūda `31` |
| **Kopēt konsoles komandu** programmā BackUP Master | GNU `base64` ar `--wrap=0` atbalstu | Komandu nevar nokopēt; kļūda `30` |

Piemēram, ja ikmēneša arhivēšana nav paredzēta, `zip` trūkums netraucē parastai dublēšanas palaišanai.
`base64` trūkums netraucē izveidot dublējumus.
*(Piezīme. Tā ir vajadzīga, kad izvēlaties **Kopēt konsoles komandu**.)*

Vispārējā atkarību pārbaude notiek pirms dublēšanas, nevis katrā programmas atvēršanas reizē.
Tāpēc palīdzība, versijas informācija vai izvēlne var būt pieejama arī tad, ja dublēšanas utilītas nav instalētas.

<br />

### Linux pamatvide

Skripts arī pieņem, ka ir pieejamas parastās sistēmas komandas darbam ar failiem
un direktorijiem, tostarp `date`, `stat`, `mkdir`, `cp`, `ln` un `rm`.

Tās ir operētājsistēmas pamatvides daļa. Iepriekš pārbaudīto atkarību saraksts
nav pilns visu skripta izmantoto ārējo komandu uzskaitījums. Ja trūkst sistēmas
pamatkomandas, attiecīgā darbība var neizdoties, nevis parādīt ziņojumu par
neizpildītu atkarību.

<br />

### Vajadzīgo pakotņu instalēšana Debian/Ubuntu

Šis piemērs instalē obligātos rīkus un iepriekš minētos neobligātos rīkus:
*(Piezīme. Šeit un zemāk lietotājam tiek pieņemts, ka viņam ir administratora privilēģijas.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Skripta failu iegūšana

Versijas 2.3.1 galvenais instalēšanas veids ir pilnais GitHub Release resurss `mikrotik-backup-2.3.1.zip`. Tas tiek izpakots tieši instalēšanas direktorijā bez papildu ietverošas mapes.
*(Piezīme. Piemēros, kuros faili tiek ievietoti zem `/opt`, izpildiet komandas ar tiesībām izveidot šo direktoriju un tajā rakstīt.)*

### 1. iespēja: pilnā laidiena pakotne

Lejupielādējiet `mikrotik-backup-2.3.1.zip` no MikroTik Backup Script 2.3.1 GitHub Release un izpildiet:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Pēc izpakošanas lietošanai gatavā struktūra ir:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Ja kontrolsummas pārbaude neizdodas, nedarbiniet skriptu, kamēr nav noskaidrots iemesls.

<br />

### 2. iespēja: minimāla savrupa instalācija

Lejupielādējiet resursus `mikrotik-backup.sh` un `SHA256SUMS` no tā paša Release aizsargātā direktorijā, pārbaudiet tos un padariet skriptu izpildāmu:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Lejupielādējiet abus Release resursus šajā direktorijā.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Ārējai izpildlaika valodai izmantojiet pilno pakotni vai iegūstiet atbilstošo `.lang` failu no tās pašas versijas avota ar tagu.

<br />

### Papildu variants: Git vai pirmkoda arhīvs

Šī repozitorija Git klons vai **Code → Download ZIP** arhīvs arī ir pilns produkta pirmkoda koks. Noderīgā saknes struktūra ir:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` ir Release artefakts un pirmkoda checkout var nebūt. Parastai instalēšanai joprojām ieteicama versijai piesaistītā Release pakotne, jo tajā ir kontrolsummas fails un tieši publicētās versijas faili.

<br />

## Faili blakus skriptam

Pēc pilnās Release pakotnes izpakošanas izvēlētajā direktorijā ir skripts un tā pavadošie faili:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Fails vai mape | Mērķis |
|---|---|
| mikrotik-backup.sh | Pats dublēšanas skripts |
| SHA256SUMS | Kontrolsummas lejupielādēto failu pārbaudei |
| README.md | Produkta apraksts un saites uz detalizēto dokumentāciju |
| lang/ | Lokalizācijas faili. Nokopējiet vajadzīgās valodas failu no šī direktorija uz skripta direktoriju. |
| docs/ | Detalizēta instalēšanas, konfigurēšanas un lietošanas dokumentācija |

Faktiskai darbībai nepieciešams tikai `mikrotik-backup.sh`.
Lai mainītu iestatījumus, izveidojiet **option.cfg** un novietojiet to blakus skriptam.
Ja plānojat vaicāt un dublēt vairākas ierīces pēc kārtas, izveidojiet arī **devicelist.cfg** blakus skriptam.
Lokalizācijas fails ar nosaukumu `<xx>.lang` ir nepieciešams, ja vēlaties izvēlnes un žurnalēšanas ierakstus savā valodā. Ievietojiet to tajā pašā mapē, kā `mikrotik-backup.sh`.
Krievu un angļu valodā nav nepieciešami atsevišķi lokalizācijas faili, jo abi ir iebūvēti skriptā.

**Interaktīvajā režīmā skripts var izveidot un saglabāt:**
ierīču sarakstu — **devicelist.cfg** — ar BackUP Master;
konfigurācijas failu — **option.cfg** — ar konfigurācijas redaktoru.
Tos var sagatavot arī manuāli:
*TSV ierīču saraksta formāts detalizēti aprakstīts [DEVICES.md](DEVICES.md).*
*`Key=value` konfigurācijas faila formāts detalizēti aprakstīts [OPTIONS.md](OPTIONS.md).*

<br />

## Krātuves un žurnālu sagatavošana

Ar noklusējuma dublēšanas iestatījumiem skripts blakus sev izveido direktoriju `./backups` un tajā saglabā ierīču dublējumus.
Režīmi atšķiras tikai ar to, ka vienas ierīces palaišana ievieto izveidotos failus tieši `./backups`, bet pakešrežīms zem `./backups` izveido ierīces nosaukumam atbilstošu apakšdirektoriju un tajā glabā šīs ierīces dublējumus.

Skripts pats izveido vajadzīgos krātuves direktorijus ar atbilstošām piekļuves tiesībām.
*(Tas automātiski nemaina esošo administratora izveidoto direktoriju īpašnieku vai piekļuves režīmu.)*

Pēc noklusējuma skripta galvenais žurnāls, `main.log`, tiek glabāts `./backups`.
Pakešrežīmā ierīces žurnāls tiek glabāts attiecīgās ierīces apakšdirektorijā.

Ja dublējumu direktorijs atrodas tīkla krātuvē, skripts pakešapstrādes laikā var pārbaudīt tā pieejamību. Šī opcija pēc noklusējuma ir izslēgta un pirms lietošanas jākonfigurē.
*(Direktorija montēšanas veidam nav nozīmes.)*

Visas šīs opcijas var mainīt, iestatot nepieciešamos parametrus `option.cfg`.
Norādījumus un parametru sintaksi skatiet sadaļā [Konfigurācija](OPTIONS.md).

<br />

<a id="running-the-script-automatically"></a>
## Automātiska skripta darbināšana

Pirms ieslēdzat grafiku, sagatavojiet iestatījumus un ierīču sarakstu.
Pretējā gadījumā automātiska palaišana nevarēs veikt pakešrežīma dublēšanu.

Skripta darbināšanai nav obligāti jāizveido atsevišķs lietotājs, taču šādu darbību veikšana kā **root** tiek uzskatīta par sliktu praksi. Nākamajā piemērā izveidots atsevišķs lietotājs.

Izveidojiet lietotāju **bsmt** *(varat izvēlēties citu nosaukumu; tad piemēros aizstājiet **bsmt**)* un piešķiriet tam tikai vajadzīgās tiesības:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Ja skripts jau ir darbināts kā root**

*(Piezīme. Ja iepriekš skripts darbināts kā **root**, tā izveidotie direktoriji, dublējumi
un žurnāli var nebūt pieejami lietotājam **bsmt**.
Pirms grafika iespējošanas nododiet esošo krātuvi šim lietotājam.)*

Šis piemērs izmanto lokālo `/opt/mikrotik-backup/backups` mapi.
Šī komanda maina direktorija un visa tā satura īpašnieku un grupu:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(Piezīme. Norādiet šī skripta rezerves mapi, nevis kopīgotu mapi, kas satur arī datus no citām programmām.
Ja krātuve vai galvenais žurnāls atrodas citur, konfigurējiet piekļuvi katram atsevišķam atbilstoši izvēlētās krātuves atļaujām un iestatījumiem, ievērojot to pašu modeli.)*

Šis piemērs atver konfigurācijas redaktoru kā lietotājs **bsmt**, kad tam jau ir piešķirta piekļuve skripta direktorijam un failiem:
*(Piezīme. Palaist komandu kā root vai kā lietotājam atļauts to darīt caur sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Skripta grafika izveide**

Šajā piemērā grafiks tiek izveidots ar systemd,
taču varat izmantot crontab vai jebkuru citu piemērotu metodi.

Tiks izveidots serviss, kas darbina skriptu ar atsevišķā lietotāja tiesībām, un taimeris, kas to palaiž pēc grafika.
*(Piemērā palaišana notiek katru dienu plkst. 1.00, taču grafiku izvēlaties jūs.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` neiespējo nokavētas palaišanas panākšanu pēc laika, kad taimeris bijis izslēgts.
`Restart=no` pēc kļūdas neieplāno automātisku servisa atkārtotu palaišanu.*
