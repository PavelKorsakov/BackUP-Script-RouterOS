# Interaktive Oberfläche

[Zur Übersicht](../README_DE.md)
## Hauptmenü

Im Hauptmenü können Sie das Skript konfigurieren, Sicherungen erstellen, eine Geräteliste vorbereiten oder die integrierte Hilfe öffnen.

```bash
mikrotik-backup.sh -i
```

| Eintrag | Funktion |
|---|---|
| `1` | BackUP Master starten |
| `2` | Stapelsicherung ausführen |
| `3` | Skripteinstellungen (`option.cfg` erstellen oder bearbeiten) |
| `4` | CLI-Optionen |
| `5` | Bedienungsanleitung |
| `6` | Beenden |

Das Element `2` erscheint, wenn `devicelist.cfg` mindestens einen berechtigten Eintrag enthält. Wenn die Liste noch nicht existiert oder keine geeigneten Geräte enthält, wird das Element ausgeblendet. Die Nummern der anderen Elemente ändern sich nicht.

Nach einer Stapelsicherung wird das Ergebnis angezeigt; anschließend kehrt das Skript zur Konsole zurück.

*(Hinweis: Ein Start ohne Optionen öffnet nicht das Hauptmenü. Fehlt `option.cfg` oder enthält sie keine verwendbaren Einstellungen, wird der Konfigurationseditor geöffnet; mit vorbereiteten Einstellungen beginnt die Stapelsicherung.)*

<br />

## Bedienung

Navigieren Sie mit den Pfeiltasten **Auf** und **Ab** durch die Einträge und wählen Sie mit **Enter**. Steht neben einer Aktion eine Zahl, können Sie auch die entsprechende Zahlentaste drücken.

Im Editor und im Master erscheint oberhalb der Liste eine Beschreibung des ausgewählten Feldes. Passen nicht alle Zeilen in das Terminalfenster, scrollt die Liste bei der Navigation mit. Überschrift und Beschreibung bleiben sichtbar, und die ausgewählte Zeile bleibt im Fenster.

Die Aktionen zum Speichern, Ausführen und Beenden stehen am Ende derselben Liste. Abgeblendete Zeilen sind mit den gewählten Einstellungen nicht verfügbar und werden bei der Navigation übersprungen.

Ein Terminal und das `stty`-Dienstprogramm sind erforderlich. Sowohl Standardeingang als auch Standardausgang müssen an ein Terminal angeschlossen sein. Die Hauptbildschirme benötigen eine Breite von mindestens 46 Spalten. Die eingebauten Anweisungen erfordern 80. Wenn das Fenster zu klein ist, meldet das Skript den Fehler `31`. Vergrößern Sie das Fenster und führen Sie es erneut aus.

<br />

## Konfigurationseditor

Öffnen Sie den Editor über den Eintrag `3` im Hauptmenü oder direkt mit:

```bash
mikrotik-backup.sh -e
```

Wenn `option.cfg` bereits vorbereitet ist, wird das Formular mit Ihren Einstellungen ausgefüllt. Wenn die Datei noch nicht vorhanden ist, werden Standardwerte verwendet.

Im Editor wählen Sie Sprache, Quelle der Geräteliste, Sicherungseinstellungen, Speicher, monatliche Archivierung und Protokollierung. Die Einstellungen und zulässigen Werte beschreibt [OPTIONS.md](OPTIONS.md).

### Ändern der Einstellungen

Ändern Sie die Ja/Nein-Schalter, den Sicherungstyp, das Exportformat und die Protokollebene, indem Sie in der entsprechenden Zeile **Enter** drücken.

Das Feld **Inkrementellen Vergleich verwenden** (`UseIncremental`) folgt unmittelbar auf den Sicherungstyp. **Ja** aktiviert den Vergleich; **Nein** behält jede neue gültige Sicherung ohne Vergleich mit der vorherigen.

Für die monatliche Archivierung geben Sie zum Deaktivieren `false` oder eine Zahl von `1` bis `28` ein. Das Formular zeigt den deaktivierten Zustand als „Nein“ und andernfalls den gewählten Monatstag an.

Felder, die im gewählten Modus nicht gelten, werden abgeblendet: Ist beispielsweise nur `.rsc` gewählt, stehen die Verschlüsselung binärer Sicherungen und die vorherigen Bereinigungsschritte nicht zur Verfügung; bei ausschließlich `.backup` sind die Textexporteinstellungen nicht verfügbar.

Das Verschlüsselungskennwort wird eingegeben und als Sternchen angezeigt.

### Speichern und Abbrechen

Wählen Sie die benötigten Einstellungen → gehen Sie zu „Speichern“ → drücken Sie **Enter**. Aus den gewählten Einstellungen wird `option.cfg` erstellt oder überschrieben.

Bis zum Speichern befinden sich Änderungen nur im Arbeitsspeicher. „Abbrechen“ lässt die vorhandene Datei unverändert. Nach Änderungen fragt der Editor nach einer Bestätigung, bevor er sie verwirft.

Ein aus dem Hauptmenü geöffneter Editor kehrt dorthin zurück. Wurde der Editor separat mit `-e` gestartet, führt das Schließen zurück zur Konsole.

*(Hinweis: `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` und `Password` werden im Formular nicht angezeigt. Ihre Einstellungen und Erhaltungsregeln stehen in [OPTIONS.md](OPTIONS.md).)*

### Eine Sprache wählen

In der Sprachzeile wählt jeder Druck von **Enter** die nächste Option aus:

```text
auto → ru → en → erkannte externe Sprachen in alphabetischer Reihenfolge → auto
```

Die Formularsprache wechselt sofort und zeigt damit eine Vorschau. **Speichern** schreibt die gewählte Sprache in `option.cfg`; **Abbrechen** stellt die vorherige Oberflächensprache wieder her. Wurde `--language` beim Start ausdrücklich angegeben, gilt diese Option nach dem Verlassen des Editors erneut.

Wie externe Übersetzungen eingebunden werden, beschreibt [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

Im BackUP Master können Sie die Daten und Einstellungen eines Geräts eingeben, Sicherungen erstellen, das Gerät in der Liste speichern oder einen Befehl für die spätere Ausführung in der Konsole vorbereiten.

Wählen Sie Eintrag `1` im Hauptmenü oder führen Sie direkt aus:

```bash
mikrotik-backup.sh -b
```

Anders als der Konfigurationseditor befüllt der Master seine normalen Felder nicht aus `option.cfg`. Die Werte stammen aus den eingebauten Standardeinstellungen und ausdrücklich übergebenen CLI-Optionen. `UseIncremental` bildet die Ausnahme: Der Wert kommt aus der Optionsdatei oder lautet `true`, wenn die Einstellung fehlt.

Bestehende Einträge aus `devicelist.cfg` werden ebenfalls nicht in das Formular geladen. Sie geben Name, Adresse, Benutzername und Kennwort des gewählten Geräts selbst ein.

### Felder des BackUP Master

Die Felder erscheinen in dieser Reihenfolge; ihre Bezeichnungen entsprechen der deutschen Benutzeroberfläche:

| Feld | Zweck |
|---|---|
| Gerätename | Name für die Geräteliste und – bei deaktiviertem Abruf der RouterOS Identity – für die Sicherungen |
| IP-Adresse | Geräte-IP-Adresse oder DNS-Name |
| Benutzer | Benutzername auf dem RouterOS-Gerät |
| Kennwort | Kennwort des RouterOS-Benutzers |
| SSH-Port | Verbindungsport; Standardwert `22` |
| Sicherungstyp | `.rsc`-Konfiguration, binäre `.backup`-Sicherung oder beide Formate |
| Inkrementellen Vergleich verwenden | Neue Sicherung mit der vorherigen vergleichen oder ohne Vergleich aufbewahren |
| Exportformat | `compact`, `terse` oder `verbose` |
| Vertrauliche Daten | Vertrauliche Werte in den Textexport aufnehmen |
| Verschlüsselungskennwort | Binäre Sicherung verschlüsseln; ein leerer Wert deaktiviert die Verschlüsselung |
| DNS-Cache leeren | DNS-Cache vor einer binären Sicherung leeren |
| Konsolenverlauf leeren | Konsolenverlauf vor einer binären Sicherung leeren |
| Sicherungsverzeichnis | Verzeichnis, in dem Dateien gespeichert werden |
| Dies ist ein Netzwerkverzeichnis | `UseNetFolder`-Wert; Mount-Verifizierung gilt im Stapelbetrieb |
| RouterOS Identity verwenden | Namen vom Gerät abrufen, statt den im Formular eingegebenen Namen zu verwenden |

Schalter, Sicherungstyp und Exportformat ändern Sie mit **Enter**; andere Werte geben Sie in die jeweiligen Felder ein.

**Bitte beachten Sie!!!**
Vertrauliche Daten im Textexport sowie das Leeren von DNS-Cache und Konsolenverlauf vor einer binären Sicherung sind standardmäßig aktiviert. Prüfen Sie diese Einstellungen, bevor Sie die Sicherung ausführen.

Der Master besitzt keine Felder für `MonthlyArchive`, `LogLevel` oder `MainLogPath`. Bei einer Sicherung über den Master ist die monatliche Archivierung deaktiviert. Die Protokollierungseinstellungen stammen dagegen aus `option.cfg` und den für den Lauf übergebenen CLI-Optionen.

### 1. Sicherung ausführen

Tragen Sie Adresse, Benutzer und Kennwort ein, prüfen Sie Port und Sicherungseinstellungen → wählen Sie **1. Sicherung ausführen**.

Ist der Abruf der RouterOS Identity aktiviert, wird der Sicherungsname vom Gerät übernommen.

Nun beginnt die Einzelgerätesicherung. Nach ihrem Abschluss werden Ergebnis und Code angezeigt, anschließend kehrt das Skript zur Konsole zurück. Unabhängig vom Erfolg wird das Masterformular nicht erneut geöffnet.

Dateispeicherorte und Aufbewahrungsregeln werden in [BACKUPS.md](BACKUPS.md) beschrieben; Fortschrittsmeldungen werden in [LOGGING.md](LOGGING.md) behandelt.

### 2. Gerät in `devicelist.cfg` speichern

Gerätename, Adresse, Benutzername, Kennwort und SSH-Port werden zum Speichern benötigt. Bis alle erforderlichen Felder ausgefüllt sind, bleibt die entsprechende Aktion nicht verfügbar.

Der Master erstellt die Datei, fügt einen neuen Eintrag hinzu oder aktualisiert einen vorhandenen Eintrag gleichen Namens. Bei widersprüchlichen Einträgen oder einem Speicherfehler bleibt die bisherige Liste unverändert. Das Formular bleibt nach dem Speichern geöffnet.

**Nur die Gerätedaten werden in `devicelist.cfg` gespeichert.** Sicherungseinstellungen aus dem Formular werden nicht in `option.cfg` geschrieben; diese Aktion startet auch keine Sicherung.

*(Hinweis: Port `22` wird als leeres Feld gespeichert. In einem späteren Stapellauf verwendet ein solcher Eintrag `SshPort` aus den Skripteinstellungen. Ein nicht standardmäßiger Port wird explizit geschrieben.)*

Das Listenformat und die Aktualisierungsregeln sind in [DEVICES.md](DEVICES.md) beschrieben.

### 3. Konsolenbefehl kopieren

Der Master erzeugt aus dem ausgefüllten Formular einen Startbefehl und kopiert ihn in die Zwischenablage. Dabei wird keine Sicherung gestartet. Anschließend endet der Master und kehrt zur Konsole zurück.

Diese Funktion erfordert GNU `base64` mit `--wrap=0`-Unterstützung und einem Terminal, das OSC 52 unterstützt. Wenn Sie mit einem Terminalmultiplexer arbeiten, muss auch dieser den Befehl durchgeben.
Wird die Übertragung in die Zwischenablage nicht unterstützt, gibt der Master den Befehl nicht im Klartext auf dem Bildschirm aus.

Parameter, die den eingebauten Werten entsprechen, können im Befehl fehlen. Bei seiner späteren Ausführung gelten weiterhin Einstellungen aus `option.cfg`, sodass das Ergebnis von einer direkt über den Master ausgeführten Sicherung abweichen kann.

Die Einstellung `UseIncremental` ist nicht im Befehl enthalten: Sie hat keine dedizierte CLI-Option. Wenn der kopierte Befehl ausgeführt wird, kommt der Wert von `option.cfg` oder von den Standardeinstellungen.

*(Hinweis: Der Befehl in der Zwischenablage enthält Kennwörter. Beachten Sie dies, wenn Sie den Zwischenablageverlauf verwenden und den Befehl in eine Shell einfügen. Details finden Sie unter [SECURITY.md](SECURITY.md).)*

### 0. Zum Hauptmenü zurückkehren

Das Ergebnis hängt davon ab, wie Sie den Master geöffnet haben:

| Aufruf | Rückkehrziel |
|---|---|
| Aus dem Hauptmenü mit `-i` | Hauptmenü |
| Als separater Lauf mit `-b` | Konsole |

Nicht gespeicherte Formularwerte werden verworfen. Ein bereits in `devicelist.cfg` gespeicherter Eintrag bleibt dort erhalten.

<br />

## Hilfe und Anleitungen

Eintrag `4` im Hauptmenü öffnet die Referenz der Befehlszeilenoptionen; Eintrag `5` zeigt eine kurze Bedienungsanleitung.

Passt der Text nicht vollständig in das Fenster, wird er auf Seiten verteilt. Blättern Sie mit **PageUp / PageDown**; die aktuelle Seitenzahl wird angezeigt.

Element `0` kehrt zum Hauptmenü zurück und Element `6` verlässt das Skript. Sie können diese Aktionen mit den Pfeiltasten und **Enter** oder mit der entsprechenden Zahlentaste auswählen.

Die gleiche CLI-Hilfe ist direkt von der Konsole aus verfügbar:

```bash
mikrotik-backup.sh -h
```
