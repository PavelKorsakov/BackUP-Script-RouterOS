# Rejestrowanie zdarzeń

[Spis treści](../README_PL.md)

## Dziennik główny i dzienniki urządzeń

Przebieg pracy skryptu jest zapisywany w głównym dzienniku `main.log`, a szczegóły pracy z każdym urządzeniem — w osobnym dzienniku urządzenia.

W `main.log` można sprawdzić przygotowanie listy urządzeń, przebieg przetwarzania wsadowego oraz wyniki odpytywania urządzeń. Trafiają tam również błędy powstałe przed wskazaniem konkretnego urządzenia.

Dziennik urządzenia zawiera informacje o pobieraniu `.rsc` i `.backup`, ponawianiu prób, porównywaniu kopii oraz archiwizacji. Aby ustalić, co wydarzyło się podczas tworzenia kopii konkretnego urządzenia, należy więc sprawdzić właśnie jego dziennik. Szczegóły te nie są powielane w `main.log`.

<br />

## Miejsce przechowywania dzienników

Domyślnie dziennik główny znajduje się w katalogu `backups` obok skryptu. Dzienniki urządzeń są zapisywane obok ich kopii zapasowych:

| Dziennik | Położenie |
|---|---|
| Dziennik główny | `<BackupRoot>/main.log` |
| Urządzenie w trybie wsadowym | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Urządzenie w trybie pojedynczym | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

W trybie wsadowym nowe wpisy są dopisywane do tego samego dziennika urządzenia. W trybie pojedynczego urządzenia nazwa dziennika zawiera tę samą datę i godzinę co nazwy kopii z danego uruchomienia.

### Osobny katalog dla main.log

Aby przechowywać dziennik główny oddzielnie od kopii, podaj odpowiedni katalog w parametrze `MainLogPath` pliku `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

Dziennik znajdzie się wtedy w `/var/log/mikrotik-backup/main.log`. Dzienniki urządzeń pozostaną na swoich miejscach.

Pusta wartość `MainLogPath=` oznacza bieżący `BackupRoot`. Ścieżka względna, na przykład `MainLogPath=logs`, wskazuje katalog obok skryptu, a nie wewnątrz miejsca przechowywania kopii.

*(N.B. W `MainLogPath` podaje się katalog, a nie pełną nazwę pliku. Katalog musi już istnieć i być dostępny do zapisu dla użytkownika uruchamiającego skrypt.)*

<br />

## Szczegółowość rejestrowania

Ilością informacji na wyjściu i w dziennikach steruje parametr `LogLevel`. Wartość domyślna to `2`:

| Wartość | Przebieg pracy w terminalu | Wpisy w plikach dzienników |
|---|---|---|
| `0` | Tylko błędy | Tylko błędy |
| `1` | Główne etapy i ich wyniki | Dziennik skrócony |
| `2` | Główne etapy i ich wyniki | Dziennik szczegółowy |
| `3` | Główne etapy i bieżące operacje składowe | Dziennik szczegółowy |

**Błędy są zapisywane na każdym poziomie.** Dziennik skrócony zawiera główne etapy i ich wyniki; dziennik szczegółowy zapisuje dodatkowo operacje wykonywane w obrębie tych etapów.

Poziom można zmienić w `option.cfg` albo za pomocą Configuration Editor:

```ini
LogLevel=3
```

Dla jednego uruchomienia skonfigurowanego już przetwarzania wsadowego poziom można podać przez CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Wartość w pliku parametrów nie jest przy tym zmieniana. Analogicznie położenie dziennika głównego dla bieżącego uruchomienia można podać przez `--main-log-path`.

BackUP Master nie ma osobnych pól dla `LogLevel` i `MainLogPath`. Podczas wykonania używane są ustawienia rejestrowania bieżącego uruchomienia.

<br />

## Wygląd wpisów

Dzienniki są zwykłymi plikami tekstowymi. Każdy wpis zawiera datę i godzinę według zegara hosta, na którym działa skrypt. Kolory i wskaźniki oczekiwania nie są zapisywane w pliku.

Przykładowe wpisy w `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Wsadowe przetwarzanie urządzeń
[2026-10-01 01:00:15] [PID:12345] [OK] Wsadowe przetwarzanie urządzeń
```

W dzienniku głównym podawany jest również PID procesu. Pozwala on odróżnić wpisy kilku egzemplarzy skryptu działających równocześnie.

Do dziennika urządzenia PID nie jest dodawany. Przykładowy fragment dziennika szczegółowego:

```text
[2026-10-01 01:00:05] Pobieranie binarnej kopii zapasowej
[2026-10-01 01:00:06] [1] Czyszczenie pamięci podręcznej DNS
[2026-10-01 01:00:07] [2] Czyszczenie historii konsoli
[2026-10-01 01:00:12] [OK] Pobieranie binarnej kopii zapasowej
```

`[OK]` oznacza pomyślne zakończenie operacji. Błąd jest oznaczony `[ER]` i zawiera kod, na przykład `[53]`. Numerowanie operacji składowych `[1]`, `[2]` itd. za każdym razem zaczyna się od początku w obrębie głównego etapu.

Jeżeli ponowiona próba po nieudanej zakończy się pomyślnie, w dzienniku pozostaną zarówno wcześniejszy błąd, jak i późniejszy pomyślny wynik.

Język wpisów jest zgodny z językiem interfejsu i zależy od ustawienia `Language`. Więcej informacji o wyborze języka i tłumaczeniach zawiera [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Wyjście w terminalu

Podczas ręcznego uruchomienia przebieg pracy jest widoczny na ekranie. W czasie wykonywania operacji widnieje obok niej wskaźnik oczekiwania. Po zakończeniu zmienia się on w zielony `[OK]` albo czerwony `[ER]` z kodem błędu.

Na poziomach `1` i `2` wyświetlane są główne etapy. Na poziomie `3` pod bieżącym etapem widać również zmieniającą się operację składową. W trybie wsadowym dodatkowo wyświetlane jest aktualnie przetwarzane urządzenie.

*(N.B. Podczas uruchomienia bez terminala, na przykład z harmonogramu lub z przekierowanym wyjściem, nie ma wyjścia ekranowego. Dzienniki w plikach nadal działają zgodnie z wybranym poziomem.)*

<br />

## Gromadzenie i archiwizacja dzienników

Plik dziennika powstaje przy pierwszym wpisie. Przy `LogLevel=0` i braku błędów nowe dzienniki nie są tworzone, a do istniejących nie są dodawane wpisy.

Dziennik główny i wsadowe dzienniki urządzeń są przy każdym uruchomieniu uzupełniane, a nie nadpisywane. Nowe przebiegi oddziela pusty wiersz.

Plik `main.log` nie jest archiwizowany ani usuwany na podstawie wieku. Jego rotację należy skonfigurować samodzielnie.

Jeżeli włączono archiwizację miesięczną, pełny zgromadzony wsadowy dziennik urządzenia trafia do ZIP wraz z jego kopiami zapasowymi. Po pomyślnym zapisaniu archiwum spakowany dziennik jest usuwany z katalogu urządzenia, a wynik archiwizacji i dalsza praca są zapisywane już w nowym pliku dziennika.

Przy ponownej aktualizacji tego samego ZIP historia wewnątrz archiwum jest uzupełniana, a nie zastępowana nowym dziennikiem. Jeżeli archiwum nie uda się zapisać, poprzedni dziennik pozostaje na miejscu, a błąd jest zapisywany właśnie w nim.

Dzienniki uruchomień CLI dla jednego urządzenia są archiwizowane wraz z kopiami ze wspólnego katalogu. Kolejność archiwizacji w obu trybach opisano w [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Gdy nie udało się zapisać dziennika

Niewystarczające uprawnienia, niedostępny katalog lub inny błąd zapisu dziennika nie zatrzymują samego tworzenia kopii. Skrypt rejestruje ostrzeżenie i w miarę możliwości kontynuuje pracę.

Niedostępność `main.log` jest zgłaszana raz na uruchomienie, a niedostępność dziennika urządzenia — raz podczas przetwarzania tego urządzenia. Jeżeli dziennik główny jest dostępny, zapisuje się w nim błąd zapisu dziennika urządzenia.

Przy braku innych błędów takie uruchomienie kończy się kodem `1`, czyli ostrzeżeniem. Ostrzeżenie nie zastępuje błędu samego tworzenia kopii.

Kody zakończenia i wyszukiwanie przyczyn błędów opisano w [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(N.B. Szczegółowy poziom `3` nie zapisuje haseł ani pełnych poleceń połączenia. O ochronie danych uwierzytelniających i plików skryptu przeczytasz w [SECURITY.md](SECURITY.md).)*
