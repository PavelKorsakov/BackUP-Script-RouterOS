# Lokalizacja

[Spis treści](../README_PL.md)

## Język interfejsu i dzienników

Język rosyjski (`ru`) i angielski (`en`) są wbudowane w skrypt. Nie wymagają osobnych plików tłumaczenia. W wersji 2.3.1 dostarczane są zewnętrzne tłumaczenia interfejsu i dzienników: `de.lang`, `es.lang`, `lv.lang`, `pl.lang` i `uk.lang`.

Język dokumentacji i dostępność zewnętrznego tłumaczenia runtime są od siebie niezależne. Dlatego dokumentacja może być dostępna w języku, dla którego dystrybucja nie zawiera odpowiedniego pliku `.lang`.

Wybrany język jest używany w menu, pomocy, komunikatach skryptu i wpisach dziennika. Nie ma osobnego ustawienia języka dzienników.

<br />

## Wybór języka

Za wybór odpowiada parametr `Language` w pliku `option.cfg`. Jego wartość domyślna to `auto`:

| Wartość | Używany język |
|---|---|
| `auto` | Język określany na podstawie locale systemu operacyjnego |
| `ru` | Wbudowany rosyjski |
| `en` | Wbudowany angielski |
| Inny dwuliterowy kod, na przykład `de` | Tłumaczenie z odpowiedniego pliku, na przykład `de.lang` |

Aby stale używać języka rosyjskiego, podaj w `option.cfg`:

```ini
Language=ru
```

Dla jednego uruchomienia język można wskazać przez CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

Parametr `--language` ma pierwszeństwo przed ustawieniem w pliku parametrów, lecz nie zmienia samego pliku. Kod języka składa się z dwóch liter łacińskich bez rozróżniania wielkości; można też użyć `auto`.

### Wybór automatyczny

Przy `auto` skrypt pobiera pierwszą niepustą wartość z `LC_ALL`, `LC_MESSAGES` i `LANG`, dokładnie w tej kolejności.

Na przykład `ru_RU.UTF-8` wybiera rosyjski, a `de_DE.UTF-8` — niemieckie tłumaczenie z `de.lang`. Dla `C`, `C.UTF-8`, `POSIX` lub gdy nie da się ustalić języka, używany jest angielski.

Jeżeli wybrane tłumaczenie zewnętrzne nie istnieje, komunikaty również pozostają angielskie.

<br />

## Podłączanie tłumaczenia zewnętrznego

Katalog `lang/` zawiera gotowe tłumaczenia zewnętrzne `de.lang`, `es.lang`, `lv.lang`, `pl.lang` i `uk.lang` oraz kanoniczny szablon `en.lang`. Aby użyć tłumaczenia zewnętrznego, skopiuj potrzebny plik do katalogu zawierającego `mikrotik-backup.sh`.

Na przykład dla języka niemieckiego wykonaj w katalogu skryptu:

```bash
cp -- lang/de.lang de.lang
```

Następnie wybierz `de` w ustawieniach albo podaj je podczas uruchomienia:

```bash
mikrotik-backup.sh --language=de --help
```

Nazwa pliku składa się z dwóch liter łacińskich i rozszerzenia `.lang`, na przykład `de.lang`. Musi to być zwykły, czytelny plik, a nie dowiązanie symboliczne.

*(N.B. Katalog `lang/` służy do przechowywania zestawu tłumaczeń. Skrypt nie wczytuje ich stamtąd automatycznie: wymagany plik musi znajdować się obok samego skryptu.)*

`en.lang` zawiera wszystkie 245 kluczy wersji 2.3.1 i jest kanonicznym szablonem do tworzenia tłumaczeń zewnętrznych. Nie zastępuje wbudowanego języka angielskiego ani nie jest używany jako zewnętrzny język runtime. Plik `ru.lang`, jeżeli zostanie utworzony, również nie zastąpi wbudowanego rosyjskiego i będzie ignorowany.

<br />

## Wybór w Configuration Editor

Otwórz edytor poleceniem:

```bash
mikrotik-backup.sh -e
```

Przejdź do wiersza wyboru języka → naciskaj **Enter**, aż pojawi się właściwa wartość → wybierz „Zapisz”.

Warianty przełączają się cyklicznie:

```text
auto → ru → en → znalezione języki zewnętrzne w kolejności alfabetycznej → auto
```

Język formularza zmienia się natychmiast. Przed zapisaniem jest to tylko podgląd, a „Anuluj” przywraca poprzedni język interfejsu. Jeżeli podczas uruchomienia podano `--language`, po zamknięciu edytora parametr ten zaczyna ponownie obowiązywać.

Komentarze w zapisanym `option.cfg` są tworzone w języku wybranym w samym ustawieniu `Language`, a nie za pomocą tymczasowego parametru CLI. Przy `auto` również dla nich używane jest locale systemu operacyjnego.

Więcej informacji o działaniu edytora zawiera [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Tworzenie i edytowanie tłumaczenia

Jeżeli potrzebnego tłumaczenia jeszcze nie ma, można przygotować je samodzielnie. Weź `lang/en.lang` z tej samej wersji skryptu i zapisz kopię jako `<xx>.lang`, gdzie `xx` jest dwuliterowym kodem nowego języka. Szablon wersji 2.3.1 zawiera wszystkie 245 kluczy.

Format jest prosty: każdemu komunikatowi odpowiada osobny wiersz. Na przykład w angielskim szablonie:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Na początku klucza znajduje się `msg_`, dalej nazwa komunikatu (`version`, `menu_title`) i sufiks języka `_en`.

Dla nowego języka zastąp sufiks `_en` sufiksem `_xx` we wszystkich kluczach i przetłumacz tylko wartości w cudzysłowach. Nie zmieniaj nazw komunikatów i zachowaj dokładnie wszystkie placeholders. Aby poprawić istniejące tłumaczenie, wystarczy zmienić odpowiedni tekst po prawej stronie znaku `=`.

Nie trzeba tłumaczyć od razu całego pliku: brakujące komunikaty będą wyświetlane po angielsku. Skrypt nie używa dowolnie dodanych nowych kluczy.

### Zasady zapisu

Zapisz plik w UTF-8. Każda wartość musi być niepusta i ujęta w podwójne cudzysłowy. Nie dodawaj spacji przed kluczem, wokół `=` ani za końcowym cudzysłowem.

Podwójny cudzysłów wewnątrz tekstu zapisz jako `\"`, a ukośnik odwrotny jako `\\`. Inne sekwencje ucieczki, w tym `\n` i `\t`, nie są obsługiwane. Znak `=` wewnątrz cudzysłowów jest dozwolony.

Puste wiersze są pomijane. Format `.lang` nie przewiduje komentarzy, a `#` wewnątrz cudzysłowów jest częścią tekstu. Obsługiwane są zakończenia wierszy Windows (CRLF) i jeden BOM na początku pliku.

Wiersz z błędem jest pomijany, a pozostałe poprawne tłumaczenia nadal są używane. Jeżeli ten sam komunikat podano kilka razy, obowiązuje ostatni poprawny wpis. Znaki sterujące i kody kolorów terminala są w tłumaczeniach zabronione.

*(N.B. Plik lokalizacji jest przetwarzany jako dane tekstowe. Nie odbywa się z niego podstawianie zmiennych ani wykonywanie poleceń powłoki.)*

### Podstawienia w komunikatach

Niektóre wiersze zawierają wartości w nawiasach klamrowych, na przykład:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Podczas działania skrypt zastępuje `{index}` i `{total}` numerem urządzenia i łączną liczbą urządzeń. Tych oznaczeń nie tłumaczy się: zachowaj każde podstawienie z pierwotnego wiersza dokładnie raz. Można zmienić jego położenie w zdaniu.

Jeżeli podstawienia zostały naruszone, zamiast takiego wiersza zostanie użyty komunikat angielski.

Po zapisaniu pliku sprawdź tłumaczenie w pomocy i menu interaktywnym przy wybranym języku. Przyczyny, dla których tłumaczenie mogło się nie wczytać, opisano w rozdziale [Diagnostyka](TROUBLESHOOTING.md#language-problems).
