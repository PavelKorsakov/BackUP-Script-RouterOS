# Bezpieczeństwo

[Spis treści](../README_PL.md)

## Konta użytkowników

Skrypt nie wymaga uprawnień **root**. Wystarczy zwykły użytkownik mający dostęp do plików ustawień oraz prawo zapisu w wybranym miejscu przechowywania i w dziennikach.

Tworzenie osobnego użytkownika **bsmt** i konfigurowanie uruchamiania w jego imieniu opisano w [INSTALL.md](INSTALL.md#automatyczne-uruchamianie-skryptu).

Również na urządzeniu RouterOS zaleca się utworzenie osobnego użytkownika do tworzenia kopii i ograniczenie jego logowania do adresu IP hosta, na którym działa skrypt. Uprawnienia konta muszą pozwalać na wybrane operacje: pobieranie konfiguracji, tworzenie i pobieranie kopii, usuwanie plików tymczasowych oraz włączone operacje czyszczenia.

<br />

## Połączenie z RouterOS

Do połączenia używane jest SSH z uwierzytelnianiem hasłem. Klucze SSH i agent nie są używane. Pliki są pobierane przez starszy protokół SCP, czyli `scp -O`.

Skrypt używa własnych parametrów połączenia. Konfiguracja użytkownika `~/.ssh/config` ani systemowa konfiguracja SSH nie są odczytywane, ponieważ klient jest uruchamiany z `-F /dev/null`. Przekazywanie agenta, X11 i portów jest wyłączone.

**Uwaga!!! Sprawdzanie klucza serwera jest wyłączone.**

Bieżący profil używa następujących parametrów:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Zwykłe pliki `known_hosts` nie są odczytywane ani zmieniane. Skrypt nie sprawdza więc, czy odpowiada oczekiwane urządzenie, czy podstawiony serwer. Uwzględnij to podczas organizowania dostępu sieciowego do routerów.

<br />

<a id="secrets"></a>
## Hasła podczas uruchamiania skryptu

Hasło przekazane przez `--password` lub `-p=` jest częścią polecenia uruchomienia. Może być widoczne w argumentach procesu i zostać zapisane w historii powłoki. To samo dotyczy hasła szyfrowania przekazanego przez `--encrypt`.

### Wprowadzanie przez BackUP Master

Aby nie podawać hasła SSH w wierszu poleceń, uruchom BackUP Master:

```bash
mikrotik-backup.sh -b
```

Wypełnij dane uwierzytelniające urządzenia w formularzu i wybierz odpowiednią akcję. Oba hasła są wyświetlane jako gwiazdki, a wartości wpisane w formularzu nie trafiają do historii poleceń powłoki.

Podczas połączenia sam skrypt przekazuje hasło SSH do `sshpass` przez deskryptor pliku (`-d`), a nie przez argument `sshpass -p` ani zmienną `SSHPASS`.

### Hasło szyfrowania .backup

Hasło szyfrowania jest włączane do polecenia RouterOS przekazywanego procesowi potomnemu `ssh`. Użytkownik hosta z uprawnieniami wystarczającymi do przeglądania argumentów procesów może je więc zobaczyć podczas tworzenia kopii binarnej.

Wprowadzenie hasła przez BackUP Master lub zapisanie go w `option.cfg` nie zmienia sposobu przekazywania. Szyfrowanie pliku nie chroni przed administratorem hosta wykonującego kopię.

### Kopiowanie polecenia konsoli

Akcja „Skopiuj polecenie konsoli” w BackUP Master przekazuje do schowka polecenie z danymi uwierzytelniającymi połączenia oraz — jeśli zostało podane dla kopii binarnej — hasłem szyfrowania.

Pamiętaj o tym podczas korzystania z historii schowka i wklejania polecenia do powłoki. Ukrycie hasła pod gwiazdkami w formularzu nie oznacza, że jest ono ukryte w skopiowanym poleceniu.

<br />

## Pliki zawierające dane poufne

| Plik | Możliwa zawartość |
|---|---|
| `devicelist.cfg` | Adresy urządzeń, loginy i hasła SSH zapisane jawnym tekstem |
| `option.cfg` | Wspólne `Login` i `Password`, hasło szyfrowania `encrypt` |
| `.rsc` i `.backup` | Konfiguracja urządzeń, hasła i inne dane poufne |
| Miesięczny ZIP | Te same kopie zapasowe i dzienniki zebrane w jednym archiwum |

Nie umieszczaj roboczych plików ustawień ani kopii zapasowych w publicznym repozytorium lub ogólnodostępnym katalogu.

### Dane poufne w .rsc

Domyślnie używane jest `show_sensitive=true`, czyli wartości poufne są dodawane do eksportu tekstowego. Aby je wyłączyć, podaj w `option.cfg`:

```ini
show_sensitive=false
```

Nawet wtedy plik pozostaje konfiguracją Twojego urządzenia: adresy, struktura sieci, komentarze i inne własne wiersze nie znikają z niego.

### Szyfrowanie kopii binarnej

Domyślnie `encrypt` jest pusty, a `.backup` jest zapisywany bez szyfrowania. Aby je włączyć, podaj hasło w pliku parametrów lub odpowiednim polu BackUP Master:

```ini
encrypt=MySuperPassword
```

Używany jest algorytm AES-SHA256. Szyfruje on **wyłącznie `.backup`**, ale nie `.rsc`, `option.cfg`, listę urządzeń, dzienniki ani sam plik ZIP. Dostęp do miesięcznego archiwum należy więc ograniczyć tak samo jak dostęp do znajdujących się w nim plików.

<br />

## Uprawnienia do plików i miejsca przechowywania

Skrypt działa z `umask 077`. Tworzone przez niego lokalne katalogi przechowywania otrzymują uprawnienia `0700`, a programowo zapisywane pliki `option.cfg` i `devicelist.cfg` — uprawnienia `0600`.

Właściciel i uprawnienia istniejących katalogów administracyjnych nie są automatycznie zmieniane. Jeżeli katalog przygotowano ręcznie, dostęp do niego trzeba skonfigurować samodzielnie.

Lokalny katalog archiwów miesięcznych `archive/` musi należeć do użytkownika uruchamiającego skrypt i mieć uprawnienia `0700`. Wymóg dotyczy również istniejącego katalogu. Tworzone lokalnie pliki archiwów mają uprawnienia `0600`.

W trybie wsadowym ze zweryfikowanym sieciowym miejscem przechowywania i `UseNetFolder=true` właściciela oraz uprawnienia obiektów archiwum może określać serwer NAS. Sama różnica względem wartości lokalnych nie zatrzymuje archiwizacji. Dostęp do zasobu sieciowego konfiguruje się narzędziami systemu i NAS.

Przykłady przygotowania katalogów i przyznawania dostępu użytkownikowi **bsmt** podano w [INSTALL.md](INSTALL.md).

*(N.B. Skrypt odczytuje konfigurację, listę urządzeń, tłumaczenia i używane ustawienia Oxidized jako dane, a nie wykonuje ich jako skrypty powłoki.)*

<br />

## Zmiany na urządzeniu

Przed utworzeniem kopii binarnej domyślnie czyszczona jest pamięć podręczna DNS i historia konsoli RouterOS. Jeżeli te działania nie są potrzebne, wyłącz je w `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Te same funkcje można wyłączyć za pomocą Configuration Editor, BackUP Master albo odpowiednich parametrów CLI. Przy pobieraniu wyłącznie `.rsc` czyszczenie nie jest wykonywane.

<br />

## Dzienniki i przekazywanie danych diagnostycznych

Szczegółowy poziom `LogLevel=3` dodaje informacje o etapach pracy, a nie wyświetla haseł ani pełnych poleceń połączenia.

W przetworzonej diagnostyce SSH maskowane są dokładne znane wartości adresu, loginu, hasła SSH i hasła szyfrowania. Nie jest to oczyszczanie zawartości kopii zapasowych ani gwarancja usunięcia wszystkich sekretów z dowolnego tekstu.

Tymczasowe pliki nieprzetworzonej diagnostyki mogą zawierać dane poufne. Są tworzone z uprawnieniami `0600` i usuwane podczas zwykłego sprzątania.

Przed wysłaniem innym osobom dzienników, zrzutów ekranu lub wyjścia poleceń sprawdź ich zawartość. Pełne wyjście `devicelist.cfg`, lista procesów albo zawartość schowka mogą ujawnić dane nieobecne w zwykłym dzienniku.

Więcej informacji o wpisach dziennika zawiera [LOGGING.md](LOGGING.md), a o wyszukiwaniu błędów — [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Równoczesne uruchomienia

Dla uruchomień tego samego użytkownika i z tym samym `BackupRoot` stosowane są blokady:

| Równoczesne uruchomienia | Skutek |
|---|---|
| Tryb wsadowy i jeszcze jeden tryb wsadowy albo pojedyncze urządzenie | Drugie uruchomienie nie uzyska blokady |
| Dwa uruchomienia pojedyncze dla tego samego urządzenia | Drugie uruchomienie nie uzyska blokady |
| Uruchomienia pojedyncze dla różnych urządzeń | Mogą działać równocześnie |

Jeżeli blokada jest zajęta, skrypt kończy się kodem `32`. Różne katalogi główne przechowywania, z których jeden jest zagnieżdżony w drugim, nie są koordynowane jako wspólny magazyn.

Pliki blokad znajdują się w `/tmp/mikrotik-backup-${UID}/` i pozostają po zakończeniu skryptu. Sama ich obecność nie oznacza, że skrypt nadal działa.

**Nie usuwaj tych plików, aby „zwolnić zawieszoną blokadę”.** Blokada jest związana z otwartym deskryptorem pliku procesu, a nie z obecnością pliku. Blokady te nie chronią również danych przed innym programem, który zmienia je bezpośrednio.

<br />

## Weryfikowanie odtwarzania

Weryfikacja sumy kontrolnej skryptu i pomyślne pobranie pliku kopii zapasowej nie zastępują testu odtwarzania.

Sam skrypt nie przywraca RouterOS. Przydatność kopii trzeba sprawdzać osobno na odpowiednim urządzeniu, a okres ich przechowywania — ustalić samodzielnie. Szczegóły zawiera [BACKUPS.md](BACKUPS.md).
