# Backups and archives

[Contents](../../README.md)

## Backup formats

The script can save the device configuration as text, create a binary backup, or retrieve both formats.
The `backup_type` parameter in `option.cfg` selects the format:

| Value | What is saved |
|---|---|
| `configuration` | RouterOS configuration in an `.rsc` file |
| `binary` | Binary backup in a `.backup` file |
| `both` | Both formats: `.rsc` first, then `.backup` |

The default is `both`. You can change it in the options file, the Configuration Editor, BackUP Master, or with `--backup-type`.

### Text configuration: .rsc

The `export_format` parameter selects the export format. Valid values are `compact`, `terse`, and `verbose`; the default is `compact`.

The `show_sensitive` parameter determines whether the export includes sensitive data, including passwords. It is enabled by default.
To disable it, add this to `option.cfg`:

```ini
show_sensitive=false
```

### Binary backup: .backup

You can encrypt a binary backup. Set the required password in `encrypt`:

```ini
encrypt=MySuperPassword
```

With an empty `encrypt=` value, the file is saved without encryption. This is the default.

*(N.B. AES-SHA256 encryption applies only to `.backup`. It does not encrypt text configurations, logs, or ZIP archives.)*

By default, the script clears the RouterOS DNS cache and console history before creating a binary backup. If you do not need these operations, disable the corresponding parameters:

```ini
clear_dns_cache=false
clear_console_history=false
```

These cleanup operations are not performed when only a text configuration is retrieved.

<br />

## File names and locations

By default, backups are stored in the `backups` directory next to the script. Set another directory with `BackupRoot` in the options file.

In a single-device run, files are placed directly in that directory:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

In batch mode, each device has its own subdirectory:

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

A backup filename contains the device name and the date and time from the clock of the host running the script. Both formats from the same backup operation use the same timestamp.
Device-name construction is described in [DEVICES.md](DEVICES.md#device-names).

**Pay attention!!!**
If you back up the same device to the same directory twice within one minute, the filenames match. The file with that name is replaced; a separate version is not created for the second run.

You can also use a network directory for storage. In batch mode, set `UseNetFolder=true` to check that storage. Directory preparation is described in [INSTALL.md](INSTALL.md), and path settings in [OPTIONS.md](OPTIONS.md#network-storage).

[LOGGING.md](LOGGING.md) explains the location and contents of the logs in detail.

<br />

## Incremental backups

This feature avoids retaining duplicate backups when no change is detected. The `UseIncremental` parameter controls it:

| Value | How backups are retained |
|---|---|
| `true` (default) | If the new backup is identified as a duplicate, it is deleted and the previous backup remains |
| `false` | Every new valid backup is retained without comparison with the previous one |

When a change is detected or no previous backup exists, the new file is retained. If comparison cannot be completed, the file is also retained, but the script issues a warning.

**And here is the catch!!!**
The comparison differs by format:

| Format | What is compared |
|---|---|
| `.rsc` | File contents. The date and time in the standard RouterOS header are ignored |
| `.backup` | File size in bytes only |

Two binary files of the same size are therefore treated as duplicates even when their contents differ. Take this into account when choosing your retention settings.

The script compares against the most recent earlier backup of the same device and format in that device's directory. Backups already packed into a ZIP do not participate in comparison.

The script retains ordinary `.rsc` and `.backup` files, not separate change files. Disabling `UseIncremental` does not disable backup retrieval and verification, logging, or monthly archiving.

<br />

<a id="monthly-archive"></a>
## Monthly archiving

This feature is disabled by default. Set `MonthlyArchive` in `option.cfg` to choose the day on which accumulated backups and logs are archived:

| Value | Behavior |
|---|---|
| `false` (default) | Archiving is disabled |
| `true` or `1` | Archiving runs on the first day of the month |
| `2` through `28` | Archiving runs on the specified day of the month |

The time of the run within the selected day does not matter. Configure the schedule separately, as described in [INSTALL.md](INSTALL.md#running-the-script-automatically).

### What enters the archive

In batch mode, the order of work changes on that day: the script first collects the device's accumulated files into a ZIP and only then creates new backups. Backups created by the current run remain outside the archive.

The archive includes regular files directly inside the device directory, including the complete cumulative device log. This is not limited to `.rsc` and `.backup`: other regular files that you place in the directory may also be archived.

Subdirectories, symbolic links, service objects for the current run, and ZIP files previously created by the script are not packed again. **The main log, `main.log`, is not archived.**

After the finished ZIP has been verified and saved, the source files included in it are deleted from the device directory. If there is nothing to archive, no empty ZIP is created.

### Archive name and location

The ZIP is named after the previous calendar day in `DD.MM.YYYY.zip` format. For example, a run on October 1, 2026 creates `30.09.2026.zip`; a run on October 15 creates `14.10.2026.zip`.

| Mode | Archive location |
|---|---|
| Batch | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Single-device CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

A repeated run on the same day updates the archive with the same name.

### Single-device mode and BackUP Master

In a single-device CLI run, the order is reversed: backup runs first, followed by archiving. The new backup from the current run may therefore also enter the ZIP.

In this mode, `.rsc`, `.backup`, and `.log` files directly inside `BackupRoot` are archived, except for `main.log`. If results from single-device runs for several devices share one directory, their files enter the same archive.

Monthly archiving does not run when BackUP Master is used.

### If a run is missed

If the script does not run on the selected day, the missed archiving attempt is not caught up. The next attempt occurs on the designated day of the following month.

All accumulated files enter that one next archive, even if they belong to two, three, or more months. Separate ZIP files are not created for the missed months.

### If archiving fails

The source files are not deleted until a verified ZIP has been saved. An existing damaged archive is likewise not overwritten by a new one.

If the ZIP has already been saved but some source files cannot be deleted, the completed archive remains in place, as do the files that could not be deleted. Check the log for the cause of the error.

*(N.B. The archive is built in the local `/tmp` directory even when the backups themselves are stored on a NAS. Free space is therefore required outside the storage as well.)*

<br />

## If backup fails

After an unsuccessful attempt to retrieve a file, the script tries once more after 2 seconds. Retries for `.rsc` and `.backup` are performed separately.

An ordinary error while retrieving one format does not cancel the attempt to retrieve the other. If one device is unavailable, the script continues with the remaining devices. If shared storage is lost, batch processing stops.

Error messages and result codes are described in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Retention and restoration

Old ZIP files are not deleted by age or count. You decide their retention period and external rotation policy.

The script creates backups but does not restore RouterOS. Test restoration separately on a suitable device.

*(N.B. Backups and archives may contain passwords and other confidential data. Restrict access to storage as described in [SECURITY.md](SECURITY.md).)*
