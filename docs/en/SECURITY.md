# Security

[Table of contents](../../README.md)

## Accounts

The script does not require **root** privileges. An ordinary user needs only access to the settings files and permission to write to the selected storage and logs.

Creating a dedicated **bsmt** user and configuring the script to run under that account are covered in [INSTALL.md](INSTALL.md#running-the-script-automatically).

On the RouterOS device, it is also advisable to create a dedicated backup user and restrict its login to the IP address of the host running the script. That account's permissions must allow the selected operations: retrieving the configuration, creating and downloading backups, deleting temporary files, and performing any enabled cleanup operations.

<br />

## Connecting to RouterOS

The script connects over SSH using password authentication. SSH keys and the agent are not used. Files are retrieved with the legacy SCP protocol, that is, `scp -O`.

The script uses its own connection settings. It does not read the user's `~/.ssh/config` or the system SSH configuration because the client is started with `-F /dev/null`. Agent, X11, and port forwarding are disabled.

**Please note!!! Server host-key verification is disabled.**

The current profile uses these settings:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

The usual `known_hosts` files are neither read nor changed. The script therefore does not verify that the responding server is the expected device rather than an impostor. Take this into account when arranging network access to your routers.

<br />

<a id="secrets"></a>
## Passwords when starting the script

A password passed through `--password` or `-p=` becomes part of the launch command. It may be visible in process arguments and saved in shell history. The same applies to an encryption password passed through `--encrypt`.

### Entering passwords through BackUP Master

To avoid placing the SSH password on the command line, start BackUP Master:

```bash
mikrotik-backup.sh -b
```

Fill in the device credentials in the form and choose the required action. Both passwords are displayed as asterisks, and values entered in the form do not enter shell command history.

When connecting, the script itself passes the SSH password to `sshpass` through a file descriptor (`-d`), not through the `sshpass -p` argument or the `SSHPASS` environment variable.

### The .backup encryption password

The encryption password is included in the RouterOS command passed to the `ssh` child process. A host user with sufficient permission to inspect process arguments may therefore see it while a binary backup is being created.

Entering the password through BackUP Master or storing it in `option.cfg` does not change how it is passed. File encryption is not protection from an administrator of the backup host itself.

### Copying a console command

The “Copy console command” action in BackUP Master sends a command containing the connection credentials—and, if one is set for a binary backup, the encryption password—to the clipboard.

Keep this in mind when using clipboard history and when pasting the command into a shell. Masking a password with asterisks in the form does not mean that it is masked in the copied command.

<br />

## Files that contain sensitive data

| File | What it may contain |
|---|---|
| `devicelist.cfg` | Device addresses, logins, and SSH passwords in plain text |
| `option.cfg` | Shared `Login` and `Password` values and the `encrypt` encryption password |
| `.rsc` and `.backup` | Device configuration, passwords, and other sensitive data |
| Monthly ZIP | The same backups and logs collected into one archive |

Do not place working settings files or backups in a public repository or publicly accessible directory.

### Sensitive data in .rsc files

By default, `show_sensitive=true`, so sensitive values are included in the text export. To disable this, set the following in `option.cfg`:

```ini
show_sensitive=false
```

Even then, the file is still a configuration of your device: addresses, network structure, comments, and other user-provided strings do not disappear from it.

### Binary-backup encryption

By default, `encrypt` is empty and `.backup` is saved without encryption. To enable it, set a password in the options file or in the corresponding BackUP Master field:

```ini
encrypt=MySuperPassword
```

The AES-SHA256 algorithm is used. It encrypts **only `.backup`**, not `.rsc`, `option.cfg`, the device list, logs, or the ZIP itself. Access to the monthly archive must therefore be restricted just as carefully as access to the files inside it.

<br />

## File and storage permissions

The script runs with `umask 077`. Local storage directories that it creates receive mode `0700`, while `option.cfg` and `devicelist.cfg` are written with mode `0600` when saved programmatically.

The owner and permissions of existing administrator-created storage directories are not changed automatically. If you prepare a directory manually, you must configure its access yourself.

The local monthly-archive directory, `archive/`, must have mode `0700` and belong to the user running the script. This requirement also applies to an existing directory. Local archive files created by the script have mode `0600`.

In batch mode, when verified network storage is used with `UseNetFolder=true`, the NAS server may determine archive-object owners and permissions. A difference from the local values alone does not stop archiving. Configure access to network storage through your operating system and NAS.

Examples of preparing directories and granting access to the **bsmt** user are provided in [INSTALL.md](INSTALL.md).

*(N.B. The script reads its configuration, device list, translations, and any Oxidized settings it uses as data; it does not execute them as shell scripts.)*

<br />

## Changes made on the device

By default, the RouterOS DNS cache and console history are cleared before a binary backup is created. If you do not need these actions, disable them in `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

You can disable the same features through the Configuration Editor, BackUP Master, or the corresponding CLI options. These cleanup operations are not performed when only `.rsc` is retrieved.

<br />

## Logs and sharing diagnostic information

Detailed level `LogLevel=3` adds information about processing stages; it does not output passwords or complete connection commands.

Processed SSH diagnostics mask the exact known values of the address, login, SSH password, and encryption password. This does not sanitize backup contents or guarantee the removal of every secret from arbitrary text.

Temporary files containing unprocessed diagnostics may include sensitive data. They are created with mode `0600` and removed during normal cleanup.

Before sending logs, screenshots, or command output to other people, inspect their contents. Complete output from `devicelist.cfg`, a process list, or clipboard contents may reveal data absent from the normal log.

For more about log entries, see [LOGGING.md](LOGGING.md); for help investigating errors, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Concurrent runs

Runs by the same user with the same `BackupRoot` use locking:

| Concurrent runs | What happens |
|---|---|
| A batch run and another batch or single-device run | The second run does not acquire the lock |
| Two single-device runs for the same device | The second run does not acquire the lock |
| Single-device runs for different devices | They may run concurrently |

If the lock is busy, the script exits with code `32`. Different storage roots are not coordinated as a single storage area when one is nested inside the other.

Lock files are kept in `/tmp/mikrotik-backup-${UID}/` and remain after the script finishes. Their presence alone does not mean that the script is still running.

**Do not delete these files to “clear a stale lock.”** The lock is tied to an open process file descriptor, not to the existence of the file. These locks also do not protect data from an unrelated program that modifies it directly.

<br />

## Restore testing

Verifying the script checksum and successfully retrieving a backup file are no substitute for testing restoration.

The script itself does not restore RouterOS. You must separately verify that backups can be used on a suitable device and decide how long to retain them. For more information, see [BACKUPS.md](BACKUPS.md).
