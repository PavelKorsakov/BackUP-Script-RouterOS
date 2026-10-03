# Command line

[Contents](../../README.md)

## Syntax

```text
mikrotik-backup.sh [action] [parameters]
```

Command-line parameters may use a long form: `--parameter value` or `--parameter=value`.
They may also use a short form: `-p=value`. If the **value** begins with `-`, however, only the form with `=` is accepted: `--parameter=-value`.

An unknown parameter, a positional argument, or a missing, explicitly empty, or invalid value produces error code `12` and stops the script.

<br />

## Actions

| Action | Purpose |
|---|---|
| `-i` | Main interactive menu |
| `-b` | BackUP Master |
| `-e` | Configuration Editor (`option.cfg`) |
| `-h`, `--help` | CLI option help |
| `-v`, `--version` | Script version |

The script does not allow more than one action option at a time. For example, `mikrotik-backup.sh -i -b` stops with error code `12`.

<br />

## Parameters

| Parameter | Value | Purpose |
|---|---|---|
| `--device-name` | Name | Device name when `UseIdentityName=false` |
| `--address` | Address or DNS name | RouterOS device address |
| `--user` | Login | RouterOS device user |
| `--password` | Password | RouterOS device password |
| `--port` | `1`–`65535` | Device SSH port; default `22` |
| `--language` | `auto` or two ASCII letters | Language of the current interface and script logs |
| `--use-oxidized` | Boolean value* | Import the device list from Oxidized |
| `--oxidized-home` | Path | Oxidized settings directory containing `config` and `router.db` |
| `--use-identity-name` | Boolean value* | Obtain the name from RouterOS Identity |
| `--backup-root` | Path | Root directory for backup storage |
| `--use-net-folder` | Boolean value* | Check the mount in batch mode |
| `--monthly-archive` | `false` or a number from `1` to `28`* | Enable calendar-based monthly archiving |
| `--log-level` | `0`, `1`, `2`, `3` | Detail level for logs and terminal output |
| `--main-log-path` | Path | Directory for `main.log` only |
| `--backup-type` | `configuration`,`binary`,`both` | Backup formats to retrieve |
| `--export-format` | `compact`, `terse`, `verbose` | Text export format |
| `--show-sensitive` | Boolean value* | Include sensitive values in the export |
| `--encrypt` | Non-empty password | Encrypt `.backup` with AES-SHA256 |
| `--clear-dns-cache` | Boolean value* | Clear the DNS cache before a binary backup |
| `--clear-console-history` | Boolean value* | Clear the console history before a binary backup |

`*` Boolean values are `true` or `false`; the script also accepts `yes`/`no`, `1`/`0`, and `on`/`off`, without regard to case.
For `backup-type`, `config` and `conf` are also accepted as synonyms for `configuration`.

Short connection forms:

```text
-a=VALUE    same as --address VALUE
-u=VALUE    same as --user VALUE
-p=VALUE    same as --password VALUE
```

<br />

<a id="execution-mode"></a>
## Running the script from the command line

The script can back up a single device, but it requires at least three parameters for such a run:
the device **IP address**, **login**, and **password**. In other words, this command is already usable:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

All other parameters listed above are optional here.
*(N.B. A very important point: the script is NOT designed to combine this connection triple with an **action** option.)*

**One more detail!!!**
For a single-device run, all three connection parameters must be supplied through the CLI. The script does not take a missing login or password from `option.cfg`.

<br />

## Setting priority

Ordinary single-device and batch backups use the order described in [OPTIONS.md](OPTIONS.md):
**Built-in values** → **Usable lines from option.cfg** → **CLI**

If a parameter is already present in `option.cfg` but a particular run needs a different value, pass that value through the CLI. You do not need to rewrite the configuration file.

A single-device run does not use the device list or Oxidized import. Other settings from `option.cfg` still apply unless command-line parameters replace them.

**BackUP Master has its own order for filling in the form.**
Ordinary fields use built-in values and supplied CLI parameters, not `option.cfg`. `UseIncremental` is the exception: it is inherited from the file or receives its default value.
The selected `LogLevel` and `MainLogPath` are retained for the run, while monthly archiving is disabled. See [INTERACTIVE.md](INTERACTIVE.md) for details of BackUP Master itself.

<br />

## Command-line parameters by purpose

### Connection and device name

| Option | Value | Purpose |
|---|---|---|
| `--address` | IP address or DNS name | RouterOS device address |
| `--user` | Login | RouterOS device user |
| `--password` | Password | RouterOS device password |
| `--port` | `1` to `65535` | Device SSH port; default `22` |
| `--device-name` | Name | Device name when `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Obtain the name from RouterOS Identity |

To use your own name, specify `--use-identity-name false` and `--device-name NAME` together.

<br />

### Backup format and contents

| Option | Value | Purpose |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Backup formats to retrieve |
| `--export-format` | `compact`, `terse`, `verbose` | Text export format |
| `--show-sensitive` | `true` / `false` | Include sensitive values in the export |
| `--encrypt` | Non-empty password | Encrypt `.backup` with AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Clear the DNS cache before a binary backup |
| `--clear-console-history` | `true` / `false` | Clear the console history before a binary backup |

For `--backup-type`, `config` and `conf` also mean `configuration`.

*(N.B. `UseIncremental` has no separate CLI option. Set it in `option.cfg`, the Configuration Editor, or BackUP Master. Its purpose is described in [OPTIONS.md](OPTIONS.md).)*

<br />

### Storage, archiving, and logs

| Option | Value | Purpose |
|---|---|---|
| `--backup-root` | Path | Root directory for backup storage |
| `--use-net-folder` | `true` / `false` | Check the mount in batch mode |
| `--monthly-archive` | `false` or a number from `1` to `28` | Enable calendar-based monthly archiving |
| `--log-level` | `0`, `1`, `2`, `3` | Detail level for logs and terminal output |
| `--main-log-path` | Directory path | Directory for `main.log` only |

`--monthly-archive` has its own rule: `true`/`yes`/`1`/`on` mean the first day of the month, while `false`/`no`/`0`/`off` disable archiving. Values from `2` through `28` select the required day.

The option selects the archiving day; it does not run archiving immediately. See [BACKUPS.md](BACKUPS.md#monthly-archive) for the rules of this mode.

For `--main-log-path`, specify a directory, not a full path ending in `main.log`. This setting does not affect device logs.

<br />

### Device-list source and language

| Option | Value | Purpose |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Import the device list from Oxidized |
| `--oxidized-home` | Path | Oxidized settings directory containing `config` and `router.db` |
| `--language` | `auto` or a two-letter code | Language of the current interface and script logs |

With `--language auto`, the operating-system locale selects the language. You may select one explicitly, such as `ru`, `en`, or `de`. Russian and English do not require separate translation files; other translations are loaded from files next to the script. If no suitable translation exists, English is used.
See [LOCALIZATION.md](LOCALIZATION.md) for details.

<br />

## Examples

**Pay attention!!!**
By default, sensitive exports, DNS-cache cleanup, and console-history cleanup before a binary backup are enabled. The single-device examples below disable cleanup and sensitive exports.

*(N.B. Passwords supplied through the CLI may be visible in shell history and process arguments. This also applies to the `.backup` encryption password, which may be visible in the arguments of the `ssh` child process. See [SECURITY.md](SECURITY.md) for details.)*

### `.rsc` configuration only, without sensitive data

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Both formats, a custom device name, and no cleanup

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Encrypted binary backup

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Batch run with a separate directory and detailed logging

This example assumes that `option.cfg` and the device list have already been prepared:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

The remaining settings for this batch run come from `option.cfg` and the built-in values.

<br />

## If a command is rejected

An unknown option, an extra positional argument, or a missing or invalid value causes error `12`. No backup starts. Use `-h` to check option spelling.

**Empty values cannot be passed through the CLI.**
`--encrypt=''` and `--main-log-path=''` are rejected. Set empty `encrypt=` and `MainLogPath=` values in `option.cfg` or through the Configuration Editor.

Result codes and their meanings are listed under [Troubleshooting](TROUBLESHOOTING.md#result-codes).
