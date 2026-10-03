# Wiersz poleceń

[Spis treści](../README_PL.md)

## Składnia

```text
mikrotik-backup.sh [akcja] [parametry]
```

Parametry wiersza poleceń mogą mieć długą postać: `--parametr wartość` lub `--parametr=wartość`.
Dostępna jest też postać krótka: `-p=wartość`. Jeżeli jednak **wartość** zaczyna się od `-`, dozwolona jest wyłącznie postać ze znakiem `=`, czyli `--parametr=-wartość`.

Nieznany parametr, argument pozycyjny, brakująca, jawnie pusta lub niedozwolona wartość powodują błąd `12` i zatrzymanie skryptu.

<br />

## Akcje

| Akcja | Przeznaczenie |
|---|---|
| `-i` | Główne menu interaktywne |
| `-b` | BackUP Master |
| `-e` | Configuration Editor (`option.cfg`) |
| `-h`, `--help` | Pomoc dotycząca parametrów CLI |
| `-v`, `--version` | Wersja skryptu |

Nie można podawać kilku parametrów akcji jednocześnie. Na przykład `mikrotik-backup.sh -i -b` zatrzyma skrypt z błędem `12`.

<br />

## Parametry

| Parametr | Wartość | Przeznaczenie |
|---|---|---|
| `--device-name` | Nazwa | Nazwa urządzenia przy `UseIdentityName=false` |
| `--address` | Adres lub nazwa DNS | Adres urządzenia RouterOS |
| `--user` | Login | Użytkownik urządzenia RouterOS |
| `--password` | Hasło | Hasło użytkownika urządzenia RouterOS |
| `--port` | `1`–`65535` | Port SSH urządzenia; wartość domyślna `22` |
| `--language` | `auto` lub dwie litery ASCII | Język bieżącego interfejsu i dzienników skryptu |
| `--use-oxidized` | Wartość logiczna* | Importować listę z Oxidized |
| `--oxidized-home` | Ścieżka | Katalog ustawień Oxidized z plikami `config` i `router.db` |
| `--use-identity-name` | Wartość logiczna* | Pobierać nazwę z RouterOS Identity |
| `--backup-root` | Ścieżka | Katalog główny miejsca przechowywania kopii |
| `--use-net-folder` | Wartość logiczna* | Sprawdzać montowanie w trybie wsadowym |
| `--monthly-archive` | `false` lub liczba `1`–`28`* | Włączyć kalendarzową archiwizację miesięczną |
| `--log-level` | `0`, `1`, `2`, `3` | Szczegółowość dzienników i wyjścia terminala |
| `--main-log-path` | Ścieżka | Wyłącznie katalog dla `main.log` |
| `--backup-type` | `configuration`,`binary`,`both` | Formaty do pobrania |
| `--export-format` | `compact`, `terse`, `verbose` | Format eksportu tekstowego |
| `--show-sensitive` | Wartość logiczna* | Dodawać wartości poufne do eksportu |
| `--encrypt` | Niepuste hasło | Szyfrować `.backup` algorytmem AES-SHA256 |
| `--clear-dns-cache` | Wartość logiczna* | Wyczyścić pamięć podręczną DNS przed kopią binarną |
| `--clear-console-history` | Wartość logiczna* | Wyczyścić historię konsoli przed kopią binarną |

`*` Wartości logiczne to `true` lub `false`; skrypt przyjmuje również `yes`/`no`, `1`/`0` i `on`/`off` bez rozróżniania wielkości liter.
Dla `backup-type` wartości `config` i `conf` są również synonimami `configuration`.

Krótkie postacie parametrów połączenia:

```text
-a=VALUE    to samo co --address VALUE
-u=VALUE    to samo co --user VALUE
-p=VALUE    to samo co --password VALUE
```

<br />

<a id="execution-mode"></a>
## Uruchamianie skryptu z wiersza poleceń

Skrypt może utworzyć kopię zapasową jednego urządzenia, ale takie uruchomienie wymaga co najmniej trzech parametrów: **adresu IP urządzenia**, **loginu** i **hasła**. Poniższe polecenie jest więc już kompletne:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Wszystkie pozostałe parametry wymienione wyżej są tutaj opcjonalne.
*(N.B. Bardzo ważna uwaga: skrypt NIE jest przeznaczony do łączenia tej trójki z parametrami **Akcji**.)*

**Niuans!!!**
W trybie pojedynczego urządzenia wszystkie trzy parametry połączenia trzeba przekazać przez CLI. Skrypt nie pobierze brakującego loginu ani hasła z `option.cfg`.

<br />

## Priorytet ustawień

Dla zwykłego uruchomienia pojedynczego urządzenia i trybu wsadowego obowiązuje kolejność opisana w [OPTIONS.md](OPTIONS.md):
**Wartości wbudowane** → **Prawidłowe wiersze option.cfg** → **CLI**

Jeżeli parametr znajduje się już w `option.cfg`, ale dane uruchomienie wymaga innej wartości, przekaż ją przez CLI. Nie trzeba przepisywać pliku ustawień.

Podczas uruchomienia dla jednego urządzenia lista urządzeń i import z Oxidized nie są używane. Pozostałe ustawienia z `option.cfg` nadal obowiązują, o ile nie zastąpiły ich parametry wiersza poleceń.

**BackUP Master ma własną kolejność wypełniania formularza.**
Zwykłe pola pobierają wartości z ustawień wbudowanych i przekazanych parametrów CLI, a nie z `option.cfg`. Wyjątkiem jest `UseIncremental`: to ustawienie jest dziedziczone z pliku lub otrzymuje wartość domyślną.
Podczas wykonywania zachowywane są wybrane dla uruchomienia `LogLevel` i `MainLogPath`, a archiwizacja miesięczna jest wyłączona. Działanie BackUP Master opisano szczegółowo w [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Parametry wiersza poleceń według przeznaczenia

### Połączenie i nazwa urządzenia

| Parametr | Wartość | Przeznaczenie |
|---|---|---|
| `--address` | Adres IP lub nazwa DNS | Adres urządzenia RouterOS |
| `--user` | Login | Użytkownik urządzenia RouterOS |
| `--password` | Hasło | Hasło użytkownika urządzenia RouterOS |
| `--port` | Od `1` do `65535` | Port SSH urządzenia; wartość domyślna `22` |
| `--device-name` | Nazwa | Nazwa urządzenia przy `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Pobierać nazwę z RouterOS Identity |

Aby użyć własnej nazwy, podaj jednocześnie `--use-identity-name false` i `--device-name NAZWA`.

<br />

### Format i zawartość kopii zapasowych

| Parametr | Wartość | Przeznaczenie |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Formaty do pobrania |
| `--export-format` | `compact`, `terse`, `verbose` | Format eksportu tekstowego |
| `--show-sensitive` | `true` / `false` | Dodawać wartości poufne do eksportu |
| `--encrypt` | Niepuste hasło | Szyfrować `.backup` algorytmem AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Wyczyścić pamięć podręczną DNS przed kopią binarną |
| `--clear-console-history` | `true` / `false` | Wyczyścić historię konsoli przed kopią binarną |

Dla `--backup-type` wartości `config` i `conf` również oznaczają `configuration`.

*(N.B. Parametr `UseIncremental` nie ma osobnego odpowiednika w CLI. To ustawienie określa się w `option.cfg`, Configuration Editor albo BackUP Master. Jego przeznaczenie opisano w [OPTIONS.md](OPTIONS.md).)*

<br />

### Miejsce przechowywania, archiwizacja i dzienniki

| Parametr | Wartość | Przeznaczenie |
|---|---|---|
| `--backup-root` | Ścieżka | Katalog główny miejsca przechowywania kopii |
| `--use-net-folder` | `true` / `false` | Sprawdzać montowanie w trybie wsadowym |
| `--monthly-archive` | `false` lub liczba od `1` do `28` | Włączyć kalendarzową archiwizację miesięczną |
| `--log-level` | `0`, `1`, `2`, `3` | Szczegółowość dzienników i wyjścia terminala |
| `--main-log-path` | Ścieżka katalogu | Wyłącznie katalog dla `main.log` |

Dla `--monthly-archive` obowiązuje osobna reguła: `true`/`yes`/`1`/`on` oznaczają pierwszy dzień miesiąca, a `false`/`no`/`0`/`off` wyłączają archiwizację. Wartości od `2` do `28` wybierają odpowiedni dzień.

Parametr wybiera dzień archiwizacji, a nie uruchamia jej natychmiast. Zasady tego trybu opisano w [BACKUPS.md](BACKUPS.md#monthly-archive).

Dla `--main-log-path` podawaj katalog, a nie pełną ścieżkę z nazwą `main.log`. Ustawienie nie wpływa na dzienniki urządzeń.

<br />

### Źródło listy urządzeń i język

| Parametr | Wartość | Przeznaczenie |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Importować listę z Oxidized |
| `--oxidized-home` | Ścieżka | Katalog ustawień Oxidized z plikami `config` i `router.db` |
| `--language` | `auto` lub dwuliterowy kod | Język bieżącego interfejsu i dzienników skryptu |

Przy `--language auto` język wybiera locale systemu operacyjnego. Można podać go jawnie, na przykład `ru`, `en` lub `de`. Rosyjski i angielski nie wymagają osobnego pliku tłumaczenia; pozostałe tłumaczenia są wczytywane z plików umieszczonych obok skryptu. Jeżeli brak odpowiedniego tłumaczenia, używany jest angielski.
Szczegóły znajdują się w [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Przykłady uruchomienia

**Uwaga!!!**
Domyślnie włączone jest dodawanie danych poufnych do eksportu oraz czyszczenie pamięci podręcznej DNS i historii konsoli przed kopią binarną. W poniższych przykładach dla jednego urządzenia czyszczenie i dane poufne w eksporcie są wyłączone.

*(N.B. Hasła przekazane przez CLI mogą być widoczne w historii powłoki i argumentach procesów. Dotyczy to także hasła szyfrowania `.backup`, które może być również widoczne w argumentach procesu potomnego `ssh`. Więcej informacji zawiera [SECURITY.md](SECURITY.md).)*

### Tylko konfiguracja `.rsc`, bez danych poufnych

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Oba formaty, własna nazwa urządzenia, bez czyszczenia

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Zaszyfrowana kopia binarna

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='HASŁO_SZYFROWANIA' --clear-dns-cache=false --clear-console-history=false
```

### Uruchomienie wsadowe z osobnym katalogiem i szczegółowym rejestrowaniem

Zakłada się tutaj, że `option.cfg` i lista urządzeń są już przygotowane:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Pozostałe ustawienia tego uruchomienia wsadowego są pobierane z `option.cfg` i wartości wbudowanych.

<br />

## Gdy polecenie zostanie odrzucone

Nieznany parametr, zbędny argument pozycyjny, brakująca lub niedozwolona wartość powodują błąd `12`. Tworzenie kopii zapasowych nie rozpoczyna się. Pisownię parametrów można sprawdzić za pomocą `-h`.

**Pustych wartości nie można przekazywać przez CLI.**
Zapisy `--encrypt=''` i `--main-log-path=''` zostaną odrzucone. Puste wartości `encrypt=` i `MainLogPath=` ustawia się w `option.cfg` albo za pomocą Configuration Editor.

Kody zakończenia i ich znaczenie podano w rozdziale [Diagnostyka](TROUBLESHOOTING.md#result-codes).
