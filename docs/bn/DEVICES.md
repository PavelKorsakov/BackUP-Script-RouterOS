# ডিভাইস তালিকা

[সূচিপত্র](../README_BN.md)

## ব্যাকআপের ডিভাইস: devicelist.cfg ফাইল

নাম থেকেই বোঝা যায়, `devicelist.cfg` batch backup-এর device এবং সেগুলোতে connect করার প্রয়োজনীয় data list করে।
File-টি সরাসরি `mikrotik-backup.sh`-এর পাশে রাখুন।
`devicelist.cfg` manual-ভাবে বা BackUP Master দিয়ে তৈরি করা যায়।
Oxidized একই server-এ চললে তৃতীয় option-টি কাজে লাগে। Options file-এ corresponding setting যোগ করার পরে script প্রতিটি run-এ Oxidized configuration file থেকে প্রয়োজনীয় data নিয়ে dynamically `devicelist.cfg` তৈরি করে।

<br />

## তালিকা তৈরি ও সম্পাদনা

BackUP Master দিয়ে list তৈরি করতে চালান:

```bash
mikrotik-backup.sh -b
```

Device name, address, login, password ও SSH port পূরণ করুন → **2. Save device to devicelist.cfg** নির্বাচন করুন।
BackUP Master প্রয়োজনীয় entry-সহ file তৈরি করে অথবা existing file-এ entry যোগ বা update করে।

তৈরি list সাধারণ text editor-এ edit করা যায়। BackUP Master existing entry form-এ load করে না।

*(বি.দ্র.: BackUP Master port `22` save করলে empty field লেখে। ওই entry-র batch backup script setting-এর `SshPort` ব্যবহার করে। Nonstandard port স্পষ্টভাবে লেখা হয়।)*

<br />

## ফাইল ফরম্যাট

প্রতিটি device আলাদা line-এ লিখুন। Field আলাদা করতে space নয়, **TAB character** ব্যবহার করুন। Field-এর order:

| অবস্থান | Field | উদ্দেশ্য |
|---|---|---|
| 1 | Name | Device name; আবশ্যক |
| 2 | Address | Device IP address বা DNS name; আবশ্যক |
| 3 | Login | RouterOS device user; বাদ দিলে `option.cfg`-এর `Login` থেকে inherited |
| 4 | Password | RouterOS device password; বাদ দিলে `option.cfg`-এর `Password` থেকে inherited |
| 5 | Port | `1` থেকে `65535` পর্যন্ত SSH port; বাদ দিলে `SshPort` থেকে inherited, যার default `22` |
| 6 | Device marker | `MikroTik`; খালি হতে পারে। Case-insensitive |

সপ্তম ও পরের field ব্যবহার হয় না। ভিন্ন device marker-এর entry skip করা হয়।

### তালিকার উদাহরণ

এই example-এ field-গুলো actual TAB character দিয়ে আলাদা:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

দ্বিতীয় line-এ port বাদ দেওয়া হয়েছে: password ও `MikroTik`-এর মাঝে দুইটি TAB character আছে। Address ও credential নিজেরটি দিয়ে বদলান।

### একই login, password ও port ব্যবহার

সব device একই credential ব্যবহার করলে `option.cfg`-এ একবার নির্ধারণ করুন:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

তখন `devicelist.cfg`-এ প্রতিটি device-এর শুধু name ও address লাগে:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Device-এর নিজস্ব entry-তে দেওয়া credential shared value-কে override করে।

*(বি.দ্র.: Device-list file-এ password থাকে। [SECURITY.md](SECURITY.md)-এ বর্ণিতভাবে access সীমিত করুন।)*

<br />

## তালিকা যেভাবে পড়া হয়

Blank line এবং প্রথম non-whitespace character `#` এমন line উপেক্ষা করা হয়। Comment আলাদা line-এ রাখুন; field-এর ভেতরের `#` তার value-এর অংশ।

Name, address, port ও marker-এর শুরুর ও শেষের space বাদ দেওয়া হয়। Login ও password space ও quotation mark-সহ হুবহু পড়া হয়। Windows line ending (CRLF)-এর file সমর্থিত।

কোনো line—অর্থাৎ device entry—required syntax ভাঙলে execution-এর সময় script সেটি skip করে এবং entry invalid বলে warning দেয়।

যদি কোনো কারণে line duplicate হয়—অর্থাৎ চারটি connection parameter (**address, login, password ও port**) সব মিলে যায়—script last entry-র data ব্যবহার করে device-টিতে শুধু একবার connect করে।
ভিন্ন connection-এর একই name থাকলে first usable entry ব্যবহার হয় এবং conflicting entry skip করা হয়।

<br />

<a id="device-names"></a>
## ডিভাইসের নাম

Name backup filename-এ এবং batch mode-এ device subdirectory-র নামে ব্যবহার হয়।
Name-এর source `option.cfg`-এর `UseIdentityName` setting নির্ধারণ করে:

| Value | Name source |
|---|---|
| `true` (default) | RouterOS device-এর নিজস্ব Identity value |
| `false` | `devicelist.cfg`-এর name, BackUP Master field, অথবা single-device CLI run-এর `--device-name` |

### বন্ধনীর মধ্যে নাম

মূল name-এ parentheses থাকলে script প্রথম complete, non-empty group-এর content ব্যবহার করে। এমন group না থাকলে পুরো name ব্যবহার করে।

| Original name | Backup name |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### অনুমোদিত অক্ষর

Final name-এ Cyrillic-সহ letter, digit, period, hyphen ও underscore থাকে। Space ও invalid character `_` দিয়ে বদলানো হয়। Repeated এবং leading/trailing underscore, leading period ও hyphen, এবং name-এর শেষে period বাদ দেওয়া হয়।

যেমন, `ЦОД Москва №1` হয়ে যায় `ЦОД_Москва_1`।

Final name-এর length **1 থেকে 32 character** হতে হবে। অতিরিক্ত দীর্ঘ name truncate করা হয় না; error ঘটায়। Reserved name `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` এবং `LPT1`–`LPT9` অনুমোদিত নয়।

Case নির্বিশেষে final name unique হতে হবে: `Router-A` ও `router-a` একই বলে গণ্য। সেই name-এর দ্বিতীয় device current run-এ skip করা হয়।

*(বি.দ্র.: Final name বদলালে device subdirectory-ও বদলায়। পুরোনো backup স্বয়ংক্রিয়ভাবে সরানো হয় না।)*

<br />

## Oxidized থেকে ইমপোর্ট

Oxidized-এ device list বজায় রাখলে script সেখান থেকে তা নিতে পারে। `option.cfg`-এ যোগ করুন:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

`OxidizedHome`-কে `config` ও `router.db` থাকা directory-তে সেট করুন। Script সেগুলো থেকে `devicelist.cfg` তৈরি করে। Oxidized file পরিবর্তন করে না।

*(বি.দ্র.: Import `devicelist.cfg` replace করে; file extend করে না। পরের successful Oxidized update-এ manual addition হারিয়ে যায়।)*

### সোর্স সেটিং

Oxidized configuration-কে one-character delimiter-সহ `csv` source ব্যবহার করতে হবে। `source.csv.map` column order নির্ধারণ করে; numbering zero থেকে শুরু:

| Map field | ব্যবহৃত value |
|---|---|
| `name` | Device name; required column |
| `ip` | Device address; বাদ দিলে `name` value ব্যবহার হয় |
| `username` | Login; বাদ দিলে `option.cfg`-এর shared `Login` ব্যবহার হয় |
| `password` | Password; বাদ দিলে `option.cfg`-এর shared `Password` ব্যবহার হয় |
| `port` | SSH port; বাদ দিলে `SshPort` ব্যবহার হয় |
| `model` | Device model; column না থাকলে root `model` parameter ব্যবহার হয় |

প্রথম match পর্যন্ত `model_map` rule apply হয়। শুধু final model `routeros` এমন device import হয়। `model` column থাকলে root parameter ওই column-এর empty value replace করে না।

Data সব সময় `<OxidizedHome>/router.db` থেকে পড়া হয়। Oxidized-এর `source.csv.file` parameter এই path বদলায় না।

### ইমপোর্ট ব্যর্থ হলে

Oxidized file unavailable হলে, format unsupported হলে অথবা suitable device না পাওয়া গেলে আগের `devicelist.cfg` রেখে দেওয়া হয়।

`IgnoreOxiAccess=true` হলে script previous usable list ব্যবহার করতে পারে। `false` হলে old list থেকে কোনো backup হয় না।

আগের list দিয়ে backup processing সফল হলেও import error run result-এ প্রভাব ফেলে।

List ও import error-এর বিস্তারিত [সমস্যা সমাধান](TROUBLESHOOTING.md)-এ দেখুন।
