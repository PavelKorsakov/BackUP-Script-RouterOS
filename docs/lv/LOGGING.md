# Žurnalēšana

[Atpakaļ uz pārskatu](../README_LV.md)

## Galvenais žurnāls un ierīču žurnāli

Skripts reģistrē kopējo izpildes gaitu galvenajā žurnālā `main.log`, bet informācija par darbu ar katru ierīci tiek glabāta atsevišķā ierīces žurnālā.

Failā `main.log` var redzēt ierīču saraksta sagatavošanu, sekot pakešapstrādei un pārskatīt ierīču apstrādes rezultātus. Tajā tiek ierakstītas arī kļūdas, kas rodas, pirms ir noteikta konkrēta ierīce.

Ierīces žurnālā ir informācija par `.rsc` un `.backup` failu iegūšanu, atkārtotiem mēģinājumiem, salīdzināšanu un arhivēšanu. Tātad, ja jānoskaidro, kas notika konkrētas ierīces dublēšanas laikā, skatiet šīs ierīces žurnālu. Šī detalizētā informācija netiek dublēta failā `main.log`.

<br />

## Žurnālu glabāšanas vietas

Pēc noklusējuma galvenais žurnāls tiek glabāts direktorijā `backups` blakus skriptam. Ierīču žurnāli tiek saglabāti blakus attiecīgajiem dublējumiem:

| Žurnāls | Atrašanās vieta |
|---|---|
| Galvenais žurnāls | `<BackupRoot>/main.log` |
| Ierīce pakešrežīmā | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Ierīce vienas ierīces palaišanā | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

Pakešrežīmā jaunie ieraksti tiek pievienoti tam pašam ierīces žurnālam. Vienas ierīces dublēšanā žurnāla nosaukumā ir tas pats datums un laiks, kas palaišanas laikā izveidoto dublējumu failu nosaukumos.

### Atsevišķs direktorijs failam main.log

Lai galveno žurnālu glabātu atsevišķi no dublējumiem, norādiet direktoriju `option.cfg` iestatījumā `MainLogPath`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

Tad žurnāls tiks rakstīts failā `/var/log/mikrotik-backup/main.log`. Ierīču žurnāli paliks savās parastajās vietās.

Tukša vērtība `MainLogPath=` izmanto aktīvo `BackupRoot`. Relatīvs ceļš, piemēram, `MainLogPath=logs`, attiecas uz direktoriju blakus skriptam, nevis dublējumu krātuves iekšpusē.

*(Piezīme. `MainLogPath` norāda direktoriju, nevis pilnu faila nosaukumu. Direktorijam jau jāpastāv, un skripta lietotājam tajā jābūt rakstīšanas tiesībām.)*

<br />

## Žurnalēšanas detalizācija

Iestatījums `LogLevel` nosaka, cik daudz informācijas rāda un ieraksta. Tā noklusējuma vērtība ir `2`:

| Vērtība | Izvade terminālī | Ieraksti žurnālfailos |
|---|---|---|
| `0` | Tikai kļūdas | Tikai kļūdas |
| `1` | Galvenie posmi un to rezultāti | Īss žurnāls |
| `2` | Galvenie posmi un to rezultāti | Detalizēts žurnāls |
| `3` | Galvenie posmi un pašreizējās apakšdarbības | Detalizēts žurnāls |

**Kļūdas tiek ierakstītas visos līmeņos.** Īsajā žurnālā ir galvenie posmi un to rezultāti; detalizētajā žurnālā ir arī šo posmu iekšējās darbības.

Līmeni var mainīt failā `option.cfg` vai konfigurācijas redaktorā:

```ini
LogLevel=3
```

Lai mainītu līmeni vienai jau konfigurētai pakešrežīma palaišanai, izmantojiet komandrindu:

```bash
mikrotik-backup.sh --log-level=3
```

Tas nemaina opciju faila vērtību. Tāpat ar `--main-log-path` var norādīt galvenā žurnāla atrašanās vietu tikai pašreizējai palaišanai.

BackUP Master nav atsevišķu lauku `LogLevel` un `MainLogPath`. Tas izmanto aktīvajai palaišanai spēkā esošos žurnalēšanas iestatījumus.

<br />

## Žurnāla ierakstu izskats

Žurnāli ir parasti teksta faili. Katrā ierakstā ir datums un laiks pēc skripta resursdatora pulksteņa. Krāsas un progresa indikatori failā netiek ierakstīti.

`main.log` ierakstu piemērs:

```text
[2026-10-01 01:00:00] [PID:12345] Ierīču pakešapstrāde
[2026-10-01 01:00:15] [PID:12345] [OK] Ierīču pakešapstrāde
```

Galvenajā žurnālā tiek norādīts arī procesa PID. Tas palīdz atšķirt ierakstus, ko rakstījušas vairākas vienlaikus darbojošās skripta instances.

Ierīces žurnālā PID netiek pievienots. Detalizēta žurnāla fragments:

```text
[2026-10-01 01:00:05] Binārā dublējuma iegūšana
[2026-10-01 01:00:06] [1] DNS kešatmiņas tīrīšana
[2026-10-01 01:00:07] [2] Konsoles vēstures tīrīšana
[2026-10-01 01:00:12] [OK] Binārā dublējuma iegūšana
```

`[OK]` nozīmē, ka darbība sekmīgi pabeigta. Kļūda tiek atzīmēta ar `[ER]`, norādot arī tās kodu, piemēram, `[53]`. Apakšdarbības tiek numurētas ar `[1]`, `[2]` un tā tālāk, sākot no jauna katrā galvenajā posmā.

Ja pēc nesekmīga mēģinājuma atkārtošana izdodas, žurnālā paliek gan iepriekšējā kļūda, gan vēlākā sekmīgā rezultāta ieraksts.

Žurnāla ierakstos izmanto to pašu saskarnes valodu, ko nosaka iestatījums `Language`. Plašāk par valodas izvēli un tulkojumu izmantošanu skatiet [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Izvade terminālī

Manuālas palaišanas laikā ekrānā ir redzama izpildes gaita. Kamēr notiek darbība, tai blakus redzams gaidīšanas indikators. Kad darbība beidzas, indikators mainās uz zaļu `[OK]` vai sarkanu `[ER]` ar kļūdas kodu.

Līmeņi `1` un `2` rāda galvenos posmus. Līmenī `3` zem pašreizējā posma tiek rādīta arī aktuālā apakšdarbība, kas darba gaitā mainās. Pakešrežīmā papildus norāda pašlaik apstrādājamo ierīci.

*(Piezīme. Ja skripts darbojas bez termināļa, piemēram, no plānotāja vai ar novirzītu izvadi, ekrāna izvade nav redzama. Žurnalēšana failos turpinās izvēlētajā līmenī.)*

<br />

## Žurnālu uzkrāšana un arhivēšana

Žurnālfails tiek izveidots, ierakstot pirmo ierakstu. Ar `LogLevel=0` un bez kļūdām jauni žurnālfaili netiek izveidoti, bet esošie paliek nemainīti.

Galvenais žurnāls un pakešrežīma ierīču žurnāli katrā palaišanā tiek papildināti, nevis pārrakstīti. Secīgas palaišanas atdala tukša rinda.

`main.log` netiek ne arhivēts, ne dzēsts pēc vecuma. Tā rotācija jāorganizē jums.

Ja ikmēneša arhivēšana ir ieslēgta, uzkrātais pakešrežīma ierīces žurnāls tiek iekļauts pilnajā ZIP komplektā kopā ar šīs ierīces dublējumiem. Kad arhīvs sekmīgi saglabāts, arhivētais žurnāls tiek izņemts no ierīces direktorija; arhivēšanas rezultāts un turpmākās darbības tiek rakstītas jaunā žurnālfailā.

Ja tas pats ZIP tiek atjaunināts vēlreiz, tajā esošā vēsture tiek papildināta, nevis aizstāta ar jaunu žurnālu. Ja arhīvu nevar saglabāt, iepriekšējais žurnāls paliek savā vietā un kļūda tiek ierakstīta tajā.

Vienas ierīces komandrindas palaišanu žurnāli tiek arhivēti kopā ar dublējumiem kopīgajā direktorijā. Arhivēšana abos režīmos aprakstīta [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Ja žurnālā nevar rakstīt

Nepietiekamas tiesības, nepieejams direktorijs vai cita žurnāla rakstīšanas kļūda neaptur pašu dublēšanu. Skripts izdod brīdinājumu un, ja iespējams, turpina darbu.

Par nepieejamu `main.log` ziņo vienreiz katrā palaišanā; par nepieejamu ierīces žurnālu — vienreiz attiecīgās ierīces apstrādes laikā. Ja galvenais žurnāls ir pieejams, tajā ieraksta ierīces žurnāla rakstīšanas kļūdu.

Ja citu kļūdu nav, palaišana beidzas ar kodu `1`, kas nozīmē pabeigšanu ar brīdinājumu. Šis brīdinājums neaizstāj pašas dublēšanas darbības kļūdu.

Rezultātu kodus un norādes kļūdas cēloņa atrašanai skatiet [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(Piezīme. Detalizācijas līmenis `3` nežurnalē paroles vai pilnas savienojuma komandas. Informāciju par autentifikācijas datu un skripta failu aizsardzību skatiet [SECURITY.md](SECURITY.md).)*
