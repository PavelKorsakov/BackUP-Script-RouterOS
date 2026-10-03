# নিরাপত্তা

[সূচিপত্র](../README_BN.md)

## অ্যাকাউন্ট

Script-এর **root** privilege প্রয়োজন নেই। Ordinary user-এর শুধু settings file-এ access এবং selected storage ও log-এ write permission দরকার।

Dedicated **bsmt** user তৈরি এবং সেই account-এ script চালানোর configuration [INSTALL.md](INSTALL.md#স্ক্রিপ্ট-স্বয়ংক্রিয়ভাবে-চালানো)-এ বর্ণিত।

RouterOS device-এ dedicated backup user তৈরি এবং তার login-কে script চালানো host-এর IP address-এ সীমাবদ্ধ রাখাও উপযুক্ত। Account-এর permission selected operation—configuration retrieve, backup তৈরি ও download, temporary file delete এবং enabled cleanup operation—করতে দিতে হবে।

<br />

## RouterOS-এ সংযোগ

Script SSH-এর মাধ্যমে password authentication ব্যবহার করে connect করে। SSH key ও agent ব্যবহার হয় না। File legacy SCP protocol, অর্থাৎ `scp -O`, দিয়ে retrieve হয়।

Script নিজের connection setting ব্যবহার করে। Client `-F /dev/null` দিয়ে start হওয়ায় user-এর `~/.ssh/config` বা system SSH configuration পড়ে না। Agent, X11 ও port forwarding disabled।

**অনুগ্রহ করে লক্ষ্য করুন!!! Server host-key verification নিষ্ক্রিয়।**

বর্তমান profile-এ এই setting ব্যবহার করা হয়:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

সাধারণ `known_hosts` file পড়া বা পরিবর্তন করা হয় না। তাই response দেওয়া server প্রত্যাশিত device, নাকি impostor—script তা verify করে না। Router-এ network access ব্যবস্থা করার সময় এটি বিবেচনা করুন।

<br />

<a id="secrets"></a>
## স্ক্রিপ্ট চালুর সময় পাসওয়ার্ড

`--password` বা `-p=` দিয়ে দেওয়া password launch command-এর অংশ হয়। এটি process argument-এ দেখা যেতে পারে এবং shell history-তে save হতে পারে। `--encrypt` দিয়ে দেওয়া encryption password-এর ক্ষেত্রেও একই কথা প্রযোজ্য।

### BackUP Master দিয়ে পাসওয়ার্ড দেওয়া

SSH password command line-এ না রাখতে BackUP Master চালু করুন:

```bash
mikrotik-backup.sh -b
```

Form-এ device credential পূরণ করে required action বেছে নিন। উভয় password asterisk হিসেবে display হয় এবং form-এ দেওয়া value shell command history-তে যায় না।

Connect করার সময় script নিজে SSH password `sshpass`-কে file descriptor (`-d`) দিয়ে দেয়; `sshpass -p` argument বা `SSHPASS` environment variable দিয়ে নয়।

### .backup এনক্রিপশন পাসওয়ার্ড

Encryption password `ssh` child process-এ পাঠানো RouterOS command-এর মধ্যে থাকে। তাই host-এর এমন user যার process argument দেখার যথেষ্ট permission আছে, binary backup তৈরির সময় password-টি দেখতে পারে।

BackUP Master দিয়ে password enter করা বা `option.cfg`-এ রাখা—কোনোটিই password যেভাবে pass হয় তা বদলায় না। File encryption backup host-এর administrator-এর নিজের কাছ থেকে সুরক্ষা দেয় না।

### কনসোল কমান্ড কপি করা

BackUP Master-এর “Copy console command” action connection credential—এবং binary backup-এর encryption password set থাকলে সেটিও—থাকা command clipboard-এ পাঠায়।

Clipboard history ব্যবহার ও shell-এ command paste করার সময় এটি মনে রাখুন। Form-এ asterisk দিয়ে password mask হওয়ার অর্থ copied command-এও mask হওয়া নয়।

<br />

## সংবেদনশীল ডেটা থাকা ফাইল

| File | যা থাকতে পারে |
|---|---|
| `devicelist.cfg` | Plain text-এ device address, login ও SSH password |
| `option.cfg` | Shared `Login` ও `Password` value এবং `encrypt` encryption password |
| `.rsc` ও `.backup` | Device configuration, password ও অন্য sensitive data |
| Monthly ZIP | একই backup ও log একটি archive-এ collected |

Working settings file বা backup public repository বা publicly accessible directory-তে রাখবেন না।

### .rsc ফাইলে সংবেদনশীল ডেটা

Default-ভাবে `show_sensitive=true`, তাই text export-এ sensitive value থাকে। Disabled করতে `option.cfg`-এ সেট করুন:

```ini
show_sensitive=false
```

তারপরও file-টি আপনার device-এর configuration: address, network structure, comment এবং user-provided অন্য string file থেকে অদৃশ্য হয় না।

### বাইনারি ব্যাকআপ এনক্রিপশন

Default-ভাবে `encrypt` empty এবং `.backup` encryption ছাড়াই save হয়। Enable করতে options file বা corresponding BackUP Master field-এ password দিন:

```ini
encrypt=MySuperPassword
```

AES-SHA256 algorithm ব্যবহার হয়। এটি **শুধু `.backup` encrypt করে**, `.rsc`, `option.cfg`, device list, log বা ZIP নিজে নয়। তাই monthly archive-এর access ভেতরের file-এর মতোই সতর্কভাবে সীমিত করতে হবে।

<br />

## ফাইল ও স্টোরেজের অনুমতি

Script `umask 077` দিয়ে চলে। Script-এর তৈরি local storage directory mode `0700`, আর programmatically save করা `option.cfg` ও `devicelist.cfg` mode `0600` পায়।

Administrator-এর তৈরি existing storage directory-র owner ও permission automatically বদলায় না। Manual-ভাবে directory প্রস্তুত করলে access আপনাকেই configure করতে হবে।

Local monthly-archive directory `archive/`-এর mode `0700` এবং owner script চালানো user হতে হবে। Existing directory-তেও এই requirement প্রযোজ্য। Script-এর তৈরি local archive file mode `0600` পায়।

Batch mode-এ `UseNetFolder=true` দিয়ে verified network storage ব্যবহার করলে NAS server archive object-এর owner ও permission নির্ধারণ করতে পারে। শুধু local value থেকে difference-এর কারণে archiving থামে না। Operating system ও NAS দিয়ে network storage access configure করুন।

Directory প্রস্তুত ও **bsmt** user-কে access দেওয়ার example [INSTALL.md](INSTALL.md)-এ আছে।

*(বি.দ্র.: Script তার configuration, device list, translation ও ব্যবহৃত Oxidized setting data হিসেবে পড়ে; shell script হিসেবে execute করে না।)*

<br />

## ডিভাইসে করা পরিবর্তন

Default-ভাবে binary backup তৈরির আগে RouterOS DNS cache ও console history clear করা হয়। এই action না চাইলে `option.cfg`-এ disabled করুন:

```ini
clear_dns_cache=false
clear_console_history=false
```

Configuration Editor, BackUP Master অথবা corresponding CLI option দিয়েও একই feature disabled করা যায়। শুধু `.rsc` retrieve করলে এই cleanup operation করা হয় না।

<br />

## লগ ও ডায়াগনস্টিক তথ্য শেয়ার করা

Detailed level `LogLevel=3` processing stage সম্পর্কে information যোগ করে; password বা complete connection command output করে না।

Processed SSH diagnostic address, login, SSH password ও encryption password-এর exact known value mask করে। এতে backup content sanitize হয় না এবং arbitrary text থেকে প্রতিটি secret remove হবে—এমন guarantee নেই।

Unprocessed diagnostic থাকা temporary file-এ sensitive data থাকতে পারে। এগুলো mode `0600` দিয়ে তৈরি এবং normal cleanup-এ remove হয়।

অন্যকে log, screenshot বা command output পাঠানোর আগে content পরীক্ষা করুন। `devicelist.cfg`-এর complete output, process list অথবা clipboard content normal log-এ অনুপস্থিত data reveal করতে পারে।

Log entry সম্পর্কে [LOGGING.md](LOGGING.md) এবং error investigation-এর জন্য [TROUBLESHOOTING.md](TROUBLESHOOTING.md) দেখুন।

<br />

## একই সময়ের রান

একই user ও একই `BackupRoot`-এর run software locking ব্যবহার করে:

| Concurrent run | যা ঘটে |
|---|---|
| একটি batch run এবং আরেকটি batch বা single-device run | দ্বিতীয় run lock acquire করে না |
| একই device-এর দুইটি single-device run | দ্বিতীয় run lock acquire করে না |
| ভিন্ন device-এর single-device run | একই সময়ে চলতে পারে |

Lock busy হলে script code `32` দিয়ে exit করে। ভিন্ন storage root-এর একটি অন্যটির ভেতরে nested হলেও একক storage area হিসেবে coordinated হয় না।

Lock file `/tmp/mikrotik-backup-${UID}/`-এ রাখা হয় এবং script শেষ হওয়ার পরেও থেকে যায়। শুধু এগুলোর উপস্থিতি script এখনো চলছে—এমন অর্থ নয়।

**“Stale lock ছাড়াতে” এই file-গুলো delete করবেন না।** Lock file-এর অস্তিত্বের সঙ্গে নয়, process-এর open file descriptor-এর সঙ্গে যুক্ত। এই locking সরাসরি data modify করা কোনো unrelated program থেকে data-কে সুরক্ষা দেয় না।

<br />

## পুনরুদ্ধার পরীক্ষা

Script-এর checksum verify করা এবং backup file সফলভাবে retrieve করা restoration test-এর বিকল্প নয়।

Script নিজে RouterOS restore করে না। Backup suitable device-এ ব্যবহার করা যায় কি না আলাদাভাবে verify এবং কতদিন রাখা হবে তা ঠিক করতে হবে। আরও তথ্য [BACKUPS.md](BACKUPS.md)-এ।
