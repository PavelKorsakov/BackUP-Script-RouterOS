# Ierīču saraksts

[Atpakaļ uz pārskatu](../README_LV.md)

## Dublējamās ierīces: fails devicelist.cfg

Kā norāda nosaukums, `devicelist.cfg` uzskaita pakešrežīmā dublējamās ierīces un savienojumam vajadzīgos datus.
Novieto failu tieši blakus `mikrotik-backup.sh`.
Jūs varat izveidot `devicelist.cfg` manuāli vai caur BackUP Master.
Trešā iespēja noder, ja tajā pašā serverī darbojas Oxidized. Pēc attiecīgo iestatījumu pievienošanas opciju failam
skripts katrā palaišanas reizē dinamiski izveido `devicelist.cfg`, izmantojot vajadzīgos datus no Oxidized konfigurācijas failiem.

<br />

## Saraksta izveide un rediģēšana

Lai izveidotu sarakstu caur BackUP Master, palaist:

```bash
mikrotik-backup.sh -b
```

Aizpildiet ierīces nosaukumu, adresi, lietotājvārdu, paroli un SSH portu → izvēlieties **2. Saglabāt ierīci failā devicelist.cfg**.
BackUP Master vai nu izveido failu ar nepieciešamo ierakstu, vai pievieno vai atjaunina ierakstu esošajā failā.

Gatavo sarakstu var rediģēt parastā teksta redaktorā. BackUP Master neielādē esošos ierakstus savā veidlapā.

*(Piezīme. Saglabājot portu `22`, BackUP Master ieraksta tukšu lauku. Šim ierakstam pakešrežīmā tiek izmantots skripta iestatījums `SshPort`. Nestandarta ports tiek ierakstīts tieši.)*

<br />

## Faila formāts

Katru ierīci ierakstiet atsevišķā rindā. Laukus atdaliet ar **TAB rakstzīmi**, nevis atstarpēm. Lauku secība ir šāda:

| Pozīcija | Aile | Mērķis |
|---|---|---|
| 1 | Nosaukums | Ierīces nosaukums; vajadzīgs |
| 2 | Adrese | Ierīces IP adrese vai DNS nosaukums; nepieciešams |
| 3 | Lietotājvārds | RouterOS ierīces lietotājvārds; ja nav norādīts, tiek pārmantots `Login` no `option.cfg` |
| 4 | Parole | RouterOS ierīces parole; ja nav norādīta, tiek pārmantota `Password` no `option.cfg` |
| 5 | Ports | SSH ports no `1` līdz `65535`; ja nav norādīts, tiek pārmantots `SshPort`, kura noklusējums ir `22` |
| 6 | Ierīces marķieris | `MikroTik`; var būt tukšs. Lielo un mazo burtu atšķirība netiek ņemta vērā |

Lauki no septītā uz priekšu netiek izmantoti. Ieraksti ar citu ierīces marķieri tiek izlaisti.

### Piemēru saraksts

Laukus šajā piemērā atdala ar faktiskām TAB rakstzīmēm:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

Otrajā rindā ports nav norādīts: starp paroli un `MikroTik` ir divas TAB rakstzīmes. Aizstājiet adreses un autentifikācijas datus ar saviem.

### Kopīgs lietotājvārds, parole un ports

Ja visas jūsu ierīces izmanto vienus un tos pašus akreditācijas datus, norādiet tos vienu reizi `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Tad `devicelist.cfg` nepieciešams tikai katras ierīces nosaukums un adrese:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Ierīces ierakstā tieši norādītie autentifikācijas dati aizstāj kopīgās vērtības.

*(Piezīme. Ierīču saraksta fails satur paroles. Ierobežot piekļuvi kā aprakstīts [SECURITY.md](SECURITY.md).)*

<br />

## Kā lasīt sarakstu

Tukšās rindas un rindas, kuru pirmā rakstzīme pēc atkāpēm ir `#`, tiek ignorētas. Komentārus rakstiet atsevišķās rindās; laukā esoša `#` zīme ir tā vērtības daļa.

Nosaukuma, adreses, porta un marķiera sākuma un beigu atstarpes tiek noņemtas. Lietotājvārds un parole tiek nolasīti burtiski, tostarp atstarpes un pēdiņas. Tiek atbalstītas Windows rindu beigas (CRLF).

Ja rindā trūkst obligātas vērtības vai ir sintakses kļūda, skripts izpildes laikā to izlaiž un brīdina, ka ieraksts nav derīgs.

Ja rinda kāda iemesla dēļ atkārtojas, proti, sakrīt visi četri savienojuma parametri (**adrese, lietotājvārds, parole un ports**), skripts savienojas ar ierīci tikai vienreiz, izmantojot pēdējā ieraksta datus.
Ja atšķirīgiem savienojumiem ir vienāds nosaukums, tiek izmantots pirmais derīgais ieraksts, bet konfliktējošais ieraksts tiek izlaists.

<br />

<a id="device-names"></a>
## Ierīces nosaukums

Nosaukums tiek izmantots rezerves kopiju failu nosaukumos un, pakešrežīmā, ierīces apakšdirektorijā.
`UseIdentityName` iestatījums `option.cfg` nosaka, no kurienes cēlies nosaukums:

| Vērtība | Nosaukums |
|---|---|
| `true` (noklusējums) | Identitātes vērtība uz pašas RouterOS ierīces |
| `false` | Nosaukums no `devicelist.cfg`, BackUP Master lauka vai `--device-name` vienas ierīces komandrindas palaišanā |

### Nosaukums iekavās

Ja sākotnējā nosaukumā ir iekavas, skripts izmanto pirmās pilnās netukšās iekavu grupas saturu. Ja šādas grupas nav, tiek izmantots viss nosaukums.

| Sākotnējais nosaukums | Rezerves kopijas nosaukums |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Atļautās rakstzīmes

Gala nosaukumā tiek saglabāti burti, tostarp kirilicas burti, cipari, punkti, defises un pasvītrojuma zīmes. Atstarpes un neatļautās rakstzīmes tiek aizstātas ar `_`. Atkārtotas, sākuma un beigu pasvītrojuma zīmes tiek noņemtas; tāpat tiek noņemti punkti un defises nosaukuma sākumā un punkti tā beigās.

Piemēram, `ЦОД Москва №1` kļūst par `ЦОД_Москва_1`.

Gala nosaukuma garumam jābūt **no 1 līdz 32 rakstzīmēm**. Nosaukums netiek saīsināts; pārsniegums izraisa kļūdu. Rezervētie nosaukumi `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` un `LPT1`–`LPT9` nav atļauti.

Gala nosaukumiem jābūt unikāliem neatkarīgi no burtu reģistra: `Router-A` un `router-a` tiek uzskatīti par vienādiem. Otra ierīce ar šo nosaukumu attiecīgajā palaišanā tiek izlaista.

*(Piezīme. Gala nosaukuma maiņa maina arī ierīces apakšdirektoriju. Vecie dublējumi netiek pārvietoti automātiski.)*

<br />

## Importējot no Oxidized

Ja ierīču sarakstu jau glabājat Oxidized, skripts to var iegūt no turienes. Pievienojiet failam `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Parametrā `OxidizedHome` norādiet direktoriju, kurā atrodas `config` un `router.db`. No tiem skripts izveido `devicelist.cfg`. Oxidized faili netiek mainīti.

*(Piezīme. Imports aizstāj `devicelist.cfg`, nevis papildina to. Manuālie papildinājumi tiks zaudēti nākamajā veiksmīgajā Oxidized atjaunināšanas reizē.)*

### Avota iestatījumi

Oxidized konfigurācijai jāizmanto `csv` avots ar vienas rakstzīmes atdalītāju. `source.csv.map` nosaka kolonnu secību; numerācija sākas no nulles:

| Kartes lauks | Izmantotā vērtība |
|---|---|
| `name` | Ierīces nosaukums; nepieciešamā kolonna |
| `ip` | Ierīces adrese; ja nav norādīta, tiek izmantota `name` vērtība |
| `username` | Lietotājvārds; ja nav norādīts, tiek izmantots kopīgais `Login` no `option.cfg` |
| `password` | Parole; ja izlaista, tiek izmantota koplietotā `Password` no `option.cfg` |
| `port` | SSH ports; ja izlaists, tiek lietots `SshPort` |
| `model` | Ierīces modelis; ja kolonnas nav, tiek izmantots saknes parametrs `model` |

`model_map` noteikumiem izmanto pirmo atbilstību. Tiek importētas tikai ierīces, kuru gala modelis ir `routeros`. Ja kolonna `model` pastāv, saknes parametrs neaizstāj tukšās vērtības šajā kolonnā.

Dati vienmēr tiek lasīti no `<OxidizedHome>/router.db`. Oxidized `source.csv.file` parametrs nemaina šo ceļu.

### Ja imports neizdodas

Ja Oxidized faili nav pieejami, to formāts nav atbalstīts vai nav atrastas piemērotas ierīces, iepriekšējā `devicelist.cfg` tiek saglabāta.

Ar `IgnoreOxiAccess=true` skripts var izmantot iepriekšējo derīgo sarakstu. Ar `false` vecais saraksts dublēšanai netiek izmantots.

Importēšanas kļūda ietekmē palaišanas rezultātu pat tad, ja rezerves kopēšana ar iepriekšējo sarakstu izdodas.

Plašāku informāciju par saraksta un importa kļūdām skatiet [Problēmu novēršanā](TROUBLESHOOTING.md).
