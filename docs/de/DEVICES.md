# Geräteliste

[Zur Übersicht](../README_DE.md)
## Zu sichernde Geräte: die Datei `devicelist.cfg`

Wie der Name schon sagt, listet `devicelist.cfg` die Geräte für Stapelsicherungen und die Daten auf, die für die Verbindung mit ihnen erforderlich sind.
Platzieren Sie die Datei direkt neben `mikrotik-backup.sh`.
Sie können `devicelist.cfg` manuell oder über den BackUP Master erstellen.
Eine dritte Möglichkeit ist praktisch, wenn Oxidized auf demselben Server läuft. Nach dem Ergänzen der passenden Einstellungen in der Optionsdatei erzeugt das Skript `devicelist.cfg` bei jedem Lauf dynamisch aus den Oxidized-Konfigurationsdateien.

<br />

## Erstellen und Bearbeiten der Liste

Um die Liste über BackUP Master zu erstellen, führen Sie aus:

```bash
mikrotik-backup.sh -b
```

Geben Sie Gerätename, Adresse, Benutzer, Kennwort und SSH-Port ein → wählen Sie **2. Gerät in `devicelist.cfg` speichern**.
BackUP Master erstellt entweder die Datei mit dem erforderlichen Eintrag oder fügt oder aktualisiert einen Eintrag in der vorhandenen Datei.

Sie können die fertige Liste in einem gewöhnlichen Texteditor bearbeiten. BackUP Master lädt keine vorhandenen Einträge in sein Formular.

*(Hinweis: Speichert der BackUP Master Port `22`, schreibt er ein leeres Feld. Eine spätere Stapelsicherung verwendet für diesen Eintrag `SshPort` aus den Skripteinstellungen. Ein vom Standard abweichender Port wird ausdrücklich eingetragen.)*

<br />

## Dateiformat

Schreiben Sie jedes Gerät in eine eigene Zeile. Trennen Sie die Felder mit einem **Tabulatorzeichen (TAB)**, nicht mit Leerzeichen. Die Feldreihenfolge lautet:

| Position | Feld | Zweck |
|---|---|---|
| 1 | Name | Gerätename; erforderlich |
| 2 | Adresse | Geräte-IP-Adresse oder DNS-Name; erforderlich |
| 3 | Benutzer | RouterOS-Gerätebenutzer; wenn leer, aus `Login` in `option.cfg` übernommen |
| 4 | Kennwort | Kennwort des RouterOS-Benutzers; wenn leer, aus `Password` in `option.cfg` übernommen |
| 5 | Port | SSH-Port von `1` bis `65535`; wenn leer, aus `SshPort` übernommen, dessen Standardwert `22` ist |
| 6 | Gerätekennung | `MikroTik`; darf leer sein, Groß- und Kleinschreibung wird ignoriert |

Felder ab Position sieben werden nicht verwendet. Einträge mit einem anderen Gerätemarker werden übersprungen.

### Beispielliste

Die Felder in diesem Beispiel sind durch tatsächliche TAB-Zeichen getrennt:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

Der Port wird in der zweiten Zeile weggelassen: Es erscheinen zwei TAB-Zeichen zwischen dem Kennwort und `MikroTik`. Ersetzen Sie die Adressen und Anmeldeinformationen durch Ihre eigenen.

### Gemeinsamer Benutzer, gemeinsames Kennwort und gemeinsamer Port

Wenn alle Ihre Geräte die gleichen Anmeldeinformationen verwenden, geben Sie diese einmal in `option.cfg` an:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Dann benötigt `devicelist.cfg` nur noch den Namen und die Adresse jedes Geräts:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Anmeldeinformationen, die im eigenen Eintrag eines Geräts angegeben sind, überschreiben die gemeinsamen Werte.

*(Hinweis: Die Gerätelistendatei enthält Kennwörter. Beschränken Sie den Zugriff wie in [SECURITY.md](SECURITY.md) beschrieben.)*

<br />

## Wie die Liste gelesen wird

Leerzeilen und Zeilen, deren erstes Nicht-Leerzeichen `#` ist, werden ignoriert. Schreiben Sie Kommentare in eigene Zeilen; ein `#` innerhalb eines Feldes gehört zum Feldwert.

Führende und nachlaufende Leerzeichen werden von Name, Adresse, Port und Marker entfernt. Benutzername und Kennwort werden wörtlich gelesen, einschließlich Leerzeichen und Anführungszeichen. Dateien mit Windows-Zeilenendungen (CRLF) werden unterstützt.

Verstößt eine Zeile – also ein Geräteeintrag – gegen die erforderliche Syntax, überspringt das Skript sie während des Laufs und meldet den ungültigen Eintrag als Warnung.

Ist eine Verbindung doppelt vorhanden – stimmen also alle vier Verbindungsparameter (**Adresse, Benutzername, Kennwort und Port**) überein –, verbindet sich das Skript nur einmal mit dem Gerät und verwendet die Daten des letzten Eintrags.
Wenn verschiedene Verbindungen den gleichen Namen haben, wird der erste nutzbare Eintrag verwendet und der widersprüchliche Eintrag übersprungen.

<br />

<a id="device-names"></a>
## Gerätenamen

Der Name wird in Sicherungsdateinamen und im Stapelbetrieb für das Geräteunterverzeichnis verwendet.
Die `UseIdentityName`-Einstellung in `option.cfg` bestimmt, woher der Name stammt:

| Wert | Namensquelle |
|---|---|
| `true` (Standard) | Der Identitätswert auf dem RouterOS-Gerät selbst |
| `false` | Der Name aus `devicelist.cfg`, dem BackUP-Master-Feld oder `--device-name` in einem CLI-Lauf mit einem Gerät |

### Name in Klammern

Enthält der ursprüngliche Name Klammern, verwendet das Skript den Inhalt der ersten vollständigen, nicht leeren Klammergruppe. Gibt es keine solche Gruppe, wird der gesamte Name verwendet.

| Ursprünglicher Name | Sicherungsname |
|---|---|
| `Niederlassung (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Niederlassung (Core (East) West)` | `Core_East_West` |

### Zulässige Zeichen

Im endgültigen Namen bleiben Buchstaben einschließlich kyrillischer Zeichen, Ziffern, Punkte, Bindestriche und Unterstriche erhalten. Leerzeichen und unzulässige Zeichen werden durch `_` ersetzt. Mehrfache sowie führende und nachgestellte Unterstriche werden entfernt; ebenso führende Punkte und Bindestriche sowie Punkte am Namensende.

`Rechenzentrum Berlin Nr. 1` wird beispielsweise zu `Rechenzentrum_Berlin_Nr_1`.

Der endgültige Name muss **1 bis 32 Zeichen** lang sein. Ein zu langer Name wird nicht gekürzt, sondern verursacht einen Fehler. Die reservierten Namen `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` und `LPT1`–`LPT9` sind unzulässig.

Endgültige Namen müssen unabhängig von der Groß-/Kleinschreibung eindeutig sein: `Router-A` und `router-a` gelten als gleich.

*(Hinweis: Eine Änderung des endgültigen Namens ändert auch das Geräteunterverzeichnis. Alte Sicherungen werden nicht automatisch verschoben.)*

<br />

## Import aus Oxidized

Wenn Sie bereits eine Geräteliste in Oxidized pflegen, kann das Skript sie von dort abrufen.

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Setzen Sie `OxidizedHome` in das Verzeichnis, das `config` und `router.db` enthält. Das Skript erstellt `devicelist.cfg` aus ihnen.

*(Hinweis: Import ersetzt `devicelist.cfg`; es erweitert die Datei nicht. Manuelle Ergänzungen gehen verloren, wenn ein Oxidized-Update das nächste Mal erfolgreich ist.)*

### Quelleneinstellungen

Die Oxidized-Konfiguration muss die Quelle `csv` mit einem einstelligen Trennzeichen verwenden. `source.csv.map` legt die Spaltenreihenfolge fest; die Nummerierung beginnt bei null:

| Zuordnungsfeld | Verwendeter Wert |
|---|---|
| `name` | Gerätename; erforderliche Spalte |
| `ip` | Geräteadresse; falls weggelassen, wird der `name`-Wert verwendet |
| `username` | Benutzername; falls leer, wird der gemeinsame Wert `Login` aus `option.cfg` verwendet |
| `password` | Kennwort; falls leer, wird das gemeinsame `Password` aus `option.cfg` verwendet |
| `port` | SSH-Port; falls weggelassen, wird `SshPort` verwendet |
| `model` | Gerätemodell; wenn die Spalte fehlt, wird der Stammparameter `model` verwendet |

Bei den Regeln von `model_map` gilt die erste Übereinstimmung. Importiert werden nur Geräte, deren endgültiges Modell `routeros` lautet. Existiert die Spalte `model`, ersetzt der Parameter auf oberster Ebene keine leeren Werte in dieser Spalte.

Die Daten werden immer aus `<OxidizedHome>/router.db` gelesen. Der Oxidized-Parameter `source.csv.file` ändert diesen Pfad nicht.

### Wenn der Import fehlschlägt

Sind die Oxidized-Dateien nicht verfügbar, wird ihr Format nicht unterstützt oder werden keine geeigneten Geräte gefunden, bleibt die bisherige `devicelist.cfg` erhalten.

Mit `IgnoreOxiAccess=true` kann das Skript die bisherige nutzbare Liste verwenden. Mit `false` wird keine Sicherung aus der alten Liste durchgeführt.

Ein Importfehler wirkt sich auch dann auf das Laufergebnis aus, wenn die Sicherungsverarbeitung mit der bisherigen Liste erfolgreich ist.

Siehe [Troubleshooting](TROUBLESHOOTING.md) für Details der Liste und Importfehler.
