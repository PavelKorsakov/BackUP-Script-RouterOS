# Lokalisierung

[Zur Übersicht](../README_DE.md)
## Sprache der Oberfläche und der Protokolle

Russisch (`ru`) und Englisch (`en`) sind in das Skript integriert und benötigen keine separaten Übersetzungsdateien. Mit Version 2.3.1 werden die externen Übersetzungen für Oberfläche und Protokolle `de.lang`, `es.lang`, `lv.lang`, `pl.lang` und `uk.lang` ausgeliefert.

Die Sprache der Dokumentation und die Verfügbarkeit einer externen Laufzeitübersetzung sind voneinander unabhängig. Deshalb kann Dokumentation in einer Sprache vorhanden sein, für die kein entsprechendes `.lang` mitgeliefert wird.

Die gewählte Sprache wird in Menüs, Hilfe, Skriptnachrichten und Protokolleinträgen verwendet.

<br />

## Eine Sprache wählen

Die Einstellung `Language` in `option.cfg` steuert die Auswahl.

| Wert | Verwendete Sprache |
|---|---|
| `auto` | Ermittelt aus dem Gebietsschema des Betriebssystems |
| `ru` | Eingebautes Russisch |
| `en` | Eingebautes Englisch |
| Ein anderer zweibuchstabiger Code, z. B. `de` | Übersetzung aus der entsprechenden Datei, z. B. `de.lang` |

Um Russisch dauerhaft auszuwählen, legen Sie dies in `option.cfg` fest:

```ini
Language=ru
```

Für einen einzelnen Durchlauf können Sie die Sprache über die CLI auswählen:

```bash
mikrotik-backup.sh --language=ru --help
```

Die Option `--language` hat Vorrang vor der Einstellung in der Optionsdatei, ändert jedoch die Datei selbst nicht. Verwenden Sie entweder `auto` oder einen zweistelligen Sprachcode; Groß- und Kleinschreibung spielt keine Rolle.

### Automatische Auswahl

Bei `auto` verwendet das Skript in dieser Reihenfolge den ersten nicht leeren Wert aus `LC_ALL`, `LC_MESSAGES` und `LANG`.

`ru_RU.UTF-8` wählt beispielsweise Russisch, während `de_DE.UTF-8` die deutsche Übersetzung aus `de.lang` auswählt. Bei `C`, `C.UTF-8`, `POSIX` oder einer nicht ermittelbaren Sprache wird Englisch verwendet.

Auch wenn die gewählte externe Übersetzung nicht verfügbar ist, werden Meldungen auf Englisch angezeigt.

<br />

## Externe Übersetzung einbinden

Das Verzeichnis `lang/` enthält die fertigen externen Übersetzungen `de.lang`, `es.lang`, `lv.lang`, `pl.lang` und `uk.lang` sowie die kanonische Vorlage `en.lang`. Kopieren Sie die benötigte externe Übersetzung in das Verzeichnis mit `mikrotik-backup.sh`.

Führen Sie dies beispielsweise im Skriptverzeichnis aus, um Deutsch zu installieren:

```bash
cp -- lang/de.lang de.lang
```

Wählen Sie dann `de` in den Einstellungen aus oder geben Sie es beim Starten des Skripts an:

```bash
mikrotik-backup.sh --language=de --help
```

Der Dateiname besteht aus zwei lateinischen Buchstaben und der `.lang`-Erweiterung, z. B. `de.lang`. Es muss sich um eine gewöhnliche lesbare Datei handeln, nicht um einen symbolischen Link.

*(Hinweis: Das Verzeichnis `lang/` enthält die Sammlung der Übersetzungen. Das Skript lädt sie dort nicht automatisch: Die benötigte Datei muss neben dem Skript liegen.)*

`en.lang` enthält alle 245 Schlüssel der Version 2.3.1 und ist die kanonische Vorlage für Übersetzungen Dritter. Sie ersetzt das integrierte Englisch nicht und wird nicht als externe Laufzeitsprache verwendet. Auch eine selbst angelegte `ru.lang` ersetzt das integrierte Russisch nicht und wird ignoriert.

<br />

## Sprache im Konfigurationseditor wählen

Öffnen Sie den Editor mit:

```bash
mikrotik-backup.sh -e
```

Gehen Sie zur Sprachzeile → drücken Sie **Enter**, bis der gewünschte Wert erscheint → wählen Sie „Speichern“.

Die Optionen wechseln in folgender Reihenfolge:

```text
auto → ru → en → erkannte externe Sprachen in alphabetischer Reihenfolge → auto
```

Die Formularsprache ändert sich sofort. Bis zum Speichern ist dies nur eine Vorschau; „Abbrechen“ stellt die vorherige Oberflächensprache wieder her. Wurde beim Start `--language` angegeben, gilt diese CLI-Option nach dem Verlassen des Editors erneut.

Kommentare in der gespeicherten `option.cfg` verwenden die Sprache, die von der `Language`-Einstellung selbst ausgewählt wurde, keine temporäre CLI-Option.

Weitere Informationen zum Editor finden Sie in [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Erstellen und Bearbeiten einer Übersetzung

Ist die benötigte Übersetzung noch nicht vorhanden, können Sie sie selbst erstellen. Nehmen Sie `lang/en.lang` derselben Skriptversion und speichern Sie eine Kopie als `<xx>.lang`, wobei `xx` der zweibuchstabige Code der neuen Sprache ist. Die Vorlage der Version 2.3.1 enthält alle 245 Schlüssel.

Das Format ist einfach: Jede Nachricht hat ihre eigene Zeile, zum Beispiel enthält die englische Vorlage:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Jeder Schlüssel beginnt mit `msg_`, gefolgt von dem Nachrichtennamen (`version`, `menu_title`) und dem Sprachsuffix `_en`.

Ersetzen Sie für eine neue Sprache das Suffix `_en` in allen Schlüsseln durch `_xx` und übersetzen Sie nur die Werte in Anführungszeichen. Ändern Sie die Nachrichtennamen nicht und erhalten Sie alle Platzhalter exakt. Um eine vorhandene Übersetzung zu korrigieren, genügt es, den erforderlichen Text rechts neben `=` zu ändern.

Sie müssen nicht die gesamte Datei auf einmal übersetzen: Fehlende Meldungen erscheinen auf Englisch. Das Skript übernimmt keine beliebigen neuen Schlüssel.

### Dateiformatregeln

Speichern Sie die Datei als UTF-8. Setzen Sie jeden nicht leeren Wert in doppelte Anführungszeichen. Vor einem Schlüssel, um `=` und nach dem schließenden Anführungszeichen sind keine Leerzeichen zulässig.

Verwenden Sie `\"` für ein doppeltes Anführungszeichen im Text und `\\` für einen Backslash. Andere Escape-Sequenzen, darunter `\n` und `\t`, werden nicht unterstützt. Ein `=` innerhalb der Anführungszeichen ist zulässig.

Leere Zeilen werden übersprungen. Das `.lang`-Format kennt keine Kommentare; ein `#` innerhalb von Anführungszeichen gehört zum Text. Windows-Zeilenenden (CRLF) und eine UTF-8-BOM am Dateianfang werden unterstützt.

Eine fehlerhafte Zeile wird übersprungen, während andere gültige Übersetzungen weiter verwendet werden. Wird eine Nachricht mehr als einmal angegeben, gewinnt der letzte gültige Eintrag. Steuerzeichen und Terminal-Farbcodes sind in Übersetzungen nicht zulässig.

*(Hinweis: Eine Lokalisierungsdatei wird als Textdaten behandelt. Variablen werden nicht erweitert und Shell-Befehle werden nicht von ihr ausgeführt.)*

### Platzhalter in Nachrichten

Einige Zeichenfolgen enthalten Werte in geschweiften Klammern, zum Beispiel:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Zur Laufzeit ersetzt das Skript `{index}` und `{total}` durch die Gerätenummer und die Gesamtzahl der Geräte. Übersetzen Sie diese Markierungen nicht: bewahren Sie jeden Platzhalter aus der Quellzeichenfolge genau einmal. Sie können seine Position innerhalb des Satzes ändern.

Wenn die Platzhalter ungültig sind, wird die englische Nachricht anstelle dieser Zeichenfolge verwendet.

Prüfen Sie die Übersetzung nach dem Speichern mit der gewählten Sprache in der Hilfe und im interaktiven Menü.
