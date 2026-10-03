# Installation

[Zur Übersicht](../README_DE.md)
## Host-Anforderungen

Das Skript benötigt Linux mit GNU Bash **4.4 oder neuer** und den üblichen GNU-Dateiwerkzeugen.
Das Skript selbst muss nicht kompiliert werden und benötigt weder Python noch einen Container oder eine Datenbank.
Zusätzlich werden die unter [Abhängigkeiten](#abhängigkeiten) aufgeführten Programme benötigt.

Für die Verarbeitung von Gerätenamen benötigt das Skript eine funktionsfähige **`C.UTF-8`**-Locale: Es muss Mehrbytezeichen zählen, Buchstaben erkennen und deren Groß-/Kleinschreibung ändern können.
Das Skript überprüft diese Fähigkeiten, bevor es mit Geräten arbeitet. Dies ist eine Systemanforderung, nicht ein separates Programm namens `C.UTF-8`.

Außerdem benötigt der Host Netzwerkzugriff auf den SSH-Dienst von RouterOS und Schreibrechte für den ausgewählten Speicher.

**Dringend empfohlen!!!**
Das Skript verbindet sich mit RouterOS-Geräten über SSH mit Kennwort-Authentifizierung, nicht mit schlüsselbasierter Authentifizierung.
(*Siehe [SECURITY.md](SECURITY.md) für die genaue Transportpolitik.*)
Sie sollten daher einen dedizierten Benutzer auf dem Gerät erstellen und die Anmeldung dieses Benutzers durch die IP-Adresse des Hosts, auf dem dieses Skript ausgeführt wird, einschränken.

<br />

## Abhängigkeiten

### Für Sicherungen erforderlich

**Alle folgenden Programme werden zum Erstellen von Sicherungen benötigt:**

| Programme | Zweck |
|---|---|
| `ssh`, `scp`, `sshpass` | Verbindung mit RouterOS herstellen, Befehle ausführen und Dateien abrufen |
| GNU `timeout`, `sleep` | Laufzeiten begrenzen und Pausen einfügen |
| `sha256sum` | Prüfsummen berechnen |
| `realpath` | Absolute Pfade ermitteln |
| `flock` | Gleichzeitige, miteinander kollidierende Läufe durch Sperren verhindern |

**Falls ein erforderliches Dienstprogramm fehlt, meldet das Skript eine nicht erfüllte Abhängigkeit
und bricht den Sicherungsversuch ab.
Der Abhängigkeitsfehlercode ist `30`. Dies ist erwartetes Verhalten.**

Die Liste gilt gleichermaßen für Einzelgeräte- und Stapelsicherungen, unabhängig davon, ob
das Skript `.rsc`, `.backup` oder beide Formate erstellt.

Programme mit den richtigen Namen allein genügen nicht. Das installierte OpenSSH muss
die vom Skript verwendeten Optionen unterstützen, einschließlich des mit `scp -O` ausgewählten klassischen SCP-Modus.
GNU `timeout` muss `--signal` und `--kill-after` unterstützen.
Diese Fähigkeiten werden lokal überprüft, ohne eine Verbindung zum Router herzustellen.

<br />

### Für bestimmte Funktionen erforderlich

Diese Werkzeuge gehören nicht zu den allgemeinen Abhängigkeiten; sie werden nur benötigt,
wenn die jeweilige Funktion verwendet wird.

| Funktion | Anforderung | Verhalten bei Fehlen |
|---|---|---|
| Stapelbetrieb mit `UseNetFolder=true` | `findmnt` | Die Sicherung startet in diesem Modus nicht; Abhängigkeitsfehler `30` |
| Ein Lauf, bei dem die monatliche Archivierung fällig ist | Info-ZIP `zip`, `unzip`, GNU `mv` | Der Lauf stoppt während der Abhängigkeitsprüfung, vor jeder Sicherung; Fehler `30` |
| Interaktives Menü, Konfigurations-Editor und BackUP-Master | `stty` und ein Terminal auf Standard-Ein- und -Ausgabe | Der interaktive Bildschirm wird nicht geöffnet; Terminalfehler `31` |
| **Konsolenbefehl kopieren** im BackUP Master | GNU `base64` mit Unterstützung für `--wrap=0` | Der Befehl kann nicht kopiert werden; Fehler `30` |

Beispielsweise verhindert ein fehlendes `zip` keinen gewöhnlichen Sicherungslauf, wenn die monatliche Archivierung nicht fällig ist.
Ein fehlendes `base64` verhindert nicht, dass Sicherungen erstellt werden.
*(Hinweis: Es wird benötigt, wenn Sie **Konsolenbefehl kopieren** auswählen.)*

Die allgemeine Abhängigkeitsprüfung läuft vor einer Sicherung, nicht jedes Mal, wenn das Programm geöffnet wird.
Daher können Hilfe, Versionsinformationen und das Menü auch dann verfügbar sein, wenn die Sicherungsprogramme nicht installiert sind.

<br />

### Linux-Basisumgebung

Das Skript setzt außerdem voraus, dass übliche Systembefehle für Dateien und Verzeichnisse
vorhanden sind, darunter `date`, `stat`, `mkdir`, `cp`, `ln` und `rm`.

Diese Befehle gehören zur Grundausstattung des Betriebssystems. Die vorab geprüfte Liste
umfasst nicht jeden externen Befehl, den das Skript verwendet. Fehlt ein Basisbefehl,
kann daher die betreffende Operation fehlschlagen, ohne dass eine Meldung über eine
nicht erfüllte Abhängigkeit erscheint.

<br />

### Installieren der erforderlichen Pakete auf Debian/Ubuntu

In diesem Beispiel werden die erforderlichen Tools und die oben aufgeführten optionalen Tools installiert:
*(Hinweis: Hier und unten wird angenommen, dass der Benutzer Administratorrechte hat.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Erhalten der Skriptdateien

Die primäre Installationsmethode für Version 2.3.1 ist das vollständige GitHub-Release-Asset `mikrotik-backup-2.3.1.zip`. Es wird ohne zusätzliches übergeordnetes Verzeichnis direkt in das Installationsverzeichnis entpackt.
*(Hinweis: Führen Sie Beispiele, die Dateien unter `/opt` ablegen, mit den erforderlichen Rechten zum Erstellen und Beschreiben dieses Verzeichnisses aus.)*

### Option 1: Vollständiges Release-Paket

Laden Sie `mikrotik-backup-2.3.1.zip` aus dem GitHub Release von MikroTik Backup Script 2.3.1 herunter und führen Sie Folgendes aus:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Nach dem Entpacken sieht die einsatzbereite Struktur so aus:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Wenn die Prüfsummenprüfung fehlschlägt, führen Sie das Skript erst aus, nachdem Sie die Ursache gefunden haben.

<br />

### Option 2: Minimale eigenständige Installation

Laden Sie die Assets `mikrotik-backup.sh` und `SHA256SUMS` aus demselben Release in ein geschütztes Verzeichnis herunter, prüfen Sie sie und machen Sie das Skript ausführbar:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Laden Sie beide Release-Assets in dieses Verzeichnis herunter.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Verwenden Sie für eine externe Laufzeitsprache das vollständige Paket oder beziehen Sie die passende `.lang`-Datei aus dem getaggten Quelltext derselben Version.

<br />

### Erweiterte Option: Git oder Quellcode-Archiv

Ein Git-Clone oder das **Code → Download ZIP**-Archiv dieses Repositorys ist ebenfalls ein vollständiger Produkt-Quellbaum. Die relevante Struktur im Stammverzeichnis ist:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` ist ein Release-Asset und kann in einem Quellcode-Checkout fehlen. Für eine normale Installation wird weiterhin das versionierte Release-Paket empfohlen, weil es die Prüfsummendatei enthält und genau der veröffentlichten Version entspricht.

<br />

## Dateien neben dem Skript

Nach dem Entpacken des vollständigen Release-Pakets enthält das gewählte Verzeichnis das Skript und die zugehörigen Dateien:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Datei oder Verzeichnis | Zweck |
|---|---|
| mikrotik-backup.sh | Das Sicherungsskript selbst |
| SHA256SUMS | Prüfsummen zur Überprüfung der heruntergeladenen Dateien |
| README.md | Produktbeschreibung und Links zur detaillierten Dokumentation |
| lang/ | Lokalisierungsdateien. Kopieren Sie die erforderliche Sprachdatei aus diesem Verzeichnis in das Skriptverzeichnis. |
| docs/ | Detaillierte Installations-, Konfigurations- und Nutzungsdokumentation |

Für den tatsächlichen Betrieb ist nur `mikrotik-backup.sh` erforderlich.
Um Einstellungen zu ändern, erstellen Sie **option.cfg** und platzieren Sie es neben dem Skript.
Wenn Sie mehrere Geräte nacheinander abfragen und sichern möchten, erstellen Sie auch **devicelist.cfg** neben dem Skript.
Eine Lokalisierungsdatei mit dem Namen `<xx>.lang` wird benötigt, wenn Sie Menüs und Protokolleinträge in Ihrer eigenen Sprache wünschen.
Russisch und Englisch erfordern keine separaten Lokalisierungsdateien, da beide in das Skript integriert sind.

**Im interaktiven Modus kann das Skript folgende Dateien erstellen und speichern:**

- die Geräteliste **devicelist.cfg** über den BackUP Master;
- die Konfigurationsdatei **option.cfg** über den Konfigurationseditor.

Sie können beide Dateien auch selbst vorbereiten:
*Das TSV-Gerätelistenformat wird ausführlich in [DEVICES.md](DEVICES.md) beschrieben.*
*Das Konfigurationsdateiformat `Key=value` ist im Detail in [OPTIONS.md](OPTIONS.md) beschrieben.*

<br />

## Speicher und Protokolle vorbereiten

Mit den Standardsicherungseinstellungen erstellt das Skript neben seiner eigenen Datei ein Verzeichnis `./backups` und speichert dort die Gerätesicherungen.
Der einzige Unterschied zwischen den Modi besteht darin, dass ein Einzelgerätelauf die erstellten Dateien direkt in `./backups` platziert, während der Stapelbetrieb ein Unterverzeichnis mit dem Gerätenamen unter `./backups` erstellt und die Sicherungen dieses Geräts dort speichert.

Das Skript erstellt die erforderlichen Speicherverzeichnisse selbst mit den entsprechenden Berechtigungen.
*(Es ändert nicht automatisch den Besitzer oder den Zugriffsmodus bestehender vom Administrator erstellter Verzeichnisse.)*

Standardmäßig wird das Hauptprotokoll des Skripts, `main.log`, in `./backups` gespeichert.
Im Stapelbetrieb wird ein Geräteprotokoll im Unterverzeichnis dieses Geräts gespeichert.

Liegt Ihr Sicherungsverzeichnis auf einem Netzwerkspeicher, kann das Skript dessen Verfügbarkeit
während der Stapelverarbeitung prüfen. Diese Funktion ist standardmäßig deaktiviert und muss vor der Verwendung konfiguriert werden.
*(Wie das Verzeichnis gemountet ist, spielt keine Rolle.)*

Alle diese Optionen können geändert werden, indem die erforderlichen Parameter in `option.cfg` eingestellt werden.
Siehe [Konfiguration](OPTIONS.md) für Anweisungen und Parametersyntax.

<br />

## Automatisches Ausführen des Skripts

Bevor Sie einen Zeitplan aktivieren, bereiten Sie die Einstellungen und die Geräteliste vor.
Andernfalls kann ein automatischer Lauf keine Stapelsicherung durchführen.

Ein eigener Benutzer ist nicht zwingend erforderlich; solche Aufgaben als **root** auszuführen gilt jedoch als schlechte Praxis.

Erstellen Sie den Benutzer **bsmt** *(Sie können einen anderen Namen wählen; ersetzen Sie dann **bsmt** in den Beispielen)* und erteilen Sie ihm nur die erforderlichen Rechte:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Wenn das Skript bereits als root ausgeführt wurde**

*(Hinweis: Wenn Sie das Skript zuvor als **root** ausgeführt haben, sind die dabei erstellten Verzeichnisse, Sicherungen
und Protokolle möglicherweise nicht für **bsmt** zugänglich.
Übertragen Sie den vorhandenen Speicher an diesen Benutzer, bevor Sie den Zeitplan aktivieren.
)*

In diesem Beispiel wird das lokale Verzeichnis `/opt/mikrotik-backup/backups` verwendet.
Der folgende Befehl ändert den Besitzer und die Gruppe des Verzeichnisses und alles darin:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(Hinweis: Geben Sie das Sicherungsverzeichnis dieses Skripts an, nicht ein freigegebenes Verzeichnis, das auch Daten anderer Programme enthält.)*
Wenn sich das Speicher- oder Hauptprotokoll an anderer Stelle befindet, konfigurieren Sie den Zugriff auf jedes einzelne separat gemäß den Berechtigungen und Einstellungen des ausgewählten Speichers nach demselben Muster.

In diesem Beispiel wird der Konfigurationseditor als **bsmt** geöffnet, nachdem dem Benutzer Zugriff auf das Skriptverzeichnis und die Dateien gewährt wurde:
*(Hinweis: Führen Sie den Befehl als root oder als Benutzer aus, der dies über sudo tun darf.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Einen Zeitplan für das Skript erstellen**

Das folgende Beispiel erstellt einen Zeitplan mit systemd.
Sie können stattdessen auch crontab oder eine andere bevorzugte Methode verwenden.

Wir werden einen Dienst erstellen, der das Skript als unseren dedizierten Benutzer ausführt, und einen Timer, der es planmäßig startet.
*(Das Beispiel läuft täglich um 01:00 Uhr; den tatsächlichen Zeitplan legen Sie selbst fest.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` ermöglicht keinen Aufhollauf nach einer Zeit, in der der Timer ausgeschaltet war.
`Restart=no` plant keine automatischen Dienstneustarts nach einem Fehler.*
