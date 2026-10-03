# Kommandozeile

[Zur Übersicht](../README_DE.md)
## Syntax

```text
mikrotik-backup.sh [Aktion] [Parameter]
```

Befehlszeilenparameter können in Langform angegeben werden: `--parameter value` oder `--parameter=value`.
Daneben gibt es die Kurzform `-p=value`. Beginnt der **Wert** mit `-`, ist jedoch nur die Schreibweise mit `=` zulässig: `--parameter=-value`.

Ein unbekannter Parameter, ein Positionsargument oder ein fehlender, explizit leerer oder ungültiger Wert erzeugt den Fehlercode `12` und stoppt das Skript.

<br />

## Aktionen

| Aktion | Zweck |
|---|---|
| `-i` | Interaktives Hauptmenü |
| `-b` | BackUP Master |
| `-e` | Konfigurationseditor (`option.cfg`) |
| `-h`, `--help` | Hilfe zu den CLI-Optionen |
| `-v`, `--version` | Skriptversion |

Das Skript erlaubt nicht mehr als eine Aktionsoption gleichzeitig. `mikrotik-backup.sh -i -b` stoppt beispielsweise mit dem Fehlercode `12`.

<br />

## Parameter

| Parameter | Wert | Zweck |
|---|---|---|
| `--device-name` | Name | Gerätename, wenn `UseIdentityName=false` |
| `--address` | Adresse oder DNS-Name | Adresse des RouterOS-Geräts |
| `--user` | Benutzername | RouterOS-Gerätebenutzer |
| `--password` | Kennwort | Kennwort des RouterOS-Geräts |
| `--port` | `1`–`65535` | Geräte-SSH-Port; Standard `22` |
| `--language` | `auto` oder zwei ASCII-Buchstaben | Sprache der aktuellen Oberfläche und Skriptprotokolle |
| `--use-oxidized` | Boolescher Wert* | Geräteliste aus Oxidized importieren |
| `--oxidized-home` | Pfad | Oxidized-Konfigurationsverzeichnis mit `config` und `router.db` |
| `--use-identity-name` | Boolescher Wert* | Namen aus der RouterOS Identity übernehmen |
| `--backup-root` | Pfad | Stammverzeichnis für Sicherungen |
| `--use-net-folder` | Boolescher Wert* | Einhängung im Stapelbetrieb prüfen |
| `--monthly-archive` | `false` oder eine Nummer von `1` bis `28`* | Kalenderbasierte monatliche Archivierung aktivieren |
| `--log-level` | `0`, `1`, `2`, `3` | Detailebene für Protokolle und Terminalausgabe |
| `--main-log-path` | Pfad | Verzeichnis nur für `main.log` |
| `--backup-type` | `configuration`, `binary`, `both` | Abzurufende Sicherungsformate |
| `--export-format` | `compact`, `terse`, `verbose` | Textexportformat |
| `--show-sensitive` | Boolescher Wert* | Sensible Werte in den Export einbeziehen |
| `--encrypt` | Nicht leeres Kennwort | `.backup` mit AES-SHA256 verschlüsseln |
| `--clear-dns-cache` | Boolescher Wert* | DNS-Cache vor einer binären Sicherung leeren |
| `--clear-console-history` | Boolescher Wert* | Konsolenverlauf vor einer binären Sicherung leeren |

`*` Boolesche Werte sind `true` oder `false`; außerdem akzeptiert das Skript `yes`/`no`, `1`/`0` und `on`/`off`, jeweils unabhängig von der Groß-/Kleinschreibung.
Für `backup-type` werden `config` und `conf` auch als Synonyme für `configuration` akzeptiert.

Kurzformen für die Verbindungsdaten:

```text
-a=WERT    entspricht --address WERT
-u=WERT    entspricht --user WERT
-p=WERT    entspricht --password WERT
```

<br />

<a id="execution-mode"></a>
## Ausführen des Skripts aus der Befehlszeile

Das Skript kann ein einzelnes Gerät sichern, benötigt dafür jedoch mindestens drei Parameter:
die **IP-Adresse**, den **Benutzernamen** und das **Kennwort** des Geräts. Dieser Befehl ist also bereits vollständig:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Alle anderen oben aufgeführten Parameter sind hier optional.
*(Hinweis: Sehr wichtig: Dieses Verbindungstriplett darf NICHT mit einer **Aktionsoption** kombiniert werden.)*

**Noch ein Detail!!!**
Für einen Einzelgerätelauf müssen alle drei Verbindungsparameter über die CLI bereitgestellt werden. Das Skript ergänzt einen fehlenden Benutzernamen oder ein fehlendes Kennwort nicht aus `option.cfg`.

<br />

## Priorität der Einstellungen

Gewöhnliche Einzelgeräte- und Stapelsicherungen verwenden die in [OPTIONS.md](OPTIONS.md) beschriebene Reihenfolge:
**Eingebaute Werte** → **verwendbare Zeilen aus `option.cfg`** → **CLI**

Ist ein Parameter bereits in `option.cfg` vorhanden, für einen bestimmten Lauf aber ein anderer Wert nötig, übergeben Sie ihn über die CLI.

Ein Einzelgerätelauf verwendet nicht die Geräteliste oder den Oxidized-Import. Andere Einstellungen von `option.cfg` gelten weiterhin, es sei denn, die Befehlszeilenparameter ersetzen sie.

**Für das Befüllen des BackUP-Master-Formulars gilt eine eigene Reihenfolge.**
Normale Felder verwenden eingebaute Werte und übergebene CLI-Parameter, nicht `option.cfg`. `UseIncremental` bildet die Ausnahme: Der Wert wird aus der Datei übernommen oder auf seinen Standardwert gesetzt.
Die gewählten Werte für `LogLevel` und `MainLogPath` gelten für den Lauf; die monatliche Archivierung ist dabei deaktiviert. Einzelheiten zum BackUP Master stehen in [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Befehlszeilenparameter nach Zweck

### Verbindung und Gerätename

| Option | Wert | Zweck |
|---|---|---|
| `--address` | IP-Adresse oder DNS-Name | Adresse des RouterOS-Geräts |
| `--user` | Benutzername | RouterOS-Gerätebenutzer |
| `--password` | Kennwort | Kennwort des RouterOS-Geräts |
| `--port` | `1` bis `65535` | SSH-Port des Geräts; Standardwert `22` |
| `--device-name` | Name | Gerätename, wenn `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Namen aus der RouterOS Identity übernehmen |

Um Ihren eigenen Namen zu verwenden, geben Sie `--use-identity-name false` und `--device-name NAME` zusammen an.

<br />

### Sicherungsformat und Inhalt

| Option | Wert | Zweck |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Abzurufende Sicherungsformate |
| `--export-format` | `compact`, `terse`, `verbose` | Textexportformat |
| `--show-sensitive` | `true` / `false` | Sensible Werte in den Export einbeziehen |
| `--encrypt` | Nicht leeres Kennwort | `.backup` mit AES-SHA256 verschlüsseln |
| `--clear-dns-cache` | `true` / `false` | DNS-Cache vor einer binären Sicherung leeren |
| `--clear-console-history` | `true` / `false` | Konsolenverlauf vor einer binären Sicherung leeren |

Für `--backup-type` bedeuten `config` und `conf` auch `configuration`.

*(Hinweis: `UseIncremental` hat keine eigene CLI-Option. Legen Sie den Wert in `option.cfg`, im Konfigurationseditor oder im BackUP Master fest. Den Zweck der Einstellung beschreibt [OPTIONS.md](OPTIONS.md).)*

<br />

### Speicherung, Archivierung und Protokolle

| Option | Wert | Zweck |
|---|---|---|
| `--backup-root` | Pfad | Stammverzeichnis für Sicherungen |
| `--use-net-folder` | `true` / `false` | Einhängung im Stapelbetrieb prüfen |
| `--monthly-archive` | `false` oder eine Nummer von `1` bis `28` | Kalenderbasierte monatliche Archivierung aktivieren |
| `--log-level` | `0`, `1`, `2`, `3` | Detailebene für Protokolle und Terminalausgabe |
| `--main-log-path` | Verzeichnispfad | Verzeichnis nur für `main.log` |

`--monthly-archive` hat seine eigene Regel: `true`/`yes`/`1`/`on` bedeutet den ersten Tag des Monats, während `false`/`no`/`0`/`off` die Archivierung deaktiviert.

Die Option wählt den Archivierungstag aus; die Archivierung wird nicht sofort ausgeführt. Siehe [BACKUPS.md](BACKUPS.md#monthly-archive) für die Regeln dieses Modus.

Für `--main-log-path` geben Sie ein Verzeichnis an, nicht einen vollständigen Pfad, der in `main.log` endet.

<br />

### Gerätelistenquelle und Sprache

| Option | Wert | Zweck |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Geräteliste aus Oxidized importieren |
| `--oxidized-home` | Pfad | Oxidized-Konfigurationsverzeichnis mit `config` und `router.db` |
| `--language` | `auto` oder ein Zwei-Buchstaben-Code | Sprache der aktuellen Oberfläche und Skriptprotokolle |

Mit `--language auto` bestimmt die Betriebssystemumgebung die Sprache. Sie können auch ausdrücklich `ru`, `en`, `de` oder einen anderen Sprachcode wählen. Russisch und Englisch benötigen keine separaten Übersetzungsdateien; andere Übersetzungen werden aus Dateien neben dem Skript geladen. Ist keine passende Übersetzung vorhanden, wird Englisch verwendet.
Einzelheiten finden Sie in [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Beispiele

**Achtung!!!**
Standardmäßig sind der Export vertraulicher Daten sowie das Leeren von DNS-Cache und Konsolenverlauf vor einer binären Sicherung aktiviert.

*(Hinweis: Über die CLI übergebene Kennwörter können im Shell-Verlauf und in Prozessargumenten sichtbar sein. Das gilt auch für das Verschlüsselungskennwort von `.backup`, das in den Argumenten des Kindprozesses `ssh` erscheinen kann. Einzelheiten finden Sie in [SECURITY.md](SECURITY.md).)*

### `.rsc`-Konfiguration nur ohne sensible Daten

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Beide Formate, ein benutzerdefinierter Gerätename und keine Bereinigung

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Verschlüsselte binäre Sicherung

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Stapellauf mit einem separaten Verzeichnis und detaillierter Protokollierung

Dieses Beispiel geht davon aus, dass `option.cfg` und die Geräteliste bereits erstellt wurden:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Die restlichen Einstellungen für diesen Stapellauf stammen aus `option.cfg` und den eingebauten Werten.

<br />

## Wenn ein Befehl abgelehnt wird

Eine unbekannte Option, ein zusätzliches Positionsargument oder ein fehlender beziehungsweise ungültiger Wert führt zu Fehler `12`. Es wird keine Sicherung gestartet. Prüfen Sie die Schreibweise der Optionen mit `-h`.

**Leere Werte können nicht über die CLI übergeben werden.**
`--encrypt=''` und `--main-log-path=''` werden abgelehnt. Legen Sie leere `encrypt=` und `MainLogPath=`-Werte in `option.cfg` oder über den Konfigurationseditor fest.

Ergebniscodes und ihre Bedeutungen sind unter [Troubleshooting](TROUBLESHOOTING.md#result-codes) aufgeführt.
