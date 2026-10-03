# ব্যাকআপ ও আর্কাইভ

[সূচিপত্র](../README_BN.md)

## ব্যাকআপ ফরম্যাট

Script device configuration text হিসেবে save করতে, binary backup তৈরি করতে অথবা উভয় format-ই retrieve করতে পারে।
`option.cfg`-এর `backup_type` parameter format নির্বাচন করে:

| Value | যা save হয় |
|---|---|
| `configuration` | `.rsc` file-এ RouterOS configuration |
| `binary` | `.backup` file-এ binary backup |
| `both` | উভয় format: প্রথমে `.rsc`, তারপর `.backup` |

Default হলো `both`। Options file, Configuration Editor, BackUP Master অথবা `--backup-type` দিয়ে এটি বদলানো যায়।

### টেক্সট কনফিগারেশন: .rsc

`export_format` parameter export format নির্বাচন করে। Valid value হলো `compact`, `terse` ও `verbose`; default `compact`।

Export-এ password-সহ sensitive data থাকবে কি না `show_sensitive` parameter নির্ধারণ করে। এটি default-ভাবে enabled।
নিষ্ক্রিয় করতে `option.cfg`-এ যোগ করুন:

```ini
show_sensitive=false
```

### বাইনারি ব্যাকআপ: .backup

Binary backup এনক্রিপ্ট করা যায়। প্রয়োজনীয় password `encrypt`-এ দিন:

```ini
encrypt=MySuperPassword
```

Empty `encrypt=` value হলে file encryption ছাড়াই save হয়। এটিই default।

*(বি.দ্র.: AES-SHA256 encryption শুধু `.backup`-এ প্রযোজ্য। এটি text configuration, log বা ZIP archive encrypt করে না।)*

Default-ভাবে binary backup তৈরির আগে script RouterOS DNS cache ও console history clear করে। এই operation না চাইলে corresponding parameter disabled করুন:

```ini
clear_dns_cache=false
clear_console_history=false
```

শুধু text configuration retrieve করলে এই cleanup operation করা হয় না।

<br />

## ফাইলের নাম ও অবস্থান

Default-ভাবে backup script-এর পাশের `backups` directory-তে থাকে। Options file-এর `BackupRoot` দিয়ে অন্য directory নির্ধারণ করুন।

Single-device run-এ file সরাসরি সেই directory-তে রাখা হয়:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Batch mode-এ প্রতিটি device-এর নিজস্ব subdirectory থাকে:

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

Backup filename-এ device name এবং script চালানো host-এর clock অনুযায়ী date ও time থাকে। একই backup operation-এর উভয় format একই timestamp ব্যবহার করে।
Device name তৈরির নিয়ম [DEVICES.md](DEVICES.md#device-names)-এ বর্ণিত।

**মনোযোগ দিন!!!**
এক মিনিটের মধ্যে একই device একই directory-তে দুইবার backup করলে filename একই হয়। সেই name-এর file replace হয়; দ্বিতীয় run-এর জন্য আলাদা version তৈরি হয় না।

Storage-এর জন্য network directory-ও ব্যবহার করা যায়। Batch mode-এ storage পরীক্ষা করতে `UseNetFolder=true` সেট করুন। Directory preparation [INSTALL.md](INSTALL.md)-এ এবং path setting [OPTIONS.md](OPTIONS.md#network-storage)-এ বর্ণিত।

Log-এর location ও content [LOGGING.md](LOGGING.md)-এ বিস্তারিত ব্যাখ্যা করা হয়েছে।

<br />

## ইনক্রিমেন্টাল ব্যাকআপ

পরিবর্তন শনাক্ত না হলে এই feature duplicate backup রেখে দেওয়া এড়ায়। `UseIncremental` parameter এটি নিয়ন্ত্রণ করে:

| Value | Backup যেভাবে রাখা হয় |
|---|---|
| `true` (default) | নতুন backup duplicate হিসেবে শনাক্ত হলে সেটি delete হয় এবং previous backup থাকে |
| `false` | Previous backup-এর সঙ্গে compare না করে প্রতিটি নতুন valid backup রাখা হয় |

পরিবর্তন শনাক্ত হলে বা previous backup না থাকলে new file রাখা হয়। Comparison শেষ করা না গেলে file-টিও রাখা হয়, তবে script warning দেয়।

**কিন্তু এখানেই ফাঁদ!!!**
Format অনুযায়ী comparison আলাদা:

| Format | যা compare করা হয় |
|---|---|
| `.rsc` | File content। Standard RouterOS header-এর date ও time উপেক্ষা করা হয় |
| `.backup` | শুধু byte-এ file size |

তাই একই size-এর দুইটি binary file content আলাদা হলেও duplicate হিসেবে ধরা হয়। Retention setting বেছে নেওয়ার সময় এটি বিবেচনা করুন।

Script একই device ও format-এর সবচেয়ে সাম্প্রতিক আগের backup-এর সঙ্গে সেই device directory-তে compare করে। ZIP-এ pack করা backup comparison-এ অংশ নেয় না।

Script আলাদা change file নয়, সাধারণ `.rsc` ও `.backup` file রাখে। `UseIncremental` disabled করলেও backup retrieval ও verification, logging বা monthly archiving disabled হয় না।

<br />

<a id="monthly-archive"></a>
## মাসিক আর্কাইভ

Feature-টি default-ভাবে disabled। জমা হওয়া backup ও log কোন দিনে archive হবে তা `option.cfg`-এর `MonthlyArchive` দিয়ে বেছে নিন:

| Value | আচরণ |
|---|---|
| `false` (default) | Archiving disabled |
| `true` বা `1` | মাসের প্রথম দিনে archiving চলে |
| `2` থেকে `28` | মাসের specified day-তে archiving চলে |

Selected day-র মধ্যে run-এর time গুরুত্বপূর্ণ নয়। [INSTALL.md](INSTALL.md#স্ক্রিপ্ট-স্বয়ংক্রিয়ভাবে-চালানো)-এ বর্ণিতভাবে schedule আলাদাভাবে configure করুন।

### আর্কাইভে যা যায়

Batch mode-এ সেই দিনে কাজের order বদলে যায়: script প্রথমে device-এর accumulated file একটি ZIP-এ collect করে, তারপর new backup তৈরি করে। Current run-এর তৈরি backup archive-এর বাইরে থাকে।

Archive-এ device directory-র সরাসরি ভেতরের regular file যায়, সম্পূর্ণ cumulative device log-সহ। এটি শুধু `.rsc` ও `.backup`-এ সীমাবদ্ধ নয়: directory-তে রাখা অন্য regular file-ও archive হতে পারে।

Subdirectory, symbolic link, current run-এর service object এবং script-এর আগে তৈরি ZIP আবার pack করা হয় না। **Main log `main.log` archive করা হয় না।**

সম্পূর্ণ ZIP verify ও save হওয়ার পরে তাতে থাকা source file device directory থেকে delete করা হয়। Archive করার কিছু না থাকলে empty ZIP তৈরি হয় না।

### আর্কাইভের নাম ও অবস্থান

ZIP-এর নাম আগের calendar day অনুযায়ী `DD.MM.YYYY.zip` format-এ হয়। যেমন, 1 অক্টোবর 2026-এর run `30.09.2026.zip` এবং 15 অক্টোবরের run `14.10.2026.zip` তৈরি করে।

| মোড | আর্কাইভের অবস্থান |
|---|---|
| ব্যাচ | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| একক-ডিভাইস CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

একই দিনে আবার run করলে একই name-এর archive update হয়।

### একক-ডিভাইস মোড ও BackUP Master

Single-device CLI run-এ order উল্টো: প্রথমে backup চলে, তারপর archiving। তাই current run-এর new backup-ও ZIP-এ যেতে পারে।

এই mode-এ `BackupRoot`-এর সরাসরি ভেতরের `.rsc`, `.backup` ও `.log` file archive হয়, `main.log` ছাড়া। একাধিক device-এর single-device run-এর result একই directory ব্যবহার করলে সেগুলোর file একই archive-এ যায়।

BackUP Master ব্যবহার করলে monthly archiving চলে না।

### কোনো রান বাদ পড়লে

Selected day-তে script না চললে missed archiving attempt পরে পূরণ করা হয় না। পরবর্তী attempt হয় পরের মাসের নির্ধারিত দিনে।

জমা হওয়া সব file সেই একটিমাত্র next archive-এ যায়, সেগুলো দুই, তিন বা আরও বেশি মাসের হলেও। Missed month-এর জন্য আলাদা ZIP তৈরি হয় না।

### আর্কাইভ ব্যর্থ হলে

Verified ZIP save না হওয়া পর্যন্ত source file delete হয় না। আগে থেকে থাকা damaged archive-ও নতুনটি দিয়ে overwrite করা হয় না।

ZIP save হয়ে গেলেও কিছু source file delete করা না গেলে completed archive যথাস্থানে থাকে এবং undeleted file-ও থাকে। Error-এর কারণ log-এ দেখুন।

*(বি.দ্র.: Backup NAS-এ থাকলেও archive local `/tmp` directory-তে build হয়। তাই storage-এর বাইরেও free space প্রয়োজন।)*

<br />

## ব্যাকআপ ব্যর্থ হলে

File retrieve করার attempt ব্যর্থ হলে script 2 second পরে আরও একবার চেষ্টা করে। `.rsc` ও `.backup`-এর retry আলাদা।

এক format retrieve করার সাধারণ error অন্য format retrieve করার attempt cancel করে না। একটি device unavailable হলে script বাকি device নিয়ে চলে। Shared storage হারিয়ে গেলে batch processing থামে।

Error message ও result code-এর ব্যাখ্যা [TROUBLESHOOTING.md](TROUBLESHOOTING.md)-এ আছে।

<br />

## সংরক্ষণ ও পুনরুদ্ধার

পুরোনো ZIP file age বা count অনুযায়ী delete হয় না। Retention period ও external rotation policy আপনি নির্ধারণ করবেন।

Script backup তৈরি করে, কিন্তু RouterOS restore করে না। উপযুক্ত device-এ restoration আলাদাভাবে test করুন।

*(বি.দ্র.: Backup ও archive-এ password এবং অন্য confidential data থাকতে পারে। [SECURITY.md](SECURITY.md)-এ বর্ণিতভাবে storage access সীমিত করুন।)*
