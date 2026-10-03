# Troubleshooting

[Table of contents](../../README.md)

## Where to start

If backup did not start or ended with an error, check the logs first. `main.log` contains the overall stages of the run, while the details of backing up a particular device are written to its separate device log.

Look for entries marked `[ER]` and an error code. The codes are explained [below](#result-codes), and log locations are described in [LOGGING.md](LOGGING.md).

Use these commands to display the installed script version and option reference:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

To repeat an already configured batch run with detailed output:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

The second command displays the result of the completed run. It does not change the logging level in `option.cfg`.

<br />

## The script does not start a backup

### The editor opened instead of a backup

When the script is started without options, this means that `option.cfg` is absent from the script directory or contains no usable settings. An empty file, comments alone, or unknown settings do not change the outcome.

Open the Configuration Editor, choose the required settings, save the file, and run the script again:

```bash
mikrotik-backup.sh -e
```

Saving a device through BackUP Master creates `devicelist.cfg`, but it does not replace the preparation of `option.cfg`.

*(N.B. If such a run is started by a scheduler, the editor cannot open and the script exits with code `31`. Settings for an automatic run must be prepared in advance.)*

### Option error, code 12

Check option names, their values, and the combination of actions. Possible causes include an unknown option, an empty value, multiple different actions requested at once, or incomplete credentials for a single-device connection.

A single-device CLI run requires an address, login, and password. Missing credentials are not filled in from `option.cfg`.

Short connection options must use `=`: `-a=`, `-u=`, and `-p=`. Note that `-p` specifies the password; use `--port` for the SSH port.

All accepted options and examples are listed in [CLI.md](CLI.md).

### option.cfg cannot be read, code 21

Make sure `option.cfg` is an ordinary file readable by the user running the script. A readable symbolic link to such a file is also allowed.

A missing file and an unreadable file are different situations. If the file exists but cannot be read, the script does not continue with default settings.

### Missing dependency, code 30

Check for the main utilities with:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Batch operation with `UseNetFolder=true` also requires `findmnt`. On the day of monthly archiving, `zip`, `unzip`, and GNU `mv` are required. Copying a console command from BackUP Master requires GNU `base64` with `--wrap=0` support.

**Merely having a utility installed is not enough.** The installed OpenSSH must support the options in use and `scp -O`; GNU `timeout` must support `--signal` and `--kill-after`.

The complete dependency list and installation commands are in [INSTALL.md](INSTALL.md#dependencies).

### The menu does not open, code 31

The menu, editor, and master require a terminal and a working `stty` utility. Do not start them through a pipe or with standard input or output redirected.

If the message says that the terminal is too small, enlarge the window. The main screens need a width of at least 46 columns, while the built-in instructions need 80. Long lists in the editor and master scroll with the arrow keys; the whole form does not need to fit on screen at once.

Interface controls are described in [INTERACTIVE.md](INTERACTIVE.md).

<br />

## The device list does not load

### The devicelist.cfg file, codes 22 and 23

Check the file location and access to it. `devicelist.cfg` must be next to `mikrotik-backup.sh`, regardless of the directory from which you start the script.

Fields are separated by an actual TAB character, not spaces. A device must have a name, address, login, password, and valid SSH port. Shared credentials may come from `option.cfg` when the corresponding entry fields are empty.

An invalid entry is skipped with a warning. If no eligible devices remain, there is nothing to back up and the script exits with a list error.

Also check for duplicate connections and for different devices with the same name. The file format, credential inheritance, and duplicate-handling rules are covered in [DEVICES.md](DEVICES.md).

### Importing from Oxidized, codes 24 and 25

Code `24` means that the `config` or `router.db` file in `OxidizedHome` could not be read. Code `25` concerns their contents: an unsupported schema, invalid data, or no eligible MikroTik devices.

Check the path, access to both files, the `csv` source, delimiter, column map, and the definition of the `routeros` model. Data is read specifically from `<OxidizedHome>/router.db`; the Oxidized `source.csv.file` setting does not change that path.

With `IgnoreOxiAccess=true`, the script may continue with the previous eligible list. The import failure nevertheless remains in the run result. With `false`, the old list is not used for that run.

Import configuration is described in [DEVICES.md](DEVICES.md#importing-from-oxidized).

<br />

## Storage and locking

### Lock is busy, code 32

Check whether another job is already using the same backup directory. For runs by one user, a batch backup conflicts with any other backup using the same `BackupRoot`. Two single-device runs for the same device also cannot run simultaneously in that storage.

Wait for the active job to finish, then run the script again.

**Do not delete lock files to “release” the storage.** They remain after the script finishes; the process itself holds the lock. The presence of a file in `/tmp/mikrotik-backup-${UID}/` does not mean that the lock is busy.

### No access to the directory

Check the `BackupRoot` path, user permissions, free space, and availability of the storage device itself. A relative path is resolved from the script directory. The filesystem root, `/`, cannot be used to store backups.

If the script previously ran as root and now runs as **bsmt**, that user may not have access to the old directories and files. Permission preparation is covered in [INSTALL.md](INSTALL.md#running-the-script-automatically).

Batch operation with `UseNetFolder=true` requires a separate mount. Check it with:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Replace the first path with your own. If both paths belong to the same mount entry, an ordinary directory on the root filesystem does not satisfy `UseNetFolder=true`. The script does not mount storage itself.

Code `64` means that the device directory or its archive failed while shared storage remained available. Processing of other devices may continue. Code `65` means that shared storage was lost or its state became invalid, and stops the rest of the batch.

Network-storage rules are described in [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Errors while working with a device

### SSH and file transfer, codes 40–43

Check the device address, availability of its SSH service, login, password, and port. If no port is specified in `devicelist.cfg`, the value of `SshPort` from the settings is used; it defaults to `22`.

The RouterOS user must have permission for the selected operations: exporting configuration, creating and retrieving backups, deleting temporary files, and performing any enabled cleanup operations.

**And there is a nuance here!!!** A successful connection with your usual SSH command does not mean that the script uses the same settings. It works with a password and does not use the SSH agent, keys, or the normal `~/.ssh/config`. Files are retrieved through `scp -O`.

Code `40` concerns the connection or SSH/SCP transport, `41` authentication, `42` a RouterOS command or its response, and `43` file transfer. Connection settings are explained further in [SECURITY.md](SECURITY.md#connecting-to-routeros).

### Naming error, codes 50 and 52

Code `50` means that the final device name is invalid. Check the selected name source and the contents of parentheses: in the current version, the first completed, nonempty fragment in parentheses is the one used as the name.

After processing, the name must contain between 1 and 32 characters. An overlong name is not truncated. Reserved names such as `CON` and `NUL` are also rejected.

Code `52` means that the final name duplicates another device in the same run. Comparison is case-insensitive: `Router-A` and `router-a` are considered identical.

The name source and processing rules are described in [DEVICES.md](DEVICES.md#device-names).

### Backup validation failed, codes 51 and 53

Code `51` applies to `.rsc`, and code `53` to `.backup`. The retrieved file failed validation—for example, it is empty or its size does not match the file on the device.

Check the stage at which the error occurred, along with free space and permissions on both the host and RouterOS. After a failed attempt, the script tries once more after 2 seconds. Attempts are separate for the two formats, so one file may be retrieved successfully while the other fails.

A warning about failure to delete a temporary RouterOS file after a backup was retrieved successfully does not by itself mean that the local backup is damaged.

<br />

## There is no new backup, but there are no errors either

First check `UseIncremental`. When comparison is enabled, a new backup may be deleted as a duplicate while the previous one remains. For `.rsc`, contents are compared without the date in the standard header; for `.backup`, only file sizes are compared.

With `UseIncremental=false`, a new valid backup is kept without this comparison.

Also bear in mind that two runs for the same device into the same directory within one minute use the same filename. A separate version is not created for the second run.

If monthly archiving ran that day, check the ZIP as well. In single-device CLI mode, the new backup may also be inside it. Full retention rules are provided in [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## The monthly archive did not appear

Check the `MonthlyArchive` value and the run date in the host's local time. `false` disables archiving; `true` or `1` selects the first day, while a number from `2` through `28` selects that day of the month.

On the selected day, the run time does not matter. If that day is missed, a later ordinary run does not catch up. Monthly archiving is not performed through BackUP Master.

If there is nothing to archive, no empty ZIP is created.

### Where to find the ZIP

The archive name corresponds to the previous calendar day. For example, a run on October 1, 2026 creates `30.09.2026.zip`:

| Mode | Location |
|---|---|
| Batch | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Single-device through the CLI | `<BackupRoot>/30.09.2026.zip` |

The `archive/` directory name is lowercase. Another run on the same day updates the same ZIP.

### Archiving ended with an error

For codes `70` and `71`, check the device log, access to the archive directory, free space, and the state of any existing ZIP. Space is required both in storage and in local `/tmp`.

On a local disk, the `archive/` directory must belong to the script user and have mode `0700`. In batch mode with verified network storage and `UseNetFolder=true`, a different owner or permissions assigned by the NAS are not, by themselves, a reason for failure. Storage errors during archiving may also produce code `64` or `65`.

Check an existing archive with the following command, substituting its actual path:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Source files are not removed until a verified ZIP has been saved. If the archive was saved but some source files could not be removed, both the ZIP and the undeleted files remain. A damaged existing archive is not automatically replaced with a new one.

**Do not delete remaining backups or logs until you have checked the archive contents.** The archiving sequence is described in [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## There is no log or on-screen output

With `LogLevel=0` and no errors, no new logs are created. Otherwise, check the selected `BackupRoot`, `MainLogPath`, and write permissions.

An empty `MainLogPath=` leaves `main.log` in `BackupRoot`. If a separate directory is specified, it must already exist and be accessible to the script user. Device logs are not moved by this setting.

After monthly archiving, the device's previous history is in the ZIP. Subsequent work is written to a new log beside the backups.

When the script runs from a scheduler or with its output redirected, the on-screen log with its indicator and colored marks is absent. File logging is not disabled by this.

A log-writing error does not stop the backup itself, but appears in the run result as a warning. See [LOGGING.md](LOGGING.md) for details.

<br />

<a id="language-problems"></a>
## A translation was not applied

Check the selected language and file location. For example, `Language=de` requires a readable ordinary file named `de.lang` next to `mikrotik-backup.sh`, not in the `lang/` directory. A symbolic link is not used as a translation file.

With `Language=auto`, the operating-system environment determines the language. You can select it explicitly for one run, for example when viewing help:

```bash
mikrotik-backup.sh --language=de --help
```

Untranslated messages are displayed in English. Malformed lines in the file are skipped. Files named `ru.lang` and `en.lang` do not replace the built-in translations.

The line format, key names, and rules for loading a translation are described in [LOCALIZATION.md](LOCALIZATION.md).

<br />

## A setting does not take effect

Check the setting name, accepted value, and duplicate entries in `option.cfg`. When a setting is repeated, the last usable value wins. Key names are case-insensitive, but hyphens and underscores are not interchangeable.

A CLI option overrides the corresponding value from the file. For ordinary single-device and batch runs, the order is:

**Built-in values** → **Usable option.cfg lines** → **CLI**

BackUP Master populates its form differently: ordinary fields come from built-in values and the CLI, not from the options file. `UseIncremental` is the exception. Logging settings from the file are also honored when a backup is executed through the master.

The rules for reading settings are in [OPTIONS.md](OPTIONS.md), and master behavior is covered in [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Result codes

| Code | Meaning |
|---:|---|
| `0` | Success with no recorded errors or warnings |
| `1` | Completed with warnings and no recorded execution error |
| `12` | Error in CLI options, their values, or their combination |
| `21` | Could not read `option.cfg` |
| `22` | Could not obtain the device list |
| `23` | Invalid device list or no eligible entries |
| `24` | Could not read Oxidized files |
| `25` | Unsupported schema or invalid Oxidized data; no eligible MikroTik entries |
| `30` | A required utility is missing or does not support the required capabilities |
| `31` | Terminal unavailable, `stty` error, or insufficient window size |
| `32` | The required lock is held by another run |
| `33` | Invalid storage path or object for a single-device run |
| `34` | Could not create or prepare the single-device run directory |
| `35` | Error accessing or validating a local service object, including a lock |
| `36` | Single-device run storage failed its availability check before file retrieval |
| `37` | Could not write or replace a service file |
| `40` | SSH/SCP connection or transport error |
| `41` | Device authentication error |
| `42` | RouterOS command or expected-response error |
| `43` | SCP file-transfer error |
| `50` | Invalid final device name |
| `51` | `.rsc` file failed validation |
| `52` | Duplicate final device names |
| `53` | `.backup` file failed validation |
| `61` | Shared storage unavailable while preparing a batch run |
| `62` | Could not confirm or activate a separate mount for `UseNetFolder=true` |
| `63` | Error preparing or validating the shared batch-backup directory |
| `64` | Device or archive storage error while shared storage remains available |
| `65` | Shared storage was lost or became invalid during the run; batch processing stops |
| `70` | Error creating or updating an archive |
| `71` | ZIP or target archive object failed validation |
| `80` | Internal error or unmet system requirement, including `C.UTF-8` capability |
| `81` | Internal MikroTik driver error |
| `129` | Terminated by the HUP signal |
| `130` | Terminated by the INT signal, for example by pressing Ctrl+C |
| `143` | Terminated by the TERM signal |

The final code reflects the first recorded execution error. Warning `1` is replaced by the first such error, and a later success does not clear it. The final code therefore does not necessarily match the last message in the log.

If a file-retrieval retry succeeds, the stage may finish with `[OK]` even though the first attempt's error remains in the log. A nonzero final code from a batch run also does not mean that every device failed: inspect each result separately.

For code `80`, pay attention to system requirements: GNU Bash 4.4 or later and a working `C.UTF-8` locale. Details are in [INSTALL.md](INSTALL.md#host-requirements).

<br />

## If you need help

Provide the script version, operating system and Bash version, how the script was started, its exit code, and the relevant excerpt from the log. For a problem with one device, include its device log; for an error while preparing a run, start with `main.log`.

**Do not send real passwords or complete working settings files.** Before sending logs, screenshots, or commands, check them for sensitive data. Password-protection considerations are described in [SECURITY.md](SECURITY.md).

You can contact the author using the details in the [product description](../../README.md#contact-the-author).
