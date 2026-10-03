# ইন্টারঅ্যাক্টিভ ইন্টারফেস

[সূচিপত্র](../README_BN.md)

## প্রধান মেনু

Main menu দিয়ে script configure, backup তৈরি, device list প্রস্তুত অথবা built-in help খোলা যায়। খুলতে চালান:

```bash
mikrotik-backup.sh -i
```

| Item | যা খোলে বা করে |
|---|---|
| `1` | একটি device নিয়ে কাজের জন্য BackUP Master |
| `2` | Device list ব্যবহার করে batch backup |
| `3` | `option.cfg` তৈরি বা বদলানোর Configuration Editor |
| `4` | CLI option reference |
| `5` | Script ব্যবহারের instruction |
| `6` | Console-এ exit |

`devicelist.cfg`-এ অন্তত একটি eligible entry থাকলে item `2` দেখা যায়। List এখনো না থাকলে বা suitable device না থাকলে item-টি hidden থাকে। অন্য item-এর number বদলায় না।

Batch backup-এর পরে result display হয় এবং script console-এ ফিরিয়ে দেয়।

*(বি.দ্র.: Option ছাড়া script চালালে main menu খোলে না। `option.cfg` অনুপস্থিত বা usable setting না থাকলে Configuration Editor খোলে; prepared setting থাকলে script batch backup-এ যায়।)*

<br />

## নিয়ন্ত্রণ

**Up** ও **Down** arrow key দিয়ে item-এর মধ্যে চলুন এবং **Enter** দিয়ে item বেছে নিন। Action-এর পাশে number থাকলে corresponding number key দিয়েও বেছে নেওয়া যায়।

Editor ও master-এ selected field-এর description list-এর উপরে দেখা যায়। সব row terminal window-তে না ধরলে arrow key দিয়ে চলার সঙ্গে list scroll করে। Heading ও description visible থাকে এবং selected row window-র মধ্যে থাকে।

Save, execute ও exit action একই list-এর শেষে থাকে। Dimmed row selected setting-এ unavailable এবং navigation-এর সময় skip হয়।

Terminal ও `stty` utility আবশ্যক। Standard input ও standard output—দুটিকেই terminal-এ connected থাকতে হবে। Main screen-এর width অন্তত 46 column; built-in instruction-এর জন্য 80। Window ছোট হলে script error `31` report করে; window বড় করে আবার চালান।

<br />

## কনফিগারেশন এডিটর

Main menu-র item `3` দিয়ে অথবা সরাসরি খুলুন:

```bash
mikrotik-backup.sh -e
```

`option.cfg` প্রস্তুত থাকলে form আপনার setting দিয়ে filled হয়। File এখনো না থাকলে default value ব্যবহার হয়।

Editor দিয়ে language, device-list source, backup setting, storage, monthly archiving ও logging বেছে নেওয়া যায়। Setting ও accepted value [OPTIONS.md](OPTIONS.md)-এ বর্ণিত।

### সেটিং পরিবর্তন

Corresponding row-তে **Enter** চেপে Yes/No switch, backup type, export format ও log level বদলান। Path বা monthly-archiving day বেছে নিলে value-entry prompt খোলে।

“Use incremental backups” field (`UseIncremental`) backup type-এর ঠিক পরে থাকে। “Yes” comparison enable করে; “No” previous backup-এর সঙ্গে compare না করে প্রতিটি new valid backup রাখে।

Monthly archiving নিষ্ক্রিয় করতে `false` দিন; সক্রিয় করে দিন বেছে নিতে `1` থেকে `28` পর্যন্ত সংখ্যা দিন। Form disabled state-কে “No” এবং enabled state-কে মাসের selected day হিসেবে দেখায়।

Chosen mode-এ প্রযোজ্য নয় এমন field dimmed হয়। যেমন, শুধু `.rsc` selected হলে binary-backup encryption ও তার আগের cleanup operation unavailable; শুধু `.backup` selected হলে text-export setting unavailable। Mode switch করলে inapplicable setting default-এ reset হয়।

Encryption password asterisk হিসেবে enter ও display হয়।

### সংরক্ষণ ও বাতিল

প্রয়োজনীয় setting বেছে নিন → “Save”-এ যান → **Enter** চাপুন। Selected setting দিয়ে `option.cfg` তৈরি বা overwrite হয়।

Save না করা পর্যন্ত change শুধু memory-তে থাকে। “Cancel” existing file অপরিবর্তিত রাখে। কিছু বদলালে editor change discard করার confirmation চায়।

Main menu থেকে খোলা editor সেখানে ফিরে যায়। `-e` দিয়ে আলাদাভাবে চালানো editor বন্ধ করলে console-এ ফেরা হয়।

*(বি.দ্র.: `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` ও `Password` form-এ দেখা যায় না। এগুলোর setting ও preservation rule [OPTIONS.md](OPTIONS.md)-এ আছে।)*

### ভাষা নির্বাচন

Language row-তে **Enter** প্রতিবার next option নির্বাচন করে:

```text
auto → ru → en → শনাক্ত বাহ্যিক ভাষা alphabetical order-এ → auto
```

Preview-এর জন্য form language সঙ্গে সঙ্গে বদলায়। “Save” selected language `option.cfg`-এ লেখে; cancel করলে previous interface language ফিরে আসে। Startup-এ `--language` স্পষ্টভাবে দেওয়া হলে editor থেকে বেরোনোর পরে সেই option আবার effective হয়।

External translation connect করা [LOCALIZATION.md](LOCALIZATION.md)-এ বর্ণিত।

<br />

## BackUP Master

BackUP Master-এ একটি device-এর setting পূরণ, backup তৈরি, device list-এ save অথবা console থেকে চালানোর command প্রস্তুত করা যায়।

Main menu-র item `1` বেছে নিন অথবা চালান:

```bash
mikrotik-backup.sh -b
```

Configuration Editor-এর বিপরীতে master তার ordinary field `option.cfg` থেকে fill করে না। Value আসে built-in default ও CLI দিয়ে explicitly passed option থেকে। `UseIncremental` ব্যতিক্রম: এর value options file থেকে আসে, অথবা setting না থাকলে default `true`।

`devicelist.cfg`-এর existing entry-ও form-এ load হয় না। Chosen device-এর name, address, login ও password আপনাকেই পূরণ করতে হবে।

### BackUP Master-এর ফিল্ড

Field-গুলো নিচের order-এ দেখা যায়। এগুলো English interface-এর প্রকৃত name:

| Field | উদ্দেশ্য |
|---|---|
| Device name | RouterOS Identity retrieval disabled হলে device list ও backup-এ ব্যবহৃত name |
| IP address | Device IP address বা DNS name |
| User | RouterOS device user |
| Password | RouterOS device password |
| SSH port | Connection port; default `22` |
| Backup type | `.rsc` configuration, binary `.backup`, অথবা উভয় format |
| Use incremental backups | New backup previous-টির সঙ্গে compare করা, অথবা comparison ছাড়া রাখা |
| Export format | `compact`, `terse` অথবা `verbose` |
| Sensitive data | Text export-এ sensitive value অন্তর্ভুক্ত করা |
| Encryption password | Binary backup encrypt করা; empty value encryption disabled করে |
| Clear DNS cache | Binary backup তৈরির আগে DNS cache clear করা |
| Clear console history | Binary backup তৈরির আগে console history clear করা |
| Backup directory | File save হওয়ার directory |
| This is a network directory | `UseNetFolder` value; mount verification batch mode-এ প্রযোজ্য |
| Use RouterOS Identity | Form-এ enter করা name-এর বদলে device থেকে name retrieve করা |

Switch, backup type ও export format **Enter** দিয়ে বদলানো হয়; অন্য value তাদের field-এ enter করা হয়। উভয় password asterisk দিয়ে masked।

**অনুগ্রহ করে লক্ষ্য করুন!!!**
Text export-এ sensitive data, DNS-cache cleanup এবং binary backup-এর আগে console-history cleanup default-ভাবে enabled। Backup execute করার আগে প্রয়োজনীয় setting বেছে নিন।

Master-এ `MonthlyArchive`, `LogLevel` বা `MainLogPath`-এর field নেই। Master দিয়ে backup execute করলে monthly archiving disabled থাকে; logging setting `option.cfg` এবং run-এর জন্য passed CLI option থেকে আসে।

### 1. Execute backup

Address, login ও password পূরণ করুন; port ও backup setting পরীক্ষা করুন → “1. Execute backup” বেছে নিন।

RouterOS Identity retrieval enabled হলে backup name device থেকে নেওয়া হয়। Disabled হলে “Device name” field পূরণ করতেই হবে।

Single-device backup শুরু হয়। শেষ হলে result ও code display হয় এবং script console-এ ফিরিয়ে দেয়। Backup সফল বা ব্যর্থ—কোনো ক্ষেত্রেই master form-এ ফিরে আসে না।

File location ও retention rule [BACKUPS.md](BACKUPS.md)-এ; progress message [LOGGING.md](LOGGING.md)-এ আছে।

### 2. Save device to devicelist.cfg

Save করার জন্য device name, address, login, password ও SSH port আবশ্যক। সব required field পূরণ না হওয়া পর্যন্ত corresponding action unavailable থাকে।

Master file তৈরি, new entry যোগ অথবা same name-এর existing entry update করে। Entry conflict বা saving failure হলে previous list অপরিবর্তিত থাকে। Save-এর পরে form খোলা থাকে।

**শুধু device data `devicelist.cfg`-এ save হয়।** Form-এর backup setting `option.cfg`-এ লেখা হয় না এবং এই action backup শুরু করে না।

*(বি.দ্র.: Port `22` empty field হিসেবে save হয়। পরের batch run-এ এমন entry script setting-এর `SshPort` ব্যবহার করে। Nonstandard port explicitly লেখা হয়।)*

List format ও update rule [DEVICES.md](DEVICES.md)-এ বর্ণিত।

### 3. Copy console command

Master completed form থেকে launch command তৈরি করে clipboard-এ পাঠায়। কোনো backup শুরু হয় না এবং master console-এ ফিরে শেষ হয়।

Feature-টির জন্য `--wrap=0` support-সহ GNU `base64` এবং OSC 52 support করা terminal দরকার। Terminal multiplexer ব্যবহার করলে সেটিকেও command pass করতে হবে। Clipboard transfer unsupported হলে command screen-এ plain text হিসেবে print করা হয় না।

Built-in value-এর সঙ্গে মিলে যাওয়া parameter command থেকে বাদ পড়তে পারে। পরে command চালালে `option.cfg`-এর setting তখনও apply হয়, তাই result master দিয়ে সরাসরি backup execute করার চেয়ে আলাদা হতে পারে।

`UseIncremental` setting command-এ থাকে না: এর dedicated CLI option নেই। Copied command চালালে value `option.cfg` বা default থেকে আসে।

*(বি.দ্র.: Clipboard-এ দেওয়া command-এ password থাকে। Clipboard history ব্যবহার ও shell-এ command paste করার সময় এটি মনে রাখুন। বিস্তারিত [SECURITY.md](SECURITY.md)-এ।)*

### 0. Return to Main Menu

Master কীভাবে খোলা হয়েছে তার ওপর result নির্ভর করে:

| যেভাবে খোলা হয়েছে | যেখানে ফিরে যায় |
|---|---|
| `-i` দিয়ে main menu থেকে | Main menu |
| `-b` দিয়ে separate run হিসেবে | Console |

Unsaved form value discard হয়। `devicelist.cfg`-এ ইতিমধ্যে saved entry থেকে যায়।

<br />

## সহায়তা ও নির্দেশনা

Main menu-র item `4` command-line option reference খোলে, আর item `5` script ব্যবহারের brief instruction খোলে।

Text vertically fit না করলে page-এ ভাগ হয়। **PageUp / PageDown** দিয়ে চলুন; current page number screen-এ দেখা যায়।

Item `0` main menu-তে ফিরে যায়, আর item `6` script exit করে। Arrow key ও **Enter**, অথবা corresponding number key দিয়ে action বেছে নেওয়া যায়।

একই CLI help console থেকেও পাওয়া যায়:

```bash
mikrotik-backup.sh -h
```
