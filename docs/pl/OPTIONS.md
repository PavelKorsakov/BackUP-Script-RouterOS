# Konfiguracja

[Spis treści](../README_PL.md)

## Kilka słów na początek

Opcjonalny plik `option.cfg` umożliwia zmianę domyślnych ustawień skryptu.
Aby skrypt wczytał zawarte w nim ustawienia podczas działania, plik `option.cfg` musi znajdować się obok `mikrotik-backup.sh` w tym samym katalogu.

Struktura pliku jest bardzo prosta: lista danych w formacie `Klucz=wartość`. Nie jest to skrypt powłoki.
Nie wykonuje się w nim podstawiania zmiennych ani poleceń.

## Przydatność konfiguracji do uruchomienia

Już jeden poprawny i rozpoznany wiersz sprawia, że konfiguracja jest prawidłowa.
Nie trzeba podawać pełnego zestawu ustawień: jeżeli odpowiada Ci domyślna wartość danego parametru, możesz pominąć go w `option.cfg`.

Jeżeli jednak plik jest pusty albo zawiera wyłącznie komentarze, nieznane klucze lub nieprawidłowe wartości, skrypt nie ma z niego czego wczytać.
Ustawienia pozostają wtedy domyślne.

**I tu pojawia się pewien niuans!!!**
Jeżeli w takiej sytuacji uruchomisz skrypt bez argumentów, tworzenie kopii zapasowych nie rozpocznie się. Zamiast tego skrypt spróbuje otworzyć Configuration Editor.
To samo stanie się, gdy pliku `option.cfg` w ogóle nie ma.
Zapisz potrzebne ustawienia i uruchom skrypt ponownie.
*(N.B. Otwarcie edytora wymaga terminala. Jeżeli takie uruchomienie odbywa się bez terminala, na przykład z harmonogramu, skrypt zakończy pracę z błędem `31`. Przygotuj `option.cfg` przed skonfigurowaniem automatycznego uruchamiania.)*

**Kolejność odczytywania parametrów opcjonalnych:**
Źródła parametrów mają określony priorytet. Jeżeli nie ma `option.cfg`, używane są wartości domyślne wbudowane w skrypt.
Jeżeli plik istnieje i został pomyślnie odczytany, zawarte w nim <mark>poprawne</mark> parametry zastępują odpowiednie wartości domyślne.

I najważniejsze!!! Jeżeli ten sam parametr przekazano przez CLI, pierwszeństwo ma wartość z CLI.
Dla zwykłego uruchomienia pojedynczego urządzenia i trybu wsadowego kolejność wygląda więc tak:
**Wartości wbudowane** → **Prawidłowe wiersze option.cfg** → **CLI**

*(N.B. Brak pliku i brak możliwości jego odczytania to nie to samo. Jeżeli `option.cfg` istnieje, lecz skrypt nie może go odczytać, wykonanie zakończy się błędem konfiguracji o kodzie `21`, zamiast kontynuować z ustawieniami domyślnymi.)*

## Sposób odczytu pliku

Każdy wiersz jest dzielony przy pierwszym znaku `=`. Wielkość liter w nazwach kluczy nie ma znaczenia, ale łącznik i znak podkreślenia nie są zamienne.
Puste wiersze oraz wiersze, których pierwszym znakiem niebędącym odstępem jest `#`, są ignorowane. Nieznany lub nieprawidłowy wiersz nie unieważnia poprawnych wierszy obok.
Jeżeli klucz się powtarza, używana jest ostatnia prawidłowa wartość.

W zwykłych wartościach początkowe i końcowe odstępy są usuwane.
**Ważne:** w przypadku `Login`, `Password` i `encrypt` wszystko po pierwszym `=` jest zachowywane dosłownie.
Nie dodawaj cudzysłowów według zasad powłoki: staną się częścią wartości.
Nie dopisuj komentarza po haśle. Umieść komentarz w osobnym wierszu.

Obsługiwany jest jeden BOM na początku pliku oraz zakończenia wierszy CRLF.
Dopuszczalne jest czytelne dowiązanie symboliczne do zwykłego pliku.
Problem z dostępem lub niewłaściwy typ obiektu nie są traktowane jak pusty plik i powodują błąd konfiguracji.

## Tworzenie, edytowanie i zapisywanie pliku 'option.cfg'

Najprostszy sposób utworzenia pliku to uruchomienie skryptu z parametrem `-e`:

```bash
./mikrotik-backup.sh -e
```

Otworzy się Configuration Editor z listą najważniejszych parametrów.
Jeżeli wszystkie wiersze nie mieszczą się w oknie terminala, lista automatycznie przewija się podczas poruszania strzałkami w górę i w dół.
Pozycje „Zapisz” i „Anuluj” znajdują się na końcu tej samej listy.
Przechodzimy między pozycjami menu, podajemy potrzebne parametry → wybieramy „Zapisz” → i (jesteś mistrzem) plik gotowy.

Podczas pracy z menu interaktywnym edytor zmienia ustawienia wyłącznie w pamięci.
Dopiero po wybraniu „Zapisz” zostanie zapisany pełny, *kanoniczny* plik.

Jeżeli `option.cfg` jeszcze nie istnieje, edytor początkowo wypełnia pola wartościami domyślnymi.
Jeżeli plik został już utworzony i zmieniono w nim niektóre parametry, Configuration Editor wypełni pola Twoimi wartościami, a nie domyślnymi.

Drugi sposób utworzenia 'option.cfg' to ręczna edycja. Tak, otwieramy ulubiony edytor tekstu własnymi rękami i wpisujemy potrzebne ustawienia.
Skąd je wziąć? Są tuż poniżej:

## Ustawienia i wartości domyślne

| Klucz | Domyślnie | Wartości i przeznaczenie |
|---|---|---|
| `Language` | `auto` | `auto` albo dwie litery ASCII, na przykład `ru`, `en`, `de` |
| `SshPort` | `22` | Port `1`–`65535`; ukryty w Configuration Editor, widoczny w BackUP Master |
| `UseOxidized` | `false` | Importować urządzenia z Oxidized |
| `IgnoreOxiAccess` | `true` | Zezwolić na użycie poprzedniej listy DeviceList po błędzie odczytu lub analizy Oxidized; tylko plik |
| `OxidizedHome` | Puste | Katalog zawierający `config` i `router.db` |
| `UseIdentityName` | `true` | Używać bieżącej RouterOS Identity jako nazwy urządzenia |
| `backup_type` | `both` | `configuration`, `binary` albo `both` |
| `UseIncremental` | `true` | Porównywać nową zweryfikowaną kopię z poprzednią; przy `false` zachowywać każdą nową kopię bez porównania |
| `export_format` | `compact` | `compact`, `terse` albo `verbose` |
| `show_sensitive` | `true` | Dodawać wartości poufne do `.rsc` |
| `encrypt` | Puste | Hasło szyfrowania `.backup`; pusta wartość oznacza brak szyfrowania |
| `encrypt_type` | `aes-sha256` | Stały algorytm; tylko plik |
| `clear_dns_cache` | `true` | Wyczyścić pamięć podręczną DNS przed kopią binarną |
| `clear_console_history` | `true` | Wyczyścić historię konsoli przed kopią binarną |
| `BackupRoot` | `backups` | Katalog główny miejsca przechowywania kopii |
| `UseNetFolder` | `false` | Wymagać osobnego punktu montowania w trybie wsadowym |
| `MonthlyArchive` | `false` | Wyłączyć archiwizację (`false`) albo wybrać dzień miesiąca od `1` do `28` |
| `LogLevel` | `2` | Poziom `0`, `1`, `2` albo `3` |
| `MainLogPath` | Puste | Wyłącznie katalog dla `main.log`; pusta wartość oznacza bieżący `BackupRoot` |
| `Login` | Puste | Wspólny login dziedziczony przez puste pola DeviceList; tylko plik |
| `Password` | Puste | Wspólne hasło dziedziczone przez puste pola DeviceList; tylko plik |

Przy `Language=auto` język interfejsu i dzienników jest wybierany na podstawie locale systemu operacyjnego.
Dla zewnętrznego tłumaczenia używany jest jego dwuliterowy kod języka: na przykład dla `de_DE.UTF-8` wymagany jest plik `de.lang` obok skryptu.
Jeżeli brak odpowiedniego tłumaczenia, używany jest język angielski.

Dla `MonthlyArchive` obowiązuje nieco inna zasada: `false`/`no`/`0`/`off` wyłączają archiwizację; `true`/`yes`/`1`/`on` oznaczają pierwszy dzień miesiąca; wartości od `2` do `28` wybierają żądany dzień.

Podczas zapisywania przez edytor do pliku trafia `MonthlyArchive=false` albo wybrana liczba.

Parametry logiczne przyjmują `true`/`false`, `yes`/`no`, `1`/`0` i `on`/`off` bez rozróżniania wielkości liter. Edytor zapisuje `true`/`false`.

Pola `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` i `Password` nie są wyświetlane w Configuration Editor.

Podczas zapisywania pliku edytor zapisuje `IgnoreOxiAccess`, `encrypt_type` i `SshPort`.
`Login` i `Password` są zachowywane tylko wtedy, gdy takie wiersze już znajdowały się w `option.cfg`, również z pustymi wartościami.

Pola `SshPort`, `Login` i `Password` mogą być przydatne, gdy wszystkie urządzenia korzystają z tego samego portu SSH i tego samego użytkownika — tej samej nazwy i hasła. Wówczas każdy wpis w `devicelist.cfg` może zawierać tylko dwie wartości: **nazwę** urządzenia i jego **adres IP**.

## Przykład bez czyszczenia i bez danych poufnych w eksporcie

To przykład wybranej polityki, **a nie lista ustawień fabrycznych**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

Pierwszych 19 kluczy podano w kanonicznej kolejności zapisu.
Istniejące zgodne wiersze `Login` i `Password` są zapisywane po nich.

Brakujące ustawienia korzystają z wartości wbudowanych, a nie z wartości z pobliskiego przykładu. Plik zawierający wyłącznie `Language=ru` nie wyłącza na przykład czyszczenia ani nie zmienia `show_sensitive=true`.

## Ścieżki

```ini
BackupRoot=backups
MainLogPath=logs
```

Te wpisy oznaczają katalogi `backups` i `logs` obok skryptu.
Ścieżki bezwzględne zachowują swoje znaczenie. `$HOME` i `~` nie są rozwijane jako zmienna ani katalog domowy.

Nieistniejący `BackupRoot` jest tworzony podczas działania, o ile pozwalają na to uprawnienia.
Katalog główny systemu plików `/` nie może służyć jako miejsce przechowywania.
W istniejących katalogach program nie poprawia automatycznie właściciela ani uprawnień.

Niepusty `MainLogPath` musi wskazywać **istniejący już katalog z prawem zapisu**.
Utworzenie samego `main.log` jest odkładane do pierwszego wpisu; nie powoduje utworzenia katalogu nadrzędnego.
Jeżeli zapis dziennika jest niemożliwy, tworzenie kopii trwa dalej z ostrzeżeniem. Ten parametr nie przenosi dzienników urządzeń.

<a id="network-storage"></a>
## Sieciowe i oddzielne miejsce przechowywania

`UseNetFolder=true` działa w trybie wsadowym. Ścieżka musi należeć do wpisu montowania innego niż wpis dla `/`.
Oddzielnym miejscem przechowywania może być zasób sieciowy, lokalny dysk albo montowanie bind; nazwa parametru nie ogranicza typu systemu plików.

Zwykły katalog w tym samym głównym systemie plików nie spełnia tego wymagania.
Skrypt sprawdza dostępność i montowanie, ale nie wywołuje `mount`, `umount` ani `sudo` i nie przełącza się po cichu na zapasowy magazyn lokalny.

## Powiązane parametry

Przy `UseIncremental=false` skrypt nie porównuje nowej kopii zapasowej z poprzednią i zachowuje każdy nowy, pomyślnie utworzony oraz zweryfikowany plik.
To ustawienie nie wpływa na pobieranie kopii ani na archiwizację miesięczną.
Domyślnie `UseIncremental=true`. Jeżeli tego parametru nie ma jeszcze w Twoim `option.cfg`, porównywanie pozostaje włączone.

`backup_type=configuration` nie korzysta z szyfrowania kopii binarnej ani z czyszczenia przed jej utworzeniem. `backup_type=binary` nie korzysta z `export_format` ani `show_sensitive`. `UseOxidized=false` nie korzysta z `OxidizedHome`.

Przy `UseIdentityName=true` błąd odczytu Identity nie jest zastępowany wartością `--device-name` ani nazwą z DeviceList. Aby użyć podanej nazwy, wyłącz `UseIdentityName`: zobacz [reguły nazewnictwa](DEVICES.md#device-names).

Przy `MonthlyArchive=true` archiwizacja odbywa się podczas uruchomienia skryptu w wybranym dniu miesiąca według czasu lokalnego hosta. Godzina uruchomienia w tym dniu nie ma znaczenia.
Jeżeli skrypt nie został uruchomiony tego dnia, pominięta archiwizacja nie jest nadrabiana.

Pliki trafiające do archiwum, miejsce jego utworzenia i zasady nadawania nazwy opisano w [BACKUPS.md](BACKUPS.md#monthly-archive).
Okres, granicę danych i pominięte próby również zdefiniowano w [BACKUPS.md](BACKUPS.md#monthly-archive).

Konfiguracja może zawierać dane tajne. Ogranicz do niej dostęp i nie dodawaj jej do publicznego repozytorium: [SECURITY.md](SECURITY.md).
