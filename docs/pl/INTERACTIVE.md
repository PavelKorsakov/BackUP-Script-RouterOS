# Interfejs interaktywny

[Spis treści](../README_PL.md)

## Menu główne

Menu główne pozwala skonfigurować skrypt, utworzyć kopie zapasowe, przygotować listę urządzeń albo otworzyć wbudowaną pomoc. Aby je wywołać, uruchom:

```bash
mikrotik-backup.sh -i
```

| Pozycja | Otwierana lub wykonywana funkcja |
|---|---|
| `1` | BackUP Master do pracy z jednym urządzeniem |
| `2` | Wsadowe tworzenie kopii na podstawie listy urządzeń |
| `3` | Configuration Editor do tworzenia lub zmiany `option.cfg` |
| `4` | Pomoc dotycząca parametrów CLI |
| `5` | Instrukcja obsługi skryptu |
| `6` | Powrót do konsoli |

Pozycja `2` pojawia się, gdy `devicelist.cfg` zawiera co najmniej jeden prawidłowy wpis. Jeżeli lista jeszcze nie istnieje lub nie zawiera odpowiednich urządzeń, pozycja nie jest wyświetlana. Numery pozostałych pozycji się nie zmieniają.

Po zakończeniu przetwarzania wsadowego zostanie wyświetlony wynik, a następnie skrypt powróci do konsoli.

*(N.B. Uruchomienie bez parametrów nie otwiera menu głównego. Jeżeli brakuje `option.cfg` albo nie zawiera on prawidłowych ustawień, otworzy się Configuration Editor; jeżeli ustawienia są gotowe, skrypt przejdzie do przetwarzania wsadowego.)*

<br />

## Sterowanie

Przechodź między pozycjami strzałkami **w górę** i **w dół**, a wybraną pozycję zatwierdzaj klawiszem **Enter**. Jeżeli przy akcji podano numer, można ją również wybrać odpowiednim klawiszem cyfrowym.

W Configuration Editor i BackUP Master nad listą wyświetlany jest opis wybranego pola. Jeżeli wszystkie wiersze nie mieszczą się w oknie terminala, lista przewija się podczas poruszania strzałkami. Nagłówek i opis pozostają widoczne, a zaznaczony wiersz nie wychodzi poza okno.

Pozycje zapisu, wykonania i wyjścia znajdują się na końcu tej samej listy. Wyszarzone wiersze są niedostępne przy wybranych ustawieniach i pomijane podczas nawigacji.

Do pracy potrzebne są terminal i narzędzie `stty`. Zarówno standardowe wejście, jak i standardowe wyjście muszą być połączone z terminalem. Główne ekrany wymagają szerokości co najmniej 46 kolumn, a wbudowana instrukcja — 80. Jeżeli okno jest zbyt małe, skrypt zgłosi błąd `31`; powiększ je i spróbuj ponownie.

<br />

## Configuration Editor

Edytor można otworzyć przez pozycję `3` menu głównego albo bezpośrednio poleceniem:

```bash
mikrotik-backup.sh -e
```

Jeżeli `option.cfg` jest już przygotowany, formularz zostanie wypełniony Twoimi ustawieniami. Jeżeli plik jeszcze nie istnieje, używane są wartości domyślne.

W edytorze wybiera się język, źródło listy urządzeń, parametry kopii, miejsce przechowywania, archiwizację miesięczną i rejestrowanie zdarzeń. Przeznaczenie parametrów i dozwolone wartości opisano w [OPTIONS.md](OPTIONS.md).

### Zmiana ustawień

Przełączniki „Tak / Nie”, typ kopii, format eksportu i poziom dziennika zmienia się klawiszem **Enter** w odpowiednim wierszu. Dla ścieżki lub dnia archiwizacji miesięcznej otwiera się pole wprowadzania wartości.

Pole „Używaj porównywania przyrostowego” (`UseIncremental`) znajduje się bezpośrednio po typie kopii. „Tak” włącza porównywanie, a „Nie” zachowuje każdą nową prawidłową kopię bez porównania z poprzednią.

Dla archiwizacji miesięcznej podaj `false`, aby ją wyłączyć, albo liczbę od `1` do `28`. Stan wyłączony jest przedstawiony w formularzu jako „Nie”, a stan włączony — jako wybrany dzień miesiąca.

Pola niezwiązane z wybranym trybem są wyszarzane. Jeżeli powstaje na przykład tylko `.rsc`, niedostępne są szyfrowanie kopii binarnej i czyszczenie przed jej utworzeniem; przy samym `.backup` niedostępne są parametry eksportu tekstowego. Po takim przełączeniu nieużywane parametry wracają do wartości domyślnych.

Hasło szyfrowania jest wprowadzane i wyświetlane jako gwiazdki.

### Zapisywanie i anulowanie

Wybierz potrzebne parametry → przejdź do „Zapisz” → naciśnij **Enter**. Plik `option.cfg` zostanie utworzony lub nadpisany wybranymi ustawieniami.

Do chwili zapisania zmiany istnieją wyłącznie w pamięci. Pozycja „Anuluj” pozostawia poprzedni plik bez zmian. Jeżeli coś już zmieniono, edytor poprosi o potwierdzenie odrzucenia zmian.

Edytor otwarty z menu głównego wraca do tego menu. Po osobnym uruchomieniu przez `-e` zamknięcie edytora powoduje powrót do konsoli.

*(N.B. Pola `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` i `Password` nie są wyświetlane w formularzu. Ich ustawienia i reguły zapisu opisano w [OPTIONS.md](OPTIONS.md).)*

### Wybór języka

W wierszu języka każde naciśnięcie **Enter** wybiera następny wariant:

```text
auto → ru → en → znalezione języki zewnętrzne w kolejności alfabetycznej → auto
```

Język formularza zmienia się natychmiast, aby można było obejrzeć wynik. „Zapisz” umieszcza wybrany język w `option.cfg`, a anulowanie przywraca poprzedni język interfejsu. Jeżeli podczas uruchomienia jawnie podano `--language`, po wyjściu z edytora parametr ten ponownie zaczyna obowiązywać.

Podłączanie tłumaczeń zewnętrznych opisano w [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master umożliwia wypełnienie parametrów jednego urządzenia, utworzenie jego kopii, zapisanie urządzenia na liście albo przygotowanie polecenia do uruchomienia z konsoli.

Wybierz pozycję `1` menu głównego albo uruchom:

```bash
mikrotik-backup.sh -b
```

W przeciwieństwie do Configuration Editor program BackUP Master nie wypełnia zwykłych pól ustawieniami z `option.cfg`. Wartości pochodzą z ustawień wbudowanych oraz parametrów jawnie przekazanych przez CLI. Wyjątkiem jest `UseIncremental`: jego wartość pochodzi z pliku parametrów, a jeżeli brak tego ustawienia, używane jest `true`.

Istniejące wpisy z `devicelist.cfg` również nie są wczytywane do formularza. Dla wybranego urządzenia trzeba wypełnić nazwę, adres, login i hasło.

### Pola BackUP Master

Pola są ułożone w podanej niżej kolejności. Przedstawiono tu ich nazwy w polskim tłumaczeniu:

| Pole | Przeznaczenie |
|---|---|
| Nazwa urządzenia | Nazwa używana na liście urządzeń i w nazwach kopii, gdy pobieranie RouterOS Identity jest wyłączone |
| Adres IP | Adres IP lub nazwa DNS urządzenia |
| Login | Użytkownik urządzenia RouterOS |
| Hasło | Hasło użytkownika urządzenia RouterOS |
| Port SSH | Port połączenia; wartość domyślna `22` |
| Typ kopii zapasowej | Konfiguracja `.rsc`, kopia binarna `.backup` albo oba formaty |
| Używaj porównywania przyrostowego | Porównywać nową kopię z poprzednią albo zapisywać bez porównania |
| Format eksportu | `compact`, `terse` albo `verbose` |
| Dane poufne | Dodawać wartości poufne do eksportu tekstowego |
| Hasło szyfrowania | Szyfrować kopię binarną; pusta wartość wyłącza szyfrowanie |
| Czyszczenie pamięci podręcznej DNS | Wyczyścić pamięć podręczną DNS przed kopią binarną |
| Czyszczenie historii konsoli | Wyczyścić historię konsoli przed kopią binarną |
| Katalog kopii zapasowych | Katalog, w którym zostaną zapisane pliki |
| To katalog sieciowy | Wartość `UseNetFolder`; sprawdzanie montowania dotyczy trybu wsadowego |
| Używaj RouterOS Identity | Pobierać nazwę z urządzenia zamiast używać nazwy podanej w formularzu |

Przełączniki, typ kopii i format eksportu zmienia się klawiszem **Enter**, a pozostałe wartości wprowadza w odpowiednich polach. Oba hasła są ukryte pod gwiazdkami.

**Uwaga!!!**
Domyślnie włączone są dane poufne w eksporcie tekstowym oraz czyszczenie pamięci podręcznej DNS i historii konsoli przed kopią binarną. Przed wykonaniem wybierz odpowiednie ustawienia.

BackUP Master nie zawiera pozycji dla `MonthlyArchive`, `LogLevel` ani `MainLogPath`. Archiwizacja miesięczna jest wyłączona podczas pracy przez BackUP Master, a ustawienia rejestrowania są pobierane z `option.cfg` z uwzględnieniem przekazanych parametrów CLI.

### 1. Utwórz kopię zapasową

Wypełnij adres, login i hasło, sprawdź port oraz parametry kopii → wybierz „1. Utwórz kopię zapasową”.

Jeżeli pobieranie RouterOS Identity jest włączone, nazwa kopii zostanie pobrana z urządzenia. Jeżeli funkcja jest wyłączona, trzeba wypełnić pole „Nazwa urządzenia”.

Rozpocznie się tworzenie kopii jednego urządzenia. Po zakończeniu zostanie wyświetlony wynik z kodem, a skrypt powróci do konsoli. Nie wróci już do formularza BackUP Master, niezależnie od powodzenia lub błędu.

Rozmieszczenie plików i reguły przechowywania opisano w [BACKUPS.md](BACKUPS.md), a komunikaty wykonania — w [LOGGING.md](LOGGING.md).

### 2. Zapisz urządzenie w devicelist.cfg

Do zapisania potrzebne są nazwa urządzenia, adres, login, hasło i port SSH. Dopóki wymagane pola nie zostaną wypełnione, odpowiednia akcja pozostaje niedostępna.

BackUP Master utworzy plik, doda nowy wpis albo zaktualizuje istniejący wpis o tej samej nazwie. W przypadku konfliktu wpisów lub błędu zapisu poprzednia lista pozostaje bez zmian. Po zapisaniu formularz pozostaje otwarty.

**Do `devicelist.cfg` zapisywane są wyłącznie dane urządzenia.** Parametry kopii z formularza nie trafiają do `option.cfg`, a ta akcja nie uruchamia tworzenia kopii.

*(N.B. Port `22` jest zapisywany jako puste pole. Podczas następnego uruchomienia wsadowego taki wpis użyje `SshPort` z ustawień skryptu. Port niestandardowy jest zapisywany jawnie.)*

Format listy i zasady aktualizacji opisano w [DEVICES.md](DEVICES.md).

### 3. Skopiuj polecenie konsoli

BackUP Master przygotuje polecenie uruchomienia na podstawie wypełnionego formularza i przekaże je do schowka. Tworzenie kopii nie rozpocznie się, a BackUP Master zakończy działanie i wróci do konsoli.

Ta funkcja wymaga GNU `base64` z obsługą `--wrap=0` oraz obsługi OSC 52 przez terminal. Jeżeli używasz multipleksera terminala, również on musi przepuszczać to polecenie. Gdy przekazywanie do schowka nie jest obsługiwane, polecenie nie jest wyświetlane jawnym tekstem na ekranie.

Parametry zgodne z wartościami wbudowanymi mogą nie trafić do polecenia. Podczas późniejszego uruchomienia tego polecenia ustawienia z `option.cfg` nadal obowiązują, więc wynik może różnić się od wykonania bezpośrednio przez BackUP Master.

Ustawienie `UseIncremental` nie jest przenoszone do polecenia, ponieważ nie ma osobnego parametru CLI. Przy uruchamianiu skopiowanego polecenia wartość pochodzi z `option.cfg` albo z ustawień domyślnych.

*(N.B. Polecenie w schowku zawiera hasła. Pamiętaj o tym, używając historii schowka i wklejając polecenie do powłoki. Szczegóły zawiera [SECURITY.md](SECURITY.md).)*

### 0. Powrót do menu głównego

Wynik zależy od sposobu otwarcia BackUP Master:

| Sposób otwarcia | Miejsce powrotu |
|---|---|
| Przez menu główne `-i` | Menu główne |
| Osobnym uruchomieniem `-b` | Konsola |

Niezapisane parametry formularza są odrzucane. Wpis zapisany już w `devicelist.cfg` pozostaje.

<br />

## Pomoc i instrukcja

Pozycja `4` menu głównego otwiera pomoc dotyczącą parametrów wiersza poleceń, a pozycja `5` — krótką instrukcję obsługi skryptu.

Jeżeli tekst nie mieści się na wysokość, jest dzielony na strony. Przewijaj je klawiszami **PageUp / PageDown**; numer bieżącej strony jest widoczny na ekranie.

Pozycja `0` wraca do menu głównego, a pozycja `6` kończy pracę skryptu. Działania te można wybrać strzałkami i klawiszem **Enter** albo odpowiednią cyfrą.

Tę samą pomoc dotyczącą CLI można uzyskać bezpośrednio w konsoli:

```bash
mikrotik-backup.sh -h
```
