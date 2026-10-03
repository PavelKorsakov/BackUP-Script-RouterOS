# Kopie zapasowe i archiwa

[Spis treści](../README_PL.md)

## Formaty kopii zapasowych

Skrypt może zapisać konfigurację urządzenia jako tekst, utworzyć binarną kopię zapasową albo pobrać oba formaty.
Format wybiera parametr `backup_type` w pliku `option.cfg`:

| Wartość | Zapisywana zawartość |
|---|---|
| `configuration` | Konfiguracja RouterOS w pliku `.rsc` |
| `binary` | Binarna kopia zapasowa w pliku `.backup` |
| `both` | Oba formaty: najpierw `.rsc`, potem `.backup` |

Domyślnie wybrane jest `both`. Wartość można zmienić w pliku parametrów, Configuration Editor, BackUP Master albo przez `--backup-type`.

### Tekstowa konfiguracja .rsc

Format eksportu określa parametr `export_format`. Dozwolone wartości to `compact`, `terse` i `verbose`; domyślna wartość to `compact`.

Parametr `show_sensitive` określa, czy eksport ma zawierać dane poufne, w tym hasła. Domyślnie jest włączony.
Aby wyłączyć tę funkcję, dodaj do `option.cfg`:

```ini
show_sensitive=false
```

### Binarna kopia .backup

Binarną kopię zapasową można zaszyfrować. Podaj wymagane hasło w parametrze `encrypt`:

```ini
encrypt=MySuperPassword
```

Przy pustym `encrypt=` plik jest zapisywany bez szyfrowania. Jest to zachowanie domyślne.

*(N.B. Szyfrowanie AES-SHA256 dotyczy wyłącznie `.backup`. Nie szyfruje konfiguracji tekstowej, dzienników ani archiwów ZIP.)*

Przed utworzeniem kopii binarnej domyślnie czyszczona jest pamięć podręczna DNS i historia konsoli RouterOS. Jeżeli te działania nie są potrzebne, wyłącz odpowiednie parametry:

```ini
clear_dns_cache=false
clear_console_history=false
```

Gdy pobierana jest wyłącznie konfiguracja tekstowa, czyszczenie nie jest wykonywane.

<br />

## Nazwy i rozmieszczenie plików

Domyślnie kopie są zapisywane w katalogu `backups` obok skryptu. Inny katalog można wskazać parametrem `BackupRoot` w pliku parametrów.

W trybie pojedynczego urządzenia pliki trafiają bezpośrednio do tego katalogu:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

W trybie wsadowym każde urządzenie ma własny podkatalog:

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

Nazwa kopii zawiera nazwę urządzenia oraz datę i godzinę według zegara hosta, na którym działa skrypt. Oba formaty pochodzące z jednej operacji mają ten sam znacznik czasu.
Reguły tworzenia nazwy urządzenia opisano w [DEVICES.md](DEVICES.md#device-names).

**Uwaga!!!**
Jeżeli kopie tego samego urządzenia zostaną utworzone dwa razy w ciągu jednej minuty w tym samym katalogu, ich nazwy będą identyczne. Plik o takiej nazwie zostanie zastąpiony; osobna wersja z drugiego uruchomienia nie powstanie.

Do przechowywania można użyć katalogu sieciowego. W trybie wsadowym jego sprawdzanie włącza `UseNetFolder=true`. Przygotowanie katalogu opisano w [INSTALL.md](INSTALL.md), a ustawienia ścieżek — w [OPTIONS.md](OPTIONS.md#network-storage).

Rozmieszczenie i zawartość dzienników szczegółowo opisano w [LOGGING.md](LOGGING.md).

<br />

## Przechowywanie przyrostowe

Ta funkcja pozwala nie zapisywać kolejnych kopii, gdy nie wykryto zmian. Steruje nią parametr `UseIncremental`:

| Wartość | Sposób zapisywania kopii |
|---|---|
| `true` (domyślnie) | Jeżeli nowa kopia zostanie uznana za powtórzenie, jest usuwana, a poprzednia pozostaje |
| `false` | Każda nowa prawidłowa kopia jest zachowywana bez porównania z poprzednią |

Gdy wykryto zmiany albo nie istnieje poprzednia kopia, nowy plik zostaje zachowany. Jeżeli porównanie się nie powiedzie, plik również pozostaje, ale skrypt zgłasza ostrzeżenie.

**I tu pojawia się pewien niuans!!!**
Poszczególne formaty są porównywane w różny sposób:

| Format | Porównywana zawartość |
|---|---|
| `.rsc` | Zawartość plików. Data i godzina w standardowym nagłówku RouterOS są pomijane |
| `.backup` | Wyłącznie rozmiar plików w bajtach |

Dwa pliki binarne o identycznym rozmiarze zostaną więc uznane za powtórzenia, nawet jeśli różnią się zawartością. Uwzględnij to przy wyborze polityki przechowywania.

Do porównania używana jest najnowsza ze starszych kopii tego samego urządzenia i formatu w katalogu urządzenia. Kopie już spakowane do ZIP nie uczestniczą w porównaniu.

Zapisywane są zwykłe pliki `.rsc` i `.backup`, a nie osobne pliki zmian. Wyłączenie `UseIncremental` nie wyłącza pobierania i weryfikowania kopii, rejestrowania zdarzeń ani archiwizacji miesięcznej.

<br />

<a id="monthly-archive"></a>
## Archiwizacja miesięczna

Domyślnie ta funkcja jest wyłączona. Parametr `MonthlyArchive` w pliku `option.cfg` wybiera dzień archiwizacji zgromadzonych kopii i dzienników:

| Wartość | Sposób działania |
|---|---|
| `false` (domyślnie) | Archiwizacja wyłączona |
| `true` lub `1` | Archiwizacja odbywa się pierwszego dnia miesiąca |
| Od `2` do `28` | Archiwizacja odbywa się we wskazanym dniu miesiąca |

Godzina uruchomienia w wybranym dniu nie ma znaczenia. Harmonogram konfiguruje się osobno zgodnie z opisem w [INSTALL.md](INSTALL.md#automatyczne-uruchamianie-skryptu).

### Co trafia do archiwum

W trybie wsadowym kolejność pracy w tym dniu ulega zmianie: skrypt najpierw zbiera zgromadzone pliki urządzenia do ZIP, a dopiero potem tworzy nowe kopie. Nowe kopie z bieżącego uruchomienia pozostają poza archiwum.

Do archiwum trafiają zwykłe pliki znajdujące się bezpośrednio w katalogu urządzenia, w tym pełny dziennik zbiorczy. Nie są to tylko `.rsc` i `.backup`: zarchiwizowane mogą zostać również inne zwykłe pliki umieszczone w tym katalogu.

Podkatalogi, dowiązania symboliczne, obiekty pomocnicze bieżącego uruchomienia oraz pliki ZIP utworzone wcześniej przez skrypt nie są pakowane ponownie. **Główny dziennik `main.log` nie jest archiwizowany.**

Po zweryfikowaniu i pomyślnym zapisaniu gotowego ZIP dodane do niego pliki źródłowe są usuwane z katalogu urządzenia. Jeżeli nie ma czego archiwizować, pusty ZIP nie powstaje.

### Nazwa i położenie archiwum

Nazwa ZIP odpowiada poprzedniemu dniowi kalendarzowemu i ma format `DD.MM.YYYY.zip`. Na przykład uruchomienie 1 października 2026 roku utworzy `30.09.2026.zip`, a uruchomienie 15 października — `14.10.2026.zip`.

| Tryb | Położenie archiwum |
|---|---|
| Wsadowy | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Jedno urządzenie przez CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

Ponowne uruchomienie tego samego dnia aktualizuje archiwum o tej samej nazwie.

### Tryb pojedynczego urządzenia i BackUP Master

W uruchomieniu CLI dla jednego urządzenia kolejność jest odwrotna: najpierw powstaje kopia zapasowa, a potem odbywa się archiwizacja. Dlatego nowa kopia z bieżącego uruchomienia również może trafić do ZIP.

W tym trybie archiwizowane są pliki `.rsc`, `.backup` i `.log` znajdujące się bezpośrednio w `BackupRoot`, z wyjątkiem `main.log`. Jeżeli wyniki uruchomień dla kilku urządzeń są zapisywane w jednym katalogu, ich pliki trafią do wspólnego archiwum.

Podczas pracy przez BackUP Master archiwizacja miesięczna nie jest wykonywana.

### Gdy uruchomienie zostało pominięte

Jeżeli skrypt nie został uruchomiony w wybranym dniu, pominięta archiwizacja nie jest nadrabiana. Następna próba odbędzie się w wyznaczonym dniu następnego miesiąca.

Wszystkie nagromadzone pliki trafią do jednego kolejnego archiwum, nawet jeśli pochodzą z dwóch, trzech lub większej liczby miesięcy. Nie są tworzone osobne pliki ZIP dla pominiętych miesięcy.

### Gdy archiwizacja się nie powiedzie

Pliki źródłowe nie są usuwane, dopóki zweryfikowany ZIP nie zostanie zapisany. Uszkodzone istniejące archiwum również nie jest zastępowane nowym.

Jeżeli ZIP został już zapisany, ale nie udało się usunąć części plików źródłowych, gotowe archiwum i nieusunięte pliki pozostają na miejscu. Przyczyny błędu szukaj w dzienniku.

*(N.B. Archiwum jest tworzone w lokalnym katalogu `/tmp`, nawet gdy same kopie znajdują się na NAS. Wolne miejsce jest więc potrzebne nie tylko w docelowym magazynie.)*

<br />

## Gdy tworzenie kopii zapasowej się nie powiedzie

Po nieudanej próbie pobrania pliku skrypt ponowi ją jeszcze raz po 2 sekundach. Próby dla `.rsc` i `.backup` są wykonywane oddzielnie.

Zwykły błąd pobierania jednego formatu nie anuluje próby pobrania drugiego. Jeżeli pojedyncze urządzenie jest niedostępne, skrypt kontynuuje pracę z pozostałymi. Jeżeli wspólne miejsce przechowywania zostanie utracone, przetwarzanie wsadowe jest zatrzymywane.

Komunikaty o błędach i kody zakończenia opisano w [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Przechowywanie i odtwarzanie

Stare pliki ZIP nie są usuwane według wieku ani liczby. Okres przechowywania i zewnętrzną rotację określasz samodzielnie.

Skrypt tworzy kopie zapasowe, ale nie przywraca RouterOS. Odtwarzanie należy sprawdzić oddzielnie na odpowiednim urządzeniu.

*(N.B. Kopie zapasowe i archiwa mogą zawierać hasła oraz inne dane poufne. Ogranicz dostęp do miejsca przechowywania zgodnie z opisem w [SECURITY.md](SECURITY.md).)*
