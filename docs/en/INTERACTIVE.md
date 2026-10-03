# Interactive interface

[Table of contents](../../README.md)

## Main menu

The main menu lets you configure the script, create backups, prepare a device list, or open the built-in help. To open it, run:

```bash
mikrotik-backup.sh -i
```

| Item | What it opens or does |
|---|---|
| `1` | BackUP Master for working with a single device |
| `2` | Batch backup using the device list |
| `3` | Configuration Editor for creating or changing `option.cfg` |
| `4` | CLI option reference |
| `5` | Instructions for using the script |
| `6` | Exit to the console |

Item `2` appears when `devicelist.cfg` contains at least one eligible entry. If the list does not yet exist or contains no suitable devices, the item is hidden. The numbers of the other items do not change.

After a batch backup, the result is displayed and the script returns you to the console.

*(N.B. Running the script without options does not open the main menu. If `option.cfg` is missing or contains no usable settings, the Configuration Editor opens; with prepared settings, the script proceeds to batch backup.)*

<br />

## Controls

Move through the items with the **Up** and **Down** arrow keys, and select an item with **Enter**. If an action has a number beside it, you can also choose it with the corresponding number key.

In the editor and the master, a description of the selected field appears above the list. If all rows do not fit in the terminal window, the list scrolls as you move with the arrow keys. The heading and description remain visible, and the selected row stays within the window.

Save, execute, and exit actions are located at the end of the same list. Dimmed rows are unavailable under the selected settings and are skipped during navigation.

A terminal and the `stty` utility are required. Both standard input and standard output must be connected to a terminal. The main screens require a width of at least 46 columns; the built-in instructions require 80. If the window is too small, the script reports error `31`; enlarge the window and run it again.

<br />

## Configuration Editor

Open the editor through item `3` in the main menu or directly with:

```bash
mikrotik-backup.sh -e
```

If `option.cfg` is already prepared, the form is populated with your settings. If the file does not yet exist, default values are used.

The editor lets you choose the language, the source of the device list, backup settings, storage, monthly archiving, and logging. The settings and their accepted values are described in [OPTIONS.md](OPTIONS.md).

### Changing settings

Change Yes/No switches, the backup type, the export format, and the log level by pressing **Enter** on the corresponding row. Selecting a path or the monthly-archiving day opens a value-entry prompt.

The “Use incremental backups” field (`UseIncremental`) comes immediately after the backup type. “Yes” enables comparison; “No” keeps every new valid backup without comparing it with the previous one.

For monthly archiving, enter `false` to disable it or a number from `1` through `28`. The form displays the disabled state as “No” and an enabled state as the selected day of the month.

Fields that do not apply to the chosen mode are dimmed. For example, when only `.rsc` is selected, binary-backup encryption and the cleanup operations that precede it are unavailable; when only `.backup` is selected, text-export settings are unavailable. Switching modes resets inapplicable settings to their defaults.

The encryption password is entered and displayed as asterisks.

### Saving and canceling

Choose the required settings → move to “Save” → press **Enter**. The selected settings are used to create or overwrite `option.cfg`.

Until you save, changes exist only in memory. “Cancel” leaves the existing file unchanged. If you have changed anything, the editor asks you to confirm that you want to discard those changes.

An editor opened from the main menu returns there. When you run the editor separately with `-e`, closing it returns you to the console.

*(N.B. `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login`, and `Password` are not shown in the form. Their settings and preservation rules are covered in [OPTIONS.md](OPTIONS.md).)*

### Choosing a language

On the language row, every press of **Enter** selects the next option:

```text
auto → ru → en → detected external languages in alphabetical order → auto
```

The form language changes immediately so that you can preview it. “Save” writes the selected language to `option.cfg`; canceling restores the previous interface language. If `--language` was explicitly given at startup, that option takes effect again after you leave the editor.

Connecting external translations is described in [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master lets you fill in the settings for one device, create its backups, save the device to the list, or prepare a command to run from the console.

Choose item `1` in the main menu or run:

```bash
mikrotik-backup.sh -b
```

Unlike the Configuration Editor, the master does not populate its ordinary fields from `option.cfg`. Their values come from built-in defaults and options explicitly passed through the CLI. `UseIncremental` is the exception: its value comes from the options file, or defaults to `true` when that setting is absent.

Existing entries from `devicelist.cfg` are not loaded into the form either. You fill in the name, address, login, and password for the device you have chosen.

### Master fields

The fields appear in the following order. These are their names in the English interface:

| Field | Purpose |
|---|---|
| Device name | Name used in the device list and for backups when RouterOS Identity retrieval is disabled |
| IP address | Device IP address or DNS name |
| User | RouterOS device user |
| Password | RouterOS device password |
| SSH port | Connection port; `22` by default |
| Backup type | `.rsc` configuration, binary `.backup`, or both formats |
| Use incremental backups | Compare a new backup with the previous one, or keep it without comparison |
| Export format | `compact`, `terse`, or `verbose` |
| Sensitive data | Include sensitive values in the text export |
| Encryption password | Encrypt the binary backup; an empty value disables encryption |
| Clear DNS cache | Clear the DNS cache before creating a binary backup |
| Clear console history | Clear the console history before creating a binary backup |
| Backup directory | Directory in which files are saved |
| This is a network directory | `UseNetFolder` value; mount verification applies in batch mode |
| Use RouterOS Identity | Retrieve the name from the device instead of using the name entered in the form |

Switches, the backup type, and the export format are changed with **Enter**; other values are entered in their fields. Both passwords are masked with asterisks.

**Please note!!!**
Sensitive data in the text export, DNS-cache cleanup, and console-history cleanup before a binary backup are enabled by default. Choose the settings you need before executing the backup.

The master has no fields for `MonthlyArchive`, `LogLevel`, or `MainLogPath`. Monthly archiving is disabled when a backup is executed through the master, while logging settings come from `option.cfg` together with any CLI options passed for the run.

### 1. Execute backup

Fill in the address, login, and password; check the port and backup settings → choose “1. Execute backup.”

When RouterOS Identity retrieval is enabled, the backup name is taken from the device. When it is disabled, you must fill in the “Device name” field.

A single-device backup begins. When it finishes, the result and its code are displayed, and the script returns you to the console. It does not return to the master form, whether the backup succeeds or fails.

File locations and retention rules are described in [BACKUPS.md](BACKUPS.md); progress messages are covered in [LOGGING.md](LOGGING.md).

### 2. Save device to devicelist.cfg

The device name, address, login, password, and SSH port are required for saving. Until all required fields are filled in, the corresponding action remains unavailable.

The master creates the file, adds a new entry, or updates an existing entry with the same name. If entries conflict or saving fails, the previous list remains unchanged. The form stays open after saving.

**Only the device data is saved to `devicelist.cfg`.** Backup settings from the form are not written to `option.cfg`, and this action does not start a backup.

*(N.B. Port `22` is saved as an empty field. In a later batch run, such an entry uses `SshPort` from the script settings. A nonstandard port is written explicitly.)*

The list format and update rules are described in [DEVICES.md](DEVICES.md).

### 3. Copy console command

The master builds a launch command from the completed form and sends it to the clipboard. No backup starts, and the master finishes by returning to the console.

This feature requires GNU `base64` with `--wrap=0` support and a terminal that supports OSC 52. If you work through a terminal multiplexer, it too must pass the command through. If clipboard transfer is unsupported, the command is not printed in clear text on the screen.

Parameters that match built-in values may be omitted from the command. When you later run it, settings from `option.cfg` still apply, so the result can differ from executing the backup directly through the master.

The `UseIncremental` setting is not included in the command: it has no dedicated CLI option. When the copied command is run, the value comes from `option.cfg` or from the defaults.

*(N.B. The command placed on the clipboard contains passwords. Keep this in mind when using clipboard history and when pasting the command into a shell. For details, see [SECURITY.md](SECURITY.md).)*

### 0. Return to Main Menu

The result depends on how you opened the master:

| How it was opened | Where you return |
|---|---|
| From the main menu with `-i` | Main menu |
| As a separate run with `-b` | Console |

Unsaved form values are discarded. An entry already saved in `devicelist.cfg` remains there.

<br />

## Help and instructions

Item `4` in the main menu opens the command-line option reference, while item `5` opens brief instructions for using the script.

If the text does not fit vertically, it is split into pages. Move through them with **PageUp / PageDown**; the current page number is shown on screen.

Item `0` returns to the main menu, and item `6` exits the script. You can select these actions with the arrow keys and **Enter**, or with the corresponding number key.

The same CLI help is available directly from the console:

```bash
mikrotik-backup.sh -h
```
