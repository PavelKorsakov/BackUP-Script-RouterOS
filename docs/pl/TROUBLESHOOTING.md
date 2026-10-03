# Diagnostyka

[Spis treści](../README_PL.md)

## Od czego zacząć

Jeżeli tworzenie kopii nie rozpoczęło się albo zakończyło błędem, najpierw sprawdź dzienniki. Plik `main.log` zawiera wspólne etapy pracy, a szczegóły kopiowania konkretnego urządzenia są zapisywane w jego osobnym dzienniku.

Szukaj wpisów oznaczonych `[ER]` i kodem błędu. Kody objaśniono [niżej](#result-codes), a położenie dzienników opisano w [LOGGING.md](LOGGING.md).

Wersję zainstalowanego skryptu i pomoc dotyczącą parametrów można uzyskać poleceniami:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Aby ponownie uruchomić skonfigurowane już przetwarzanie wsadowe ze szczegółowym wyjściem:

```bash
mikrotik-backup.sh --log-level=3
printf 'Kod zakończenia: %s\n' "$?"
```

Drugie polecenie pokazuje wynik zakończonego uruchomienia. Poziom rejestrowania w `option.cfg` nie jest przy tym zmieniany.

<br />

## Skrypt nie rozpoczyna tworzenia kopii

### Zamiast tworzenia kopii otworzył się edytor

Przy uruchomieniu bez parametrów oznacza to, że obok skryptu nie ma `option.cfg` albo plik nie zawiera prawidłowych ustawień. Pusty plik, same komentarze lub nieznane parametry nie zmienią sytuacji.

Otwórz Configuration Editor, wybierz potrzebne ustawienia, zapisz plik i uruchom skrypt ponownie:

```bash
mikrotik-backup.sh -e
```

Zapisanie urządzenia przez BackUP Master tworzy `devicelist.cfg`, ale nie zastępuje przygotowania `option.cfg`.

*(N.B. Jeżeli takie uruchomienie odbywa się z harmonogramu, edytora nie da się otworzyć i skrypt zakończy się kodem `31`. Ustawienia automatycznego uruchamiania trzeba przygotować wcześniej.)*

### Błąd parametrów, kod 12

Sprawdź pisownię parametrów, ich wartości i połączenia akcji. Przyczyną może być nieznany parametr, pusta wartość, kilka różnych akcji jednocześnie albo niepełne dane uwierzytelniające do połączenia z jednym urządzeniem.

Uruchomienie CLI dla jednego urządzenia wymaga adresu, loginu i hasła. Brakujące dane uwierzytelniające nie są uzupełniane z `option.cfg`.

Krótkie parametry połączenia zapisuje się wyłącznie ze znakiem `=`: `-a=`, `-u=`, `-p=`. Parametr `-p` określa hasło, a dla portu SSH używa się `--port`.

Wszystkie dozwolone parametry i przykłady znajdują się w [CLI.md](CLI.md).

### Nie można odczytać option.cfg, kod 21

Sprawdź, czy `option.cfg` jest zwykłym plikiem i czy użytkownik uruchamiający skrypt może go odczytać. Dozwolone jest również czytelne dowiązanie symboliczne do takiego pliku.

Brak pliku i brak możliwości jego odczytania to różne sytuacje. Jeżeli plik istnieje, ale jest niedostępny, skrypt nie będzie kontynuował z ustawieniami domyślnymi.

### Brak zależności, kod 30

Sprawdź obecność podstawowych narzędzi:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Do pracy wsadowej z `UseNetFolder=true` potrzebny jest również `findmnt`. W dniu archiwizacji miesięcznej wymagane są `zip`, `unzip` i GNU `mv`. Kopiowanie polecenia konsoli z BackUP Master wymaga GNU `base64` z obsługą `--wrap=0`.

**Sama obecność narzędzia nie wystarcza.** Zainstalowany OpenSSH musi obsługiwać używane parametry i `scp -O`, a GNU `timeout` — `--signal` i `--kill-after`.

Pełną listę zależności i polecenia instalacyjne podano w [INSTALL.md](INSTALL.md#zależności).

### Menu nie otwiera się, kod 31

Menu, Configuration Editor i BackUP Master wymagają terminala oraz sprawnego narzędzia `stty`. Nie uruchamiaj ich przez potok ani z przekierowanym standardowym wejściem lub wyjściem.

Jeżeli komunikat wskazuje zbyt mały rozmiar terminala, powiększ okno. Główne ekrany wymagają szerokości co najmniej 46 kolumn, a wbudowana instrukcja — 80. W Configuration Editor i BackUP Master długa lista przewija się strzałkami; cały formularz nie musi mieścić się na ekranie jednocześnie.

Sterowanie interfejsem opisano w [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Lista urządzeń nie wczytuje się

### Plik devicelist.cfg, kody 22 i 23

Sprawdź położenie pliku i dostęp do niego. `devicelist.cfg` musi znajdować się obok `mikrotik-backup.sh`, niezależnie od katalogu, z którego uruchamiany jest skrypt.

Pola rozdziela rzeczywisty znak tabulacji (TAB), a nie spacje. Dla urządzenia trzeba określić nazwę, adres, login, hasło i prawidłowy port SSH. Wspólne dane uwierzytelniające mogą pochodzić z `option.cfg`, jeżeli odpowiednie pola wpisu są puste.

Nieprawidłowy wpis jest pomijany z ostrzeżeniem. Jeżeli nie pozostanie żadne prawidłowe urządzenie, nie ma czego kopiować i skrypt kończy się błędem listy.

Sprawdź również powtarzające się połączenia i identyczne nazwy różnych urządzeń. Format pliku, dziedziczenie danych uwierzytelniających i reguły obsługi powtórzeń opisano w [DEVICES.md](DEVICES.md).

### Import z Oxidized, kody 24 i 25

Kod `24` oznacza problem z odczytem plików `config` lub `router.db` z katalogu `OxidizedHome`. Kod `25` dotyczy ich zawartości: nieobsługiwanego schematu, błędnych danych albo braku prawidłowych urządzeń MikroTik.

Sprawdź ścieżkę, dostęp do obu plików, źródło `csv`, separator, mapę kolumn i definicję modelu `routeros`. Dane są odczytywane właśnie z `<OxidizedHome>/router.db`; parametr Oxidized `source.csv.file` nie zmienia tej ścieżki.

Przy `IgnoreOxiAccess=true` skrypt może kontynuować z poprzednią prawidłową listą. Błąd importu nadal jednak wpłynie na wynik uruchomienia. Przy `false` stara lista nie jest używana w tym uruchomieniu.

Konfigurację importu opisano w [DEVICES.md](DEVICES.md#import-z-oxidized).

<br />

## Miejsce przechowywania i blokady

### Blokada jest zajęta, kod 32

Sprawdź, czy nie działa już inne zadanie z tym samym katalogiem kopii zapasowych. W przypadku uruchomień tego samego użytkownika przetwarzanie wsadowe koliduje z każdym innym tworzeniem kopii w tym samym `BackupRoot`. Dwa uruchomienia dla jednego urządzenia również nie mogą działać równocześnie w tym magazynie.

Poczekaj na zakończenie aktywnego zadania i spróbuj ponownie.

**Nie usuwaj plików blokad, aby „zwolnić” miejsce przechowywania.** Pozostają po zakończeniu skryptu, a sama blokada jest utrzymywana przez proces. Obecność pliku w `/tmp/mikrotik-backup-${UID}/` nie oznacza jeszcze, że blokada jest zajęta.

### Brak dostępu do katalogu

Sprawdź ścieżkę `BackupRoot`, uprawnienia użytkownika, wolne miejsce i dostępność samego nośnika. Ścieżka względna jest liczona od katalogu skryptu. Katalog główny systemu plików `/` nie może służyć do przechowywania kopii.

Jeżeli wcześniej skrypt działał jako root, a teraz pracuje jako **bsmt**, wcześniejsze katalogi i pliki mogą być dla niego niedostępne. Przygotowanie uprawnień opisano w [INSTALL.md](INSTALL.md#automatyczne-uruchamianie-skryptu).

Do pracy wsadowej z `UseNetFolder=true` wymagane jest osobne montowanie. Można je sprawdzić następująco:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Zastąp pierwszą ścieżkę własną. Jeżeli obie ścieżki należą do tego samego wpisu montowania, zwykły katalog w głównym systemie plików nie spełnia wymogu `UseNetFolder=true`. Sam skrypt nie montuje miejsca przechowywania.

Kod `64` oznacza błąd katalogu urządzenia lub jego archiwum przy dostępnym wspólnym magazynie. Przetwarzanie pozostałych urządzeń może być kontynuowane. Kod `65` oznacza utratę lub naruszenie stanu wspólnego magazynu i zatrzymuje pozostałą część przetwarzania wsadowego.

Reguły sieciowego miejsca przechowywania opisano w [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Błędy podczas pracy z urządzeniem

### SSH i przesyłanie plików, kody 40–43

Sprawdź adres urządzenia, dostępność usługi SSH, login, hasło i port. Jeżeli portu nie podano w `devicelist.cfg`, używany jest `SshPort` z ustawień; wartość domyślna to `22`.

Użytkownik RouterOS musi mieć uprawnienia do wybranych operacji: eksportowania konfiguracji, tworzenia i pobierania kopii, usuwania plików tymczasowych oraz włączonych operacji czyszczenia.

**I tu również pojawia się pewien niuans!!!** Pomyślne połączenie zwykłym poleceniem SSH nie oznacza jeszcze, że skrypt używa tych samych ustawień. Skrypt działa z hasłem i nie używa agenta SSH, kluczy ani zwykłego `~/.ssh/config`. Pliki pobiera przez `scp -O`.

Kod `40` dotyczy połączenia lub kanału transportowego, `41` — uwierzytelniania, `42` — polecenia RouterOS albo jego odpowiedzi, a `43` — przesyłania pliku. Szczegóły parametrów połączenia opisano w [SECURITY.md](SECURITY.md#połączenie-z-routeros).

### Błąd nazwy, kody 50 i 52

Kod `50` oznacza, że wynikowa nazwa urządzenia jest nieprawidłowa. Sprawdź wybrane źródło nazwy i zawartość nawiasów: w bieżącej wersji jako nazwa używana jest pierwsza domknięta, niepusta grupa w nawiasach okrągłych.

Po przetworzeniu długość musi wynosić od 1 do 32 znaków. Zbyt długa nazwa nie jest skracana. Zastrzeżone nazwy, takie jak `CON` i `NUL`, również są zabronione.

Kod `52` oznacza zbieżność nazwy wynikowej z innym urządzeniem w tym uruchomieniu. Wielkość liter nie jest uwzględniana: `Router-A` i `router-a` są uznawane za identyczne.

Źródło nazwy i reguły jej przetwarzania opisano w [DEVICES.md](DEVICES.md#device-names).

### Kopia nie przeszła weryfikacji, kody 51 i 53

Kod `51` dotyczy `.rsc`, a kod `53` — `.backup`. Pobrany plik nie przeszedł weryfikacji: może być na przykład pusty albo jego rozmiar może różnić się od rozmiaru pliku na urządzeniu.

Sprawdź etap, na którym wystąpił błąd, oraz wolne miejsce i uprawnienia zarówno na hoście, jak i w RouterOS. Po nieudanej próbie skrypt ponawia ją jeszcze raz po 2 sekundach. Próby dla obu formatów są wykonywane oddzielnie, więc jeden plik może zostać pobrany pomyślnie, a drugi nie.

Ostrzeżenie o nieudanym usunięciu pliku tymczasowego z RouterOS po pomyślnym pobraniu kopii samo w sobie nie oznacza uszkodzenia kopii lokalnej.

<br />

## Brak nowej kopii, ale nie ma też błędów

Najpierw sprawdź `UseIncremental`. Jeżeli porównywanie jest włączone, nowa kopia mogła zostać usunięta jako powtórzenie, a poprzednia pozostawiona. Dla `.rsc` porównywana jest zawartość bez daty w standardowym nagłówku, a dla `.backup` — wyłącznie rozmiar plików.

Przy `UseIncremental=false` nowa prawidłowa kopia jest zapisywana bez tego porównania.

Pamiętaj także, że dwa uruchomienia dla tego samego urządzenia i katalogu w ciągu jednej minuty użyją tej samej nazwy pliku. Osobna wersja dla drugiego uruchomienia nie powstanie.

Jeżeli tego dnia odbyła się archiwizacja miesięczna, sprawdź również ZIP. W trybie CLI dla jednego urządzenia nowa kopia także może trafić do środka. Pełne reguły przechowywania opisano w [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## Archiwum miesięczne nie pojawiło się

Sprawdź wartość `MonthlyArchive` i datę uruchomienia według czasu lokalnego hosta. `false` wyłącza archiwizację, `true` lub `1` wybiera pierwszy dzień, a liczba od `2` do `28` — odpowiedni dzień miesiąca.

Godzina uruchomienia w wybranym dniu nie ma znaczenia. Jeżeli ten dzień pominięto, następne zwykłe uruchomienie nie nadrabia archiwizacji. Podczas pracy przez BackUP Master archiwizacja miesięczna nie jest wykonywana.

Jeżeli nie ma czego archiwizować, pusty ZIP nie powstaje.

### Gdzie szukać ZIP

Nazwa archiwum odpowiada poprzedniemu dniowi kalendarzowemu. Na przykład przy uruchomieniu 1 października 2026 roku będzie to `30.09.2026.zip`:

| Tryb | Położenie |
|---|---|
| Wsadowy | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Jedno urządzenie przez CLI | `<BackupRoot>/30.09.2026.zip` |

Nazwa katalogu `archive/` jest zapisywana małymi literami. Ponowne uruchomienie tego samego dnia aktualizuje ZIP o tej samej nazwie.

### Archiwizacja zakończyła się błędem

Dla kodów `70` i `71` sprawdź dziennik urządzenia, dostęp do katalogu archiwów, wolne miejsce oraz stan istniejącego ZIP. Miejsce jest potrzebne zarówno w docelowym magazynie, jak i w lokalnym `/tmp`.

Na dysku lokalnym katalog `archive/` musi należeć do użytkownika skryptu i mieć uprawnienia `0700`. W trybie wsadowym ze zweryfikowanym sieciowym miejscem przechowywania i `UseNetFolder=true` inny właściciel lub uprawnienia nadane przez NAS same w sobie nie powodują odmowy. Błędy magazynu podczas archiwizacji mogą również zwracać kod `64` albo `65`.

Istniejące archiwum można sprawdzić poleceniem z jego rzeczywistą ścieżką:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Pliki źródłowe nie są usuwane przed zapisaniem zweryfikowanego ZIP. Jeżeli archiwum zostało już zapisane, ale części plików źródłowych nie udało się usunąć, pozostaną zarówno ZIP, jak i nieusunięte pliki. Uszkodzone istniejące archiwum nie jest automatycznie zastępowane nowym.

**Nie usuwaj pozostałych kopii zapasowych ani dzienników, dopóki nie sprawdzisz zawartości archiwum.** Kolejność archiwizacji opisano w [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Brak dziennika lub wyjścia ekranowego

Przy `LogLevel=0` i braku błędów nowe dzienniki nie powstają. W pozostałych przypadkach sprawdź wybrane `BackupRoot`, `MainLogPath` i uprawnienia do zapisu.

Pusty `MainLogPath=` pozostawia `main.log` w `BackupRoot`. Jeżeli wskazano osobny katalog, musi on już istnieć i być dostępny dla użytkownika skryptu. Parametr nie przenosi dzienników urządzeń.

Po archiwizacji miesięcznej wcześniejsza historia urządzenia znajduje się w ZIP. Dalsza praca jest zapisywana w nowym dzienniku obok kopii.

Przy uruchomieniu z harmonogramu lub z przekierowanym wyjściem nie ma dziennika ekranowego ze wskaźnikiem i kolorowymi oznaczeniami. Nie wyłącza to dzienników w plikach.

Błąd zapisu dziennika nie zatrzymuje samego tworzenia kopii, ale jest uwzględniany w wyniku uruchomienia jako ostrzeżenie. Szczegóły zawiera [LOGGING.md](LOGGING.md).

<br />

<a id="language-problems"></a>
## Tłumaczenie nie zostało zastosowane

Sprawdź wybrany język i położenie pliku. Dla `Language=de` wymagany jest na przykład czytelny zwykły plik `de.lang` obok `mikrotik-backup.sh`, a nie w katalogu `lang/`. Dowiązanie symboliczne nie jest używane jako plik tłumaczenia.

Przy `Language=auto` język jest określany na podstawie środowiska systemu operacyjnego. Dla jednego uruchomienia można wskazać go jawnie, na przykład podczas wyświetlania pomocy:

```bash
mikrotik-backup.sh --language=de --help
```

Nieprzetłumaczone komunikaty są wyświetlane po angielsku. Nieprawidłowe wiersze pliku są pomijane. Pliki `ru.lang` i `en.lang` nie zastępują tłumaczeń wbudowanych.

Format wierszy, nazwy kluczy i reguły podłączania opisano w [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Ustawienie nie jest stosowane

Sprawdź nazwę parametru, dozwoloną wartość oraz powtarzające się wpisy w `option.cfg`. Jeżeli parametr się powtarza, używana jest ostatnia prawidłowa wartość. Wielkość liter w kluczach nie ma znaczenia, ale łącznik i znak podkreślenia nie są zamienne.

Parametr przekazany przez CLI zastępuje odpowiadającą mu wartość z pliku. Dla zwykłych uruchomień pojedynczego urządzenia i trybu wsadowego kolejność wygląda tak:

**Wartości wbudowane** → **Prawidłowe wiersze option.cfg** → **CLI**

BackUP Master ma własną kolejność wypełniania formularza: zwykłe pola pobierają wartości z ustawień wbudowanych i CLI, a nie z pliku parametrów. Wyjątkiem jest `UseIncremental`. Podczas wykonania uwzględniane są również ustawienia rejestrowania z pliku.

Reguły odczytywania parametrów podano w [OPTIONS.md](OPTIONS.md), a szczególne cechy BackUP Master — w [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Kody zakończenia

| Kod | Znaczenie |
|---:|---|
| `0` | Powodzenie bez zapisanych błędów lub ostrzeżeń |
| `1` | Zakończenie z ostrzeżeniami, bez zapisanego błędu wykonania |
| `12` | Błąd parametrów CLI, ich wartości lub połączenia |
| `21` | Nie udało się odczytać pliku `option.cfg` |
| `22` | Nie udało się uzyskać listy urządzeń |
| `23` | Nieprawidłowa lista urządzeń albo brak prawidłowych wpisów |
| `24` | Nie udało się odczytać plików Oxidized |
| `25` | Nieobsługiwany schemat lub błędne dane Oxidized; brak prawidłowych wpisów MikroTik |
| `30` | Brak wymaganego narzędzia albo brak obsługi wymaganych funkcji |
| `31` | Terminal niedostępny, błąd `stty` albo zbyt małe okno |
| `32` | Wymagana blokada jest zajęta przez inne uruchomienie |
| `33` | Nieprawidłowa ścieżka lub obiekt magazynu dla uruchomienia pojedynczego urządzenia |
| `34` | Nie udało się utworzyć lub przygotować katalogu uruchomienia pojedynczego urządzenia |
| `35` | Błąd dostępu lub sprawdzania lokalnego obiektu pomocniczego, w tym blokady |
| `36` | Magazyn pojedynczego urządzenia nie przeszedł sprawdzania dostępności przed pobraniem pliku |
| `37` | Nie udało się zapisać lub zastąpić pliku pomocniczego |
| `40` | Błąd połączenia albo kanału transportowego SSH/SCP |
| `41` | Błąd uwierzytelniania urządzenia |
| `42` | Błąd polecenia RouterOS albo oczekiwanej odpowiedzi |
| `43` | Błąd przesyłania pliku przez SCP |
| `50` | Nieprawidłowa wynikowa nazwa urządzenia |
| `51` | Plik `.rsc` nie przeszedł weryfikacji |
| `52` | Zbieżność wynikowych nazw urządzeń |
| `53` | Plik `.backup` nie przeszedł weryfikacji |
| `61` | Wspólny magazyn niedostępny podczas przygotowywania uruchomienia wsadowego |
| `62` | Nie udało się potwierdzić lub aktywować osobnego montowania dla `UseNetFolder=true` |
| `63` | Błąd przygotowania lub weryfikacji wspólnego katalogu kopii wsadowych |
| `64` | Błąd magazynu urządzenia lub jego archiwum przy dostępnym wspólnym magazynie |
| `65` | Utrata lub naruszenie stanu wspólnego magazynu podczas pracy; przetwarzanie wsadowe zostaje zatrzymane |
| `70` | Błąd tworzenia lub aktualizowania archiwum |
| `71` | ZIP albo docelowy obiekt archiwum nie przeszedł weryfikacji |
| `80` | Błąd wewnętrzny albo niespełnione wymaganie systemowe, w tym działanie `C.UTF-8` |
| `81` | Błąd wbudowanego sterownika MikroTik |
| `129` | Zakończenie sygnałem HUP |
| `130` | Zakończenie sygnałem INT, na przykład po naciśnięciu Ctrl+C |
| `143` | Zakończenie sygnałem TERM |

Końcowy kod odzwierciedla pierwszy zapisany błąd wykonania. Ostrzeżenie `1` jest zastępowane przez pierwszy taki błąd, a późniejsze powodzenie nie usuwa go. Kod końcowy nie musi więc odpowiadać ostatniemu komunikatowi w dzienniku.

Jeżeli ponowiona próba pobrania pliku zakończyła się pomyślnie, etap może zakończyć się oznaczeniem `[OK]`, mimo że błąd pierwszej próby pozostał w dzienniku. Niezerowy kod końcowy uruchomienia wsadowego nie oznacza również, że nie udało się skopiować wszystkich urządzeń: sprawdź wynik każdego z osobna.

Dla kodu `80` zwróć uwagę na wymagania systemowe: GNU Bash 4.4 lub nowszy i prawidłowo działające locale `C.UTF-8`. Szczegóły zawiera [INSTALL.md](INSTALL.md#wymagania-dotyczące-hosta).

<br />

## Gdy potrzebujesz pomocy

Podaj wersję skryptu, system operacyjny i wersję Bash, sposób uruchomienia oraz kod zakończenia, a także dołącz fragment dziennika związany z błędem. Przy problemie z jednym urządzeniem potrzebny jest jego dziennik, a przy błędzie przygotowania uruchomienia — przede wszystkim `main.log`.

**Nie wysyłaj prawdziwych haseł ani pełnych roboczych plików ustawień.** Przed wysłaniem sprawdź dzienniki, zrzuty ekranu i polecenia pod kątem danych poufnych. Zasady ochrony haseł opisano w [SECURITY.md](SECURITY.md).

Z autorem można skontaktować się za pomocą danych w [opisie produktu](../README_PL.md#kontakt-z-autorem).
