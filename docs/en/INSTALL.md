# Installation

[Contents](../../README.md)

## Host requirements

The script requires Linux with GNU Bash **4.4 or later** and the standard GNU file utilities.
The script itself does not require compilation, Python, a container, or a database.
It does, however, require the utilities listed under [Dependencies](#dependencies).

Device names require a working **`C.UTF-8`** locale for counting multibyte characters, recognizing letters, and changing letter case.
The script checks these capabilities before working with devices. This is a system requirement, not a separate program named `C.UTF-8`.

Naturally, the host must already have network access to the RouterOS SSH service and write permission for the selected storage.

**Strongly recommended!!!**
The script connects to RouterOS devices over SSH using password authentication, not key-based authentication.
(*See [SECURITY.md](SECURITY.md) for the exact transport policy.*)
You should therefore create a dedicated user on the device and restrict that user's login by the IP address of the host running this script.

<br />

## Dependencies

### Required for backups

**All** of the following utilities are required to create backups:

| Utilities | Purpose |
|---|---|
| `ssh`, `scp`, `sshpass` | Connect to RouterOS, run commands, and retrieve files |
| GNU `timeout`, `sleep` | Limit operation time and introduce pauses |
| `sha256sum` | Calculate checksums |
| `realpath` | Resolve absolute paths |
| `flock` | Locking that prevents concurrent runs from conflicting |

**If a required utility is missing, the script reports unsatisfied dependencies
and stops the backup attempt.
The dependency error code is `30`. This is expected behavior.**

The list is the same for single-device and batch backups, regardless of whether
the script creates `.rsc`, `.backup`, or both formats.

Merely having commands with those names is not enough. The installed OpenSSH must
support the options the script uses, including legacy SCP mode selected by `scp -O`.
GNU `timeout` must support `--signal` and `--kill-after`.
These capabilities are checked locally, without connecting to the router.

<br />

### Required for specific features

These tools are not part of the general required list. They are needed only
when the corresponding feature is used.

| Feature | Requirement | What happens if it is missing |
|---|---|---|
| Batch mode with `UseNetFolder=true` | `findmnt` | The backup does not start in this mode; dependency error `30` |
| A run in which monthly archiving is due | Info-ZIP `zip`, `unzip`, GNU `mv` | The run stops during the dependency check, before any backup; error `30` |
| Interactive menu, Configuration Editor, and BackUP Master | `stty` and a terminal on standard input and output | The interactive screen does not open; terminal error `31` |
| **Copy console command** in BackUP Master | GNU `base64` with `--wrap=0` support | The command cannot be copied; error `30` |

For example, a missing `zip` does not prevent an ordinary backup run when monthly archiving is not due.
A missing `base64` does not prevent backups from being created.
*(N.B. It is required when you choose **Copy console command**.)*

The general dependency check runs before a backup, not every time the program opens.
Consequently, help, version information, or the menu may be available even when backup utilities are not installed.

<br />

### Base Linux environment

The script also assumes that ordinary system commands for working with files
and directories are available, including `date`, `stat`, `mkdir`, `cp`, `ln`, and `rm`.

They are part of the base operating-system environment. The list of dependencies
checked in advance is not a complete list of every external command used by the
script. If a base system command is missing, the corresponding operation may fail
rather than producing an unsatisfied-dependency message.

<br />

### Installing the required packages on Debian/Ubuntu

This example installs the required tools and the optional tools listed above:
*(N.B. Here and below, the user is assumed to have administrator privileges.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Obtaining the script files

The primary installation method for version 2.3.1 is the complete GitHub Release asset `mikrotik-backup-2.3.1.zip`. It extracts directly into the installation directory without an extra wrapper directory.
*(N.B. In examples that place files under `/opt`, run the commands with permission to create and write that directory.)*

### Option 1: Complete release package

Download `mikrotik-backup-2.3.1.zip` from the MikroTik Backup Script 2.3.1 GitHub Release, then run:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

After extraction, the ready-to-use layout is:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

If checksum verification fails, do not run the script until you have found the cause.

<br />

### Option 2: Minimal standalone installation

Download the `mikrotik-backup.sh` and `SHA256SUMS` assets from the same Release into a protected directory, verify them, and make the script executable:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Download both Release assets into this directory.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

For an external runtime language, use the complete package or obtain the matching `.lang` file from the tagged source of the same version.

<br />

### Advanced option: Git or a source archive

A Git clone or the repository's **Code → Download ZIP** archive is also a complete product source tree. Its useful root layout is:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` is a Release asset and may not be present in a source checkout. For ordinary installation, the versioned Release package remains recommended because it contains the checksum file and exactly the published version.

<br />

## Files next to the script

After extracting the complete Release package, the selected directory contains the script and its accompanying files:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| File or directory | Purpose |
|---|---|
| mikrotik-backup.sh | The backup script itself |
| SHA256SUMS | Checksums used to verify the downloaded files |
| README.md | Product description and links to detailed documentation |
| lang/ | Localization files. Copy the required language file from this directory to the script directory. |
| docs/ | Detailed installation, configuration, and usage documentation |

For actual operation, only `mikrotik-backup.sh` is required.
To change settings, create **option.cfg** and place it next to the script.
If you plan to query and back up several devices in sequence, also create **devicelist.cfg** next to the script.
A localization file named `<xx>.lang` is needed if you want menus and log entries in your own language. Place it in the same directory as `mikrotik-backup.sh`.
Russian and English do not require separate localization files because both are built into the script.

**In interactive mode, the script can create and save:**
The device list—**devicelist.cfg**—through BackUP Master.
The configuration file—**option.cfg**—through the Configuration Editor.
You can also prepare them yourself:
*The TSV device-list format is described in detail in [DEVICES.md](DEVICES.md).*
*The `Key=value` configuration-file format is described in detail in [OPTIONS.md](OPTIONS.md).*

<br />

## Preparing storage and logs

With the default backup settings, the script creates a `./backups` directory next to itself and stores device backups there.
The only difference between modes is that a single-device run places the created files directly in `./backups`, whereas batch mode creates a device-named subdirectory under `./backups` and stores that device's backups there.

The script creates the required storage directories itself with the appropriate permissions.
*(It does not automatically change the owner or access mode of existing administrator-created directories.)*

By default, the script's main log, `main.log`, is stored in `./backups`.
In batch mode, a device log is stored in that device's subdirectory.

You should also know that, when your backup directory is on network storage,
the script can check that directory for availability during batch processing. This option is disabled by default and must be configured before use.
*(How the directory is mounted does not matter.)*

All these options can be changed by setting the required parameters in `option.cfg`.
See [Configuration](OPTIONS.md) for instructions and parameter syntax.

<br />

## Running the script automatically

Before you enable a schedule, prepare the settings and the device list.
Otherwise, an automatic run cannot perform a batch backup.

You do not have to create a separate user to run the script, but running operations like these as **root** is considered bad practice. The following example creates a dedicated user.

Create the **bsmt** user *(you may choose another name; replace **bsmt** in the examples)* and give it only the required permissions:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**If the script has already been run as root**

*(N.B. If you previously ran the script as **root**, the directories, backups,
and logs it created may not be accessible to **bsmt**.
Transfer the existing storage to that user before enabling the schedule.)*

This example uses the local `/opt/mikrotik-backup/backups` directory.
The following command changes the owner and group of the directory and everything in it:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(N.B. Specify this script's backup directory, not a shared directory that also contains data from other programs.
If the storage or main log is located elsewhere, configure access to each one separately according to the permissions and settings of the selected storage, following the same pattern.)*

This example opens the Configuration Editor as **bsmt** after that user has been granted access to the script directory and files:
*(N.B. Run the command as root or as a user permitted to do so through sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Creating a schedule for the script**

The following example creates a schedule with systemd,
but you may use crontab or any other method you prefer.

We will create a service that runs the script as our dedicated user and a timer that starts it on schedule.
*(The example runs every day at 1 a.m., but the schedule is entirely up to you.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` does not enable a catch-up run after a period when the timer was off.
`Restart=no` does not schedule automatic service restarts after an error.*
