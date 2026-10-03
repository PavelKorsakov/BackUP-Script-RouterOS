# MikroTik Backup Script

**MikroTik-RouterOS-Geräte sichern.**

Dieses Skript erstellt Sicherungen von Geräten mit RouterOS – manuell oder automatisch über einen Scheduler *(den Sie separat einrichten)*.
Die Datei `mikrotik-backup.sh` ist ein eigenständiges Skript; einige Funktionen lassen sich zusätzlich über `option.cfg` konfigurieren.

<br>

## Funktionen des Skripts

| Funktion | Funktionsweise |
|---|---|
| Einzelgerätemodus | Erstellt mithilfe der CLI-Optionen eine Sicherung eines Geräts |
| Stapelverarbeitung | Verarbeitet die in der Geräteliste aufgeführten Geräte nacheinander; die Liste kann aus Oxidized importiert werden |
| Sicherungsformate | Erstellt `.rsc`, `.backup` oder nacheinander beide Formate |
| Sicherungsmodi | Unterstützt kompakte, kurze und ausführliche Exporte sowie die Verschlüsselung binärer Sicherungen |
| Inkrementelle Sicherungen | Kann Sicherungen nur dann behalten, wenn eine Änderung erkannt wurde |
| Monatsarchive | Kann ältere Sicherungen und Protokolle an einer Kalendergrenze archivieren |
| Protokollierung | Zeichnet allgemeine Verarbeitungsschritte in `main.log` und Geräteoperationen in `devicename.log` auf |
| Konfigurationsmenü | Bietet ein interaktives Menü zur komfortablen Einrichtung und Bedienung |
| Lokalisierung | Enthält Russisch und Englisch und unterstützt externe Lokalisierungsdateien |
| Sicherungsspeicher | Kann ein beliebiges Sicherungsverzeichnis verwenden, auch auf einem NAS |
| NAS-Betrieb | Prüft vor dem Erstellen einer Sicherung, ob der Speicher erreichbar ist |

<br>

## Systemanforderungen und erste Schritte

**Erforderlich:**
GNU Bash 4.4 oder neuer sowie die installierten Programme **SSH**, **SCP** und **SSHPass**.
**zip** wird nur für die monatliche Archivierung benötigt. Alle erforderlichen Programme und die zugehörigen Installationsbefehle stehen unter [Abhängigkeiten](de/INSTALL.md#abhängigkeiten).
*(Hinweis: Fehlt ein erforderliches Programm, beendet sich das Skript mit einem Fehler. Das ist das erwartete Verhalten.)*

**Optional:**
**autofs**, **davfs2**, **rclone** und andere Werkzeuge zum Einhängen externer Speicher.

**Installation:**
Download- und Einrichtungsanweisungen finden Sie unter [Installation](de/INSTALL.md).

Führen Sie im Verzeichnis mit den heruntergeladenen Dateien folgende Befehle aus:

Der folgende Befehlsblock gilt für Dateien aus einem GitHub Release. Ein Git-Quellcode-Checkout enthält die erzeugte Datei `SHA256SUMS` nicht; beginnen Sie bei einem Quellcode-Checkout mit `chmod 700 mikrotik-backup.sh` und führen Sie anschließend die Versions- und Hilfeprüfungen aus.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Wenn die Prüfsummenprüfung fehlschlägt, **führen Sie die Datei keinesfalls aus!!!**

<br>

## Möglichkeiten zum Starten des Skripts

**Datei OHNE zusätzliche Optionen starten** *(wenn `option.cfg` fehlt oder ungültig ist)*
Wenn neben dem Skript keine `option.cfg` liegt oder die Datei keine verwendbaren Einstellungen enthält, öffnet sich der Konfigurationseditor. Dort können Sie `option.cfg` erstellen oder bearbeiten.

**Datei OHNE zusätzliche Optionen starten** *(wenn gültige Dateien `option.cfg` und `devicelist.cfg` vorhanden sind)*
Sind verwendbare Einstellungen vorhanden, beginnt das Skript mit der Stapelverarbeitung.

**Skript mit einer Option starten:**

| Aufgabe | Befehl |
|---|---|
| Interaktives Menü öffnen | `./mikrotik-backup.sh -i` |
| BackUP Master öffnen | `./mikrotik-backup.sh -b` |
| `option.cfg` erstellen oder bearbeiten | `./mikrotik-backup.sh -e` |
| Vollständige CLI-Hilfe anzeigen | `./mikrotik-backup.sh -h` |
| Sicherung eines einzelnen Geräts ausführen | Vollständiges CLI-Triplett angeben: Geräteadresse, Benutzer und Kennwort |

Die wichtigste Option ist `-i`: Sie öffnet das interaktive Menü. Von dort aus können Sie:

- im BackUP Master Geräteparameter eingeben, Sicherungen erstellen und `devicelist.cfg` um das ausgewählte Gerät ergänzen oder die Datei neu anlegen;
- im Konfigurationseditor `option.cfg` erstellen oder bearbeiten;
- die CLI-Hilfe anzeigen;
- eine Kurzbeschreibung der Skriptfunktionen lesen.

Die vollständige CLI-Referenz einschließlich der exakten Formen `-a=...`, `-u=...` und `-p=...` finden Sie in der [Kommandozeilenreferenz](de/CLI.md).

<br>

## Wo sind die Ergebnisse – oder: „Wo sind meine Sicherungen???“

Standardmäßig werden Gerätesicherungen im Verzeichnis `backups` neben dem Skript gespeichert. Ist es nicht vorhanden, legt das Skript es an.
*(Hinweis: Der relative Pfad `backups` wird vom Skriptverzeichnis aus aufgelöst, nicht vom aktuellen Arbeitsverzeichnis!)*

Bei einem Einzelgerätelauf wird kein eigenes Geräteunterverzeichnis angelegt:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Im Stapelbetrieb erhält jedes Gerät ein eigenes Verzeichnis:

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

Diese Strukturen sind Beispiele und keine Zusicherung, dass nach jedem Lauf jede Datei vorhanden ist.
Eine Protokolldatei entsteht erst mit dem ersten für sie bestimmten Eintrag.
Mit der Option `MainLogPath` in `option.cfg` können Sie `main.log` nach `/var/log/` oder in ein anderes geeignetes Verzeichnis verschieben.
Einzelheiten zur Konfiguration von Sicherungs-, Archiv- und Protokollverzeichnissen finden Sie unter [Konfiguration](de/OPTIONS.md).

<br>

## Monatliche Archivierung

Diese Funktion ist standardmäßig deaktiviert. Wenn das Skript nach Zeitplan läuft, wählen Sie mit `MonthlyArchive=true|1...28` in `option.cfg` den Zeitpunkt, an dem alle Sicherungen des vorhergehenden Zeitraums archiviert werden.

An diesem Tag ändert ein Stapellauf seine Arbeitsreihenfolge: Zuerst archiviert er alle geeigneten Daten, die sich im Sicherungsverzeichnis angesammelt haben, danach erstellt er die Sicherungen für das aktuelle Datum.

Das Archiv wird nach dem vorherigen Kalendertag benannt. Ein Lauf am 1. Oktober erzeugt beispielsweise `30.09.YYYY.zip`.

*(Hinweis: Läuft das Skript NICHT täglich, müssen Sie für das erforderliche Datum einen eigenen geplanten Auftrag einrichten. Bei täglicher oder häufigerer Ausführung ist kein zusätzlicher Auftrag nötig.)*

Ein versäumter Monatslauf wird – unabhängig vom Grund – nicht durch tägliche Läufe nachgeholt.
Der nächste planmäßige Monatslauf sammelt sämtliche aufgelaufenen alten Daten in einem Archiv, auch wenn der Rückstand mehrere Monate umfasst. `main.log` wird nicht archiviert.

Die vollständigen Regeln, Beispiele und das Fehlerverhalten beschreibt [Monatsarchive](de/BACKUPS.md#monthly-archive).

<br>

## Ausführliche Dokumentation

| Thema | Seite |
|---|---|
| Anforderungen, Abhängigkeiten und Dateiablage | [Installation](de/INSTALL.md) |
| Parameter und Modusauswahl | [CLI](de/CLI.md) |
| Standardwerte und `option.cfg` | [Konfiguration](de/OPTIONS.md) |
| Geräteliste, Namen und Oxidized | [Geräte](de/DEVICES.md) |
| Formate, Vergleich, Speicher und ZIP-Archive | [Sicherungen](de/BACKUPS.md) |
| Protokollierungsgrade, Pfade und Meldungen | [Protokollierung](de/LOGGING.md) |
| Menü, Editor und BackUP Master | [Interaktive Oberfläche](de/INTERACTIVE.md) |
| Sprachauswahl und `.lang`-Dateien | [Lokalisierung](de/LOCALIZATION.md) |
| Zugangsdaten, SSH und Zugriffsrechte | [Sicherheit](de/SECURITY.md) |
| Diagnose nach Symptom oder Ergebniscode | [Fehlerbehebung](de/TROUBLESHOOTING.md) |
| Prüfung von Veröffentlichungen und Aktualisierungen | [Versionen](de/RELEASES.md) |
| Entwicklungsgeschichte und Pläne | [Roadmap](de/ROADMAP.md) |

<br>

## Umfang und Einschränkungen

Das Skript erstellt Sicherungen, stellt aber keine Routerkonfiguration wieder her.
Die aktuelle Version versendet weder E-Mail- noch Messenger-Benachrichtigungen und löscht alte ZIP-Dateien nicht nach ihrem Alter.
Für Wiederherstellungsverfahren, externe Aufbewahrung und die Überwachung der Ergebnisse sind Sie als Administrator verantwortlich.

Das SSH-Profil verwendet Kennwortauthentifizierung und deaktiviert die Prüfung des Hostschlüssels.
Die Verschlüsselung einer `.backup`-Datei verschlüsselt weder `.rsc`-Dateien noch Konfigurationsdateien oder ZIP-Archive.
Lesen Sie vor dem produktiven Einsatz das [Sicherheitsmodell](de/SECURITY.md).

<br>

## Dokumentation in anderen Sprachen

[English](../README.md).
[Русский](README_RU.md).
[Latviešu](README_LV.md).
[Українська](README_UK.md).
[Deutsch](README_DE.md).
[Bahasa Indonesia](README_ID.md).
[Português (Brasil)](README_PT-BR.md).
[Tiếng Việt](README_VI.md).
[Español](README_ES.md).
[Polski](README_PL.md).
[বাংলা](README_BN.md).

## Kontakt zum Autor

Vorschläge für neue Funktionen, Fehlerberichte und Fragen zum Skript senden Sie an [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev)
oder über Telegram direkt an den Autor: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
