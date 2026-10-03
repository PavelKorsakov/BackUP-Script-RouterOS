# Device list

[Contents](../../README.md)

## Devices to back up: the devicelist.cfg file

As the name suggests, `devicelist.cfg` lists the devices for batch backups and the data required to connect to them.
Place the file directly next to `mikrotik-backup.sh`.
You can create `devicelist.cfg` manually or through BackUP Master.
A third option is useful when Oxidized runs on the same server. After you add the corresponding settings to the options file,
the script dynamically creates `devicelist.cfg` on every run using the required data from the Oxidized configuration files.

<br />

## Creating and editing the list

To create the list through BackUP Master, run:

```bash
mikrotik-backup.sh -b
```

Fill in the device name, address, login, password, and SSH port → select **2. Save device to devicelist.cfg**.
BackUP Master either creates the file with the required entry or adds or updates an entry in the existing file.

You can edit the finished list in an ordinary text editor. BackUP Master does not load existing entries into its form.

*(N.B. When BackUP Master saves port `22`, it writes an empty field. A batch backup uses `SshPort` from the script settings for that entry. A nonstandard port is written explicitly.)*

<br />

## File format

Write each device on a separate line. Separate fields with a **TAB character**, not spaces. The fields are ordered as follows:

| Position | Field | Purpose |
|---|---|---|
| 1 | Name | Device name; required |
| 2 | Address | Device IP address or DNS name; required |
| 3 | Login | RouterOS device user; when omitted, inherited from `Login` in `option.cfg` |
| 4 | Password | RouterOS device password; when omitted, inherited from `Password` in `option.cfg` |
| 5 | Port | SSH port from `1` to `65535`; when omitted, inherited from `SshPort`, whose default is `22` |
| 6 | Device marker | `MikroTik`; may be empty. Case-insensitive |

Fields from the seventh onward are not used. Entries with a different device marker are skipped.

### Example list

The fields in this example are separated by actual TAB characters:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

The port is omitted from the second line: two TAB characters appear between the password and `MikroTik`. Replace the addresses and credentials with your own.

### Shared login, password, and port

If all your devices use the same credentials, specify them once in `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Then `devicelist.cfg` needs only the name and address of each device:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Credentials specified in a device's own entry override the shared values.

*(N.B. The device-list file contains passwords. Restrict access as described in [SECURITY.md](SECURITY.md).)*

<br />

## How the list is read

Blank lines and lines whose first non-whitespace character is `#` are ignored. Put comments on separate lines; a `#` inside a field is part of its value.

Leading and trailing spaces are removed from the name, address, port, and marker. The login and password are read literally, including spaces and quotation marks. Files with Windows line endings (CRLF) are supported.

If a line—a device entry—violates the required syntax, the script skips it during execution and issues a warning that the entry is invalid.

If a line is duplicated for any reason—that is, all four connection parameters (**address, login, password, and port**) match—the script connects to that device only once, using the data from the last entry.
If different connections have the same name, the first usable entry is used and the conflicting entry is skipped.

<br />

<a id="device-names"></a>
## Device names

The name is used in backup filenames and, in batch mode, for the device subdirectory.
The `UseIdentityName` setting in `option.cfg` determines where the name comes from:

| Value | Name source |
|---|---|
| `true` (default) | The Identity value on the RouterOS device itself |
| `false` | The name from `devicelist.cfg`, the BackUP Master field, or `--device-name` in a single-device CLI run |

### Name in parentheses

If the original name contains parentheses, the script uses the contents of the first complete, non-empty group. If there is no such group, it uses the entire name.

| Original name | Backup name |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Allowed characters

The final name retains letters, including Cyrillic letters, digits, periods, hyphens, and underscores. Spaces and invalid characters are replaced with `_`. Repeated and leading or trailing underscores are removed, as are leading periods and hyphens and periods at the end of the name.

For example, `ЦОД Москва №1` becomes `ЦОД_Москва_1`.

The final name must be **from 1 through 32 characters** long. An overlong name is not truncated; it causes an error. The reserved names `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, and `LPT1`–`LPT9` are not allowed.

Final names must be unique without regard to case: `Router-A` and `router-a` are considered the same. A second device with that name is skipped during the current run.

*(N.B. Changing the final name also changes the device subdirectory. Old backups are not moved automatically.)*

<br />

## Importing from Oxidized

If you already maintain a device list in Oxidized, the script can obtain it from there. Add the following to `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Set `OxidizedHome` to the directory containing `config` and `router.db`. The script builds `devicelist.cfg` from them. It does not modify the Oxidized files.

*(N.B. Import replaces `devicelist.cfg`; it does not extend the file. Manual additions are lost the next time an Oxidized update succeeds.)*

### Source settings

The Oxidized configuration must use the `csv` source with a one-character delimiter. `source.csv.map` determines the column order, with numbering starting at zero:

| Map field | Value used |
|---|---|
| `name` | Device name; required column |
| `ip` | Device address; if omitted, the `name` value is used |
| `username` | Login; if omitted, the shared `Login` from `option.cfg` is used |
| `password` | Password; if omitted, the shared `Password` from `option.cfg` is used |
| `port` | SSH port; if omitted, `SshPort` is used |
| `model` | Device model; if the column is absent, the root `model` parameter is used |

`model_map` rules are applied through the first match. Only devices whose final model is `routeros` are imported. If the `model` column exists, the root parameter does not replace empty values in that column.

Data is always read from `<OxidizedHome>/router.db`. The Oxidized `source.csv.file` parameter does not change this path.

### If import fails

If the Oxidized files are unavailable, their format is unsupported, or no suitable devices are found, the previous `devicelist.cfg` is preserved.

With `IgnoreOxiAccess=true`, the script may use the previous usable list. With `false`, no backup is performed from the old list.

An import error affects the run result even if backup processing with the previous list succeeds.

See [Troubleshooting](TROUBLESHOOTING.md) for details of list and import errors.
