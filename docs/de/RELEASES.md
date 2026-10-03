# Releases

[Zur Übersicht](../README_DE.md)
## Version 2.3.1

**Ein Wartungs- und Hotfix-Release nach der veröffentlichten Version 2.3.0.**

Die Ein-Datei-Architektur und die Mindestversion GNU Bash 4.4 bleiben unverändert. `UseIncremental` ist jetzt eine kanonische boolesche Einstellung: `false` überspringt den Vergleich nach der Sicherung und die inkrementelle Aufbewahrung und behält jedes neu erstellte und erfolgreich validierte Artefakt. Es gibt dafür keine eigene CLI-Option.

Für die monatliche Archivierung wurde die Kalenderreihenfolge korrigiert und die Metadatenbehandlung für geeignete Netzwerkspeicher gehärtet; die strengen Metadatenprüfungen lokaler Dateisysteme bleiben bestehen. Konfigurationseditor und BackUP Master verwenden auf kürzeren Terminals nun einen bestätigten Ansichtsbereich, sodass nicht mehr alle Formularzeilen gleichzeitig auf den Bildschirm passen müssen.

Russisch und Englisch bleiben integriert. Version 2.3.1 liefert externe Laufzeitübersetzungen für Deutsch, Spanisch, Lettisch, Polnisch und Ukrainisch (`de`, `es`, `lv`, `pl`, `uk`) sowie `en.lang` als vollständige kanonische Übersetzungsvorlage mit 245 Schlüsseln. Die Benutzerdokumentation ist in 11 Sprachen verfügbar.

Benachrichtigungen sind weiterhin nicht implementiert und liegen außerhalb des Umfangs dieses Releases.

<br />

Wie Sie die Dateien beziehen, ihre Prüfsummen kontrollieren und das Skript für den Einsatz vorbereiten, beschreibt [INSTALL.md](INSTALL.md).
