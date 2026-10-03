# Protokollierung

[Zur Übersicht](../README_DE.md)
## Hauptprotokoll und Geräteprotokolle

Das Skript zeichnet seinen Gesamtfortschritt im Hauptprotokoll `main.log` auf, während die Details der Arbeit mit jedem Gerät in einem separaten Geräteprotokoll gespeichert werden.

In `main.log` können Sie nachvollziehen, wie die Geräteliste erstellt wurde, die Stapelverarbeitung verfolgen und die Ergebnisse der Geräteabfragen prüfen.

Ein Geräteprotokoll enthält Informationen zum Abruf von `.rsc`- und `.backup`-Dateien, zu Wiederholungsversuchen, Sicherungsvergleichen und zur Archivierung. Wenn Sie wissen möchten, was bei der Sicherung eines bestimmten Geräts geschah, sehen Sie dort nach. Diese Einzelheiten werden nicht zusätzlich in `main.log` geschrieben.

<br />

## Wo Protokolle gespeichert werden

Standardmäßig wird das Hauptprotokoll im Verzeichnis `backups` neben dem Skript gespeichert.

| Protokoll | Speicherort |
|---|---|
| Hauptprotokoll | `<BackupRoot>/main.log` |
| Gerät im Stapelbetrieb | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Gerät in einem Einzelgerätelauf | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

Im Stapelbetrieb werden neue Einträge an dasselbe Geräteprotokoll angehängt. Bei einem Einzelgerätelauf enthält der Protokollname dasselbe Datum und dieselbe Uhrzeit wie die Sicherungsdateien dieses Laufs.

### Ein separates Verzeichnis für main.log

Wenn Sie das Hauptprotokoll von den Sicherungen getrennt halten möchten, geben Sie das Verzeichnis in der `MainLogPath`-Einstellung in `option.cfg` an:

```ini
MainLogPath=/var/log/mikrotik-backup
```

Das Protokoll wird dann in `/var/log/mikrotik-backup/main.log` geschrieben. Die Geräteprotokolle bleiben an ihren üblichen Speicherorten.

Bei leerem `MainLogPath=` wird das aktuelle `BackupRoot` verwendet. Ein relativer Pfad wie `MainLogPath=logs` bezeichnet ein Verzeichnis neben dem Skript, nicht innerhalb des Sicherungsspeichers.

*(Hinweis: `MainLogPath` spezifiziert ein Verzeichnis, keinen vollständigen Dateinamen. Das Verzeichnis muss bereits vorhanden und vom Benutzer mit dem Skript beschreibbar sein.)*

<br />

## Detailebene der Protokollierung

Die Einstellung `LogLevel` steuert, wie viele Informationen angezeigt und aufgezeichnet werden.

| Wert | Fortschritt im Terminal | Einträge in Protokolldateien |
|---|---|---|
| `0` | Nur Fehler | Nur Fehler |
| `1` | Hauptphasen und ihre Ergebnisse | Kurzprotokoll |
| `2` | Hauptphasen und ihre Ergebnisse | Detailliertes Protokoll |
| `3` | Hauptphasen und aktuelle Teilvorgänge | Detailliertes Protokoll |

**Fehler werden auf jeder Ebene aufgezeichnet.** Ein kurzes Protokoll enthält die Hauptphasen und ihre Ergebnisse; ein detailliertes Protokoll zeichnet auch die in diesen Phasen durchgeführten Operationen auf.

Sie können die Stufe in `option.cfg` oder über den Konfigurationseditor ändern:

```ini
LogLevel=3
```

Um sie für einen Lauf einer bereits konfigurierten Stapelsicherung zu ändern, verwenden Sie die CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Dadurch ändert sich der Wert in der Optionsdatei nicht. Auf die gleiche Weise kann `--main-log-path` den Hauptprotokollspeicherort für den aktuellen Lauf festlegen.

Der BackUP Master besitzt keine eigenen Felder für `LogLevel` oder `MainLogPath`. Er verwendet die für den aktuellen Lauf geltenden Protokollierungseinstellungen.

<br />

## Aufbau der Protokolleinträge

Protokolle sind normale Textdateien. Jeder Eintrag enthält Datum und Uhrzeit gemäß der lokalen Zeit des ausführenden Hosts. Farben und Fortschrittsanzeigen werden nicht in die Datei geschrieben.

Beispieleinträge in `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Stapelverarbeitung der Geräte
[2026-10-01 01:00:15] [PID:12345] [OK] Stapelverarbeitung der Geräte
```

Das Hauptprotokoll enthält auch die Prozess-PID, mit der Sie Einträge unterscheiden können, die von mehreren gleichzeitig ausgeführten Skriptinstanzen geschrieben wurden.

Die PID wird nicht zu einem Geräteprotokoll hinzugefügt. Hier ist ein Auszug aus einem detaillierten Protokoll:

```text
[2026-10-01 01:00:05] Binäre Sicherung wird abgerufen
[2026-10-01 01:00:06] [1] DNS-Cache wird geleert
[2026-10-01 01:00:07] [2] Konsolenverlauf wird geleert
[2026-10-01 01:00:12] [OK] Binäre Sicherung wird abgerufen
```

`[OK]` bedeutet, dass die Operation erfolgreich abgeschlossen wurde. Ein Fehler wird mit `[ER]` markiert und enthält seinen Code, z. B. `[53]`. Die Teiloperationen werden mit `[1]`, `[2]` usw. nummeriert und beginnen innerhalb jeder Hauptstufe von vorne.

Erfolgt ein Wiederholungsversuch nach einem fehlgeschlagenen Versuch, behält das Protokoll sowohl den früheren Fehler als auch das später erfolgreiche Ergebnis bei.

Protokolleinträge verwenden dieselbe, über `Language` gewählte Sprache wie die Oberfläche. Weitere Informationen zur Sprachauswahl und zu Übersetzungen finden Sie in [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Terminalausgabe

Bei einer manuellen Ausführung ist der Fortschritt auf dem Bildschirm sichtbar. Neben dem laufenden Vorgang erscheint eine Warteanzeige. Nach Abschluss wechselt sie zu einem grünen `[OK]` oder einem roten `[ER]` mit Fehlercode.

Die Stufen `1` und `2` zeigen die Hauptphasen. Auf Stufe `3` erscheint darunter zusätzlich der aktuelle Teilvorgang und wird im Arbeitsverlauf aktualisiert. Im Stapelbetrieb nennt die Anzeige außerdem das gerade bearbeitete Gerät.

*(Hinweis: Wenn das Skript ohne Terminal läuft – zum Beispiel von einem Scheduler aus oder mit umgeleiteter Ausgabe – fehlt diese Bildschirmausgabe. Die Dateiprotokollierung wird auf der ausgewählten Ebene fortgesetzt.)*

<br />

## Fortführung und Archivierung der Protokolle

Mit `LogLevel=0` und ohne Fehler werden keine neuen Protokolldateien erstellt, während bestehende unverändert bleiben.

Das Hauptprotokoll und die Geräteprotokolle des Stapelbetriebs werden bei jedem Lauf fortgeschrieben und nicht überschrieben; aufeinanderfolgende Läufe trennt eine Leerzeile.

`main.log` wird weder archiviert noch altersbedingt entfernt.

Bei aktivierter monatlicher Archivierung wird das gesamte bis dahin fortgeschriebene Geräteprotokoll des Stapelbetriebs zusammen mit den Sicherungen des Geräts in das ZIP-Archiv aufgenommen. Sobald das Archiv erfolgreich gespeichert ist, wird das archivierte Protokoll aus dem Geräteverzeichnis entfernt. Das Archivierungsergebnis und nachfolgende Vorgänge werden in eine neue Protokolldatei geschrieben.

Wird dasselbe ZIP-Archiv erneut aktualisiert, wird der darin enthaltene Verlauf ergänzt und nicht durch ein neues Protokoll ersetzt. Kann das Archiv nicht gespeichert werden, bleibt das bisherige Protokoll bestehen und nimmt die Fehlermeldung auf.

Protokolle von Einzelgeräte-CLI-Läufen werden zusammen mit Sicherungen aus dem gemeinsamen Verzeichnis archiviert. Die Archivierung in beiden Modi ist in [BACKUPS.md](BACKUPS.md#monthly-archive) beschrieben.

<br />

## Wenn ein Protokoll nicht geschrieben werden kann

Unzureichende Berechtigungen, ein nicht verfügbares Verzeichnis oder ein anderer Fehler beim Schreiben des Protokolls stoppen die Sicherung selbst nicht.

Ein nicht verfügbares `main.log` wird einmal pro Durchlauf gemeldet und ein nicht verfügbares Geräteprotokoll einmal während der Verarbeitung des Geräts; wenn das Hauptprotokoll verfügbar ist, wird dort ein Geräteprotokollschreibfehler aufgezeichnet.

Gibt es keine weiteren Fehler, endet der Lauf mit Code `1`: Er wurde mit einer Warnung abgeschlossen, die keinen Fehler der Sicherung selbst ersetzt.

Für Ergebniscodes und Hilfe bei der Suche nach der Ursache eines Fehlers siehe [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(Hinweis: Detaillierte Ebene `3` protokolliert keine Kennwörter oder vollständige Verbindungsbefehle. Für Informationen zum Schutz von Anmeldeinformationen und Skriptdateien siehe [SECURITY.md](SECURITY.md).)*
