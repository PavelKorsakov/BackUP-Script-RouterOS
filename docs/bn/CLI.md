# কমান্ড লাইন

[সূচিপত্র](../README_BN.md)

## সিনট্যাক্স

```text
mikrotik-backup.sh [action] [parameters]
```

Command-line parameter long form ব্যবহার করতে পারে: `--parameter value` অথবা `--parameter=value`।
Short form-ও ব্যবহার করা যায়: `-p=value`। তবে **value** `-` দিয়ে শুরু হলে শুধু `=`-সহ form গ্রহণযোগ্য: `--parameter=-value`।

অজানা parameter, positional argument, অথবা অনুপস্থিত, স্পষ্টভাবে খালি বা invalid value error code `12` তৈরি করে এবং script থামায়।

<br />

## অ্যাকশন

| অ্যাকশন | উদ্দেশ্য |
|---|---|
| `-i` | প্রধান ইন্টারঅ্যাক্টিভ মেনু |
| `-b` | BackUP Master |
| `-e` | Configuration Editor (`option.cfg`) |
| `-h`, `--help` | CLI অপশনের সহায়তা |
| `-v`, `--version` | স্ক্রিপ্টের সংস্করণ |

একই সময়ে একটির বেশি action option script অনুমতি দেয় না। যেমন, `mikrotik-backup.sh -i -b` error code `12` দিয়ে থামে।

<br />

## প্যারামিটার

| প্যারামিটার | মান | উদ্দেশ্য |
|---|---|---|
| `--device-name` | Name | `UseIdentityName=false` হলে device name |
| `--address` | Address বা DNS name | RouterOS device address |
| `--user` | Login | RouterOS device user |
| `--password` | Password | RouterOS device password |
| `--port` | `1`–`65535` | Device SSH port; default `22` |
| `--language` | `auto` বা দুইটি ASCII letter | Current interface ও script log-এর language |
| `--use-oxidized` | Boolean value* | Oxidized থেকে device list import |
| `--oxidized-home` | Path | `config` ও `router.db` থাকা Oxidized settings directory |
| `--use-identity-name` | Boolean value* | RouterOS Identity থেকে name নেওয়া |
| `--backup-root` | Path | Backup storage-এর root directory |
| `--use-net-folder` | Boolean value* | Batch mode-এ mount পরীক্ষা করা |
| `--monthly-archive` | `false` অথবা `1` থেকে `28` পর্যন্ত number* | Calendar-based monthly archiving enable করা |
| `--log-level` | `0`, `1`, `2`, `3` | Log ও terminal output-এর detail level |
| `--main-log-path` | Path | শুধু `main.log`-এর directory |
| `--backup-type` | `configuration`,`binary`,`both` | Retrieve করার backup format |
| `--export-format` | `compact`, `terse`, `verbose` | Text export format |
| `--show-sensitive` | Boolean value* | Export-এ sensitive value অন্তর্ভুক্ত করা |
| `--encrypt` | Non-empty password | AES-SHA256 দিয়ে `.backup` encrypt করা |
| `--clear-dns-cache` | Boolean value* | Binary backup-এর আগে DNS cache clear করা |
| `--clear-console-history` | Boolean value* | Binary backup-এর আগে console history clear করা |

`*` Boolean value হলো `true` বা `false`; script case নির্বিশেষে `yes`/`no`, `1`/`0` এবং `on`/`off`-ও গ্রহণ করে।
`backup-type`-এর জন্য `config` ও `conf`-ও `configuration`-এর synonym হিসেবে গ্রহণযোগ্য।

সংক্ষিপ্ত connection form:

```text
-a=VALUE    --address VALUE-এর সমান
-u=VALUE    --user VALUE-এর সমান
-p=VALUE    --password VALUE-এর সমান
```

<br />

<a id="execution-mode"></a>
## কমান্ড লাইন থেকে স্ক্রিপ্ট চালানো

Script একটি device backup করতে পারে, তবে এমন run-এর জন্য অন্তত তিনটি parameter আবশ্যক:
device-এর **IP address**, **login** ও **password**। অর্থাৎ এই command-টি ইতিমধ্যেই ব্যবহারযোগ্য:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

উপরে দেওয়া অন্য সব parameter এখানে optional।
*(বি.দ্র.—খুব গুরুত্বপূর্ণ: এই connection triple-কে কোনো **action** option-এর সঙ্গে একত্রে চালানোর জন্য script তৈরি নয়।)*

**আরও একটি বিষয়!!!**
Single-device run-এর জন্য তিনটি connection parameter-ই CLI দিয়ে দিতে হবে। অনুপস্থিত login বা password script `option.cfg` থেকে নেয় না।

<br />

## সেটিং-এর অগ্রাধিকার

সাধারণ single-device ও batch backup [OPTIONS.md](OPTIONS.md)-এ বর্ণিত order ব্যবহার করে:
**Built-in value** → **option.cfg-এর ব্যবহারযোগ্য line** → **CLI**

কোনো parameter `option.cfg`-এ থাকলেও নির্দিষ্ট run-এ অন্য value দরকার হলে CLI দিয়ে দিন। Configuration file rewrite করার দরকার নেই।

Single-device run device list বা Oxidized import ব্যবহার করে না। CLI parameter replace না করলে `option.cfg`-এর অন্য setting প্রযোজ্য থাকে।

**Form পূরণের জন্য BackUP Master-এর নিজস্ব order আছে।**
সাধারণ field `option.cfg` নয়, built-in value ও supplied CLI parameter ব্যবহার করে। `UseIncremental` ব্যতিক্রম: এটি file থেকে inherited হয় অথবা default value পায়।
Selected `LogLevel` ও `MainLogPath` run-এর জন্য রাখা হয়, আর monthly archiving disabled থাকে। BackUP Master-এর বিস্তারিত [INTERACTIVE.md](INTERACTIVE.md)-এ দেখুন।

<br />

## উদ্দেশ্য অনুযায়ী command-line parameter

### সংযোগ ও ডিভাইসের নাম

| অপশন | মান | উদ্দেশ্য |
|---|---|---|
| `--address` | IP address বা DNS name | RouterOS device address |
| `--user` | Login | RouterOS device user |
| `--password` | Password | RouterOS device password |
| `--port` | `1` থেকে `65535` | Device SSH port; default `22` |
| `--device-name` | Name | `UseIdentityName=false` হলে device name |
| `--use-identity-name` | `true` / `false` | RouterOS Identity থেকে name নেওয়া |

নিজস্ব name ব্যবহার করতে `--use-identity-name false` ও `--device-name NAME` একসঙ্গে দিন।

<br />

### ব্যাকআপের ফরম্যাট ও বিষয়বস্তু

| অপশন | মান | উদ্দেশ্য |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Retrieve করার backup format |
| `--export-format` | `compact`, `terse`, `verbose` | Text export format |
| `--show-sensitive` | `true` / `false` | Export-এ sensitive value অন্তর্ভুক্ত করা |
| `--encrypt` | Non-empty password | AES-SHA256 দিয়ে `.backup` encrypt করা |
| `--clear-dns-cache` | `true` / `false` | Binary backup-এর আগে DNS cache clear করা |
| `--clear-console-history` | `true` / `false` | Binary backup-এর আগে console history clear করা |

`--backup-type`-এর জন্য `config` ও `conf`-ও `configuration` বোঝায়।

*(বি.দ্র.: `UseIncremental`-এর আলাদা CLI option নেই। এটি `option.cfg`, Configuration Editor অথবা BackUP Master-এ সেট করুন। উদ্দেশ্য [OPTIONS.md](OPTIONS.md)-এ বর্ণিত।)*

<br />

### স্টোরেজ, আর্কাইভ ও লগ

| অপশন | মান | উদ্দেশ্য |
|---|---|---|
| `--backup-root` | Path | Backup storage-এর root directory |
| `--use-net-folder` | `true` / `false` | Batch mode-এ mount পরীক্ষা করা |
| `--monthly-archive` | `false` অথবা `1` থেকে `28` পর্যন্ত number | Calendar-based monthly archiving enable করা |
| `--log-level` | `0`, `1`, `2`, `3` | Log ও terminal output-এর detail level |
| `--main-log-path` | Directory path | শুধু `main.log`-এর directory |

`--monthly-archive`-এর নিজস্ব rule আছে: `true`/`yes`/`1`/`on` মানে মাসের প্রথম দিন, আর `false`/`no`/`0`/`off` archiving নিষ্ক্রিয় করে। `2` থেকে `28` প্রয়োজনীয় দিন নির্বাচন করে।

Option-টি archiving day নির্বাচন করে; সঙ্গে সঙ্গে archiving চালায় না। এই mode-এর rule [BACKUPS.md](BACKUPS.md#monthly-archive)-এ দেখুন।

`--main-log-path`-এ directory দিন, `main.log`-এ শেষ হওয়া full path নয়। এই setting device log-এ প্রভাব ফেলে না।

<br />

### ডিভাইস-লিস্টের উৎস ও ভাষা

| অপশন | মান | উদ্দেশ্য |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Oxidized থেকে device list import |
| `--oxidized-home` | Path | `config` ও `router.db` থাকা Oxidized settings directory |
| `--language` | `auto` অথবা two-letter code | Current interface ও script log-এর language |

`--language auto` হলে operating-system locale language নির্বাচন করে। `ru`, `en` বা `de`-এর মতো code স্পষ্টভাবে বেছে নেওয়া যায়। রুশ ও ইংরেজির জন্য আলাদা translation file লাগে না; অন্য translation script-এর পাশের file থেকে load হয়। উপযুক্ত translation না থাকলে English ব্যবহার হয়।
বিস্তারিত [LOCALIZATION.md](LOCALIZATION.md)-এ দেখুন।

<br />

## উদাহরণ

**মনোযোগ দিন!!!**
Default-ভাবে sensitive export, DNS-cache cleanup এবং binary backup-এর আগে console-history cleanup enabled থাকে। নিচের single-device example-গুলো cleanup ও sensitive export disabled করে।

*(বি.দ্র.: CLI দিয়ে দেওয়া password shell history ও process argument-এ দেখা যেতে পারে। `.backup` encryption password-এর ক্ষেত্রেও এটি প্রযোজ্য; সেটি `ssh` child process-এর argument-এ দেখা যেতে পারে। বিস্তারিত [SECURITY.md](SECURITY.md)-এ দেখুন।)*

### শুধু `.rsc` কনফিগারেশন, sensitive data ছাড়া

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### উভয় ফরম্যাট, custom device name এবং cleanup ছাড়া

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### এনক্রিপ্ট করা বাইনারি ব্যাকআপ

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### পৃথক ডিরেক্টরি ও বিস্তারিত লগিংসহ ব্যাচ রান

এই example ধরে নেয় `option.cfg` ও device list আগে থেকেই প্রস্তুত:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

এই batch run-এর বাকি setting `option.cfg` ও built-in value থেকে আসে।

<br />

## কোনো কমান্ড প্রত্যাখ্যাত হলে

অজানা option, অতিরিক্ত positional argument অথবা অনুপস্থিত/invalid value error `12` ঘটায়। কোনো backup শুরু হয় না। Option-এর বানান পরীক্ষা করতে `-h` ব্যবহার করুন।

**CLI দিয়ে empty value দেওয়া যায় না।**
`--encrypt=''` ও `--main-log-path=''` প্রত্যাখ্যাত হয়। Empty `encrypt=` ও `MainLogPath=` value `option.cfg` বা Configuration Editor-এ সেট করুন।

Result code ও তার অর্থ [সমস্যা সমাধান](TROUBLESHOOTING.md#result-codes)-এ দেওয়া আছে।
