# লগিং

[সূচিপত্র](../README_BN.md)

## প্রধান লগ ও ডিভাইস লগ

Script সামগ্রিক অগ্রগতি main log `main.log`-এ record করে, আর প্রতিটি device-এর কাজের detail আলাদা device log-এ save করে।

`main.log`-এ device list কীভাবে প্রস্তুত হয়েছে, batch processing-এর progress এবং device polling-এর result দেখা যায়। নির্দিষ্ট device শনাক্ত হওয়ার আগের error-ও এখানে record হয়।

Device log-এ `.rsc` ও `.backup` file retrieve, retry, backup comparison এবং archiving-এর তথ্য থাকে। অর্থাৎ নির্দিষ্ট device backup করার সময় কী ঘটেছে জানতে সেই device-এর log দেখুন। এই detail `main.log`-এ duplicate হয় না।

<br />

## লগ কোথায় রাখা হয়

Default-ভাবে main log script-এর পাশের `backups` directory-তে থাকে। Device log তার backup-এর সঙ্গে থাকে:

| Log | অবস্থান |
|---|---|
| Main log | `<BackupRoot>/main.log` |
| Batch mode-এর device | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Single-device run-এর device | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

Batch mode-এ new entry একই device log-এ append হয়। Single-device backup-এর log name-এ ওই run-এর backup filename-এর একই date ও time থাকে।

### main.log-এর জন্য পৃথক ডিরেক্টরি

Main log backup থেকে আলাদা রাখতে চাইলে `option.cfg`-এর `MainLogPath` setting-এ directory দিন:

```ini
MainLogPath=/var/log/mikrotik-backup
```

তখন log `/var/log/mikrotik-backup/main.log`-এ লেখা হবে। Device log usual location-এই থাকবে।

Empty `MainLogPath=` current `BackupRoot` ব্যবহার করে। `MainLogPath=logs`-এর মতো relative path script-এর পাশের directory বোঝায়, backup storage-এর ভেতরের নয়।

*(বি.দ্র.: `MainLogPath` directory নির্দেশ করে, complete filename নয়। Directory আগে থেকেই থাকতে হবে এবং script চালানো user-এর writable হতে হবে।)*

<br />

## লগিং-এর বিস্তারিত স্তর

`LogLevel` setting কতটা information display ও record হবে তা নিয়ন্ত্রণ করে। Default value `2`:

| Value | Terminal-এ progress | Log file-এর entry |
|---|---|---|
| `0` | শুধু error | শুধু error |
| `1` | Main stage ও result | সংক্ষিপ্ত log |
| `2` | Main stage ও result | বিস্তারিত log |
| `3` | Main stage ও current suboperation | বিস্তারিত log |

**প্রতিটি level-এ error record হয়।** সংক্ষিপ্ত log-এ main stage ও result থাকে; detailed log-এ ওই stage-এর ভেতরের operation-ও record হয়।

`option.cfg` বা Configuration Editor দিয়ে level বদলাতে পারেন:

```ini
LogLevel=3
```

আগে থেকে configured batch backup-এর একটি run-এর জন্য বদলাতে CLI ব্যবহার করুন:

```bash
mikrotik-backup.sh --log-level=3
```

এতে options file-এর value বদলায় না। একইভাবে `--main-log-path` current run-এর main log location সেট করতে পারে।

BackUP Master-এ `LogLevel` বা `MainLogPath`-এর আলাদা field নেই। এটি current run-এ effective logging setting ব্যবহার করে।

<br />

## লগ এন্ট্রি দেখতে যেমন

Log সাধারণ text file। প্রতিটি entry-তে script চালানো host-এর clock অনুযায়ী date ও time থাকে। Color ও progress indicator file-এ লেখা হয় না।

`main.log`-এর example entry:

```text
[2026-10-01 01:00:00] [PID:12345] ডিভাইসগুলোর ব্যাচ প্রসেসিং
[2026-10-01 01:00:15] [PID:12345] [OK] ডিভাইসগুলোর ব্যাচ প্রসেসিং
```

Main log-এ process PID-ও থাকে। একই সময়ে চলা একাধিক script instance-এর entry আলাদা করতে এটি সাহায্য করে।

Device log-এ PID যোগ হয় না। Detailed log-এর অংশ:

```text
[2026-10-01 01:00:05] বাইনারি ব্যাকআপ নেওয়া হচ্ছে
[2026-10-01 01:00:06] [1] DNS cache পরিষ্কার করা হচ্ছে
[2026-10-01 01:00:07] [2] Console history পরিষ্কার করা হচ্ছে
[2026-10-01 01:00:12] [OK] বাইনারি ব্যাকআপ নেওয়া হচ্ছে
```

`[OK]` মানে operation সফলভাবে complete হয়েছে। Error `[ER]` দিয়ে mark করা হয় এবং code থাকে, যেমন `[53]`। Suboperation `[1]`, `[2]` ইত্যাদি দিয়ে numbered হয় এবং প্রতিটি main stage-এ আবার শুরু হয়।

ব্যর্থ attempt-এর পরে retry সফল হলে log-এ আগের error ও পরের successful result—দুটিই থাকে।

Log entry interface-এর একই language ব্যবহার করে; সেটি `Language` setting নির্বাচন করে। Language selection ও translation-এর বিস্তারিত [LOCALIZATION.md](LOCALIZATION.md)-এ দেখুন।

<br />

## টার্মিনাল আউটপুট

Manual run-এর সময় progress screen-এ দেখা যায়। Operation চলার সময় পাশে waiting indicator থাকে। শেষ হলে indicator সবুজ `[OK]` অথবা error code-সহ লাল `[ER]` হয়।

Level `1` ও `2` main stage দেখায়। Level `3`-এ current suboperation-ও stage-এর নিচে দেখা যায় এবং কাজের সঙ্গে বদলায়। Batch mode-এ display current device-ও শনাক্ত করে।

*(বি.দ্র.: Terminal ছাড়া—যেমন scheduler থেকে বা output redirect করে—script চললে এই on-screen output থাকে না। Selected level-এ file logging চলতে থাকে।)*

<br />

## লগ জমা হওয়া ও আর্কাইভ

প্রথম entry লেখা হলে log file তৈরি হয়। `LogLevel=0` এবং কোনো error না থাকলে new log file তৈরি হয় না, আর existing file অপরিবর্তিত থাকে।

Main log ও batch-mode device log প্রতিটি run-এ overwrite না হয়ে append হয়। পরপর run-এর মাঝে blank line থাকে।

`main.log` archive হয় না এবং age অনুযায়ী remove-ও হয় না। Rotation আপনাকে নিজে ব্যবস্থা করতে হবে।

Monthly archiving enabled হলে accumulated batch-mode device log সম্পূর্ণভাবে সেই device-এর backup-এর সঙ্গে ZIP-এ যায়। Archive successful-ভাবে save হওয়ার পরে archived log device directory থেকে remove হয়; archiving result ও পরের কাজ new log file-এ লেখা হয়।

একই ZIP আবার update হলে ভেতরের history replace না হয়ে extend হয়। Archive save না হলে previous log যথাস্থানে থাকে এবং error তাতেই record হয়।

Single-device CLI run-এর log shared directory-র backup-এর সঙ্গে archive হয়। উভয় mode-এর archiving [BACKUPS.md](BACKUPS.md#monthly-archive)-এ বর্ণিত।

<br />

## লগ লেখা না গেলে

Insufficient permission, unavailable directory অথবা অন্য log-writing error backup-কে থামায় না। Script warning record করে এবং সম্ভব হলে চলতে থাকে।

Unavailable `main.log` প্রতি run-এ একবার, আর unavailable device log ওই device processing-এর সময় একবার report হয়। Main log available থাকলে device-log write failure সেখানে record হয়।

অন্য error না থাকলে run code `1` দিয়ে exit করে—অর্থাৎ warning-সহ complete হয়েছে। এই warning backup operation-এর error replace করে না।

Result code ও error cause খোঁজার সহায়তার জন্য [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes) দেখুন।

*(বি.দ্র.: Detailed level `3` password বা complete connection command log করে না। Credential ও script file সুরক্ষার তথ্য [SECURITY.md](SECURITY.md)-এ দেখুন।)*
