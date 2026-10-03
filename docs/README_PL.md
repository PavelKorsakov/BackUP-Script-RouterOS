# MikroTik Backup Script

**Tworzenie kopii zapasowych MikroTik RouterOS.**

Skrypt służy do ręcznego i automatycznego tworzenia kopii zapasowych urządzeń z systemem RouterOS za pomocą harmonogramu *(konfigurowanego oddzielnie)*.
Plik `mikrotik-backup.sh` jest samodzielnym skryptem, jednak część jego funkcji można zmieniać za pomocą pliku `option.cfg`.

<br>

## Możliwości skryptu

| Funkcja | Jak działa |
|---|---|
| Tryb pojedynczego urządzenia | Tworzenie kopii jednego urządzenia za pomocą parametrów CLI |
| Przetwarzanie wsadowe | Sekwencyjne przetwarzanie urządzeń z listy DeviceList; import listy z Oxidized |
| Formaty kopii | Do wyboru: `.rsc`, `.backup` albo oba formaty po kolei |
| Tryby kopii | Do wyboru: compact, terse, verbose; szyfrowanie kopii binarnych |
| Tryb przyrostowy | Możliwość zachowywania kopii zapasowych tylko wtedy, gdy wystąpiły zmiany |
| Archiwum miesięczne | Archiwizacja starych kopii i dzienników na granicy okresu kalendarzowego |
| Rejestrowanie zdarzeń | Etapy wspólne trafiają do `main.log`, a praca z urządzeniami — do `devicename.log` |
| Menu konfiguracji | Interaktywne menu ułatwiające konfigurację i obsługę |
| Lokalizacja | Wbudowany język rosyjski i angielski; możliwość podłączenia zewnętrznych plików lokalizacji |
| Miejsce przechowywania kopii | Można wybrać dowolny katalog, w tym zasób NAS |
| Obsługa NAS | Sprawdzanie dostępności miejsca przechowywania przed utworzeniem kopii zapasowej |

<br>

## Wymagania systemowe i pierwsze kroki

**Wymagane:**
GNU Bash 4.4 lub nowszy oraz zainstalowane narzędzia **SSH**, **SCP** i **SSHPass**.
Narzędzie **zip** jest potrzebne tylko do comiesięcznej archiwizacji kopii zapasowych. Wszystkie wymagane narzędzia i polecenia instalacyjne opisano w rozdziale [Zależności](pl/INSTALL.md#zależności).
*(N.B. Jeżeli brakuje narzędzia wymaganego przez wybraną operację, skrypt zakończy pracę z błędem. Jest to zachowanie zamierzone.)*

**Opcjonalne:**
**autofs**, **davfs2**, **rclone** i inne narzędzia do montowania zewnętrznych nośników.

**Instalacja:**
Pobieranie plików i przygotowanie do pracy opisano w rozdziale [Instalacja](pl/INSTALL.md).

W katalogu z pobranymi plikami wykonaj:

Poniższy blok poleceń zakłada pliki pobrane z GitHub Release. Kopia kodu źródłowego pobrana przez Git nie zawiera generowanego dla wydania pliku `SHA256SUMS`; w takim przypadku zacznij od `chmod 700 mikrotik-backup.sh`, a następnie wykonaj sprawdzenie wersji i pomocy.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Jeżeli weryfikacja sumy kontrolnej zakończy się błędem, **nie uruchamiaj pliku!!!**

<br>

## Sposoby uruchamiania

**Uruchomienie pliku BEZ dodatkowych parametrów** *(gdy plik `option.cfg` nie istnieje lub jest nieprawidłowy)*
Jeżeli obok skryptu nie ma pliku `option.cfg` albo nie zawiera on żadnego prawidłowego ustawienia, otworzy się Configuration Editor, w którym można utworzyć lub zmienić `option.cfg`.

**Uruchomienie pliku BEZ dodatkowych parametrów** *(gdy dostępne są prawidłowe pliki `option.cfg` i `devicelist.cfg`)*
Jeżeli prawidłowe ustawienia już istnieją, skrypt rozpocznie wsadowe tworzenie kopii zapasowych.

**Uruchomienie skryptu z parametrem:**

| Zadanie | Polecenie |
|---|---|
| Otwórz menu interaktywne | `./mikrotik-backup.sh -i` |
| Otwórz BackUP Master | `./mikrotik-backup.sh -b` |
| Utwórz lub zmień `option.cfg` | `./mikrotik-backup.sh -e` |
| Wyświetl pełną pomoc dotyczącą parametrów CLI | `./mikrotik-backup.sh -h` |
| Uruchom skrypt dla jednego urządzenia | Pełna trójka CLI: adres urządzenia, użytkownik i hasło |

Najważniejszy jest tutaj parametr `-i`: otwiera on menu interaktywne, w którym można:

- za pomocą BackUP Master podać parametry urządzenia, utworzyć jego kopie zapasowe oraz utworzyć lub uzupełnić `devicelist.cfg` wybranymi parametrami;
- za pomocą Configuration Editor utworzyć lub zmienić plik ustawień `option.cfg`;
- wyświetlić pomoc dotyczącą parametrów CLI;
- przeczytać krótką instrukcję opisującą możliwości skryptu.

Pełny opis parametrów CLI, w tym dokładne postacie `-a=...`, `-u=...` i `-p=...`, znajduje się w [Dokumentacji wiersza poleceń](pl/CLI.md).

<br>

## Gdzie są zapisywane wyniki, czyli „Gdzie są moje backupy???”

Domyślnie kopie zapasowe urządzeń są przechowywane w katalogu `backups` obok skryptu. Jeżeli katalog jeszcze nie istnieje, skrypt utworzy go samodzielnie.
*(N.B. Ścieżka względna `backups` jest liczona od katalogu skryptu, a nie od bieżącego katalogu roboczego!)*

W trybie pojedynczego urządzenia nie jest tworzony dla niego osobny podkatalog:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

W trybie wsadowym każde urządzenie ma własny katalog:

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

Są to przykłady rozmieszczenia plików, a nie ich obowiązkowy zestaw po każdym uruchomieniu.
Dziennik powstaje przy pierwszym komunikacie, który kwalifikuje się do zapisania.
Parametr `MainLogPath` w pliku `option.cfg` umożliwia przeniesienie `main.log`, na przykład do `/var/log/` lub innego wygodnego katalogu.
Szczegółowe ustawienia katalogów kopii zapasowych, archiwów i dzienników opisano w rozdziale [Konfiguracja](pl/OPTIONS.md).

<br>

## Archiwizacja miesięczna

Domyślnie ta funkcja jest wyłączona. Jeżeli skrypt działa według harmonogramu, parametr `MonthlyArchive=true|1...28` w pliku `option.cfg` pozwala wybrać termin archiwizacji wszystkich kopii zapasowych z poprzedniego okresu.

W trybie wsadowym kolejność pracy w tym dniu ulega zmianie: najpierw archiwizowane są wszystkie kwalifikujące się dane zgromadzone w katalogu kopii zapasowych, a dopiero potem powstają kopie z bieżącą datą.

Archiwum otrzymuje nazwę poprzedniego dnia kalendarzowego: na przykład podczas uruchomienia 1 października będzie to `30.09.YYYY.zip`.

*(N.B. Jeżeli harmonogram NIE jest codzienny, ta funkcja wymaga utworzenia osobnego zadania na odpowiednią datę. Gdy skrypt jest uruchamiany codziennie lub częściej, osobne zadanie nie jest potrzebne.)*

Pominięta miesięczna próba, niezależnie od przyczyny, nie jest nadrabiana przez codzienne uruchomienia.
Następna planowa próba zbiera wszystkie nagromadzone stare dane w jednym archiwum, nawet jeśli pochodzą one z kilku miesięcy. Plik `main.log` nie jest archiwizowany.

Pełne zasady, przykłady i skutki błędów w tym trybie opisano w rozdziale **[Archiwa miesięczne](pl/BACKUPS.md#monthly-archive)**.

<br>

## Dokumentacja szczegółowa

| Czego chcesz się dowiedzieć | Strona |
|---|---|
| Wymagania, zależności i rozmieszczenie plików | [Instalacja](pl/INSTALL.md) |
| Parametry i wybór trybu | [CLI](pl/CLI.md) |
| Wartości domyślne i `option.cfg` | [Konfiguracja](pl/OPTIONS.md) |
| DeviceList, nazwy i Oxidized | [Urządzenia](pl/DEVICES.md) |
| Formaty, porównywanie, przechowywanie i ZIP | [Kopie zapasowe](pl/BACKUPS.md) |
| Poziomy, ścieżki i komunikaty dzienników | [Rejestrowanie zdarzeń](pl/LOGGING.md) |
| Menu, edytor i BackUP Master | [Interfejs interaktywny](pl/INTERACTIVE.md) |
| Wybór języka i pliki `.lang` | [Lokalizacja](pl/LOCALIZATION.md) |
| Dane uwierzytelniające, SSH i uprawnienia | [Bezpieczeństwo](pl/SECURITY.md) |
| Wyszukiwanie przyczyny według objawu lub kodu | [Diagnostyka](pl/TROUBLESHOOTING.md) |
| Sprawdzanie wydania i aktualizacje | [Wydania](pl/RELEASES.md) |
| Etapy rozwoju i plany | [Historia i plany](pl/ROADMAP.md) |

<br>

## Zakres zastosowania

Skrypt tworzy kopie zapasowe, ale nie przywraca konfiguracji routera.
W bieżącej wersji nie wysyła powiadomień pocztą elektroniczną ani przez komunikatory i nie usuwa starych plików ZIP na podstawie ich wieku.
Za procedurę odtwarzania, zewnętrzną rotację i kontrolę wyników odpowiada administrator.

Profil SSH używa uwierzytelniania hasłem i ma wyłączone sprawdzanie klucza serwera.
Szyfrowanie `.backup` nie szyfruje plików `.rsc`, plików konfiguracyjnych ani archiwów ZIP.
Przed użyciem w środowisku produkcyjnym zapoznaj się z [modelem bezpieczeństwa](pl/SECURITY.md).

<br>

## Dokumentacja w innych językach

[English](../README.md).
[Русский](README_RU.md).
[Latviešu](README_LV.md).
[Українська](README_UK.md).
[Deutsch](README_DE.md).
[Bahasa Indonesia](README_ID.md).
[Português (Brasil)](README_PT-BR.md).
[Tiếng Việt](README_VI.md).
[Español](README_ES.md).
Polski.
[বাংলা](README_BN.md).

## Kontakt z autorem

Propozycje dotyczące działania skryptu, zgłoszenia błędów i pytania o jego możliwości wysyłaj na adres [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev) albo przez Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
