# Localization

[Table of contents](../../README.md)

## Language of the interface and logs

Russian (`ru`) and English (`en`) are built into the script. No separate translation files are required for them. Version 2.3.1 ships ready-made external runtime translations in `de.lang`, `es.lang`, `lv.lang`, `pl.lang`, and `uk.lang`.

The languages in which the documentation is available are independent from the runtime UI and log translations supplied as `.lang` files. A translated documentation tree does not by itself mean that a matching runtime translation is included.

The selected language is used in menus, help, script messages, and log entries. There is no separate language setting for logs.

<br />

## Choosing a language

The `Language` setting in `option.cfg` controls the selection. Its default value is `auto`:

| Value | Language used |
|---|---|
| `auto` | Determined from the operating-system locale |
| `ru` | Built-in Russian |
| `en` | Built-in English |
| Another two-letter code, such as `de` | Translation from the corresponding file, such as `de.lang` |

To select Russian permanently, set this in `option.cfg`:

```ini
Language=ru
```

For a single run, you can select the language through the CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

The `--language` option takes precedence over the setting in the options file but does not change the file itself. Use either `auto` or a two-letter language code; letter case does not matter.

### Automatic selection

With `auto`, the script takes the first nonempty value from `LC_ALL`, `LC_MESSAGES`, and `LANG`, in that order.

For example, `ru_RU.UTF-8` selects Russian, while `de_DE.UTF-8` selects the German translation from `de.lang`. English is used for `C`, `C.UTF-8`, `POSIX`, or when the language cannot be determined.

Messages also remain in English if the selected external translation is unavailable.

<br />

## Connecting an external translation

The `lang/` directory contains ready-made external runtime translations `de.lang`, `es.lang`, `lv.lang`, `pl.lang`, and `uk.lang`, plus `en.lang`, the canonical translation template. Copy the ready-made translation you need from there into the directory containing `mikrotik-backup.sh`.

For example, run this in the script directory to install German:

```bash
cp -- lang/de.lang de.lang
```

Then select `de` in the settings or specify it when starting the script:

```bash
mikrotik-backup.sh --language=de --help
```

The filename consists of two Latin letters and the `.lang` extension—for example, `de.lang`. It must be an ordinary readable file, not a symbolic link.

*(N.B. The `lang/` directory stores the collection of translations. The script does not load them automatically from that directory: the required file must be placed next to the script itself.)*

The `en.lang` template contains all 245 localization keys for version 2.3.1. It does not replace built-in English and is not selected as an external runtime language. Likewise, a file named `ru.lang` does not replace built-in Russian and is ignored for language selection.

<br />

## Choosing a language in the Configuration Editor

Open the editor with:

```bash
mikrotik-backup.sh -e
```

Move to the language row → press **Enter** until the required value appears → choose “Save.”

The options cycle in this order:

```text
auto → ru → en → detected external languages in alphabetical order → auto
```

The form language changes immediately. Until you save, this is only a preview; “Cancel” restores the previous interface language. If `--language` was specified at startup, that CLI option takes effect again after you leave the editor.

Comments in the saved `option.cfg` use the language selected by the `Language` setting itself, not a temporary CLI option. With `auto`, the operating-system locale is used for these comments as well.

For more about the editor, see [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Creating and editing a translation

If the translation you need does not yet exist, start with `lang/en.lang` from the same script version. The version 2.3.1 template contains all 245 localization keys. Save a copy under the required two-letter code, for example `xx.lang`.

The format is simple: every message has its own line. The canonical English template contains, for example:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Each key begins with `msg_`, followed by the message name (`version`, `menu_title`) and the language suffix `_en`.

For a new language, replace the `_en` suffix in every key with the target suffix, such as `_xx`, and translate only the quoted values. Do not change or translate the message names. Preserve every placeholder exactly. To correct an existing translation, it is enough to change the required value to the right of `=`.

You do not have to translate the whole file at once: missing messages are shown in English. The script does not use arbitrary new keys.

### File-format rules

Save the file as UTF-8. Enclose every value in double quotation marks and make it nonempty. Do not add spaces before a key, around `=`, or after the closing quotation mark.

Use `\"` for a double quotation mark within the text and `\\` for a backslash. Other escapes, including `\n` and `\t`, are unsupported. An `=` character inside quotation marks is allowed.

Blank lines are skipped. The `.lang` format has no comments; a `#` inside quotation marks is part of the text. Windows line endings (CRLF) and one BOM at the beginning of the file are supported.

A malformed line is skipped while other valid translations remain in use. If a message is specified more than once, the last valid entry wins. Control characters and terminal color codes are not allowed in translations.

*(N.B. A localization file is treated as text data. Variables are not expanded and shell commands are not executed from it.)*

### Placeholders in messages

Some strings contain values in braces, for example:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

At runtime, the script replaces `{index}` and `{total}` with the device number and the total number of devices. Do not translate these markers: preserve every placeholder from the source string exactly once. You may change its position within the sentence.

If the placeholders are invalid, the English message is used instead of that string.

After saving the file, check the translation in help and in the interactive menu with that language selected. Reasons why a translation may not load are covered under [Troubleshooting](TROUBLESHOOTING.md#language-problems).
