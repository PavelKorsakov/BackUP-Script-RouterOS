# Configuration

[Contents](../../README.md)

## A few words first

The optional `option.cfg` file lets you change the settings that the script uses by default.
For the script to load the settings listed in this file during execution,
`option.cfg` must be next to `mikrotik-backup.sh` in the same directory.

The file structure is very simple: a list of `Key=value` entries. It is not a shell script.
No variable expansion or command execution takes place in it.

## When a configuration is usable for a run

Even one valid, recognized line makes the configuration usable.
You do not need to list every setting: if a default suits you, that option does not have to appear in `option.cfg`.

If the file is empty or contains only comments, unknown keys, or invalid values, however, the script has nothing to load from it.
The settings then remain at their defaults.

**And here is the catch!!!**
If you run the script without arguments in that state, no backup starts. Instead, the script attempts to open the Configuration Editor.
The same thing happens when `option.cfg` does not exist at all.
Save the required settings and run the script again.
*(N.B. The editor requires a terminal. If the script is run without one—for example, by a scheduler—it exits with error `31`.
Prepare `option.cfg` before configuring an automatic run.)*

**Order in which optional parameters are read:**
The script applies parameter sources in priority order. If `option.cfg` is absent, it uses the defaults embedded in the script.
If the file exists and is read successfully, the <mark>valid</mark> parameters it contains replace the corresponding defaults.

And most importantly!!! If the same parameter is supplied through the CLI, the CLI value takes precedence.
For an ordinary single-device or batch run, the priority is therefore:
**Built-in values** → **Usable lines from option.cfg** → **CLI**

*(N.B. An absent file is not the same as an unreadable file.
If `option.cfg` exists but the script cannot read it, execution ends with
configuration error `21`; it does not continue with the defaults.)*

## How the file is read

Each line is split at the first `=`. Key names are case-insensitive, but hyphens and underscores are not interchangeable.
Blank lines and lines whose first non-whitespace character is `#` are ignored. An unknown or invalid line does not invalidate neighboring correct lines.
When a key appears more than once, the last valid value is used.

Leading and trailing spaces are removed from ordinary values.
**Important:** for `Login`, `Password`, and `encrypt`, everything after the first `=` is preserved literally.
Do not add quotes for shell syntax: the quotes become part of the value.
Do not put a comment after a password. Use a separate line for the comment.

One BOM at the start of the file and CRLF line endings are supported.
A readable symbolic link to a regular file is allowed.
An access problem or an unsuitable object type is not treated as an empty file
and causes a configuration error.

## Creating, editing, and saving 'option.cfg'

The easiest way to create the file is to run the script with `-e`:

```bash
./mikrotik-backup.sh -e
```

The Configuration Editor opens and lists the main options.
If all lines do not fit in the terminal window, the list scrolls automatically as you move up and down with the arrow keys.
The **Save** and **Cancel** items are at the end of the same list.
Move through the menu, enter the settings you need → select **Save** → and (you are wonderful) the file has been created.

Keep in mind that, while you work in the interactive menu, the editor changes settings only in memory.
Only after you select **Save** does it write the complete, *canonical* file.

If `option.cfg` does not exist yet, the editor initially fills its fields with the default values.
If the file already exists and you have changed some parameters, the Configuration Editor fills its fields with your values rather than the defaults.

The second way to create 'option.cfg' is manually. Yes: open your favorite text editor with your own hands and enter the settings you need.
Where do you find them? Right below:

## Settings and defaults

| Key | Default | Value and purpose |
|---|---|---|
| `Language` | `auto` | `auto` or two ASCII letters, such as `ru`, `en`, or `de` |
| `SshPort` | `22` | Port `1`–`65535`; hidden in the editor, visible in BackUP Master |
| `UseOxidized` | `false` | Import devices from Oxidized |
| `IgnoreOxiAccess` | `true` | Allow the previous DeviceList after an Oxidized read/parse failure; file only |
| `OxidizedHome` | Empty | Directory containing `config` and `router.db` |
| `UseIdentityName` | `true` | Use the live RouterOS Identity as the device name |
| `backup_type` | `both` | `configuration`, `binary`, or `both` |
| `UseIncremental` | `true` | Compare a new verified backup with the previous one; with `false`, keep every new backup without comparing it |
| `export_format` | `compact` | `compact`, `terse`, or `verbose` |
| `show_sensitive` | `true` | Include sensitive values in `.rsc` |
| `encrypt` | Empty | Password used to encrypt `.backup`; empty means no encryption |
| `encrypt_type` | `aes-sha256` | Fixed algorithm; file only |
| `clear_dns_cache` | `true` | Clear the DNS cache before a binary backup |
| `clear_console_history` | `true` | Clear the console history before a binary backup |
| `BackupRoot` | `backups` | Root directory for backup storage |
| `UseNetFolder` | `false` | Require a separate mount in batch mode |
| `MonthlyArchive` | `false` | Disable archiving (`false`) or set a day of the month from `1` to `28` |
| `LogLevel` | `2` | Level `0`, `1`, `2`, or `3` |
| `MainLogPath` | Empty | Directory for `main.log` only; empty means the current `BackupRoot` |
| `Login` | Empty | Common login inherited by empty DeviceList fields; file only |
| `Password` | Empty | Common password inherited by empty DeviceList fields; file only |

With `Language=auto`, the operating-system locale selects the interface and log language.
An external translation uses that locale's two-letter language code: for example, `de_DE.UTF-8` requires `de.lang` next to the script.
If no suitable translation is available, English is used.

`MonthlyArchive` follows a slightly different rule: `false`/`no`/`0`/`off` disable archiving; `true`/`yes`/`1`/`on` mean the first day of the month; and values from `2` through `28` select the required day.

When the Configuration Editor saves the file, it writes either
`MonthlyArchive=false` or the selected number.

Boolean parameters accept `true`/`false`, `yes`/`no`, `1`/`0`, and `on`/`off`
without regard to case. The editor writes `true`/`false`.

Fields such as `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login`, and `Password` do not appear in the Configuration Editor.

When saving the file, the editor writes `IgnoreOxiAccess`, `encrypt_type`, and `SshPort`.
It preserves `Login` and `Password` only if those lines were already present in `option.cfg`, including lines with empty values.

The `SshPort`, `Login`, and `Password` fields may be useful when all your devices use the same SSH port and the same user—the same name and password. In that case, each entry in `devicelist.cfg` needs only two values: the device **name** and its **IP address**.

## Example without cleanup or sensitive exports

This is an example of a selected policy, **not a list of factory defaults**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

The first 19 keys are shown in canonical write order.
Any compatible existing `Login` and `Password` lines are preserved after them.

Missing settings use the built-in values, not the values in the neighboring example.
For example, a file containing only `Language=ru` does not disable cleanup and does not change `show_sensitive=true`.

## Paths

```ini
BackupRoot=backups
MainLogPath=logs
```

These entries mean the `backups` and `logs` directories next to the script.
Absolute paths retain their meaning. `$HOME` and `~` are not expanded
as a variable or a home directory.

A missing `BackupRoot` is created during execution if permissions allow it.
The filesystem root directory, `/`, is forbidden as storage.
For existing directories, the program does not automatically correct ownership or permissions.

A non-empty `MainLogPath` must identify an **existing, writable directory**.
Creation of `main.log` itself is deferred until the first entry is written;
this does not create its parent directory. If the log cannot be written, backup
processing continues with a warning. This setting does not move device logs.

<a id="network-storage"></a>
## Network and separate storage

`UseNetFolder=true` applies in batch mode. The path must be covered by a mount
entry other than the entry for `/`. The separate storage may be network storage,
a local disk, or a bind mount; the option's name does not restrict the filesystem type.

A plain directory on the same root filesystem does not meet this requirement.
The script checks availability and mounting, but does not call `mount`, `umount`,
or `sudo`, and it does not silently fall back to local storage.

## Related parameters

With `UseIncremental=false`, the script does not compare a new backup with the previous one and keeps every new file that was created and verified successfully.
This setting does not affect backup creation itself or monthly archiving.
The default is `UseIncremental=true`. If your `option.cfg` does not yet contain this parameter, comparison remains enabled.

`backup_type=configuration` does not use binary-backup encryption
or the cleanup operations that precede a binary backup. `backup_type=binary` does not use `export_format`
or `show_sensitive`. `UseOxidized=false` does not use `OxidizedHome`.

With `UseIdentityName=true`, a failure to read Identity is not replaced
with `--device-name` or the name from DeviceList. To use a specified name, disable
`UseIdentityName`: see the [naming rules](DEVICES.md#device-names).

With `MonthlyArchive=true`, archiving runs when the script starts on the selected day of the month,
according to the host's local time. The time of day does not matter.
If the script does not run on that day, the missed archiving attempt is not caught up.

[BACKUPS.md](BACKUPS.md#monthly-archive) explains which files enter the archive, where it is created, and how it is named.
The data period, cutoff, and missed attempts are also defined in
[BACKUPS.md](BACKUPS.md#monthly-archive).

The configuration may contain secrets. Restrict access to it and do not commit
it to a public repository: [SECURITY.md](SECURITY.md).
