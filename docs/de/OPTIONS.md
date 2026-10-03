# Konfiguration

[Zur Übersicht](../README_DE.md)
## Ein paar Worte zuerst

Mit der optionalen `option.cfg`-Datei können Sie die Einstellungen ändern, die das Skript standardmäßig verwendet.
Damit das Skript die darin aufgeführten Einstellungen laden kann, muss sich `option.cfg` im selben Verzeichnis wie `mikrotik-backup.sh` befinden.

Die Dateistruktur ist sehr einfach: eine Liste von `Schlüssel=Wert`-Einträgen. Sie ist kein Shell-Skript.
Variablen werden darin nicht expandiert und Befehle nicht ausgeführt.

## Wann eine Konfiguration verwendbar ist

Schon eine gültige, erkannte Zeile macht die Konfiguration verwendbar.
Sie müssen nicht jede Einstellung aufführen: Entspricht ein Standardwert Ihren Anforderungen, braucht die betreffende Option nicht in `option.cfg` zu stehen.

Wenn die Datei leer ist oder nur Kommentare, unbekannte Schlüssel oder ungültige Werte enthält, hat das Skript nichts zu laden.
Die Einstellungen behalten dann ihre Standardwerte.

**Und hier ist der Haken!!!**
Starten Sie das Skript in diesem Zustand ohne Argumente, beginnt keine Sicherung; stattdessen versucht das Skript, den Konfigurationseditor zu öffnen.
Dasselbe passiert, wenn `option.cfg` überhaupt nicht existiert.
Speichern Sie die erforderlichen Einstellungen und führen Sie das Skript erneut aus.
*(Hinweis: Der Editor benötigt ein Terminal. Wird das Skript ohne Terminal ausgeführt, etwa durch einen Scheduler, endet es mit Fehler `31`.)*
Bereiten Sie `option.cfg` vor, bevor Sie einen automatischen Lauf konfigurieren.

**Reihenfolge, in der optionale Parameter gelesen werden:**
Das Skript wendet Parameterquellen in der Prioritätsreihenfolge an. Wenn `option.cfg` fehlt, verwendet es die im Skript eingebetteten Standardwerte.
Existiert die Datei und kann sie gelesen werden, ersetzen ihre <mark>gültigen</mark> Parameter die entsprechenden Standardwerte.

Und am wichtigsten!!! Wird derselbe Parameter über die CLI angegeben, hat der CLI-Wert Vorrang.
Für einen gewöhnlichen Einzelgeräte- oder Stapellauf ist die Priorität daher:
**Eingebaute Werte** → **verwendbare Zeilen aus `option.cfg`** → **CLI**

*(Hinweis: Eine fehlende Datei ist nicht dasselbe wie eine unlesbare Datei.
Wenn `option.cfg` existiert, das Skript es aber nicht lesen kann, endet die Ausführung mit
Konfigurationsfehler `21`; es wird nicht mit den Standardeinstellungen fortgesetzt.)*

## Wie die Datei gelesen wird

Jede Zeile wird beim ersten `=` geteilt. Schlüsselnamen sind fallunempfindlich, aber Bindestriche und Unterstriche sind nicht austauschbar.
Leerzeilen und Zeilen, deren erstes Nichtweißraumzeichen `#` ist, werden ignoriert.
Wenn ein Schlüssel mehr als einmal erscheint, wird der letzte gültige Wert verwendet.

Führende und nachfolgende Leerzeichen werden von gewöhnlichen Werten entfernt.
**Wichtig:** Bei `Login`, `Password` und `encrypt` bleibt alles nach dem ersten `=` unverändert erhalten.
Fügen Sie keine Anführungszeichen für die Shell-Syntax hinzu: Die Anführungszeichen werden Teil des Wertes.
Geben Sie keinen Kommentar nach einem Kennwort ein, verwenden Sie eine separate Zeile für den Kommentar.

Eine UTF-8-BOM am Dateianfang und CRLF-Zeilenenden werden unterstützt.
Ein lesbarer symbolischer Link zu einer regulären Datei ist zulässig.
Ein Zugriffsproblem oder ein ungeeigneter Objekttyp wird nicht als leere Datei behandelt
und verursacht einen Konfigurationsfehler.

## `option.cfg` erstellen, bearbeiten und speichern

Der einfachste Weg, die Datei zu erstellen, besteht darin, das Skript mit `-e` auszuführen:

```bash
./mikrotik-backup.sh -e
```

Der Konfigurationseditor wird geöffnet und zeigt die wichtigsten Optionen an.
Wenn nicht alle Zeilen in das Terminalfenster passen, scrollt die Liste automatisch, während Sie sich mit den Pfeiltasten nach oben und unten bewegen.
Die Einträge **Speichern** und **Abbrechen** stehen am Ende derselben Liste.
Gehen Sie durch das Menü, tragen Sie die benötigten Einstellungen ein → wählen Sie **Speichern** → und (Sie sind großartig) die Datei ist fertig.

Beachten Sie, dass der Editor während der Arbeit im interaktiven Menü die Einstellungen nur im Speicher ändert.
Erst nach der Auswahl von **Speichern** schreibt er die vollständige, *kanonische* Datei.

Wenn `option.cfg` noch nicht existiert, füllt der Editor zunächst seine Felder mit den Standardwerten.
Wenn die Datei bereits vorhanden ist und Sie einige Parameter geändert haben, füllt der Konfigurationseditor seine Felder mit Ihren Werten und nicht mit den Standardwerten.

Die zweite Möglichkeit besteht darin, `option.cfg` manuell zu erstellen. Ja: Öffnen Sie eigenhändig Ihren bevorzugten Texteditor und tragen Sie die benötigten Einstellungen ein.
Wo finden Sie sie?

## Einstellungen und Standardwerte

| Schlüssel | Standardwert | Wert und Zweck |
|---|---|---|
| `Language` | `auto` | `auto` oder zwei ASCII-Buchstaben wie `ru`, `en` oder `de` |
| `SshPort` | `22` | Port `1`–`65535`; versteckt im Editor, sichtbar im BackUP Master |
| `UseOxidized` | `false` | Geräte aus Oxidized importieren |
| `IgnoreOxiAccess` | `true` | Nach einem Lese- oder Analysefehler von Oxidized die vorherige Geräteliste weiterverwenden; nur in der Datei |
| `OxidizedHome` | Leer | Verzeichnis mit `config` und `router.db` |
| `UseIdentityName` | `true` | Aktuelle RouterOS Identity als Gerätenamen verwenden |
| `backup_type` | `both` | `configuration`, `binary` oder `both` |
| `UseIncremental` | `true` | Eine neue verifizierte Sicherung mit der vorherigen vergleichen; bei `false` jede neue Sicherung ohne Vergleich behalten |
| `export_format` | `compact` | `compact`, `terse` oder `verbose` |
| `show_sensitive` | `true` | Sensible Werte in `.rsc` einschließen |
| `encrypt` | Leer | Kennwort zur Verschlüsselung von `.backup`; leer bedeutet keine Verschlüsselung |
| `encrypt_type` | `aes-sha256` | Fester Algorithmus; nur Datei |
| `clear_dns_cache` | `true` | DNS-Cache vor einer binären Sicherung leeren |
| `clear_console_history` | `true` | Konsolenverlauf vor einer binären Sicherung leeren |
| `BackupRoot` | `backups` | Stammverzeichnis für Sicherungen |
| `UseNetFolder` | `false` | Im Stapelbetrieb eine separate Einhängung verlangen |
| `MonthlyArchive` | `false` | Archivierung deaktivieren (`false`) oder einen Monatstag von `1` bis `28` festlegen |
| `LogLevel` | `2` | Stufe `0`, `1`, `2` oder `3` |
| `MainLogPath` | Leer | Verzeichnis nur für `main.log`; leer bedeutet das aktuelle `BackupRoot` |
| `Login` | Leer | Gemeinsamer Benutzername, der bei leeren Feldern der Geräteliste übernommen wird; nur in der Datei |
| `Password` | Leer | Gemeinsames Kennwort, das bei leeren Feldern der Geräteliste übernommen wird; nur in der Datei |

Mit `Language=auto` wählt das Gebietsschema des Betriebssystems die Sprache der Oberfläche und der Protokolle aus.
Eine externe Übersetzung verwendet den zweibuchstabigen Sprachcode dieses Gebietsschemas: `de_DE.UTF-8` erfordert z. B. `de.lang` neben dem Skript.
Wenn keine geeignete Übersetzung verfügbar ist, wird Englisch verwendet.

`MonthlyArchive` folgt einer etwas anderen Regel: `false`/`no`/`0`/`off` deaktiviert die Archivierung; `true`/`yes`/`1`/`on` bedeutet den ersten Tag des Monats; und die Werte von `2` bis `28` wählen den gewünschten Tag aus.

Wenn der Konfigurationseditor die Datei speichert, schreibt er entweder
`MonthlyArchive=false` oder die ausgewählte Nummer.

Boolesche Parameter akzeptieren `true`/`false`, `yes`/`no`, `1`/`0` und `on`/`off`.
Der Editor schreibt `true`/`false`.

Felder wie `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` und `Password` werden im Konfigurationseditor nicht angezeigt.

Beim Speichern der Datei schreibt der Editor `IgnoreOxiAccess`, `encrypt_type` und `SshPort`.
`Login` und `Password` werden nur beibehalten, wenn diese Zeilen bereits in `option.cfg` vorhanden waren; das gilt auch für Zeilen mit leeren Werten.

Die Felder `SshPort`, `Login` und `Password` sind nützlich, wenn alle Geräte denselben SSH-Port sowie denselben Benutzernamen und dasselbe Kennwort verwenden.

## Beispiel ohne Aufräumarbeiten oder sensible Exporte

Dies ist ein Beispiel für eine bewusst gewählte Konfiguration, **keine Liste der Werkseinstellungen**:

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

Die ersten 19 Schlüssel werden in kanonischer Reihenfolge geschrieben.
Vorhandene kompatible Zeilen `Login` und `Password` bleiben danach erhalten.

Fehlende Einstellungen verwenden die eingebauten Werte, nicht die Werte im benachbarten Beispiel.
Beispielsweise deaktiviert eine Datei, die nur `Language=ru` enthält, die Bereinigung nicht und ändert `show_sensitive=true` nicht.

## Pfade

```ini
BackupRoot=backups
MainLogPath=logs
```

Diese Einträge bezeichnen die Verzeichnisse `backups` und `logs` neben dem Skript.
Absolute Pfade bleiben unverändert. `$HOME` und `~` werden weder als Variable noch als
Home-Verzeichnis expandiert.

Ein fehlendes `BackupRoot` wird während der Ausführung erstellt, wenn Berechtigungen dies zulassen.
Das Wurzelverzeichnis `/` des Dateisystems ist als Speicherort unzulässig.
Bei vorhandenen Verzeichnissen korrigiert das Programm nicht automatisch Besitz oder Berechtigungen.

Ein nicht leeres `MainLogPath` muss ein **bestehendes, beschreibbares Verzeichnis** identifizieren.
`main.log` selbst wird erst beim ersten Eintrag angelegt.
Kann das Protokoll nicht geschrieben werden, läuft die Sicherungsverarbeitung mit einer Warnung weiter. Diese Einstellung verschiebt keine Geräteprotokolle.

<a id="network-storage"></a>
## Netzwerk und separater Speicher

`UseNetFolder=true` gilt im Stapelbetrieb. Der Pfad muss von einem anderen Mount-Eintrag als `/` abgedeckt sein. Der separate Speicher kann ein Netzwerkspeicher, eine lokale Festplatte oder ein Bind-Mount sein; der Optionsname beschränkt den Dateisystemtyp nicht.

Ein einfaches Verzeichnis auf demselben Wurzeldateisystem erfüllt diese Anforderung nicht.
Das Skript prüft Verfügbarkeit und Einhängung, ruft aber weder `mount`, `umount` noch
`sudo` auf und weicht nicht stillschweigend auf lokalen Speicher aus.

## Verwandte Parameter

Mit `UseIncremental=false` vergleicht das Skript eine neue Sicherung nicht mit der vorherigen und behält jede neu erstellte und erfolgreich geprüfte Datei.
Diese Einstellung hat keinen Einfluss auf die Sicherungserstellung selbst oder die monatliche Archivierung.
Standardmäßig ist `UseIncremental=true`. Wenn Ihr `option.cfg` diesen Parameter noch nicht enthält, bleibt der Vergleich aktiviert.

Bei `backup_type=configuration` werden weder die Verschlüsselung binärer Sicherungen
noch die einer binären Sicherung vorausgehenden Bereinigungsschritte verwendet. Bei `backup_type=binary` gelten weder `export_format`
noch `show_sensitive`. Bei `UseOxidized=false` wird `OxidizedHome` nicht verwendet.

Bei `UseIdentityName=true` wird ein Fehler beim Lesen der RouterOS Identity nicht durch
`--device-name` oder den Namen aus der Geräteliste aufgefangen.
`UseIdentityName`: siehe [Namensregeln](DEVICES.md#device-names).

Bei `MonthlyArchive=true` läuft die Archivierung, wenn das Skript am ausgewählten Monatstag
nach der lokalen Zeit des Hosts startet; die Uhrzeit innerhalb dieses Tages spielt keine Rolle.
Wenn das Skript an diesem Tag nicht läuft, wird der verpasste Archivierungsversuch nicht eingeholt.

[BACKUPS.md](BACKUPS.md#monthly-archive) erklärt, welche Dateien in das Archiv eingehen, wo sie erstellt werden und wie sie benannt werden.
Auch der Datenzeitraum, die Stichtagsgrenze und versäumte Versuche werden in
[BACKUPS.md](BACKUPS.md#monthly-archive) erläutert.

Die Konfiguration kann Geheimnisse enthalten. Schränken Sie den Zugriff ein und nehmen Sie die Datei nicht in ein öffentliches Repository auf: [SECURITY.md](SECURITY.md).
