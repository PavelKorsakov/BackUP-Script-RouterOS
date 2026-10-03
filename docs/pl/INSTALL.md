# Instalacja

[Spis treści](../README_PL.md)

## Wymagania dotyczące hosta

Do uruchomienia potrzebny jest system Linux z GNU Bash **4.4 lub nowszym** oraz standardowymi narzędziami GNU do pracy z plikami.
Sam skrypt nie wymaga kompilacji, Pythona, kontenera ani bazy danych.
Wymaga jednak narzędzi wymienionych w rozdziale [Zależności](#zależności).

Do obsługi nazw urządzeń potrzebne jest prawidłowo działające locale **`C.UTF-8`**, które zapewnia liczenie znaków wielobajtowych, rozpoznawanie liter i zmianę wielkości znaków.
Skrypt sprawdza te możliwości przed rozpoczęciem pracy z urządzeniami. Jest to wymaganie systemowe, a nie osobny program o nazwie `C.UTF-8`.

Host musi oczywiście mieć uprzednio skonfigurowany dostęp sieciowy do usługi SSH RouterOS i prawo zapisu w wybranym miejscu przechowywania.

**Zdecydowanie zalecane!!!**
Do łączenia z urządzeniami RouterOS używane jest SSH z uwierzytelnianiem hasłem, a nie kluczem.
*(Dokładną politykę transportową opisano w [SECURITY.md](SECURITY.md).)*
Dlatego warto utworzyć na urządzeniu osobnego użytkownika i ograniczyć możliwość jego logowania do adresu IP hosta, na którym działa skrypt.

<br />

## Zależności

### Wymagane do tworzenia kopii zapasowych

Do tworzenia kopii zapasowych wymagane są **wszystkie** poniższe narzędzia:

| Narzędzia | Przeznaczenie |
|---|---|
| `ssh`, `scp`, `sshpass` | Łączenie z RouterOS, wykonywanie poleceń i pobieranie plików |
| GNU `timeout`, `sleep` | Ograniczanie czasu operacji i obsługa przerw |
| `sha256sum` | Obliczanie sum kontrolnych |
| `realpath` | Wyznaczanie ścieżek bezwzględnych |
| `flock` | Blokady zapobiegające konfliktom równoczesnych uruchomień |

**Jeżeli brakuje wymaganego narzędzia, skrypt zgłasza niespełnione zależności i przerywa próbę utworzenia kopii zapasowej. Kod błędu zależności to `30`. Jest to prawidłowe zachowanie.**

Lista jest taka sama dla trybu pojedynczego urządzenia i przetwarzania wsadowego, niezależnie od tego, czy powstaje plik `.rsc`, `.backup`, czy oba formaty.

Sama obecność poleceń nie wystarcza: zainstalowany OpenSSH musi obsługiwać używane parametry, w tym starszy tryb SCP wybierany przez `scp -O`.
GNU `timeout` musi obsługiwać `--signal` i `--kill-after`.
Te możliwości są sprawdzane lokalnie, bez łączenia z routerem.

<br />

### Wymagane przez wybrane funkcje

Poniższe narzędzia nie należą do wspólnej listy obowiązkowej. Są potrzebne tylko wtedy, gdy używana jest odpowiednia funkcja.

| Funkcja | Wymaganie | Skutek braku |
|---|---|---|
| Tryb wsadowy z `UseNetFolder=true` | `findmnt` | Tworzenie kopii w tym trybie nie rozpocznie się; błąd zależności `30` |
| Uruchomienie, podczas którego ma odbyć się archiwizacja miesięczna | Info-ZIP `zip`, `unzip`, GNU `mv` | Uruchomienie zatrzyma się na sprawdzaniu zależności przed utworzeniem kopii; błąd `30` |
| Menu interaktywne, Configuration Editor i BackUP Master | `stty` oraz terminal na standardowym wejściu i wyjściu | Ekran interaktywny nie otworzy się; błąd terminala `31` |
| **Copy console command** w BackUP Master | GNU `base64` z obsługą `--wrap=0` | Polecenia nie da się skopiować; błąd `30` |

Brak `zip` nie przeszkadza na przykład w zwykłym tworzeniu kopii, jeśli podczas danego uruchomienia archiwizacja miesięczna nie jest potrzebna.
Brak `base64` nie uniemożliwia tworzenia kopii zapasowych.
*(N.B. Jest ono potrzebne po wybraniu akcji **Copy console command**.)*

Ogólne sprawdzanie zależności odbywa się przed utworzeniem kopii zapasowej, a nie przy każdym otwarciu programu.
Dlatego pomoc, informacje o wersji lub menu mogą być dostępne nawet bez zainstalowanych narzędzi do tworzenia kopii.

<br />

### Podstawowe środowisko Linux

Zakłada się również obecność typowych poleceń systemowych do pracy z plikami i katalogami, w tym `date`, `stat`, `mkdir`, `cp`, `ln` i `rm`.

Należą one do podstawowego środowiska systemu operacyjnego. Powyższa lista zależności sprawdzanych z wyprzedzeniem nie obejmuje wszystkich zewnętrznych poleceń używanych przez skrypt. Brak podstawowego polecenia systemowego może ujawnić się jako błąd konkretnej operacji, a nie komunikat o niespełnionych zależnościach.

<br />

### Instalowanie wymaganych pakietów w Debianie/Ubuntu

Przykład instalacji obowiązkowych i wymienionych narzędzi dodatkowych:
*(N.B. Tu i dalej zakładamy, że użytkownik ma uprawnienia administratora.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Pobieranie plików skryptu

Podstawową metodą instalacji wersji 2.3.1 jest pełny zasób GitHub Release `mikrotik-backup-2.3.1.zip`. Jest on rozpakowywany bezpośrednio do katalogu instalacyjnego, bez dodatkowego katalogu nadrzędnego.
*(N.B. W przykładach umieszczających pliki pod `/opt` uruchom polecenia z uprawnieniami do utworzenia tego katalogu i zapisu w nim.)*

### Wariant 1. Pełny pakiet wydania

Pobierz `mikrotik-backup-2.3.1.zip` z GitHub Release MikroTik Backup Script 2.3.1, a następnie wykonaj:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Po rozpakowaniu gotowa do użycia struktura wygląda następująco:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Jeśli weryfikacja sumy kontrolnej nie powiedzie się, nie uruchamiaj skryptu, dopóki nie znajdziesz przyczyny.

<br />

### Wariant 2. Minimalna instalacja samodzielna

Pobierz zasoby `mikrotik-backup.sh` i `SHA256SUMS` z tego samego Release do chronionego katalogu, zweryfikuj je i nadaj skryptowi prawo wykonywania:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Pobierz oba zasoby Release do tego katalogu.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Aby użyć zewnętrznego języka runtime, skorzystaj z pełnego pakietu albo pobierz odpowiedni plik `.lang` ze źródeł oznaczonych tagiem tej samej wersji.

<br />

### Opcja zaawansowana: Git lub archiwum kodu źródłowego

Klon Git lub archiwum **Code → Download ZIP** tego repozytorium również zawiera kompletne drzewo źródeł produktu. Przydatny układ w katalogu głównym:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` jest zasobem wydania i może nie występować w kopii kodu źródłowego. Do zwykłej instalacji nadal zalecany jest wersjonowany pakiet Release, ponieważ zawiera plik sum kontrolnych i dokładnie odpowiada opublikowanej wersji.

<br />

## Pliki znajdujące się obok skryptu

Po rozpakowaniu pełnego pakietu Release wybrany katalog zawiera skrypt i pliki towarzyszące:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Plik lub katalog | Przeznaczenie |
|---|---|
| mikrotik-backup.sh | Właściwy skrypt kopii zapasowych |
| SHA256SUMS | Sumy kontrolne służące do weryfikacji pobranych plików |
| README.md | Opis programu i odsyłacze do szczegółowej dokumentacji |
| lang/ | Zestaw plików lokalizacji. Skopiuj potrzebny plik językowy z tego katalogu do katalogu skryptu. |
| docs/ | Szczegółowa dokumentacja instalacji, konfiguracji i użytkowania |

Do codziennej pracy potrzebny jest tylko plik `mikrotik-backup.sh`.
Aby zmienić ustawienia, utwórz **option.cfg** i umieść go obok skryptu.
Jeżeli planujesz sekwencyjnie odpytywać kilka urządzeń i tworzyć ich kopie zapasowe, utwórz obok skryptu również plik listy urządzeń **devicelist.cfg**.
Plik lokalizacji `<xx>.lang` jest potrzebny, jeśli chcesz korzystać z menu i dzienników w swoim języku. Jego również należy umieścić w katalogu z `mikrotik-backup.sh`.
Język rosyjski i angielski są wbudowane w skrypt, więc nie wymagają osobnego pliku lokalizacji.

**W trybie interaktywnym skrypt może utworzyć i zapisać:**
listę urządzeń — **devicelist.cfg** za pomocą BackUP Master;
plik konfiguracyjny — **option.cfg** za pomocą Configuration Editor.
Można je też przygotować samodzielnie:
*Format TSV listy urządzeń szczegółowo opisano w [DEVICES.md](DEVICES.md).*
*Format pliku konfiguracyjnego `Klucz=wartość` szczegółowo opisano w [OPTIONS.md](OPTIONS.md).*

<br />

## Przygotowanie miejsca przechowywania i dzienników

Przy ustawieniach domyślnych skrypt tworzy obok siebie katalog `./backups` i zapisuje w nim kopie zapasowe urządzeń.
Różnica między trybami polega jedynie na tym, że przy uruchomieniu dla jednego urządzenia pliki trafiają bezpośrednio do `./backups`, a w trybie wsadowym wewnątrz `./backups` powstaje podkatalog o nazwie urządzenia, w którym są zapisywane jego kopie.

Skrypt sam tworzy potrzebne katalogi przechowywania z odpowiednimi uprawnieniami.
*(Nie zmienia automatycznie właściciela ani trybu dostępu istniejących katalogów administracyjnych.)*

Domyślnie główny dziennik skryptu, `main.log`, znajduje się w `./backups`.
W trybie wsadowym dziennik pracy z urządzeniem znajduje się w podkatalogu tego urządzenia.

Jeżeli katalog kopii zapasowych znajduje się w zasobie sieciowym, skrypt może sprawdzać jego dostępność w trybie wsadowym. Funkcja ta jest domyślnie wyłączona i przed użyciem wymaga konfiguracji.
*(Sposób montowania katalogu nie ma znaczenia.)*

Wszystkie te parametry można zmienić w pliku `option.cfg`.
Ich składnię i sposób konfiguracji opisano w rozdziale [Konfiguracja](OPTIONS.md).

<br />

## Automatyczne uruchamianie skryptu

Przed włączeniem harmonogramu należy przygotować ustawienia i listę urządzeń.
W przeciwnym razie automatyczne uruchomienie nie będzie mogło wykonać przetwarzania wsadowego.

Tworzenie osobnego użytkownika do uruchamiania skryptu nie jest obowiązkowe, ale wykonywanie takich operacji jako **root** uważa się za złą praktykę. Poniżej przedstawiono wariant z osobnym użytkownikiem.

Utwórz użytkownika **bsmt** *(możesz wybrać inną nazwę, zastępując **bsmt** w przykładach)* i przyznaj mu tylko niezbędne uprawnienia:

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

**Jeżeli skrypt był już uruchamiany jako root**

*(N.B. Jeżeli wcześniej skrypt był uruchamiany jako **root**, utworzone przez niego katalogi, kopie i dzienniki mogą być niedostępne dla użytkownika **bsmt**. Przed włączeniem harmonogramu przekaż mu istniejące miejsce przechowywania.)*

Ten przykład używa lokalnego katalogu `/opt/mikrotik-backup/backups`.
Poniższe polecenie zmienia właściciela i grupę katalogu oraz całej jego zawartości:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(N.B. Podaj katalog kopii zapasowych tego skryptu, a nie katalog współdzielony zawierający dane innych programów. Jeżeli miejsce przechowywania lub główny dziennik znajduje się gdzie indziej, dostęp do każdego z nich trzeba skonfigurować oddzielnie, z uwzględnieniem uprawnień i parametrów danego zasobu, według powyższego wzoru.)*

Przykład otwarcia Configuration Editor jako użytkownik **bsmt** po przyznaniu mu praw do katalogu i plików skryptu:
*(N.B. Polecenie wykonuje root albo użytkownik uprawniony do takiego uruchomienia przez sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Tworzenie harmonogramu uruchomień skryptu**

Poniżej pokazano tworzenie harmonogramu za pomocą systemd, ale można użyć crontab lub dowolnego innego wygodnego rozwiązania.

Utworzymy usługę uruchamiającą skrypt jako nasz użytkownik oraz timer wywołujący ją zgodnie z harmonogramem.
*(W przykładzie wybrano codzienne uruchomienie o pierwszej w nocy, ale harmonogram zależy wyłącznie od Ciebie.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=Kopia zapasowa MikroTik
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
Description=Codzienna kopia zapasowa MikroTik

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

*`Persistent=false` nie włącza uruchomienia nadrabiającego po okresie, gdy timer był wyłączony.
`Restart=no` nie konfiguruje automatycznych restartów usługi po błędzie.*
