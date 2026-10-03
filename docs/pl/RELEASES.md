# Wydania

[Spis treści](../README_PL.md)

## Wersja 2.3.1

**Wydanie konserwacyjne i hotfix po opublikowanej wersji 2.3.0.**

Architektura jednoplikowa i minimalna wersja GNU Bash 4.4 pozostają bez zmian. `UseIncremental` jest teraz kanonicznym ustawieniem logicznym: `false` pomija porównanie po utworzeniu kopii oraz etap przyrostowego przechowywania i zachowuje każdy nowy, pomyślnie zweryfikowany artefakt. To ustawienie nie ma osobnej opcji CLI.

Poprawiono kolejność kalendarzową archiwizacji miesięcznej i wzmocniono obsługę metadanych właściwego magazynu sieciowego, zachowując rygorystyczne kontrole metadanych lokalnego systemu plików. Edytor konfiguracji i BackUP Master korzystają teraz z zaakceptowanego widoku w niższych terminalach, dzięki czemu wszystkie wiersze formularza nie muszą mieścić się na ekranie jednocześnie.

Język rosyjski i angielski nadal są wbudowane. Wersja 2.3.1 dostarcza zewnętrzne tłumaczenia runtime na język niemiecki, hiszpański, łotewski, polski i ukraiński (`de`, `es`, `lv`, `pl`, `uk`) oraz `en.lang` jako kompletny kanoniczny szablon tłumaczenia z 245 kluczami. Dokumentacja użytkownika jest dostępna w 11 językach.

Powiadomienia nadal nie są zaimplementowane i pozostają poza zakresem tego wydania.

<br />

Instrukcje pobierania plików, weryfikowania sum kontrolnych i przygotowania skryptu do pracy zawiera [INSTALL.md](INSTALL.md).
