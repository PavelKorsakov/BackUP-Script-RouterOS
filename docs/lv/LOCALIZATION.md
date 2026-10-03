# Lokalizācija

[Atpakaļ uz pārskatu](../README_LV.md)

## Saskarnes valoda un žurnāli

Krievu (`ru`) un angļu (`en`) valoda ir iebūvēta skriptā. Tām nav vajadzīgi atsevišķi tulkojuma faili. Versijā 2.3.1 tiek piegādāti ārējie saskarnes un žurnālu tulkojumi: `de.lang`, `es.lang`, `lv.lang`, `pl.lang` un `uk.lang`.

Dokumentācijas valoda un ārēja izpildlaika tulkojuma pieejamība ir savstarpēji neatkarīgas. Tādēļ dokumentācija var būt pieejama valodā, kurai komplektā nav atbilstoša `.lang` faila.

Izvēlētā valoda tiek izmantota izvēlnēs, palīdzības tekstā, skripta ziņojumos un žurnāla ierakstos. Žurnāliem nav atsevišķa valodas iestatījuma.

<br />

## Valodas izvēle

Valodu nosaka `option.cfg` iestatījums `Language`. Tā noklusējuma vērtība ir `auto`:

| Vērtība | Izmantotā valoda |
|---|---|
| `auto` | Nosaka pēc operētājsistēmas lokalizācijas |
| `ru` | Iebūvētā krievu valoda |
| `en` | Iebūvētā angļu valoda |
| Vēl viens divu burtu kods, piemēram, `de` | Tulkojums no atbilstošā faila, piemēram, `de.lang` |

Lai krievu valodu izvēlētos pastāvīgi, failā `option.cfg` norādiet:

```ini
Language=ru
```

Vienai reizei varat izvēlēties valodu, izmantojot CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

Opcijai `--language` ir prioritāte pār opciju faila iestatījumu, taču tā nemaina pašu failu. Izmantojiet `auto` vai divu burtu valodas kodu; lielie un mazie burti netiek atšķirti.

### Automātiskā izvēle

Ar `auto` skripts ņem pirmo netukšo vērtību no `LC_ALL`, `LC_MESSAGES` un `LANG` šādā secībā.

Piemēram, `ru_RU.UTF-8` izvēlas krievu, bet `de_DE.UTF-8` izvēlas vācu tulkojumu no `de.lang`. Angļu valodā tiek izmantots `C`, `C.UTF-8`, `POSIX`, vai arī, ja valodu nevar noteikt.

Ziņojumi paliek angļu valodā arī tad, ja izvēlētais ārējais tulkojums nav pieejams.

<br />

## Ārējā tulkojuma savienošana

Direktorijā `lang/` ir gatavie ārējie tulkojumi `de.lang`, `es.lang`, `lv.lang`, `pl.lang` un `uk.lang`, kā arī kanoniskā veidne `en.lang`. Lai izmantotu ārēju tulkojumu, pārkopējiet nepieciešamo failu mapē, kas satur `mikrotik-backup.sh`.

Piemēram, lai instalētu vācu tulkojumu, skripta direktorijā izpildiet:

```bash
cp -- lang/de.lang de.lang
```

Pēc tam izvēlieties `de` iestatījumos vai norādiet to, sākot skriptu:

```bash
mikrotik-backup.sh --language=de --help
```

Faila nosaukums sastāv no diviem latīņu burtiem un `.lang` paplašinājuma, piemēram, `de.lang`. Tam jābūt parastam lasāmam failam, nevis simboliskai saitei.

*(Piezīme. Direktorijā `lang/` glabājas tulkojumu kolekcija. Skripts neielādē tos automātiski no šīs mapes: nepieciešamais fails jānovieto blakus pašam skriptam.)*

`en.lang` satur visas 245 versijas 2.3.1 atslēgas un ir kanoniskā veidne trešo pušu tulkojumu izveidei. Tas neaizstāj iebūvēto angļu valodu un netiek izmantots kā ārēja izpildlaika valoda. Arī `ru.lang`, ja tādu izveido, neaizstāj iebūvēto krievu valodu un tiek ignorēts.

<br />

## Valodas izvēle konfigurācijas redaktorā

Atveriet redaktoru ar:

```bash
mikrotik-backup.sh -e
```

Pārejiet uz valodas rindu → spiediet **Enter**, līdz parādās vajadzīgā vērtība → izvēlieties **Saglabāt**.

Vērtības mainās šādā ciklā:

```text
auto → ru → en → atrastās ārējās valodas alfabētiskā secībā → auto
```

Veidlapas valoda mainās uzreiz. Kamēr izmaiņas nav saglabātas, tas ir tikai priekšskatījums; **Atcelt** atjauno iepriekšējo saskarnes valodu. Ja palaišanas laikā norādīts `--language`, šī komandrindas opcija atkal stājas spēkā pēc iziešanas no redaktora.

Saglabātā `option.cfg` komentāros tiek izmantota paša iestatījuma `Language` izvēlētā valoda, nevis pagaidu komandrindas opcija. Ar `auto` arī šo komentāru valodu nosaka operētājsistēmas lokalizācija.

Vairāk par redaktoru skatīt [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Tulkojuma izveide un rediģēšana

Ja vajadzīgā tulkojuma vēl nav, varat to sagatavot pats. Ņemiet tās pašas skripta versijas `lang/en.lang` un saglabājiet kopiju kā `<xx>.lang`, kur `xx` ir jaunās valodas divu burtu kods. Versijas 2.3.1 veidnē ir visas 245 atslēgas.

Formāts ir vienkāršs: katram ziņojumam ir sava rinda. Piemēram, angļu veidne satur:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Katra atslēga sākas ar `msg_`; pēc tam seko ziņojuma nosaukums (`version`, `menu_title`) un valodas sufikss `_en`.

Jaunai valodai aizstājiet sufiksu `_en` ar `_xx` visās atslēgās un tulkojiet tikai pēdiņās esošās vērtības. Nemainiet ziņojumu nosaukumus un precīzi saglabājiet visus placeholders. Lai labotu esošu tulkojumu, pietiek mainīt vajadzīgo tekstu pa labi no `=`.

Viss fails nav jāiztulko uzreiz: trūkstošie ziņojumi tiek rādīti angļu valodā. Skripts neizmanto patvaļīgi pievienotas jaunas atslēgas.

### Failu formāta noteikumi

Saglabājiet failu UTF-8 kodējumā. Katru vērtību lieciet pēdiņās un neatstājiet to tukšu. Nelieciet atstarpes pirms atslēgas, ap `=` zīmi vai pēc noslēdzošās pēdiņas.

Dubultpēdiņai tekstā izmantojiet `\"`, bet atpakaļvērstajai slīpsvītrai — `\\`. Citas atsoļa virknes, tostarp `\n` un `\t`, nav atļautas. Pēdiņās drīkst būt rakstzīme `=`.

Tukšās rindas tiek izlaistas. `.lang` formātā komentāru nav; pēdiņās esoša `#` zīme ir teksta daļa. Tiek atbalstītas Windows rindu beigas (CRLF) un viena BOM atzīme faila sākumā.

Nederīga rinda tiek izlaista, bet pārējie derīgie tulkojumi tiek izmantoti. Ja ziņojums norādīts vairākkārt, uzvar pēdējais derīgais ieraksts. Tulkojumos nav atļautas vadības rakstzīmes un termināļa krāsu kodi.

*(Piezīme. Lokalizācijas fails tiek uzskatīts par teksta datiem. Mainīgie nav paplašināti un no tā netiek izpildītas čaulas komandas.)*

### Vietturīši ziņojumos

Dažās virknēs ir vērtību vietturīši figūriekavās, piemēram:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Izpildes laikā skripts aizstāj `{index}` un `{total}` ar ierīces kārtas numuru un kopējo ierīču skaitu. Netulkojiet šos marķierus: katru avota virknes vietturi saglabājiet tieši vienu reizi. Tā vietu teikumā drīkst mainīt.

Ja vietturīši nav derīgi, šīs virknes vietā tiek izmantots angļu ziņojums.

Pēc faila saglabāšanas pārbaudiet tulkojumu gan palīdzības tekstā, gan interaktīvajā izvēlnē ar izvēlēto valodu. Iemesli, kuru dēļ tulkojums var netikt ielādēts, aprakstīti sadaļā [Problēmu novēršana](TROUBLESHOOTING.md#language-problems).
