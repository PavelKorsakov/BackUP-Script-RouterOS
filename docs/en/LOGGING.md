# Logging

[Table of contents](../../README.md)

## Main log and device logs

The script records its overall progress in the main log, `main.log`, while the details of work with each device are saved in a separate device log.

In `main.log`, you can see how the device list was prepared, follow batch processing, and review the results of polling devices. Errors that occur before a particular device has been identified are also recorded here.

A device log contains information about retrieving `.rsc` and `.backup` files, retries, backup comparison, and archiving. In other words, if you need to find out what happened while a particular device was being backed up, look in that device's log. These details are not duplicated in `main.log`.

<br />

## Where logs are stored

By default, the main log is stored in the `backups` directory next to the script. Device logs are stored alongside their backups:

| Log | Location |
|---|---|
| Main log | `<BackupRoot>/main.log` |
| Device in batch mode | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Device in a single-device run | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

In batch mode, new entries are appended to the same device log. For a single-device backup, the log name contains the same date and time as the backup filenames from that run.

### A separate directory for main.log

If you prefer to keep the main log separate from the backups, specify the directory in the `MainLogPath` setting in `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

The log will then be written to `/var/log/mikrotik-backup/main.log`. Device logs will remain in their usual locations.

An empty `MainLogPath=` uses the current `BackupRoot`. A relative path, such as `MainLogPath=logs`, refers to a directory next to the script, not inside the backup storage.

*(N.B. `MainLogPath` specifies a directory, not a complete filename. The directory must already exist and be writable by the user running the script.)*

<br />

## Logging detail

The `LogLevel` setting controls how much information is displayed and recorded. Its default value is `2`:

| Value | Progress in the terminal | Entries in log files |
|---|---|---|
| `0` | Errors only | Errors only |
| `1` | Main stages and their results | Brief log |
| `2` | Main stages and their results | Detailed log |
| `3` | Main stages and current suboperations | Detailed log |

**Errors are recorded at every level.** A brief log contains the main stages and their results; a detailed log also records the operations performed within those stages.

You can change the level in `option.cfg` or through the Configuration Editor:

```ini
LogLevel=3
```

To change it for one run of an already configured batch backup, use the CLI:

```bash
mikrotik-backup.sh --log-level=3
```

This does not change the value in the options file. In the same way, `--main-log-path` can set the main log location for the current run.

BackUP Master has no separate fields for `LogLevel` or `MainLogPath`. It uses the logging settings in effect for the current run.

<br />

## What log entries look like

Logs are ordinary text files. Every entry includes the date and time according to the clock of the host running the script. Colors and progress indicators are not written to the file.

Example entries in `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Batch processing devices
[2026-10-01 01:00:15] [PID:12345] [OK] Batch processing devices
```

The main log also includes the process PID. It lets you distinguish entries written by multiple script instances running at the same time.

The PID is not added to a device log. Here is an excerpt from a detailed log:

```text
[2026-10-01 01:00:05] Retrieving binary backup
[2026-10-01 01:00:06] [1] Clearing DNS cache
[2026-10-01 01:00:07] [2] Clearing console history
[2026-10-01 01:00:12] [OK] Retrieving binary backup
```

`[OK]` means that the operation completed successfully. An error is marked with `[ER]` and includes its code, for example `[53]`. Suboperations are numbered `[1]`, `[2]`, and so on, starting over within each main stage.

If a retry succeeds after a failed attempt, the log retains both the earlier error and the later successful result.

Log entries use the same language as the interface, selected by the `Language` setting. For more about choosing a language and using translations, see [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Terminal output

During a manual run, progress is visible on screen. While an operation is in progress, a waiting indicator appears beside it. When it finishes, the indicator changes to a green `[OK]` or a red `[ER]` with an error code.

Levels `1` and `2` show the main stages. At level `3`, the current suboperation is also shown beneath the stage being performed and changes as work proceeds. In batch mode, the display additionally identifies the device currently being processed.

*(N.B. When the script runs without a terminal—for example, from a scheduler or with its output redirected—this on-screen output is absent. File logging continues at the selected level.)*

<br />

## Log accumulation and archiving

A log file is created when its first entry is written. With `LogLevel=0` and no errors, no new log files are created, while existing ones remain unchanged.

The main log and batch-mode device logs are appended to rather than overwritten on every run. A blank line separates successive runs.

`main.log` is neither archived nor removed based on age. You arrange its rotation yourself.

When monthly archiving is enabled, the accumulated batch-mode device log is included in the ZIP in full, together with that device's backups. Once the archive has been saved successfully, the archived log is removed from the device directory; the archiving result and subsequent work are then written to a new log file.

If the same ZIP is updated again, the history inside it is extended rather than replaced with a new log. If the archive cannot be saved, the previous log remains in place and the error is recorded in it.

Logs from single-device CLI runs are archived together with backups from the shared directory. Archiving in both modes is described in [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## If a log cannot be written

Insufficient permissions, an unavailable directory, or another log-writing error does not stop the backup itself. The script records a warning and continues whenever possible.

An unavailable `main.log` is reported once per run, and an unavailable device log once while that device is being processed. If the main log is available, a device-log write failure is recorded there.

If there are no other errors, the run exits with code `1`, meaning that it completed with a warning. This warning does not replace an error from the backup operation itself.

For result codes and help finding the cause of an error, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(N.B. Detailed level `3` does not log passwords or complete connection commands. For information about protecting credentials and script files, see [SECURITY.md](SECURITY.md).)*
