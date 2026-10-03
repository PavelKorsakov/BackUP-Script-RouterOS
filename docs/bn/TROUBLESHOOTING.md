# সমস্যা সমাধান

[সূচিপত্র](../README_BN.md)

## কোথা থেকে শুরু করবেন

Backup শুরু না হলে বা error দিয়ে শেষ হলে প্রথমে log দেখুন। `main.log`-এ run-এর overall stage থাকে, আর নির্দিষ্ট device backup-এর detail আলাদা device log-এ লেখা হয়।

`[ER]` mark ও error code থাকা entry খুঁজুন। Code [নিচে](#result-codes) ব্যাখ্যা করা হয়েছে এবং log location [LOGGING.md](LOGGING.md)-এ বর্ণিত।

Installed script version ও option reference দেখতে:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Detailed output-সহ configured batch run আবার চালাতে:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

দ্বিতীয় command completed run-এর result দেখায়। এটি `option.cfg`-এর logging level বদলায় না।

<br />

## স্ক্রিপ্ট ব্যাকআপ শুরু করে না

### ব্যাকআপের বদলে এডিটর খুলেছে

Option ছাড়া script start করলে এর মানে `option.cfg` script directory-তে নেই অথবা usable setting নেই। Empty file, শুধু comment, অথবা শুধু unknown setting result বদলায় না।

Configuration Editor খুলে required setting বেছে save করুন, তারপর script আবার চালান:

```bash
mikrotik-backup.sh -e
```

BackUP Master দিয়ে device save করলে `devicelist.cfg` তৈরি হয়, কিন্তু এতে `option.cfg` প্রস্তুত করার প্রয়োজন শেষ হয় না।

*(বি.দ্র.: এমন run scheduler থেকে start হলে editor খুলতে পারে না এবং script code `31` দিয়ে exit করে। Automatic run-এর setting আগে থেকে প্রস্তুত করতে হবে।)*

### অপশন ত্রুটি, কোড 12

Option name, value ও action combination পরীক্ষা করুন। Unknown option, empty value, একই সঙ্গে multiple different action request, অথবা single-device connection-এর incomplete credential কারণ হতে পারে।

Single-device CLI run-এ address, login ও password আবশ্যক। Missing credential `option.cfg` থেকে পূরণ করা হয় না।

Short connection option-এ `=` ব্যবহার করতেই হবে: `-a=`, `-u=` ও `-p=`। মনে রাখুন, `-p` password বোঝায়; SSH port-এর জন্য `--port` ব্যবহার করুন।

সব accepted option ও example [CLI.md](CLI.md)-এ আছে।

### option.cfg পড়া যায় না, কোড 21

`option.cfg` যেন script চালানো user-এর readable ordinary file হয় তা নিশ্চিত করুন। এমন file-এর readable symbolic link-ও গ্রহণযোগ্য।

অনুপস্থিত file ও unreadable file আলাদা পরিস্থিতি। File থাকলেও পড়া না গেলে script default setting নিয়ে চলতে থাকে না।

### নির্ভরতা অনুপস্থিত, কোড 30

প্রধান utility-গুলো পরীক্ষা করুন:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

`UseNetFolder=true`-সহ batch operation-এর জন্য `findmnt`-ও লাগে। Monthly archiving-এর দিনে `zip`, `unzip` ও GNU `mv` আবশ্যক। BackUP Master থেকে console command copy করতে `--wrap=0` support-সহ GNU `base64` দরকার।

**শুধু utility install থাকাই যথেষ্ট নয়।** Installed OpenSSH-কে ব্যবহৃত option ও `scp -O` support করতে হবে; GNU `timeout`-কে `--signal` ও `--kill-after` support করতে হবে।

সম্পূর্ণ dependency list ও installation command [INSTALL.md](INSTALL.md#নির্ভরতা)-এ আছে।

### মেনু খোলে না, কোড 31

Menu, editor ও master-এর terminal এবং working `stty` utility প্রয়োজন। Pipe দিয়ে অথবা standard input/output redirect করে এগুলো start করবেন না।

Message terminal খুব ছোট বললে window বড় করুন। Main screen-এর width অন্তত 46 column, built-in instruction-এর জন্য 80। Editor ও master-এর long list arrow key দিয়ে scroll করে; পুরো form একসঙ্গে screen-এ ধরতে হয় না।

Interface control [INTERACTIVE.md](INTERACTIVE.md)-এ বর্ণিত।

<br />

## ডিভাইস তালিকা লোড হয় না

### devicelist.cfg ফাইল, কোড 22 ও 23

File location ও access পরীক্ষা করুন। যেই directory থেকে script start করুন না কেন, `devicelist.cfg`-কে `mikrotik-backup.sh`-এর পাশে থাকতে হবে।

Field actual TAB character দিয়ে separated, space দিয়ে নয়। Device-এর name, address, login, password ও valid SSH port থাকতে হবে। Corresponding entry field empty হলে shared credential `option.cfg` থেকে আসতে পারে।

Invalid entry warning-সহ skip হয়। কোনো eligible device না থাকলে backup করার কিছু নেই এবং script list error দিয়ে exit করে।

Duplicate connection এবং same name-এর different device-ও পরীক্ষা করুন। File format, credential inheritance ও duplicate-handling rule [DEVICES.md](DEVICES.md)-এ আছে।

### Oxidized থেকে ইমপোর্ট, কোড 24 ও 25

Code `24` মানে `OxidizedHome`-এর `config` বা `router.db` file পড়া যায়নি। Code `25` তাদের content নিয়ে: unsupported schema, invalid data অথবা eligible MikroTik device না থাকা।

Path, উভয় file-এর access, `csv` source, delimiter, column map এবং `routeros` model definition পরীক্ষা করুন। Data নির্দিষ্টভাবে `<OxidizedHome>/router.db` থেকে পড়া হয়; Oxidized-এর `source.csv.file` setting এই path বদলায় না।

`IgnoreOxiAccess=true` হলে script previous eligible list দিয়ে চলতে পারে। তবু import failure run result-এ থাকে। `false` হলে old list ওই run-এ ব্যবহার হয় না।

Import configuration [DEVICES.md](DEVICES.md#oxidized-থেকে-ইমপোর্ট)-এ বর্ণিত।

<br />

## স্টোরেজ ও লকিং

### লক ব্যস্ত, কোড 32

অন্য job একই backup directory ব্যবহার করছে কি না দেখুন। একই user-এর run-এর ক্ষেত্রে batch backup একই `BackupRoot` ব্যবহার করা অন্য যেকোনো backup-এর সঙ্গে conflict করে। একই device-এর দুইটি single-device run-ও ওই storage-এ একই সময়ে চলতে পারে না।

Active job শেষ হওয়া পর্যন্ত অপেক্ষা করে script আবার চালান।

**Storage “release” করতে lock file delete করবেন না।** Script শেষ হলেও সেগুলো থেকে যায়; lock process নিজে ধরে রাখে। `/tmp/mikrotik-backup-${UID}/`-এ file থাকলেই lock busy—এমন নয়।

### ডিরেক্টরিতে প্রবেশাধিকার নেই

`BackupRoot` path, user permission, free space এবং storage device নিজে available কি না দেখুন। Relative path script directory থেকে resolve হয়। Filesystem root `/` backup storage হিসেবে ব্যবহার করা যায় না।

Script আগে root হিসেবে এবং এখন **bsmt** হিসেবে চললে old directory ও file-এ ওই user-এর access নাও থাকতে পারে। Permission preparation [INSTALL.md](INSTALL.md#স্ক্রিপ্ট-স্বয়ংক্রিয়ভাবে-চালানো)-এ আছে।

`UseNetFolder=true`-সহ batch operation-এর separate mount দরকার। পরীক্ষা করুন:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

প্রথম path নিজেরটি দিয়ে বদলান। উভয় path একই mount entry-র হলে root filesystem-এর সাধারণ directory `UseNetFolder=true` পূরণ করে না। Script নিজে storage mount করে না।

Code `64` মানে shared storage available থাকলেও device directory বা তার archive ব্যর্থ হয়েছে। অন্য device processing চলতে পারে। Code `65` মানে shared storage হারিয়েছে বা state invalid হয়েছে; বাকি batch processing থামে।

Network-storage rule [OPTIONS.md](OPTIONS.md#network-storage)-এ আছে।

<br />

## ডিভাইস নিয়ে কাজের ত্রুটি

### SSH ও ফাইল ট্রান্সফার, কোড 40–43

Device address, SSH service availability, login, password ও port পরীক্ষা করুন। `devicelist.cfg`-এ port না থাকলে setting-এর `SshPort` ব্যবহার হয়; default `22`।

RouterOS user-এর selected operation—configuration export, backup তৈরি ও retrieve, temporary file delete এবং enabled cleanup operation—করার permission থাকতে হবে।

**এখানে একটি সূক্ষ্ম বিষয় আছে!!!** আপনার সাধারণ SSH command দিয়ে successful connection হওয়ার অর্থ script একই setting ব্যবহার করে না। এটি password দিয়ে কাজ করে এবং SSH agent, key বা normal `~/.ssh/config` ব্যবহার করে না। File `scp -O` দিয়ে retrieve হয়।

Code `40` connection বা SSH/SCP transport, `41` authentication, `42` RouterOS command বা response, এবং `43` file transfer বোঝায়। Connection setting [SECURITY.md](SECURITY.md#routeros-এ-সংযোগ)-এ আরও ব্যাখ্যা করা হয়েছে।

### নামকরণের ত্রুটি, কোড 50 ও 52

Code `50` মানে final device name invalid। Selected name source ও parentheses-এর content পরীক্ষা করুন: current version-এ প্রথম completed, nonempty parenthesized fragment name হিসেবে ব্যবহার হয়।

Processing-এর পরে name 1 থেকে 32 character হতে হবে। Overlong name truncate করা হয় না। `CON` ও `NUL`-এর মতো reserved name-ও rejected।

Code `52` মানে final name একই run-এর অন্য device-এর duplicate। Comparison case-insensitive: `Router-A` ও `router-a` identical বলে গণ্য।

Name source ও processing rule [DEVICES.md](DEVICES.md#device-names)-এ আছে।

### ব্যাকআপ যাচাই ব্যর্থ, কোড 51 ও 53

Code `51` `.rsc`-এর, আর code `53` `.backup`-এর। Retrieved file validation fail করেছে—যেমন empty অথবা device-এর file-এর সঙ্গে size মেলেনি।

Error কোন stage-এ হয়েছে এবং host ও RouterOS—উভয়ের free space ও permission দেখুন। Failed attempt-এর পরে script 2 second পর আরও একবার চেষ্টা করে। দুই format-এর attempt আলাদা, তাই একটি file সফলভাবে retrieve হলেও অন্যটি fail করতে পারে।

Backup সফলভাবে retrieve করার পরে temporary RouterOS file delete করতে না পারার warning নিজে থেকে local backup damaged বোঝায় না।

<br />

## নতুন ব্যাকআপ নেই, কিন্তু কোনো ত্রুটিও নেই

প্রথমে `UseIncremental` দেখুন। Comparison enabled থাকলে new backup duplicate হিসেবে delete হতে পারে এবং previous-টি থেকে যায়। `.rsc`-এর content standard header-এর date বাদ দিয়ে compare হয়; `.backup`-এর শুধু file size compare হয়।

`UseIncremental=false` হলে new valid backup এই comparison ছাড়াই রাখা হয়।

আরও মনে রাখুন: এক মিনিটের মধ্যে same device থেকে same directory-তে দুই run একই filename ব্যবহার করে। দ্বিতীয় run-এর জন্য আলাদা version তৈরি হয় না।

সেদিন monthly archiving চললে ZIP-ও দেখুন। Single-device CLI mode-এ new backup-ও তার ভেতরে থাকতে পারে। Full retention rule [BACKUPS.md](BACKUPS.md)-এ আছে।

<br />

<a id="archive-problems"></a>
## মাসিক আর্কাইভ দেখা যায়নি

`MonthlyArchive` value এবং host local time-এর run date পরীক্ষা করুন। `false` archiving disabled করে; `true` বা `1` first day বেছে নেয়, আর `2` থেকে `28` ওই day of month বেছে নেয়।

Selected day-তে run time গুরুত্বপূর্ণ নয়। দিনটি missed হলে later ordinary run catch up করে না। BackUP Master দিয়ে monthly archiving হয় না।

Archive করার কিছু না থাকলে empty ZIP তৈরি হয় না।

### ZIP কোথায় পাবেন

Archive name previous calendar day অনুযায়ী হয়। যেমন, 1 অক্টোবর 2026-এর run `30.09.2026.zip` তৈরি করে:

| Mode | অবস্থান |
|---|---|
| Batch | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| CLI দিয়ে single-device | `<BackupRoot>/30.09.2026.zip` |

`archive/` directory name lowercase। একই দিনে আরেকটি run একই ZIP update করে।

### আর্কাইভিং ত্রুটিতে শেষ হয়েছে

Code `70` ও `71`-এর জন্য device log, archive directory access, free space ও existing ZIP-এর state দেখুন। Storage এবং local `/tmp`—উভয় জায়গায় space প্রয়োজন।

Local disk-এ `archive/` directory script user-এর owned এবং mode `0700` হতে হবে। Verified network storage ও `UseNetFolder=true`-সহ batch mode-এ NAS-এর assigned different owner বা permission একাই failure-এর কারণ নয়। Archiving-এর storage error code `64` বা `65`-ও দিতে পারে।

Actual path বসিয়ে existing archive পরীক্ষা করুন:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Verified ZIP save না হওয়া পর্যন্ত source file remove হয় না। Archive save হলেও কিছু source file remove করা না গেলে ZIP ও undeleted file—দুটিই থাকে। আগে থেকে থাকা damaged archive automatically new one দিয়ে replace হয় না।

**Archive content পরীক্ষা না করে remaining backup বা log delete করবেন না।** Archiving sequence [BACKUPS.md](BACKUPS.md#monthly-archive)-এ আছে।

<br />

## লগ বা অন-স্ক্রিন আউটপুট নেই

`LogLevel=0` এবং কোনো error না থাকলে new log তৈরি হয় না। অন্যথায় selected `BackupRoot`, `MainLogPath` ও write permission দেখুন।

Empty `MainLogPath=` `main.log`-কে `BackupRoot`-এ রাখে। Separate directory specified হলে সেটি আগে থেকে থাকতে এবং script user-এর accessible হতে হবে। এই setting device log সরায় না।

Monthly archiving-এর পরে device-এর previous history ZIP-এ থাকে। Subsequent work backup-এর পাশের new log-এ লেখা হয়।

Scheduler থেকে অথবা output redirect করে script চললে indicator ও colored mark-সহ on-screen log থাকে না। এতে file logging disabled হয় না।

Log-writing error backup নিজেকে থামায় না, তবে warning হিসেবে run result-এ দেখা যায়। বিস্তারিত [LOGGING.md](LOGGING.md)-এ।

<br />

<a id="language-problems"></a>
## অনুবাদ প্রয়োগ হয়নি

Selected language ও file location পরীক্ষা করুন। যেমন, `Language=de`-এর জন্য `mikrotik-backup.sh`-এর পাশে `de.lang` নামের readable ordinary file দরকার, `lang/` directory-তে নয়। Symbolic link translation file হিসেবে ব্যবহার হয় না।

`Language=auto` হলে operating-system environment language নির্ধারণ করে। একটি run-এর জন্য explicitly select করা যায়, যেমন help দেখতে:

```bash
mikrotik-backup.sh --language=de --help
```

Untranslated message English-এ দেখায়। File-এর malformed line skip হয়। `ru.lang` ও `en.lang` built-in translation replace করে না।

Line format, key name ও translation loading rule [LOCALIZATION.md](LOCALIZATION.md)-এ বর্ণিত।

<br />

## কোনো সেটিং কার্যকর হয় না

Setting name, accepted value ও `option.cfg`-এর duplicate entry পরীক্ষা করুন। Setting repeated হলে last usable value জয়ী হয়। Key name case-insensitive, কিন্তু hyphen ও underscore interchangeable নয়।

CLI option file-এর corresponding value override করে। সাধারণ single-device ও batch run-এর order:

**Built-in value** → **ব্যবহারযোগ্য option.cfg line** → **CLI**

BackUP Master form অন্যভাবে populate করে: ordinary field options file নয়, built-in value ও CLI থেকে আসে। `UseIncremental` ব্যতিক্রম। Master দিয়ে backup execute করলে file-এর logging setting-ও মানা হয়।

Setting পড়ার rule [OPTIONS.md](OPTIONS.md)-এ এবং master behavior [INTERACTIVE.md](INTERACTIVE.md)-এ আছে।

<br />

<a id="result-codes"></a>
## ফলাফল কোড

| Code | অর্থ |
|---:|---|
| `0` | কোনো recorded error বা warning ছাড়া success |
| `1` | Warning-সহ complete, কোনো recorded execution error নেই |
| `12` | CLI option, value বা combination-এ error |
| `21` | `option.cfg` পড়া যায়নি |
| `22` | Device list পাওয়া যায়নি |
| `23` | Invalid device list অথবা eligible entry নেই |
| `24` | Oxidized file পড়া যায়নি |
| `25` | Unsupported schema বা invalid Oxidized data; eligible MikroTik entry নেই |
| `30` | Required utility অনুপস্থিত অথবা required capability support করে না |
| `31` | Terminal unavailable, `stty` error অথবা window size যথেষ্ট নয় |
| `32` | Required lock অন্য run ধরে রেখেছে |
| `33` | Single-device run-এর invalid storage path বা object |
| `34` | Single-device run directory create বা prepare করা যায়নি |
| `35` | Lock-সহ local service object access বা validation error |
| `36` | File retrieval-এর আগে single-device run storage availability check fail করেছে |
| `37` | Service file লেখা বা replace করা যায়নি |
| `40` | SSH/SCP connection বা transport error |
| `41` | Device authentication error |
| `42` | RouterOS command বা expected-response error |
| `43` | SCP file-transfer error |
| `50` | Invalid final device name |
| `51` | `.rsc` file validation fail করেছে |
| `52` | Duplicate final device name |
| `53` | `.backup` file validation fail করেছে |
| `61` | Batch run prepare করার সময় shared storage unavailable |
| `62` | `UseNetFolder=true`-এর separate mount confirm বা activate করা যায়নি |
| `63` | Shared batch-backup directory prepare বা validate করতে error |
| `64` | Shared storage available থাকা অবস্থায় device বা archive storage error |
| `65` | Run-এর সময় shared storage হারিয়েছে বা invalid হয়েছে; batch processing থামে |
| `70` | Archive create বা update করার error |
| `71` | ZIP বা target archive object validation fail করেছে |
| `80` | `C.UTF-8` capability-সহ internal error বা unmet system requirement |
| `81` | Internal MikroTik driver error |
| `129` | HUP signal দিয়ে terminated |
| `130` | INT signal দিয়ে terminated, যেমন Ctrl+C চাপলে |
| `143` | TERM signal দিয়ে terminated |

চূড়ান্ত code প্রথম recorded execution error দেখায়। Warning `1` প্রথম এমন error দিয়ে replaced হয়, আর পরের success সেটি clear করে না। তাই final code log-এর শেষ message-এর সঙ্গে নাও মিলতে পারে।

File-retrieval retry সফল হলে first attempt-এর error log-এ থাকলেও stage `[OK]` দিয়ে শেষ হতে পারে। Batch run-এর nonzero final code মানে প্রতিটি device fail করেছে—এমনও নয়; প্রতিটি result আলাদাভাবে দেখুন।

Code `80`-এর ক্ষেত্রে system requirement লক্ষ্য করুন: GNU Bash 4.4 বা later এবং working `C.UTF-8` locale। বিস্তারিত [INSTALL.md](INSTALL.md#হোস্টের-প্রয়োজনীয়তা)-এ।

<br />

## সহায়তা প্রয়োজন হলে

Script version, operating system ও Bash version, script কীভাবে start হয়েছে, exit code এবং relevant log excerpt দিন। একটি device-এর সমস্যা হলে তার device log দিন; run preparation-এর error হলে `main.log` দিয়ে শুরু করুন।

**Real password বা complete working settings file পাঠাবেন না।** Log, screenshot বা command পাঠানোর আগে sensitive data আছে কি না দেখুন। Password-protection consideration [SECURITY.md](SECURITY.md)-এ বর্ণিত।

লেখকের সঙ্গে যোগাযোগের তথ্য [পণ্যের বর্ণনা](../README_BN.md#লেখকের-সঙ্গে-যোগাযোগ)-এ আছে।
