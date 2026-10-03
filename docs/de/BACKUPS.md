# Sicherungen und Archive

[Zur Übersicht](../README_DE.md)
## Sicherungsformate

Das Skript kann die Gerätekonfiguration als Text speichern, eine binäre Sicherung erstellen oder beide Formate abrufen.
Der `backup_type`-Parameter in `option.cfg` wählt das Format:

| Wert | Gesicherte Daten |
|---|---|
| `configuration` | RouterOS-Konfiguration in einer `.rsc`-Datei |
| `binary` | Binäre Sicherung in einer `.backup`-Datei |
| `both` | Beide Formate: `.rsc` zuerst, dann `.backup` |

Standardmäßig ist `both`. Sie können es in der Optionsdatei, dem Konfigurationseditor, dem BackUP-Master oder mit `--backup-type` ändern.

### Textkonfiguration: `.rsc`

Der `export_format`-Parameter wählt das Exportformat aus. Gültige Werte sind `compact`, `terse` und `verbose`; der Standard ist `compact`.

Der Parameter `show_sensitive` bestimmt, ob der Export vertrauliche Daten einschließlich Kennwörtern enthält.
Um dies zu deaktivieren, ergänzen Sie `option.cfg` wie folgt:

```ini
show_sensitive=false
```

### Binäre Sicherung: `.backup`

Sie können eine binäre Sicherung verschlüsseln. Tragen Sie das gewünschte Kennwort in `encrypt` ein:

```ini
encrypt=MySuperPassword
```

Bei einem leeren `encrypt=`-Wert wird die Datei ohne Verschlüsselung gespeichert.

*(Hinweis: Die AES-SHA256-Verschlüsselung gilt nur für `.backup`. Sie verschlüsselt weder Textkonfigurationen noch Protokolle oder ZIP-Archive.)*

Standardmäßig leert das Skript den RouterOS-DNS-Cache und den Konsolenverlauf, bevor es eine binäre Sicherung erstellt.

```ini
clear_dns_cache=false
clear_console_history=false
```

Diese Bereinigungsvorgänge werden nicht durchgeführt, wenn nur eine Textkonfiguration abgerufen wird.

<br />

## Dateinamen und Standorte

Standardmäßig werden Sicherungen im Verzeichnis `backups` neben dem Skript gespeichert. Legen Sie ein weiteres Verzeichnis mit `BackupRoot` in der Optionsdatei fest.

In einem Einzelgerätelauf werden Dateien direkt in diesem Verzeichnis abgelegt:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Im Stapelbetrieb hat jedes Gerät sein eigenes Unterverzeichnis:

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

Ein Sicherungsdateiname enthält den Gerätenamen sowie Datum und Uhrzeit des Hosts, auf dem das Skript läuft.
Die Konstruktion des Gerätenamens wird in [DEVICES.md](DEVICES.md#device-names) beschrieben.

**Achtung!!!**
Wenn Sie dasselbe Gerät innerhalb einer Minute zweimal im selben Verzeichnis sichern, stimmen die Dateinamen überein. Die Datei mit diesem Namen wird ersetzt; für den zweiten Durchlauf wird keine separate Version erstellt.

Im Stapelbetrieb stellen Sie `UseNetFolder=true` ein, um diesen Speicher zu überprüfen. Die Verzeichnisvorbereitung wird in [INSTALL.md](INSTALL.md) und Pfadeinstellungen in [OPTIONS.md](OPTIONS.md#network-storage) beschrieben.

[LOGGING.md](LOGGING.md) erklärt den Ort und den Inhalt der Protokolle im Detail.

<br />

## Inkrementelle Sicherungen

Diese Funktion verhindert, dass doppelte Sicherungen aufbewahrt werden, wenn keine Änderung erkannt wurde. Gesteuert wird sie mit `UseIncremental`:

| Wert | Wie Sicherungen beibehalten werden |
|---|---|
| `true` (Standard) | Wird die neue Sicherung als Duplikat erkannt, wird sie gelöscht und die vorherige bleibt erhalten |
| `false` | Jede neue gültige Sicherung wird ohne Vergleich mit der vorherigen behalten |

Wird eine Änderung erkannt oder gibt es keine vorherige Sicherung, bleibt die neue Datei erhalten. Kann der Vergleich nicht abgeschlossen werden, bleibt die Datei ebenfalls erhalten; das Skript gibt jedoch eine Warnung aus.

**Und hier ist der Haken!!!**
Der Vergleich unterscheidet sich nach Format:

| Format | Was verglichen wird |
|---|---|
| `.rsc` | Dateiinhalte. Datum und Uhrzeit im Standard-RouterOS-Header werden ignoriert |
| `.backup` | Dateigröße nur in Bytes |

Zwei Binärdateien gleicher Größe gelten daher auch bei unterschiedlichem Inhalt als Duplikate. Berücksichtigen Sie das bei Ihrer Aufbewahrungsstrategie.

Das Skript vergleicht die neue Datei mit der letzten früheren Sicherung desselben Geräts und Formats im Geräteverzeichnis. Bereits in ein ZIP-Archiv gepackte Sicherungen werden nicht berücksichtigt.

Das Skript behält gewöhnliche `.rsc`- und `.backup`-Dateien bei, keine separaten Änderungsdateien.

<br />

<a id="monthly-archive"></a>
## Monatliche Archivierung

Setzen Sie `MonthlyArchive` in `option.cfg`, um den Tag auszuwählen, an dem akkumulierte Sicherungen und Protokolle archiviert werden:

| Wert | Verhalten |
|---|---|
| `false` (Standard) | Archivierung ist deaktiviert |
| `true` oder `1` | Archivierung läuft am ersten Tag des Monats |
| `2` bis `28` | Archivierung läuft am angegebenen Tag des Monats |

Die Uhrzeit des Laufs innerhalb des ausgewählten Tages spielt keine Rolle. Konfigurieren Sie den Zeitplan separat, wie in [INSTALL.md](INSTALL.md#automatisches-ausführen-des-skripts) beschrieben.

### Was ins Archiv kommt

Im Stapelbetrieb ändert sich an diesem Tag die Reihenfolge der Arbeit: Das Skript sammelt zunächst die angesammelten Dateien des Geräts in einem ZIP und erstellt erst dann neue Sicherungen. Sicherungen, die durch den aktuellen Lauf erstellt werden, bleiben außerhalb des Archivs.

Das Archiv enthält reguläre Dateien direkt im Geräteverzeichnis, einschließlich des vollständigen kumulativen Geräteprotokolls. Dies ist nicht auf `.rsc` und `.backup` beschränkt: Andere reguläre Dateien, die Sie im Verzeichnis ablegen, können ebenfalls archiviert werden.

Unterverzeichnisse, symbolische Links, Arbeitsobjekte des aktuellen Laufs und zuvor vom Skript erstellte ZIP-Dateien werden nicht erneut gepackt. **Das Hauptprotokoll `main.log` wird nicht archiviert.**

Nachdem das fertige ZIP-Archiv geprüft und gespeichert wurde, werden die darin enthaltenen Quelldateien aus dem Geräteverzeichnis gelöscht. Gibt es nichts zu archivieren, wird kein leeres ZIP angelegt.

### Archivname und Standort

Das ZIP-Archiv wird im Format `DD.MM.YYYY.zip` nach dem vorherigen Kalendertag benannt. Beispielsweise erzeugt ein Lauf am 1. Oktober 2026 `30.09.2026.zip`, ein Lauf am 15. Oktober `14.10.2026.zip`.

| Modus | Speicherort des Archivs |
|---|---|
| Stapel | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Einzelgerät CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

Ein wiederholter Lauf am selben Tag aktualisiert das Archiv mit dem gleichen Namen.

### Einzelgeräte-Modus und BackUP Master

Bei einem Einzelgerätelauf über die CLI ist die Reihenfolge umgekehrt: Zuerst wird gesichert, anschließend archiviert. Die neue Sicherung des aktuellen Laufs kann deshalb ebenfalls in das ZIP-Archiv gelangen.

In diesem Modus werden `.rsc`-, `.backup`- und `.log`-Dateien direkt in `BackupRoot` archiviert; `main.log` bleibt ausgenommen. Teilen sich Ergebnisse von Einzelgeräteläufen mehrerer Geräte ein Verzeichnis, gelangen ihre Dateien in dasselbe Archiv.

Die monatliche Archivierung läuft nicht, wenn BackUP Master verwendet wird.

### Wenn ein Lauf verpasst wird

Läuft das Skript am ausgewählten Tag nicht, wird der versäumte Archivierungsversuch nicht nachgeholt. Der nächste Versuch findet am vorgesehenen Tag des folgenden Monats statt.

Alle angesammelten Dateien werden in das nächste Archiv aufgenommen, auch wenn sie aus zwei, drei oder mehr Monaten stammen. Für die versäumten Monate werden keine separaten ZIP-Dateien erstellt.

### Wenn die Archivierung fehlschlägt

Die Quelldateien werden erst gelöscht, nachdem ein geprüftes ZIP-Archiv gespeichert wurde. Auch ein vorhandenes beschädigtes Archiv wird nicht durch ein neues überschrieben.

Wurde das ZIP-Archiv bereits gespeichert, lassen sich aber einige Quelldateien nicht löschen, bleiben sowohl das fertige Archiv als auch die nicht gelöschten Dateien erhalten. Prüfen Sie das Protokoll auf die Fehlerursache.

*(Hinweis: Das Archiv wird im lokalen Verzeichnis `/tmp` erstellt, auch wenn die Sicherungen selbst auf einem NAS liegen. Deshalb wird auch außerhalb des Sicherungsspeichers freier Platz benötigt.)*

<br />

## Wenn die Sicherung fehlschlägt

Nach einem fehlgeschlagenen Dateiabruf versucht es das Skript nach 2 Sekunden erneut. Die Wiederholungsversuche für `.rsc` und `.backup` erfolgen unabhängig voneinander.

Ein gewöhnlicher Abruffehler bei einem Format verhindert nicht den Abrufversuch für das andere Format. Ist ein Gerät nicht erreichbar, fährt das Skript mit den übrigen Geräten fort. Geht der gemeinsame Speicher verloren, wird die Stapelverarbeitung beendet.

Fehlermeldungen und Ergebniscodes werden in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) beschrieben.

<br />

## Aufbewahrung und Wiederherstellung

Alte ZIP-Dateien werden nicht nach Alter oder Zählung gelöscht. Sie entscheiden über deren Aufbewahrungsdauer und externe Rotation.

Das Skript erstellt Sicherungen, stellt RouterOS jedoch nicht wieder her. Testen Sie die Wiederherstellung separat auf einem geeigneten Gerät.

*(Hinweis: Sicherungen und Archive können Kennwörter und andere vertrauliche Daten enthalten. Zugriff auf den Speicher wie in [SECURITY.md](SECURITY.md) beschrieben einschränken.)*
