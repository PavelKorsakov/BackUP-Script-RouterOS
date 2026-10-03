# Lista urządzeń

[Spis treści](../README_PL.md)

## Urządzenia do tworzenia kopii, czyli plik devicelist.cfg

Jak wskazuje nazwa, `devicelist.cfg` zawiera listę urządzeń przeznaczonych do wsadowego tworzenia kopii zapasowych oraz dane potrzebne do połączenia.
Sam plik musi znajdować się bezpośrednio obok `mikrotik-backup.sh`.
Plik `devicelist.cfg` można utworzyć ręcznie albo za pomocą BackUP Master.
Trzecia możliwość przydaje się, gdy na tym samym serwerze działa Oxidized. Po dodaniu odpowiednich ustawień do pliku parametrów skrypt będzie przy każdym uruchomieniu dynamicznie tworzył `devicelist.cfg` na podstawie danych z plików konfiguracyjnych Oxidized.

<br />

## Tworzenie i edytowanie listy

Aby utworzyć listę za pomocą BackUP Master, uruchom:

```bash
mikrotik-backup.sh -b
```

Wypełnij nazwę urządzenia, adres, login, hasło i port SSH → wybierz „2. Zapisz urządzenie w devicelist.cfg”.
BackUP Master utworzy plik z odpowiednim wpisem albo doda bądź zaktualizuje wpis w istniejącym pliku.

Gotową listę można edytować zwykłym edytorem tekstu. BackUP Master nie wczytuje istniejących wpisów do formularza.

*(N.B. Gdy BackUP Master zapisuje port `22`, pozostawia puste pole. Podczas przetwarzania wsadowego taki wpis używa `SshPort` z ustawień skryptu. Port niestandardowy jest zapisywany jawnie.)*

<br />

## Format pliku

Każde urządzenie zajmuje osobny wiersz. Pola są rozdzielane rzeczywistym **znakiem tabulacji (TAB)**, a nie spacjami. Kolejność pól jest następująca:

| Pozycja | Pole | Przeznaczenie |
|---|---|---|
| 1 | Nazwa | Nazwa urządzenia; wymagana |
| 2 | Adres | Adres IP lub nazwa DNS urządzenia; wymagany |
| 3 | Login | Użytkownik urządzenia RouterOS; jeśli pole jest puste, dziedziczony z `Login` w `option.cfg` |
| 4 | Hasło | Hasło użytkownika urządzenia RouterOS; jeśli pole jest puste, dziedziczone z `Password` w `option.cfg` |
| 5 | Port | Port SSH od `1` do `65535`; jeśli pole jest puste, dziedziczony z `SshPort`, domyślnie `22` |
| 6 | Znacznik urządzenia | `MikroTik`; może być pusty. Wielkość liter nie ma znaczenia |

Pola od siódmego wzwyż nie są używane. Wpisy z innym znacznikiem urządzenia są pomijane.

### Przykładowa lista

Pola w tym przykładzie rozdzielają rzeczywiste znaki TAB:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

W drugim wierszu nie podano portu: między hasłem a `MikroTik` znajdują się dwa znaki tabulacji. Zastąp adresy i dane uwierzytelniające własnymi.

### Wspólny login, hasło i port

Jeżeli wszystkie urządzenia używają tych samych danych uwierzytelniających, podaj je raz w `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Wtedy w `devicelist.cfg` wystarczą nazwa i adres każdego urządzenia:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Dane uwierzytelniające podane we własnym wpisie urządzenia zastępują wartości wspólne.

*(N.B. Plik listy urządzeń zawiera hasła. Ogranicz dostęp do niego zgodnie z opisem w [SECURITY.md](SECURITY.md).)*

<br />

## Sposób odczytu listy

Puste wiersze oraz wiersze, których pierwszym znakiem niebędącym odstępem jest `#`, są ignorowane. Komentarze umieszczaj w osobnych wierszach; znak `#` wewnątrz pola stanowi część jego wartości.

Początkowe i końcowe odstępy w nazwie, adresie, porcie i znaczniku są usuwane. Login i hasło są odczytywane dosłownie, wraz ze spacjami i cudzysłowami. Obsługiwane są pliki z zakończeniami wierszy Windows (CRLF).

Jeżeli wiersz z wpisem urządzenia narusza wymaganą składnię, skrypt pomija go podczas działania i wyświetla ostrzeżenie o nieprawidłowym wpisie.

Jeżeli wiersz z dowolnego powodu się powtarza, czyli wszystkie cztery parametry połączenia (**adres, login, hasło i port**) są identyczne, skrypt łączy się z tym urządzeniem tylko raz, używając danych z ostatniego wpisu.
Jeżeli tę samą nazwę mają różne połączenia, używany jest pierwszy prawidłowy wpis, a konfliktowy zostaje pominięty.

<br />

<a id="device-names"></a>
## Nazwy urządzeń

Nazwa jest używana w nazwach kopii zapasowych, a w trybie wsadowym również jako nazwa podkatalogu urządzenia.
Źródło nazwy określa ustawienie `UseIdentityName` w pliku `option.cfg`:

| Wartość | Źródło nazwy |
|---|---|
| `true` (domyślnie) | Wartość Identity na samym urządzeniu RouterOS |
| `false` | Nazwa z `devicelist.cfg`, pola BackUP Master albo parametru `--device-name` przy uruchomieniu jednego urządzenia przez CLI |

### Nazwa w nawiasach

Jeżeli nazwa początkowa zawiera nawiasy okrągłe, skrypt używa zawartości pierwszej domkniętej, niepustej grupy. Jeżeli takiej grupy nie ma, używana jest cała nazwa.

| Nazwa początkowa | Nazwa kopii zapasowej |
|---|---|
| `Oddział (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Oddział (Core (East) West)` | `Core_East_West` |

### Dozwolone znaki

W nazwie wynikowej zachowywane są litery, w tym znaki cyrylicy, cyfry, kropki, łączniki i znaki podkreślenia. Spacje i niedozwolone znaki są zastępowane znakiem `_`. Powtarzające się oraz początkowe i końcowe znaki podkreślenia są usuwane, podobnie jak początkowe kropki i łączniki oraz kropki na końcu nazwy.

Na przykład `ЦОД Київ №1` zostanie przekształcone w `ЦОД_Київ_1`.

Nazwa wynikowa musi zawierać **od 1 do 32 znaków**. Zbyt długa nazwa nie jest skracana, lecz powoduje błąd. Zastrzeżone nazwy `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` i `LPT1`–`LPT9` są niedozwolone.

Nazwy wynikowe muszą być unikatowe bez uwzględniania wielkości liter: `Router-A` i `router-a` są uznawane za identyczne. Drugie urządzenie o takiej nazwie zostanie pominięte w bieżącym uruchomieniu.

*(N.B. Zmiana nazwy wynikowej zmienia również podkatalog urządzenia. Stare kopie zapasowe nie są przenoszone automatycznie.)*

<br />

## Import z Oxidized

Jeżeli lista urządzeń jest już prowadzona w Oxidized, skrypt może ją stamtąd pobierać. Dodaj do `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

W `OxidizedHome` podaj katalog zawierający pliki `config` i `router.db`. Na ich podstawie tworzony jest `devicelist.cfg`. Same pliki Oxidized nie są zmieniane.

*(N.B. Import zastępuje plik `devicelist.cfg`, a nie uzupełnia go. Wpisy dodane ręcznie zostaną utracone podczas następnej pomyślnej aktualizacji z Oxidized.)*

### Konfiguracja źródła

Konfiguracja Oxidized musi używać źródła `csv` z separatorem składającym się z jednego znaku. Kolejność kolumn określa mapa `source.csv.map`, a numeracja zaczyna się od zera:

| Pole mapy | Używana wartość |
|---|---|
| `name` | Nazwa urządzenia; kolumna wymagana |
| `ip` | Adres urządzenia; jeśli nie podano, używana jest wartość `name` |
| `username` | Login; jeśli nie podano, używany jest wspólny `Login` z `option.cfg` |
| `password` | Hasło; jeśli nie podano, używane jest wspólne `Password` z `option.cfg` |
| `port` | Port SSH; jeśli nie podano, używany jest `SshPort` |
| `model` | Model urządzenia; jeśli kolumna nie istnieje, używany jest główny parametr `model` |

Reguły `model_map` są stosowane do pierwszego dopasowania. Importowane są wyłącznie urządzenia, których model wynikowy to `routeros`. Jeżeli istnieje kolumna `model`, parametr główny nie zastępuje w niej pustych wartości.

Dane są zawsze odczytywane z `<OxidizedHome>/router.db`. Parametr Oxidized `source.csv.file` nie zmienia tej ścieżki.

### Gdy import się nie powiedzie

Jeżeli pliki Oxidized są niedostępne, ich format nie jest obsługiwany albo brak prawidłowych urządzeń, poprzedni `devicelist.cfg` zostaje zachowany.

Przy `IgnoreOxiAccess=true` skrypt może użyć poprzedniej prawidłowej listy. Przy `false` nie wykonuje kopii na podstawie starej listy.

Błąd importu wpływa na wynik uruchomienia nawet wtedy, gdy tworzenie kopii z poprzedniej listy zakończyło się pomyślnie.

Więcej informacji o błędach listy i importu zawiera rozdział [Diagnostyka](TROUBLESHOOTING.md).
