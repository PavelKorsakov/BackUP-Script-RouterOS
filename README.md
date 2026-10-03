# MikroTik Backup Script

**Back up MikroTik RouterOS devices.**

This script creates backups of devices running RouterOS, either manually or automatically through a scheduler *(which you configure separately)*.
The `mikrotik-backup.sh` file is a self-contained script, although some features can be configured through `option.cfg`.

<br>

## Script features

| Feature | How it works |
|---|---|
| Single-device mode | Creates a backup of one device using CLI options |
| Batch processing | Processes the devices listed in DeviceList in sequence; can import the list from Oxidized |
| Backup formats | Creates `.rsc`, `.backup`, or both formats in sequence |
| Backup modes | Supports compact, terse, and verbose exports, plus encryption of binary backups |
| Incremental backups | Can keep backups only when a change is detected |
| Monthly archives | Can archive old backups and logs at a calendar boundary |
| Logging | Records general stages in `main.log` and device operations in `devicename.log` |
| Configuration menu | Provides an interactive menu for convenient setup and operation |
| Localization | Includes Russian and English and supports external localization files |
| Backup storage | Can use any backup directory, including a NAS |
| NAS operation | Checks that storage is available before creating a backup |

<br>

## System requirements and getting started

**Required:**
GNU Bash 4.4 or later and the following installed utilities: **SSH**, **SCP**, and **SSHPass**.
**zip** is required only for monthly backup archiving. All required utilities and their installation commands are listed under [Dependencies](docs/en/INSTALL.md#dependencies).
*(N.B. If a required utility is missing, the script terminates with an error. This is expected behavior.)*

**Optional:**
**autofs**, **davfs2**, **rclone**, and other tools for mounting external storage.

**Installation:**
See [Installation](docs/en/INSTALL.md) for download and setup instructions.

Run the following commands in the directory containing the downloaded files:

The command block below assumes files obtained from a GitHub Release. A Git source checkout does not include the generated `SHA256SUMS`; for a source checkout, start with `chmod 700 mikrotik-backup.sh` and continue with the version/help checks.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

If checksum verification fails, **do not run the file!!!**

<br>

## Ways to run the script

**Run the file WITHOUT additional options** *(when `option.cfg` is absent or invalid)*
If there is no `option.cfg` next to the script, or the file contains no usable settings, the Configuration Editor opens so that you can create or edit `option.cfg`.

**Run the file WITHOUT additional options** *(when valid `option.cfg` and `devicelist.cfg` files exist)*
If usable settings already exist, the script starts batch processing.

**Run the script with an option:**

| Task | Command |
|---|---|
| Open the interactive menu | `./mikrotik-backup.sh -i` |
| Open BackUP Master | `./mikrotik-backup.sh -b` |
| Create or edit `option.cfg` | `./mikrotik-backup.sh -e` |
| Show the complete CLI help | `./mikrotik-backup.sh -h` |
| Run a single-device backup | Supply the complete CLI triple: device address, user, and password |

The most important option here is `-i`, which opens the interactive menu. From there you can:

- use BackUP Master to enter device parameters, create its backups, and create or extend `devicelist.cfg` with the selected device parameters;
- use the Configuration Editor to create or edit `option.cfg`;
- view CLI help;
- read a short guide to the script's features.

For the complete CLI reference, including the exact `-a=...`, `-u=...`, and `-p=...` forms, see the [command-line reference](docs/en/CLI.md).

<br>

## Where are the results, or “Where are my backups???”

By default, device backups are stored in the `backups` directory next to the script. If the directory does not exist, the script creates it.
*(N.B. The relative `backups` path is resolved from the script directory, not from the current working directory!)*

In a single-device run, no separate device subdirectory is created:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

In batch mode, each device has its own directory:

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

These layouts are examples, not a promise that every file will exist after every run.
A log is created when its first applicable entry is written.
The `MainLogPath` option in `option.cfg` can move `main.log` to `/var/log/` or any other suitable directory.
See [Configuration](docs/en/OPTIONS.md) for details on configuring backup, archive, and log directories.

<br>

## Monthly archiving

This feature is disabled by default. If the script runs on a schedule, set `MonthlyArchive=true|1...28` in `option.cfg` to select the point at which all backups from the preceding period are archived.

On that day, a batch run changes its order of work: it first archives all eligible data accumulated in the backup directory, then creates backups for the current date.

The archive is named after the previous calendar day. For example, a run on October 1 creates `30.09.YYYY.zip`.

*(N.B. If the script does NOT run daily, you must create a separate scheduled job for the required date. No separate job is needed when the script runs daily or more often.)*

A missed monthly attempt—whatever the reason—is not caught up by daily runs.
The next scheduled monthly attempt collects all accumulated old data into one archive, even if the backlog covers several months. `main.log` is not archived.

See [Monthly archives](docs/en/BACKUPS.md#monthly-archive) for the complete rules, examples, and failure behavior.

<br>

## Detailed documentation

| Subject | Page |
|---|---|
| Requirements, dependencies, and file placement | [Installation](docs/en/INSTALL.md) |
| Parameters and mode selection | [CLI](docs/en/CLI.md) |
| Defaults and `option.cfg` | [Configuration](docs/en/OPTIONS.md) |
| DeviceList, names, and Oxidized | [Devices](docs/en/DEVICES.md) |
| Formats, comparison, storage, and ZIP archives | [Backups](docs/en/BACKUPS.md) |
| Log levels, paths, and messages | [Logging](docs/en/LOGGING.md) |
| Menu, editor, and BackUP Master | [Interactive interface](docs/en/INTERACTIVE.md) |
| Language selection and `.lang` files | [Localization](docs/en/LOCALIZATION.md) |
| Credentials, SSH, and access permissions | [Security](docs/en/SECURITY.md) |
| Diagnosis by symptom or result code | [Troubleshooting](docs/en/TROUBLESHOOTING.md) |
| Release verification and updates | [Releases](docs/en/RELEASES.md) |
| Development history and plans | [Roadmap](docs/en/ROADMAP.md) |

<br>

## Scope and limitations

The script creates backups but does not restore a router configuration.
The current version does not send email or messenger notifications and does not delete old ZIP files by age.
The administrator is responsible for restoration procedures, external retention, and result monitoring.

The SSH profile uses password authentication and disables host-key verification.
Encrypting a `.backup` file does not encrypt `.rsc` files, configuration files, or ZIP archives.
Read the [security model](docs/en/SECURITY.md) before production use.

<br>

## Documentation in other languages

[English](README.md).
[Русский](docs/README_RU.md).
[Latviešu](docs/README_LV.md).
[Українська](docs/README_UK.md).
[Deutsch](docs/README_DE.md).
[Bahasa Indonesia](docs/README_ID.md).
[Português (Brasil)](docs/README_PT-BR.md).
[Tiếng Việt](docs/README_VI.md).
[Español](docs/README_ES.md).
[Polski](docs/README_PL.md).
[বাংলা](docs/README_BN.md).

## Contact the author

Send feature suggestions, bug reports, and questions about the script to [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev),
or contact the author on Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
