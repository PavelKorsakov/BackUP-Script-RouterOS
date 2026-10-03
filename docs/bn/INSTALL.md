# ইনস্টলেশন

[সূচিপত্র](../README_BN.md)

## হোস্টের প্রয়োজনীয়তা

স্ক্রিপ্টের জন্য GNU Bash **4.4 বা পরবর্তী সংস্করণ**-সহ Linux এবং standard GNU file utility প্রয়োজন।
স্ক্রিপ্টটি compile করা লাগে না; Python, container বা database-ও প্রয়োজন নেই।
তবে [নির্ভরতা](#নির্ভরতা) অংশে উল্লেখ করা utility-গুলো আবশ্যক।

Multibyte character গণনা, অক্ষর শনাক্তকরণ এবং letter case পরিবর্তনের জন্য device name-এ সচল **`C.UTF-8`** locale প্রয়োজন।
ডিভাইস নিয়ে কাজ করার আগে স্ক্রিপ্ট এই capability-গুলো পরীক্ষা করে। এটি system requirement, `C.UTF-8` নামের আলাদা কোনো program নয়।

স্বাভাবিকভাবেই host-এর RouterOS SSH service-এ network access এবং নির্বাচিত storage-এ write permission আগে থেকেই থাকতে হবে।

**জোরালোভাবে সুপারিশ করা হচ্ছে!!!**
স্ক্রিপ্ট RouterOS ডিভাইসে SSH দিয়ে password authentication ব্যবহার করে connect করে; key-based authentication ব্যবহার করে না।
(*সুনির্দিষ্ট transport policy-এর জন্য [SECURITY.md](SECURITY.md) দেখুন।*)
তাই ডিভাইসে dedicated user তৈরি করা এবং সেই user-এর login-কে স্ক্রিপ্ট চালানো host-এর IP address-এ সীমাবদ্ধ রাখা উচিত।

<br />

## নির্ভরতা

### ব্যাকআপের জন্য আবশ্যক

ব্যাকআপ তৈরি করতে নিচের **সব** utility আবশ্যক:

| Utility | উদ্দেশ্য |
|---|---|
| `ssh`, `scp`, `sshpass` | RouterOS-এ connect করা, command চালানো এবং file retrieve করা |
| GNU `timeout`, `sleep` | operation-এর সময়সীমা নির্ধারণ ও বিরতি দেওয়া |
| `sha256sum` | checksum গণনা করা |
| `realpath` | absolute path resolve করা |
| `flock` | concurrent run-এর conflict ঠেকাতে software locking |

**কোনো আবশ্যক utility অনুপস্থিত থাকলে স্ক্রিপ্ট dependency পূরণ হয়নি বলে জানায়
এবং backup attempt বন্ধ করে দেয়।
Dependency error code হলো `30`। এটি প্রত্যাশিত আচরণ।**

একক-ডিভাইস ও batch backup—উভয়ের জন্য তালিকাটি একই; স্ক্রিপ্ট `.rsc`, `.backup` বা দুই format-ই তৈরি করুক না কেন।

একই নামের command থাকাই যথেষ্ট নয়। Installed OpenSSH-কে স্ক্রিপ্টে ব্যবহৃত option, বিশেষ করে `scp -O` দিয়ে নির্বাচিত legacy SCP mode সমর্থন করতে হবে।
GNU `timeout`-কে `--signal` ও `--kill-after` সমর্থন করতে হবে।
Router-এ connect না করেই এই capability-গুলো local host-এ পরীক্ষা করা হয়।

<br />

### নির্দিষ্ট feature-এর জন্য আবশ্যক

এই tool-গুলো সাধারণ required list-এর অংশ নয়। শুধু সংশ্লিষ্ট feature ব্যবহার করলেই এগুলো লাগে।

| Feature | প্রয়োজন | না থাকলে যা ঘটে |
|---|---|---|
| `UseNetFolder=true`-সহ batch mode | `findmnt` | এই mode-এ backup শুরু হয় না; dependency error `30` |
| যে run-এ monthly archiving due | Info-ZIP `zip`, `unzip`, GNU `mv` | কোনো backup-এর আগেই dependency check-এ run বন্ধ হয়; error `30` |
| Interactive menu, Configuration Editor এবং BackUP Master | Standard input ও output-এ `stty` এবং terminal | Interactive screen খোলে না; terminal error `31` |
| BackUP Master-এর **Copy console command** | `--wrap=0` সমর্থনকারী GNU `base64` | Command copy করা যায় না; error `30` |

উদাহরণস্বরূপ, monthly archiving due না হলে `zip` অনুপস্থিত থাকলেও সাধারণ backup run থামে না।
`base64` অনুপস্থিত থাকলেও backup তৈরি করা যায়।
*(বি.দ্র.: **Copy console command** বেছে নিলে এটি আবশ্যক।)*

সাধারণ dependency check backup-এর আগে চলে, program খোলার প্রতিবার নয়।
তাই backup utility install করা না থাকলেও help, version information বা menu উপলভ্য হতে পারে।

<br />

### মৌলিক Linux environment

স্ক্রিপ্ট ধরে নেয় যে file ও directory নিয়ে কাজ করার সাধারণ system command-গুলোও আছে, যেমন `date`, `stat`, `mkdir`, `cp`, `ln` ও `rm`।

এগুলো base operating-system environment-এর অংশ। আগে থেকে পরীক্ষা করা dependency list স্ক্রিপ্টে ব্যবহৃত প্রতিটি external command-এর সম্পূর্ণ তালিকা নয়। কোনো base system command অনুপস্থিত থাকলে unsatisfied-dependency message না দিয়ে সংশ্লিষ্ট operation ব্যর্থ হতে পারে।

<br />

### Debian/Ubuntu-তে আবশ্যক package install করা

এই উদাহরণে আবশ্যক tool এবং উপরে উল্লেখ করা optional tool install করা হয়:
*(বি.দ্র.: এখানে ও নিচে user-এর administrator privilege আছে ধরে নেওয়া হয়েছে।)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## স্ক্রিপ্টের ফাইল সংগ্রহ

Version 2.3.1 install করার primary method হলো সম্পূর্ণ GitHub Release asset `mikrotik-backup-2.3.1.zip`। এটি কোনো অতিরিক্ত wrapper directory ছাড়াই সরাসরি installation directory-তে extract হয়।
*(বি.দ্র.: `/opt`-এর নিচে file রাখা example-গুলো এমন permission দিয়ে চালান যাতে ওই directory create ও write করা যায়।)*

### বিকল্প 1: সম্পূর্ণ Release package

MikroTik Backup Script 2.3.1 GitHub Release থেকে `mikrotik-backup-2.3.1.zip` download করে চালান:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Extract করার পরে ready-to-use layout হলো:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Checksum verification fail হলে কারণ না জানা পর্যন্ত script চালাবেন না।

<br />

### বিকল্প 2: ন্যূনতম standalone installation

একই Release থেকে `mikrotik-backup.sh` ও `SHA256SUMS` asset একটি protected directory-তে download করুন, verify করুন এবং script executable করুন:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Release-এর দুটি asset এই directory-তে download করুন।
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

External runtime language-এর জন্য সম্পূর্ণ package ব্যবহার করুন অথবা একই version-এর tagged source থেকে matching `.lang` file নিন।

<br />

### উন্নত বিকল্প: Git অথবা source archive

এই repository-এর Git clone বা **Code → Download ZIP** archive-ও সম্পূর্ণ product source tree। Root-এ প্রয়োজনীয় layout হলো:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` একটি Release asset এবং source checkout-এ নাও থাকতে পারে। সাধারণ installation-এর জন্য versioned Release package-ই সুপারিশ করা হয়, কারণ এতে checksum file থাকে এবং এটি ঠিক প্রকাশিত version-এর files বহন করে।

<br />

## স্ক্রিপ্টের পাশের ফাইলগুলো

সম্পূর্ণ Release package extract করার পরে নির্বাচিত directory-তে script ও সঙ্গে থাকা file থাকে:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| File বা directory | উদ্দেশ্য |
|---|---|
| mikrotik-backup.sh | Backup script নিজেই |
| SHA256SUMS | Downloaded file যাচাইয়ের checksum |
| README.md | Product description ও detailed documentation-এর link |
| lang/ | Localization file। এই directory থেকে প্রয়োজনীয় language file script directory-তে copy করুন। |
| docs/ | Installation, configuration ও usage-এর detailed documentation |

বাস্তব পরিচালনার জন্য শুধু `mikrotik-backup.sh` আবশ্যক।
Setting পরিবর্তন করতে **option.cfg** তৈরি করে script-এর পাশে রাখুন।
একাধিক device ধারাবাহিকভাবে query ও backup করতে চাইলে script-এর পাশে **devicelist.cfg**-ও তৈরি করুন।
Menu ও log entry নিজের ভাষায় চাইলে `<xx>.lang` নামের localization file প্রয়োজন। `mikrotik-backup.sh`-এর একই directory-তে এটি রাখুন।
রুশ ও ইংরেজির জন্য আলাদা localization file দরকার নেই, কারণ উভয়ই script-এ built-in।

**Interactive mode-এ script যেগুলো তৈরি ও save করতে পারে:**
BackUP Master দিয়ে device list—**devicelist.cfg**।
Configuration Editor দিয়ে configuration file—**option.cfg**।
আপনি চাইলে নিজেও এগুলো প্রস্তুত করতে পারেন:
*TSV device-list format [DEVICES.md](DEVICES.md)-এ বিস্তারিত বর্ণিত।*
*`Key=value` configuration-file format [OPTIONS.md](OPTIONS.md)-এ বিস্তারিত বর্ণিত।*

<br />

## স্টোরেজ ও লগ প্রস্তুত করা

Default backup setting-এ script নিজের পাশে `./backups` directory তৈরি করে এবং সেখানে device backup রাখে।
Mode-গুলোর একমাত্র পার্থক্য হলো: single-device run তৈরি করা file সরাসরি `./backups`-এ রাখে, আর batch mode `./backups`-এর নিচে device-এর নামে subdirectory তৈরি করে সেখানে backup রাখে।

উপযুক্ত permission দিয়ে প্রয়োজনীয় storage directory script নিজেই তৈরি করে।
*(Administrator আগে থেকে যে directory তৈরি করেছেন, তার owner বা access mode script স্বয়ংক্রিয়ভাবে বদলায় না।)*

Default-ভাবে script-এর main log `main.log`, `./backups`-এ থাকে।
Batch mode-এ device log সেই device-এর subdirectory-তে থাকে।

Backup directory network storage-এ থাকলে batch processing-এর সময় script directory-টির availability পরীক্ষা করতে পারে। এই option default-ভাবে disabled এবং ব্যবহারের আগে configure করতে হয়।
*(Directory কীভাবে mount করা হয়েছে তা গুরুত্বপূর্ণ নয়।)*

`option.cfg`-এ প্রয়োজনীয় parameter দিয়ে এই সব option বদলানো যায়।
নির্দেশনা ও parameter syntax-এর জন্য [কনফিগারেশন](OPTIONS.md) দেখুন।

<br />

## স্ক্রিপ্ট স্বয়ংক্রিয়ভাবে চালানো

Schedule সক্রিয় করার আগে setting ও device list প্রস্তুত করুন।
তা না হলে automatic run batch backup করতে পারবে না।

Script চালাতে আলাদা user তৈরি করতেই হবে এমন নয়, তবে **root** হিসেবে এ ধরনের operation চালানো খারাপ practice। নিচের উদাহরণ একটি dedicated user তৈরি করে।

**bsmt** user তৈরি করুন *(অন্য নাম বেছে নিতে পারেন; example-এ **bsmt** বদলে দিন)* এবং শুধু প্রয়োজনীয় permission দিন:

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

**স্ক্রিপ্ট আগে root হিসেবে চালানো হয়ে থাকলে**

*(বি.দ্র.: আগে **root** হিসেবে script চালালে তার তৈরি directory, backup ও log **bsmt**-এর জন্য accessible নাও হতে পারে।
Schedule সক্রিয় করার আগে existing storage ওই user-এর কাছে transfer করুন।)*

এই example local `/opt/mikrotik-backup/backups` directory ব্যবহার করে।
নিচের command directory এবং তার ভেতরের সব কিছুর owner ও group বদলায়:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(বি.দ্র.: এই script-এর backup directory দিন, এমন shared directory নয় যেখানে অন্য program-এর data-ও আছে।
Storage বা main log অন্য কোথাও থাকলে একই pattern মেনে নির্বাচিত storage-এর permission ও setting অনুযায়ী প্রতিটির access আলাদাভাবে configure করুন।)*

Script directory ও file-এ access দেওয়ার পরে এই example **bsmt** হিসেবে Configuration Editor খোলে:
*(বি.দ্র.: Command-টি root হিসেবে বা sudo দিয়ে অনুমোদিত user হিসেবে চালান।)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**স্ক্রিপ্টের schedule তৈরি করা**

নিচের example systemd দিয়ে schedule তৈরি করে, তবে crontab বা নিজের পছন্দের অন্য method ব্যবহার করতে পারেন।

আমরা dedicated user হিসেবে script চালানো একটি service এবং schedule অনুযায়ী তা start করা একটি timer তৈরি করব।
*(Example-টি প্রতিদিন রাত 1টায় চলে, তবে schedule সম্পূর্ণ আপনার পছন্দ।)*

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

*`Persistent=false` timer বন্ধ থাকা সময়ের জন্য catch-up run enable করে না।
`Restart=no` error-এর পরে automatic service restart schedule করে না।*
