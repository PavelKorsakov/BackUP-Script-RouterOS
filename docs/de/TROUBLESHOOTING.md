# Fehlerbehebung

[Zur Übersicht](../README_DE.md)
## Wo Sie anfangen sollten

Wenn eine Sicherung nicht startet oder mit einem Fehler endet, prüfen Sie zuerst die Protokolle. `main.log` enthält die übergeordneten Phasen des Laufs; Einzelheiten zur Sicherung eines bestimmten Geräts stehen im separaten Geräteprotokoll.

Suchen Sie nach Einträgen mit der Markierung `[ER]` und einem Fehlercode. Die Codes werden [unten](#result-codes) erläutert; die Speicherorte der Protokolle beschreibt [LOGGING.md](LOGGING.md).

Verwenden Sie diese Befehle, um die installierte Skriptversion und Optionsreferenz anzuzeigen:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Um einen bereits konfigurierten Stapellauf mit detaillierter Ausgabe zu wiederholen:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

Der zweite Befehl zeigt das Ergebnis des abgeschlossenen Durchlaufs an. Er ändert die Protokollierungsebene in `option.cfg` nicht.

<br />

## Das Skript startet keine Sicherung

### Statt einer Sicherung wird der Editor geöffnet

Wenn das Skript ohne Optionen gestartet wird, bedeutet dies, dass `option.cfg` im Skriptverzeichnis fehlt oder keine verwendbaren Einstellungen enthält.
Eine leere Datei, ausschließlich Kommentare oder ausschließlich unbekannte Parameter ändern daran nichts.

Öffnen Sie den Konfigurationseditor, wählen Sie die erforderlichen Einstellungen aus, speichern Sie die Datei und führen Sie das Skript erneut aus:

```bash
mikrotik-backup.sh -e
```

Das Speichern eines Geräts über den BackUP Master erzeugt `devicelist.cfg`, ersetzt jedoch nicht die Vorbereitung von `option.cfg`.

*(Hinweis: Wird ein solcher Lauf von einem Scheduler gestartet, kann der Editor nicht geöffnet werden und das Skript endet mit Code `31`. Die Einstellungen für einen automatischen Lauf müssen vorab vorbereitet werden.)*

### Optionsfehler, Code 12

Mögliche Ursachen sind eine unbekannte Option, ein leerer Wert, mehrere verschiedene Aktionen, die gleichzeitig angefordert werden, oder unvollständige Anmeldeinformationen für eine Verbindung mit einem Gerät.

Für einen Einzelgeräte-CLI-Lauf werden Adresse, Benutzername und Kennwort benötigt. Fehlende Anmeldedaten werden nicht aus `option.cfg` ergänzt.

Kurze Verbindungsoptionen müssen `=` verwenden: `-a=`, `-u=` und `-p=`. Beachten Sie, dass `-p` das Kennwort angibt; verwenden Sie `--port` für den SSH-Port.

Alle akzeptierten Optionen und Beispiele sind in [CLI.md](CLI.md) aufgeführt.

### option.cfg kann nicht gelesen werden, Code 21

Stellen Sie sicher, dass `option.cfg` eine gewöhnliche Datei ist, die vom Benutzer mit dem Skript gelesen werden kann.

Eine fehlende Datei und eine unlesbare Datei sind unterschiedliche Situationen. Wenn die Datei existiert, aber nicht gelesen werden kann, wird das Skript nicht mit den Standardeinstellungen fortgesetzt.

### Fehlende Abhängigkeit, Code 30

Prüfen Sie die wichtigsten Dienstprogramme mit:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Der Stapelbetrieb mit `UseNetFolder=true` benötigt außerdem `findmnt`. Ist die monatliche Archivierung fällig, werden `zip`, `unzip` und GNU `mv` benötigt. Für **Konsolenbefehl kopieren** im BackUP Master ist GNU `base64` mit Unterstützung für `--wrap=0` erforderlich.

**Ein Dienstprogramm lediglich installiert zu haben, reicht nicht aus.** Das installierte OpenSSH muss die verwendeten Optionen unterstützen und `scp -O`; GNU `timeout` muss `--signal` und `--kill-after` unterstützen.

Die vollständige Abhängigkeitsliste und die Installationsbefehle finden Sie in [INSTALL.md](INSTALL.md#abhängigkeiten).

### Das Menü wird nicht geöffnet, Code 31

Menü, Editor und Master benötigen ein Terminal und ein funktionsfähiges `stty`. Starten Sie sie weder über eine Pipe noch mit umgeleiteter Standardeingabe oder Standardausgabe.

Meldet das Skript ein zu kleines Terminal, vergrößern Sie das Fenster. Die Hauptansichten benötigen mindestens 46 Spalten, die integrierten Anleitungen 80. Lange Listen im Editor und Master lassen sich mit den Pfeiltasten verschieben; das gesamte Formular muss nicht gleichzeitig auf den Bildschirm passen.

Schnittstellensteuerungen sind in [INTERACTIVE.md](INTERACTIVE.md) beschrieben.

<br />

## Die Geräteliste wird nicht geladen

### Die devicelist.cfg-Datei, Codes 22 und 23

Überprüfen Sie den Speicherort der Datei und den Zugriff darauf. `devicelist.cfg` muss neben `mikrotik-backup.sh` sein, unabhängig vom Verzeichnis, aus dem Sie das Skript starten.

Die Felder werden durch ein echtes TAB-Zeichen getrennt, nicht durch Leerzeichen. Ein Gerät benötigt Namen, Adresse, Benutzernamen, Kennwort und einen gültigen SSH-Port. Gemeinsame Anmeldedaten können aus `option.cfg` übernommen werden, wenn die entsprechenden Felder leer sind.

Ein ungültiger Eintrag wird mit einer Warnung übersprungen. Wenn keine geeigneten Geräte mehr vorhanden sind, gibt es nichts zu sichern und das Skript wird mit einem Listenfehler beendet.

Prüfen Sie außerdem auf doppelte Verbindungen und auf verschiedene Geräte mit demselben Namen. Dateiformat, Vererbung der Anmeldedaten und Regeln zur Behandlung von Duplikaten beschreibt [DEVICES.md](DEVICES.md).

### Import aus Oxidized, Codes 24 und 25

Code `24` bedeutet, dass die `config`- oder `router.db`-Datei in `OxidizedHome` nicht gelesen werden konnte. Code `25` betrifft deren Inhalt: ein nicht unterstütztes Schema, ungültige Daten oder keine geeigneten MikroTik-Geräte.

Prüfen Sie den Pfad, den Zugriff auf beide Dateien, die `csv`-Quelle, das Trennzeichen, die Spaltenzuordnung und die Definition des Modells `routeros`. Die Daten werden stets aus `<OxidizedHome>/router.db` gelesen; die Oxidized-Einstellung `source.csv.file` ändert diesen Pfad nicht.

Bei `IgnoreOxiAccess=true` kann das Skript mit der vorherigen Liste fortfahren. Der Importfehler bleibt dennoch im Laufergebnis. Bei `false` wird die alte Liste nicht für diesen Lauf verwendet.

Die Importkonfiguration ist in [DEVICES.md](DEVICES.md#import-aus-oxidized) beschrieben.

<br />

## Speicher und Sperren

### Sperre belegt, Code 32

Prüfen Sie, ob ein anderer Auftrag bereits dasselbe Sicherungsverzeichnis verwendet. Läufe desselben Benutzers stehen miteinander im Konflikt, wenn eine Stapelsicherung und ein weiterer Stapel- oder Einzelgerätelauf dasselbe `BackupRoot` verwenden.

Warten Sie, bis der aktive Job abgeschlossen ist, und führen Sie das Skript erneut aus.

**Löschen Sie keine Sperrdateien, um den Speicher „freizugeben“.** Die Dateien bleiben nach dem Ende des Skripts erhalten; die Sperre selbst wird vom Prozess gehalten. Das Vorhandensein einer Datei in `/tmp/mikrotik-backup-${UID}/` bedeutet daher nicht, dass die Sperre belegt ist.

### Kein Zugriff auf das Verzeichnis

Prüfen Sie den Pfad `BackupRoot`, die Benutzerrechte, den freien Speicherplatz und die Verfügbarkeit des Speichergeräts. Ein relativer Pfad wird vom Skriptverzeichnis aus aufgelöst. Das Wurzelverzeichnis des Dateisystems, `/`, darf nicht als Sicherungsspeicher verwendet werden.

Wenn das Skript zuvor als root lief und jetzt als **bsmt** läuft, hat dieser Benutzer möglicherweise keinen Zugriff auf die alten Verzeichnisse und Dateien. Wie Sie die Berechtigungen vorbereiten, beschreibt [INSTALL.md](INSTALL.md#automatisches-ausführen-des-skripts).

Der Stapelbetrieb mit `UseNetFolder=true` erfordert einen separaten Einhängepunkt.

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Gehören beide Pfade zum selben Einhängepunkt, erfüllt ein gewöhnliches Verzeichnis im Wurzeldateisystem die Anforderung von `UseNetFolder=true` nicht.

Code `64` bedeutet, dass das Geräteverzeichnis oder sein Archiv ausgefallen ist, während der freigegebene Speicher verfügbar blieb. Die Verarbeitung anderer Geräte kann fortgesetzt werden. Code `65` bedeutet, dass der freigegebene Speicher verloren gegangen ist oder sein Status ungültig wurde, und stoppt den Rest des Stapels.

Netzwerkspeicherregeln werden in [OPTIONS.md](OPTIONS.md#network-storage) beschrieben.

<br />

## Fehler beim Arbeiten mit einem Gerät

### SSH und Dateiübertragung, Codes 40-43

Prüfen Sie Geräteadresse, Verfügbarkeit des SSH-Dienstes, Benutzername, Kennwort und Port. Ist in `devicelist.cfg` kein Port angegeben, wird der Einstellungswert `SshPort` verwendet; sein Standardwert ist `22`.

Der RouterOS-Benutzer muss über die Berechtigung für die ausgewählten Vorgänge verfügen: Exportieren der Konfiguration, Erstellen und Abrufen von Sicherungen, Löschen temporärer Dateien und Durchführen aller aktivierten Bereinigungsvorgänge.

**Und hier gibt es eine Nuance!!!** Eine erfolgreiche Verbindung mit Ihrem üblichen SSH-Befehl bedeutet nicht, dass das Skript die gleichen Einstellungen verwendet. Es funktioniert mit einem Kennwort und verwendet nicht den SSH-Agenten, Schlüssel oder das normale `~/.ssh/config`. Dateien werden über `scp -O` abgerufen.

Code `40` betrifft die Verbindung oder den SSH/SCP-Transport, `41` die Authentifizierung, `42` einen RouterOS-Befehl oder dessen Antwort und `43` die Dateiübertragung. Weitere Erläuterungen zu den Verbindungseinstellungen finden Sie in [SECURITY.md](SECURITY.md#verbindung-zu-routeros).

### Namensfehler, Codes 50 und 52

Code `50` bedeutet, dass der endgültige Gerätename ungültig ist. Überprüfen Sie die ausgewählte Namensquelle und den Inhalt der Klammern: In der aktuellen Version ist das erste ausgefüllte, nicht leere Fragment in Klammern dasjenige, das als Name verwendet wird.

Nach der Verarbeitung muss der Name 1 bis 32 Zeichen lang sein. Ein überlanger Name wird nicht gekürzt. Reservierte Namen wie `CON` und `NUL` werden ebenfalls abgelehnt.

Der Code `52` bedeutet, dass der endgültige Name ein anderes Gerät im gleichen Durchlauf dupliziert. Der Vergleich ist fallunempfindlich: `Router-A` und `router-a` gelten als identisch.

Die Namensquelle und die Verarbeitungsregeln sind in [DEVICES.md](DEVICES.md#device-names) beschrieben.

### Sicherungsvalidierung fehlgeschlagen, Codes 51 und 53

Code `51` gilt für `.rsc` und Code `53` für `.backup`. Die abgerufene Datei hat die Validierung nicht bestanden, z. B. ist sie leer oder ihre Größe stimmt nicht mit der Datei auf dem Gerät überein.

Prüfen Sie den gemeldeten Fehler sowie freien Speicherplatz und Berechtigungen auf dem Host und auf RouterOS. Nach einem Fehlschlag versucht es das Skript nach 2 Sekunden erneut. Die Versuche für beide Formate sind voneinander unabhängig, sodass eine Datei erfolgreich abgerufen werden kann, während die andere fehlschlägt.

Eine Warnung, dass eine temporäre RouterOS-Datei nach dem erfolgreichen Abruf nicht gelöscht werden konnte, bedeutet nicht, dass die lokale Sicherung beschädigt ist.

<br />

## Es gibt keine neue Sicherung, aber auch keinen Fehler

Prüfen Sie zuerst `UseIncremental`. Ist der Vergleich aktiviert, kann eine neue Sicherung als Duplikat gelöscht werden, während die vorherige Datei erhalten bleibt. Bei `.rsc` wird der Inhalt ohne das Datum im Standardheader verglichen; bei `.backup` nur die Dateigröße.

Mit `UseIncremental=false` bleibt eine neue gültige Sicherung ohne diesen Vergleich erhalten.

Beachten Sie außerdem: Zwei Läufe für dasselbe Gerät innerhalb derselben Minute verwenden im selben Verzeichnis denselben Dateinamen. Für den zweiten Lauf wird keine separate Version angelegt.

Wurde an diesem Tag die monatliche Archivierung ausgeführt, prüfen Sie auch das ZIP-Archiv. Bei einem Einzelgeräte-CLI-Lauf kann sich die neue Sicherung bereits darin befinden. Die vollständigen Aufbewahrungsregeln beschreibt [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## Das monatliche Archiv erschien nicht

Überprüfen Sie den `MonthlyArchive`-Wert und das Laufzeitdatum in der lokalen Uhrzeit des Hosts. `false` deaktiviert die Archivierung; `true` oder `1` wählt den ersten Tag aus, während eine Zahl von `2` bis `28` diesen Tag des Monats auswählt.

Wenn dieser Tag verpasst wird, holt ein späterer normaler Lauf nicht auf. Die monatliche Archivierung wird nicht über den BackUP Master durchgeführt.

Wenn nichts zu archivieren ist, wird kein leeres ZIP erstellt.

### Wo finde ich den ZIP

Der Archivname entspricht dem vorherigen Kalendertag. Beispielsweise erzeugt ein Lauf am 1. Oktober 2026 `30.09.2026.zip`:

| Modus | Speicherort |
|---|---|
| Stapel | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Einzelgerät über die CLI | `<BackupRoot>/30.09.2026.zip` |

Der Verzeichnisname `archive/` ist kleinbuchstabig. Ein anderer Lauf am selben Tag aktualisiert den gleichen ZIP.

### Die Archivierung endete mit einem Fehler

Prüfen Sie bei den Codes `70` und `71` das Geräteprotokoll, den Zugriff auf das Archivverzeichnis, den freien Speicherplatz und den Zustand eines vorhandenen ZIP-Archivs.

Auf einer lokalen Festplatte muss das Verzeichnis `archive/` dem Skriptbenutzer gehören und den Modus `0700` haben. Im Stapelbetrieb mit verifiziertem Netzwerkspeicher und `UseNetFolder=true` sind ein anderer Eigentümer oder vom NAS zugewiesene Berechtigungen für sich genommen kein Grund für den Fehler. Speicherfehler während der Archivierung können auch Code `64` oder `65` erzeugen.

Überprüfen Sie ein vorhandenes Archiv mit dem folgenden Befehl und ersetzen Sie den tatsächlichen Pfad:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Quelldateien werden erst entfernt, wenn ein verifizierter ZIP gespeichert wurde. Wenn das Archiv gespeichert wurde, aber einige Quelldateien nicht entfernt werden konnten, bleiben sowohl der ZIP als auch die nicht gelöschten Dateien erhalten. Ein beschädigtes vorhandenes Archiv wird nicht automatisch durch ein neues ersetzt.

**Löschen Sie die verbleibenden Sicherungen oder Protokolle erst, wenn Sie den Archivinhalt überprüft haben.** Die Archivierungssequenz wird in [BACKUPS.md](BACKUPS.md#monthly-archive) beschrieben.

<br />

## Es gibt weder Protokoll- noch Bildschirmausgabe

Mit `LogLevel=0` und ohne Fehler werden keine neuen Protokolle erstellt.

Ein leeres `MainLogPath=` hinterlässt `main.log` in `BackupRoot`. Wenn ein separates Verzeichnis angegeben ist, muss es bereits vorhanden und für den Skriptbenutzer zugänglich sein.

Nach der monatlichen Archivierung befindet sich der bisherige Verlauf des Geräts im ZIP-Archiv. Nachfolgende Vorgänge werden in ein neues Protokoll neben den Sicherungen geschrieben.

Wenn das Skript von einem Scheduler aus läuft oder seine Ausgabe umgeleitet wird, fehlt das Bildschirmprotokoll mit seinem Indikator und den farbigen Markierungen.

Ein Fehler beim Schreiben des Protokolls stoppt die Sicherung nicht, erscheint aber als Warnung im Laufergebnis. Einzelheiten finden Sie in [LOGGING.md](LOGGING.md).

<br />

<a id="language-problems"></a>
## Eine Übersetzung wurde nicht angewendet

`Language=de` benötigt beispielsweise eine lesbare gewöhnliche Datei namens `de.lang` neben `mikrotik-backup.sh`, nicht im Verzeichnis `lang/`. Ein symbolischer Link wird nicht als Übersetzungsdatei verwendet.

Mit `Language=auto` bestimmt die Betriebssystemumgebung die Sprache. Sie können sie explizit für einen Durchlauf auswählen, zum Beispiel bei der Anzeige von Hilfe:

```bash
mikrotik-backup.sh --language=de --help
```

Unübersetzte Nachrichten werden in Englisch angezeigt. Falsche Zeilen in der Datei werden übersprungen. Dateien mit den Namen `ru.lang` und `en.lang` ersetzen nicht die eingebauten Übersetzungen.

Das Zeilenformat, die Schlüsselnamen und die Regeln zum Laden einer Übersetzung sind in [LOCALIZATION.md](LOCALIZATION.md) beschrieben.

<br />

## Eine Einstellung wirkt nicht

Wenn eine Einstellung wiederholt wird, gewinnt der letzte nutzbare Wert. Schlüsselnamen sind fallunempfindlich, aber Bindestriche und Unterstriche sind nicht austauschbar.

Eine CLI-Option überschreibt den entsprechenden Wert aus der Datei. Für gewöhnliche Einzelgeräte- und Stapelläufe lautet die Reihenfolge:

**Eingebaute Werte** → **verwendbare Zeilen aus `option.cfg`** → **CLI**

Der BackUP Master befüllt sein Formular anders: Normale Felder stammen aus den eingebauten Werten und der CLI, nicht aus der Optionsdatei. `UseIncremental` bildet die Ausnahme. Die Protokollierungseinstellungen aus der Datei gelten auch dann, wenn die Sicherung über den Master ausgeführt wird.

Die Regeln zum Einlesen der Einstellungen beschreibt [OPTIONS.md](OPTIONS.md), das Verhalten des Masters [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Ergebniscodes

| Code | Bedeutung |
|---:|---|
| `0` | Erfolg ohne aufgezeichnete Fehler oder Warnungen |
| `1` | Mit Warnungen abgeschlossen, ohne aufgezeichneten Ausführungsfehler |
| `12` | Fehler in CLI-Optionen, deren Werte oder deren Kombination |
| `21` | `option.cfg` konnte nicht gelesen werden |
| `22` | Die Geräteliste konnte nicht geladen werden |
| `23` | Ungültige Geräteliste oder keine berechtigten Einträge |
| `24` | Oxidized-Dateien konnten nicht gelesen werden |
| `25` | Nicht unterstütztes Schema oder ungültige Oxidized-Daten; keine geeigneten MikroTik-Einträge |
| `30` | Ein erforderliches Dienstprogramm fehlt oder unterstützt die erforderlichen Funktionen nicht |
| `31` | Terminal nicht verfügbar, `stty`-Fehler oder unzureichende Fenstergröße |
| `32` | Die erforderliche Sperre wird von einem anderen Lauf gehalten |
| `33` | Ungültiger Speicherpfad oder Objekt für einen Einzelgerätelauf |
| `34` | Das Verzeichnis für den Einzelgerätelauf konnte nicht erstellt oder vorbereitet werden |
| `35` | Fehler beim Zugriff auf oder beim Prüfen eines lokalen Betriebsobjekts einschließlich einer Sperre |
| `36` | Der Einzelgeräte-Laufspeicher hat vor dem Abruf der Datei die Verfügbarkeitsprüfung nicht bestanden |
| `37` | Eine Betriebsdatei konnte nicht geschrieben oder ersetzt werden |
| `40` | SSH/SCP-Verbindung oder Transportfehler |
| `41` | Authentifizierungsfehler am Gerät |
| `42` | Fehler bei einem RouterOS-Befehl oder dessen erwarteter Antwort |
| `43` | SCP-Dateiübertragungsfehler |
| `50` | Ungültiger endgültiger Gerätename |
| `51` | Validierung einer `.rsc`-Datei fehlgeschlagen |
| `52` | Doppelte endgültige Gerätenamen |
| `53` | Validierung einer `.backup`-Datei fehlgeschlagen |
| `61` | Gemeinsamer Speicher beim Vorbereiten eines Stapellaufs nicht verfügbar |
| `62` | Für `UseNetFolder=true` konnte kein separater Einhängepunkt bestätigt oder aktiviert werden |
| `63` | Fehler beim Erstellen oder Prüfen des gemeinsamen Stapelsicherungsverzeichnisses |
| `64` | Fehler beim Speichern von Geräten oder Archiven, während der freigegebene Speicher verfügbar bleibt |
| `65` | Gemeinsamer Speicher ging während des Laufs verloren oder wurde ungültig; die Stapelverarbeitung wird gestoppt |
| `70` | Fehler beim Erstellen oder Aktualisieren eines Archivs |
| `71` | Validierung des ZIP-Archivs oder Zielobjekts fehlgeschlagen |
| `80` | Interne Fehler oder nicht erfüllte Systemanforderung, einschließlich `C.UTF-8`-Fähigkeit |
| `81` | Interner MikroTik-Treiberfehler |
| `129` | Durch das Signal HUP beendet |
| `130` | Durch das Signal INT beendet, z. B. durch Drücken von Strg+C |
| `143` | Durch das Signal TERM beendet |

Der endgültige Code spiegelt den ersten aufgezeichneten Ausführungsfehler wider. Die Warnung `1` wird durch den ersten Fehler ersetzt, und ein späterer Erfolg löscht ihn nicht. Der endgültige Code stimmt daher nicht unbedingt mit der letzten Nachricht im Protokoll überein.

Ist die Wiederholung eines Dateiabrufs erfolgreich, kann die Phase mit `[OK]` enden, obwohl der Fehler des ersten Versuchs im Protokoll erhalten bleibt.

Prüfen Sie bei Code `80` die Systemanforderungen: GNU Bash 4.4 oder neuer und eine funktionsfähige `C.UTF-8`-Locale. Einzelheiten finden Sie in [INSTALL.md](INSTALL.md#host-anforderungen).

<br />

## Wenn Sie Hilfe benötigen

Nennen Sie die Skriptversion, das Betriebssystem und die Bash-Version, den verwendeten Startbefehl, den Exitcode sowie den relevanten Protokollauszug.

**Schicken Sie keine echten Kennwörter oder vollständige Arbeitseinstellungen.** Bevor Sie Protokolle, Screenshots oder Befehle senden, überprüfen Sie diese auf sensible Daten. Passwortschutzüberlegungen werden in [SECURITY.md](SECURITY.md) beschrieben.

Die Kontaktdaten des Autors finden Sie in der [Produktbeschreibung](../README_DE.md#kontakt-zum-autor).
