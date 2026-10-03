# Sicherheit

[Zur Übersicht](../README_DE.md)
## Konten

Das Skript benötigt keine **root**-Rechte. Ein gewöhnlicher Benutzer braucht lediglich Zugriff auf die Konfigurationsdateien sowie Schreibrechte für den gewählten Speicher und die Protokolle.

Wie Sie einen eigenen Benutzer **bsmt** anlegen und das Skript unter diesem Konto ausführen, beschreibt [INSTALL.md](INSTALL.md#automatisches-ausführen-des-skripts).

Auf dem RouterOS-Gerät empfiehlt sich ebenfalls ein eigener Sicherungsbenutzer, dessen Anmeldung auf die IP-Adresse des Skript-Hosts beschränkt ist. Die Rechte dieses Kontos müssen die gewählten Vorgänge erlauben: Konfiguration abrufen, Sicherungen erstellen und herunterladen, temporäre Dateien löschen und aktivierte Bereinigungsschritte ausführen.

<br />

## Verbindung zu RouterOS

Das Skript verbindet sich per SSH mit Kennwortauthentifizierung. SSH-Schlüssel und SSH-Agent werden nicht verwendet. Dateien werden über das klassische SCP-Protokoll, also mit `scp -O`, abgerufen.

Das Skript verwendet seine eigenen Verbindungseinstellungen. Es liest nicht die `~/.ssh/config` des Benutzers oder die System-SSH-Konfiguration, da der Client mit `-F /dev/null` gestartet wird. Agent, X11 und Port-Weiterleitung sind deaktiviert.

**Bitte beachten Sie!!! Die Prüfung des Server-Hostschlüssels ist deaktiviert.**

Das aktuelle Profil verwendet diese Einstellungen:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Die üblichen `known_hosts`-Dateien werden weder gelesen noch geändert. Das Skript prüft daher nicht, ob der antwortende Server wirklich das erwartete Gerät und kein Angreifer ist.

<br />

<a id="secrets"></a>
## Kennwörter beim Starten des Skripts

Ein über `--password` oder `-p=` übergebenes Kennwort wird Teil des Startbefehls. Es kann in Prozessargumenten sichtbar sein und im Shell-Verlauf gespeichert werden. Gleiches gilt für ein über `--encrypt` übergebenes Verschlüsselungskennwort.

### Kennwörter über BackUP Master eingeben

Um zu vermeiden, dass das SSH-Kennwort in der Befehlszeile platziert wird, starten Sie BackUP Master:

```bash
mikrotik-backup.sh -b
```

Füllen Sie die Gerätezugangsdaten im Formular aus und wählen Sie die gewünschte Aktion. Beide Kennwörter erscheinen als Sternchen; die eingegebenen Werte gelangen nicht in den Shell-Verlauf.

Beim Verbinden übergibt das Skript selbst das SSH-Kennwort an `sshpass` über einen Dateideskriptor (`-d`), nicht über das `sshpass -p`-Argument oder die `SSHPASS`-Umgebungsvariable.

### Das Verschlüsselungskennwort für `.backup`

Das Verschlüsselungskennwort ist Teil des RouterOS-Befehls, der an den Kindprozess `ssh` übergeben wird. Ein Hostbenutzer mit ausreichenden Rechten zum Einsehen von Prozessargumenten kann es daher während einer binären Sicherung sehen.

Ob das Kennwort im BackUP Master eingegeben oder in `option.cfg` gespeichert wird, ändert nichts an dieser Übergabe.
Die Dateiverschlüsselung bietet keinen Schutz vor einem Administrator des Sicherungshosts selbst.

### Kopieren eines Konsolenbefehls

Die Aktion **3. Konsolenbefehl kopieren** im BackUP Master legt einen Befehl mit den Zugangsdaten – und bei entsprechend konfigurierter binärer Sicherung auch mit dem Verschlüsselungskennwort – in die Zwischenablage.

Beachten Sie dies beim Verwenden des Zwischenablageverlaufs und beim Einfügen in eine Shell. Die Sternchenanzeige im Formular bedeutet nicht, dass das Kennwort im kopierten Befehl maskiert wäre.

<br />

## Dateien, die sensible Daten enthalten

| Datei | Möglicher Inhalt |
|---|---|
| `devicelist.cfg` | Geräteadressen, Logins und SSH-Kennwörter im Klartext |
| `option.cfg` | Gemeinsame Werte für `Login` und `Password` sowie das Verschlüsselungskennwort `encrypt` |
| `.rsc` und `.backup` | Gerätekonfiguration, Kennwörter und andere sensible Daten |
| Monatliches ZIP-Archiv | Dieselben Sicherungen und Protokolle, zusammengefasst in einem Archiv |

Platzieren Sie keine Arbeitseinstellungsdateien oder Sicherungen in einem öffentlichen Repository oder einem öffentlich zugänglichen Verzeichnis.

### Vertrauliche Daten in `.rsc`-Dateien

Standardmäßig gilt `show_sensitive=true`; vertrauliche Werte sind daher im Textexport enthalten.

```ini
show_sensitive=false
```

Selbst dann ist die Datei immer noch eine Konfiguration Ihres Geräts: Adressen, Netzwerkstruktur, Kommentare und andere vom Benutzer bereitgestellte Zeichenfolgen verschwinden nicht aus ihr.

### Verschlüsselung binärer Sicherungen

Standardmäßig ist `encrypt` leer und `.backup` wird ohne Verschlüsselung gespeichert.

```ini
encrypt=MySuperPassword
```

Verwendet wird der Algorithmus AES-SHA256. Er verschlüsselt **nur `.backup`**, nicht `.rsc`, `option.cfg`, die Geräteliste, Protokolle oder das ZIP-Archiv selbst. Der Zugriff auf das Monatsarchiv muss daher ebenso sorgfältig eingeschränkt werden wie der Zugriff auf die darin enthaltenen Dateien.

<br />

## Datei- und Speicherberechtigungen

Das Skript läuft mit `umask 077`. Neu angelegte lokale Speicherverzeichnisse erhalten den Modus `0700`; programmgesteuert gespeicherte Dateien `option.cfg` und `devicelist.cfg` erhalten `0600`.

Der Eigentümer und die Berechtigungen bestehender, vom Administrator erstellter Speicherverzeichnisse werden nicht automatisch geändert.

Das Verzeichnis des lokalen Monatsarchivs, `archive/`, muss den Modus `0700` haben und dem Benutzer gehören, der das Skript ausführt. Diese Anforderung gilt auch für ein bestehendes Verzeichnis. Lokale Archivdateien, die durch das Skript erstellt wurden, haben den Modus `0600`.

Im Stapelbetrieb kann der NAS-Server bei Verwendung des verifizierten Netzwerkspeichers mit `UseNetFolder=true` möglicherweise Archivobjektbesitzer und -berechtigungen ermitteln. Ein Unterschied zu den lokalen Werten allein stoppt die Archivierung nicht. Konfigurieren Sie den Zugriff auf den Netzwerkspeicher über Ihr Betriebssystem und NAS.

Beispiele für die Erstellung von Verzeichnissen und die Gewährung des Zugriffs auf den **bsmt**-Benutzer finden Sie in [INSTALL.md](INSTALL.md).

*(Hinweis: Das Skript liest seine Konfiguration, Geräteliste, Übersetzungen und alle verwendeten Oxidized-Einstellungen als Daten; es führt sie nicht als Shell-Skripte aus.)*

<br />

## Änderungen am Gerät

Standardmäßig werden der RouterOS-DNS-Cache und der Konsolenverlauf vor einer binären Sicherung geleert.

```ini
clear_dns_cache=false
clear_console_history=false
```

Sie können beide Funktionen im Konfigurationseditor, im BackUP Master oder über die entsprechenden CLI-Optionen deaktivieren. Wird nur `.rsc` abgerufen, finden diese Bereinigungsschritte nicht statt.

<br />

## Protokolle und Austausch von Diagnoseinformationen

Die Detailebene `LogLevel=3` fügt Informationen zu Verarbeitungsstufen hinzu; sie gibt keine Kennwörter oder vollständige Verbindungsbefehle aus.

Die aufbereitete SSH-Diagnose maskiert die exakt bekannten Werte für Adresse, Benutzername, SSH-Kennwort und Verschlüsselungskennwort. Das garantiert weder eine Bereinigung des Sicherungsinhalts noch die Entfernung jedes Geheimnisses aus beliebigem Text.

Vorübergehende Dateien, die nicht verarbeitete Diagnosen enthalten, können sensible Daten enthalten, die im Modus `0600` erstellt und bei der normalen Bereinigung entfernt werden.

Prüfen Sie Protokolle, Screenshots und Befehlsausgaben, bevor Sie sie weitergeben. Die vollständige Ausgabe von `devicelist.cfg`, einer Prozessliste oder des Zwischenablageinhalts kann Daten offenlegen, die im normalen Protokoll fehlen.

Weitere Informationen zu Protokolleinträgen finden Sie unter [LOGGING.md](LOGGING.md); für Hilfe bei der Fehleruntersuchung siehe [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Gleichzeitige Läufe

Läufe desselben Benutzers mit demselben `BackupRoot` werden wie folgt gesperrt:

| Gleichzeitige Läufe | Verhalten |
|---|---|
| Ein Stapellauf und ein weiterer Stapel- oder Einzelgerätelauf | Der zweite Lauf erhält die Sperre nicht |
| Zwei Einzelgeräteläufe für dasselbe Gerät | Der zweite Lauf erhält die Sperre nicht |
| Einzelgeräteläufe für unterschiedliche Geräte | Sie können gleichzeitig laufen |

Ist die Sperre belegt, endet das Skript mit Code `32`. Verschiedene Speicherstämme werden nicht als gemeinsamer Speicherbereich koordiniert, auch wenn einer im anderen liegt.

Sperrdateien werden in `/tmp/mikrotik-backup-${UID}/` aufbewahrt und bleiben nach dem Ende des Skripts erhalten.

**Löschen Sie diese Dateien nicht, um eine vermeintlich veraltete Sperre zu beseitigen.** Die Sperre hängt an einem offenen Dateideskriptor des Prozesses, nicht an der Existenz der Datei. Außerdem schützen diese Sperren die Daten nicht vor einem anderen Programm, das sie direkt verändert.

<br />

## Wiederherstellungstest

Die Prüfung der Skriptprüfsumme und der erfolgreiche Abruf einer Sicherungsdatei ersetzen keinen Wiederherstellungstest.

Das Skript selbst stellt RouterOS nicht wieder her. Sie müssen separat prüfen, ob sich die Sicherungen auf einem geeigneten Gerät verwenden lassen, und ihre Aufbewahrungsdauer festlegen. Weitere Informationen finden Sie in [BACKUPS.md](BACKUPS.md).
