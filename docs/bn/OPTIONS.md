# কনফিগারেশন

[সূচিপত্র](../README_BN.md)

## শুরুতে কয়েকটি কথা

ঐচ্ছিক `option.cfg` ফাইল দিয়ে স্ক্রিপ্টের default setting বদলানো যায়।
স্ক্রিপ্ট চালানোর সময় এই ফাইলের setting load করতে হলে `option.cfg`-কে `mikrotik-backup.sh`-এর পাশে একই directory-তে থাকতে হবে।

ফাইলের structure খুব সহজ: `Key=value` entry-র একটি list। এটি shell script নয়।
এখানে variable expansion বা command execution হয় না।

## কোনো run-এর জন্য configuration কখন ব্যবহারযোগ্য

একটি valid ও recognized line থাকলেই configuration ব্যবহারযোগ্য।
সব setting list করতে হয় না: default value উপযুক্ত হলে option-টি `option.cfg`-এ না থাকলেও চলে।

তবে file খালি হলে, অথবা শুধু comment, unknown key কিংবা invalid value থাকলে script-এর load করার মতো কিছু থাকে না।
তখন setting-গুলো default value-তেই থাকে।

**কিন্তু এখানেই ফাঁদ!!!**
এই অবস্থায় argument ছাড়া script চালালে backup শুরু হয় না। বরং script Configuration Editor খোলার চেষ্টা করে।
`option.cfg` একেবারেই না থাকলেও একই ঘটনা ঘটে।
প্রয়োজনীয় setting save করে script আবার চালান।
*(বি.দ্র.: Editor-এর terminal প্রয়োজন। Terminal ছাড়া—যেমন scheduler থেকে—script চালালে error `31` দিয়ে exit করে।
Automatic run configure করার আগে `option.cfg` প্রস্তুত করুন।)*

**Optional parameter পড়ার ক্রম:**
Script priority order অনুযায়ী parameter source apply করে। `option.cfg` অনুপস্থিত থাকলে script-এর built-in default ব্যবহার হয়।
File থাকলে এবং সফলভাবে পড়া গেলে তার <mark>valid</mark> parameter সংশ্লিষ্ট default বদলে দেয়।

আর সবচেয়ে গুরুত্বপূর্ণ বিষয়!!! একই parameter CLI দিয়েও দেওয়া হলে CLI value অগ্রাধিকার পায়।
তাই সাধারণ single-device বা batch run-এর priority হলো:
**Built-in value** → **option.cfg-এর ব্যবহারযোগ্য line** → **CLI**

*(বি.দ্র.: File অনুপস্থিত থাকা আর unreadable হওয়া এক বিষয় নয়।
`option.cfg` থাকলেও script পড়তে না পারলে configuration error `21` দিয়ে execution শেষ হয়; default নিয়ে চলতে থাকে না।)*

## ফাইল যেভাবে পড়া হয়

প্রতিটি line প্রথম `=`-এ ভাগ করা হয়। Key name case-insensitive, কিন্তু hyphen ও underscore পরস্পরের বিকল্প নয়।
Blank line এবং প্রথম non-whitespace character `#` এমন line উপেক্ষা করা হয়। Unknown বা invalid line পাশের সঠিক line-কে invalid করে না।
একই key একাধিকবার থাকলে শেষ valid value ব্যবহার হয়।

সাধারণ value-এর শুরুর ও শেষের space বাদ দেওয়া হয়।
**গুরুত্বপূর্ণ:** `Login`, `Password` ও `encrypt`-এর ক্ষেত্রে প্রথম `=`-এর পরের সবকিছু হুবহু রাখা হয়।
Shell syntax-এর জন্য quote দেবেন না: quote value-এর অংশ হয়ে যাবে।
Password-এর পরে comment দেবেন না। Comment-এর জন্য আলাদা line ব্যবহার করুন।

File-এর শুরুতে একটি BOM এবং CRLF line ending সমর্থিত।
Regular file-এর দিকে নির্দেশ করা readable symbolic link গ্রহণযোগ্য।
Access problem বা unsuitable object type-কে empty file ধরা হয় না এবং তা configuration error ঘটায়।

## 'option.cfg' তৈরি, সম্পাদনা ও সংরক্ষণ

File তৈরির সবচেয়ে সহজ উপায় হলো `-e` দিয়ে script চালানো:

```bash
./mikrotik-backup.sh -e
```

Configuration Editor খুলে main option-গুলো দেখায়।
সব line terminal window-তে না ধরলে arrow key দিয়ে উপরে-নিচে যাওয়ার সঙ্গে list নিজে scroll করে।
একই list-এর শেষে **Save** ও **Cancel** item থাকে।
Menu-তে চলুন, দরকারি setting দিন → **Save** নির্বাচন করুন → এবং (আপনি অসাধারণ) file তৈরি হয়ে গেছে।

Interactive menu-তে কাজ করার সময় editor শুধু memory-তে setting বদলায়—এটি মনে রাখুন।
**Save** নির্বাচন করার পরেই editor সম্পূর্ণ *canonical* file লেখে।

`option.cfg` এখনো না থাকলে editor শুরুতে field-গুলো default value দিয়ে পূরণ করে।
File আগে থেকে থাকলে এবং কিছু parameter বদলানো থাকলে Configuration Editor default-এর বদলে আপনার value দিয়ে field পূরণ করে।

'option.cfg' তৈরির দ্বিতীয় উপায় manual। হ্যাঁ: নিজের প্রিয় text editor নিজ হাতে খুলে প্রয়োজনীয় setting লিখুন।
সেগুলো কোথায় পাবেন? ঠিক নিচে:

## সেটিং ও ডিফল্ট

| Key | Default | Value ও উদ্দেশ্য |
|---|---|---|
| `Language` | `auto` | `auto` অথবা দুইটি ASCII letter, যেমন `ru`, `en` বা `de` |
| `SshPort` | `22` | Port `1`–`65535`; editor-এ hidden, BackUP Master-এ visible |
| `UseOxidized` | `false` | Oxidized থেকে device import |
| `IgnoreOxiAccess` | `true` | Oxidized read/parse failure-এর পরে আগের DeviceList ব্যবহারের অনুমতি; শুধু file-এ |
| `OxidizedHome` | খালি | `config` ও `router.db` থাকা directory |
| `UseIdentityName` | `true` | Live RouterOS Identity-কে device name হিসেবে ব্যবহার |
| `backup_type` | `both` | `configuration`, `binary` বা `both` |
| `UseIncremental` | `true` | নতুন verified backup আগেরটির সঙ্গে compare; `false` হলে compare না করে প্রতিটি নতুন backup রাখা |
| `export_format` | `compact` | `compact`, `terse` বা `verbose` |
| `show_sensitive` | `true` | `.rsc`-এ sensitive value অন্তর্ভুক্ত করা |
| `encrypt` | খালি | `.backup` encrypt করার password; খালি মানে encryption নেই |
| `encrypt_type` | `aes-sha256` | Fixed algorithm; শুধু file-এ |
| `clear_dns_cache` | `true` | Binary backup-এর আগে DNS cache clear করা |
| `clear_console_history` | `true` | Binary backup-এর আগে console history clear করা |
| `BackupRoot` | `backups` | Backup storage-এর root directory |
| `UseNetFolder` | `false` | Batch mode-এ আলাদা mount আবশ্যক করা |
| `MonthlyArchive` | `false` | Archiving নিষ্ক্রিয় (`false`) অথবা মাসের `1` থেকে `28` তারিখ নির্ধারণ |
| `LogLevel` | `2` | Level `0`, `1`, `2` বা `3` |
| `MainLogPath` | খালি | শুধু `main.log`-এর directory; খালি মানে current `BackupRoot` |
| `Login` | খালি | Empty DeviceList field-এর inherited common login; শুধু file-এ |
| `Password` | খালি | Empty DeviceList field-এর inherited common password; শুধু file-এ |

`Language=auto` হলে operating-system locale interface ও log language নির্বাচন করে।
External translation সেই locale-এর two-letter language code ব্যবহার করে: যেমন `de_DE.UTF-8`-এর জন্য script-এর পাশে `de.lang` প্রয়োজন।
উপযুক্ত translation না থাকলে English ব্যবহার হয়।

`MonthlyArchive`-এর rule কিছুটা আলাদা: `false`/`no`/`0`/`off` archiving নিষ্ক্রিয় করে; `true`/`yes`/`1`/`on` মানে মাসের প্রথম দিন; আর `2` থেকে `28` প্রয়োজনীয় দিন নির্বাচন করে।

Configuration Editor file save করলে `MonthlyArchive=false` অথবা selected number লেখে।

Boolean parameter case নির্বিশেষে `true`/`false`, `yes`/`no`, `1`/`0` ও `on`/`off` গ্রহণ করে। Editor `true`/`false` লেখে।

`IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` ও `Password`-এর মতো field Configuration Editor-এ দেখা যায় না।

File save করার সময় editor `IgnoreOxiAccess`, `encrypt_type` ও `SshPort` লেখে।
`Login` ও `Password` line আগে থেকে `option.cfg`-এ থাকলেই শুধু সেগুলো রেখে দেয়—empty value-র line-সহ।

সব device একই SSH port ও একই user—একই name ও password—ব্যবহার করলে `SshPort`, `Login` ও `Password` field উপকারী। তখন `devicelist.cfg`-এর প্রতিটি entry-তে শুধু দুইটি value লাগে: device-এর **name** ও **IP address**।

## Cleanup বা sensitive export ছাড়া উদাহরণ

এটি নির্বাচিত policy-র উদাহরণ, **factory default-এর list নয়**:

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

প্রথম 19টি key canonical write order-এ দেখানো হয়েছে।
Compatible existing `Login` ও `Password` line-গুলো এর পরে রাখা হয়।

অনুপস্থিত setting built-in value ব্যবহার করে, পাশের example-এর value নয়।
যেমন, শুধু `Language=ru` থাকা file cleanup নিষ্ক্রিয় করে না এবং `show_sensitive=true` বদলায় না।

## পাথ

```ini
BackupRoot=backups
MainLogPath=logs
```

এই entry-গুলো script-এর পাশের `backups` ও `logs` directory বোঝায়।
Absolute path নিজের অর্থ বজায় রাখে। `$HOME` ও `~` variable বা home directory হিসেবে expand হয় না।

`BackupRoot` না থাকলে permission সাপেক্ষে execution-এর সময় তৈরি হয়।
Filesystem root directory `/` storage হিসেবে নিষিদ্ধ।
Existing directory-র ownership বা permission program স্বয়ংক্রিয়ভাবে ঠিক করে না।

Non-empty `MainLogPath`-কে একটি **existing, writable directory** নির্দেশ করতে হবে।
`main.log` নিজে প্রথম entry লেখার সময় পর্যন্ত তৈরি হয় না; এতে parent directory তৈরি হয় না। Log লেখা না গেলে warning-সহ backup processing চলতে থাকে। এই setting device log সরায় না।

<a id="network-storage"></a>
## নেটওয়ার্ক ও পৃথক স্টোরেজ

`UseNetFolder=true` batch mode-এ প্রযোজ্য। Path-টি `/`-এর mount entry ছাড়া অন্য একটি mount entry-র আওতায় থাকতে হবে।
Separate storage network storage, local disk বা bind mount হতে পারে; option-এর name filesystem type সীমিত করে না।

একই root filesystem-এর সাধারণ directory এই requirement পূরণ করে না।
Script availability ও mounting পরীক্ষা করে, কিন্তু `mount`, `umount` বা `sudo` call করে না এবং চুপিসারে local storage-এ fallback করে না।

## সংশ্লিষ্ট প্যারামিটার

`UseIncremental=false` হলে script নতুন backup আগেরটির সঙ্গে compare করে না এবং সফলভাবে তৈরি ও verified প্রতিটি নতুন file রেখে দেয়।
এই setting backup তৈরি বা monthly archiving-কে প্রভাবিত করে না।
Default হলো `UseIncremental=true`। `option.cfg`-এ parameter-টি এখনো না থাকলে comparison enabled থাকে।

`backup_type=configuration` binary-backup encryption বা binary backup-এর আগের cleanup operation ব্যবহার করে না। `backup_type=binary` `export_format` বা `show_sensitive` ব্যবহার করে না। `UseOxidized=false` `OxidizedHome` ব্যবহার করে না।

`UseIdentityName=true` হলে Identity পড়তে ব্যর্থ হওয়ার পর `--device-name` বা DeviceList-এর name দিয়ে তা প্রতিস্থাপন করা হয় না। নির্দিষ্ট name ব্যবহার করতে `UseIdentityName` নিষ্ক্রিয় করুন: [নামকরণের নিয়ম](DEVICES.md#device-names) দেখুন।

`MonthlyArchive=true` হলে host-এর local time অনুযায়ী মাসের selected day-তে script শুরু হলে archiving চলে। দিনের কোন সময় তা গুরুত্বপূর্ণ নয়।
সেদিন script না চললে বাদ পড়া archiving attempt পরে পূরণ করা হয় না।

[BACKUPS.md](BACKUPS.md#monthly-archive)-এ কোন file archive-এ যায়, কোথায় তৈরি হয় এবং কী নাম হয় তা ব্যাখ্যা করা হয়েছে।
Data period, cutoff ও missed attempt-ও [BACKUPS.md](BACKUPS.md#monthly-archive)-এ সংজ্ঞায়িত।

Configuration-এ secret থাকতে পারে। এতে access সীমিত করুন এবং public repository-তে commit করবেন না: [SECURITY.md](SECURITY.md)।
