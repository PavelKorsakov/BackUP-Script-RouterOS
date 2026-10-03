# সফটওয়্যার লোকালাইজেশন

[সূচিপত্র](../README_BN.md)

## ইন্টারফেস ও লগের ভাষা

Russian (`ru`) ও English (`en`) script-এর built-in। এগুলোর জন্য আলাদা translation file লাগে না। Version 2.3.1-এর সঙ্গে interface ও log-এর external translation হিসেবে `de.lang`, `es.lang`, `lv.lang`, `pl.lang` ও `uk.lang` ship হয়।

Documentation-এর language ও external runtime translation-এর availability স্বাধীন বিষয়। তাই distribution-এ সংশ্লিষ্ট `.lang` না থাকলেও সেই language-এ documentation থাকতে পারে।

নির্বাচিত language menu, help, script message ও log entry-তে ব্যবহার হয়। Log-এর জন্য আলাদা language setting নেই।

<br />

## ভাষা নির্বাচন

`option.cfg`-এর `Language` setting selection নিয়ন্ত্রণ করে। Default value `auto`:

| Value | ব্যবহৃত ভাষা |
|---|---|
| `auto` | Operating-system locale থেকে নির্ধারিত |
| `ru` | Built-in Russian |
| `en` | Built-in English |
| অন্য two-letter code, যেমন `de` | Corresponding file থেকে translation, যেমন `de.lang` |

Russian স্থায়ীভাবে বেছে নিতে `option.cfg`-এ সেট করুন:

```ini
Language=ru
```

একটি run-এর জন্য CLI দিয়ে language নির্বাচন করা যায়:

```bash
mikrotik-backup.sh --language=ru --help
```

`--language` option options file-এর setting-এর চেয়ে priority পায়, কিন্তু file নিজে বদলায় না। `auto` অথবা two-letter language code ব্যবহার করুন; letter case গুরুত্বপূর্ণ নয়।

### স্বয়ংক্রিয় নির্বাচন

`auto` হলে script এই order-এ `LC_ALL`, `LC_MESSAGES` ও `LANG` থেকে first nonempty value নেয়।

যেমন, `ru_RU.UTF-8` Russian নির্বাচন করে, আর `de_DE.UTF-8` `de.lang` থেকে German translation নির্বাচন করে। `C`, `C.UTF-8`, `POSIX` অথবা language নির্ধারণ না করা গেলে English ব্যবহৃত হয়।

নির্বাচিত external translation unavailable হলেও message English-এই থাকে।

<br />

## বাহ্যিক অনুবাদ যুক্ত করা

`lang/` directory-তে ready-made external translation `de.lang`, `es.lang`, `lv.lang`, `pl.lang` ও `uk.lang`, এবং canonical template `en.lang` থাকে। External translation ব্যবহার করতে প্রয়োজনীয় file `mikrotik-backup.sh` থাকা directory-তে copy করুন।

যেমন, German install করতে script directory-তে চালান:

```bash
cp -- lang/de.lang de.lang
```

তারপর setting-এ `de` নির্বাচন করুন অথবা script start করার সময় দিন:

```bash
mikrotik-backup.sh --language=de --help
```

Filename-এ দুইটি Latin letter ও `.lang` extension থাকে—যেমন `de.lang`। এটি ordinary readable file হতে হবে, symbolic link নয়।

*(বি.দ্র.: `lang/` directory translation collection রাখে। Script ওই directory থেকে automatically load করে না: required file script-এর পাশেই রাখতে হবে।)*

`en.lang`-এ version 2.3.1-এর সব 245 key আছে এবং third-party translation তৈরির canonical template হিসেবে এটি ব্যবহৃত হয়। এটি built-in English replace করে না এবং external runtime language হিসেবে অংশ নেয় না। `ru.lang` তৈরি করা হলেও সেটি built-in Russian replace করে না এবং ignored হয়।

<br />

## Configuration Editor-এ ভাষা নির্বাচন

Editor খুলুন:

```bash
mikrotik-backup.sh -e
```

Language row-তে যান → required value না আসা পর্যন্ত **Enter** চাপুন → “Save” বেছে নিন।

Option এই order-এ cycle করে:

```text
auto → ru → en → শনাক্ত বাহ্যিক ভাষা alphabetical order-এ → auto
```

Form-এর language সঙ্গে সঙ্গে বদলায়। Save না করা পর্যন্ত এটি শুধু preview; “Cancel” previous interface language restore করে। Startup-এ `--language` specified থাকলে editor ছাড়ার পরে সেই CLI option আবার effective হয়।

Saved `option.cfg`-এর comment temporary CLI option নয়, `Language` setting নিজে যে language নির্বাচন করে তা ব্যবহার করে। `auto` হলে comment-এর জন্যও operating-system locale ব্যবহার হয়।

Editor সম্পর্কে আরও জানতে [INTERACTIVE.md](INTERACTIVE.md) দেখুন।

<br />

## অনুবাদ তৈরি ও সম্পাদনা

প্রয়োজনীয় translation এখনো না থাকলে নিজে প্রস্তুত করতে পারেন। একই script version-এর `lang/en.lang` নিন এবং `<xx>.lang` হিসেবে copy save করুন, যেখানে `xx` নতুন language-এর দুই অক্ষরের code। Version 2.3.1-এর template-এ সব 245 key আছে।

Format সহজ: প্রতিটি message-এর নিজস্ব line। যেমন English template-এ আছে:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

প্রতিটি key `msg_` দিয়ে শুরু, তারপর message name (`version`, `menu_title`) এবং language suffix `_en`।

New language-এর জন্য সব key-তে `_en` suffix বদলে `_xx` করুন এবং শুধু quotation mark-এর value translate করুন। Message name বদলাবেন না এবং সব placeholder হুবহু রাখুন। Existing translation ঠিক করতে শুধু `=`-এর ডান পাশের required text বদলালেই হয়।

একবারেই পুরো file translate করতে হয় না: missing message English-এ দেখায়। Script arbitrary new key ব্যবহার করে না।

### ফাইল-ফরম্যাটের নিয়ম

File UTF-8 হিসেবে save করুন। প্রতিটি value double quotation mark-এ রাখুন এবং nonempty করুন। Key-এর আগে, `=`-এর চারপাশে বা closing quote-এর পরে space দেবেন না।

Text-এর ভেতরে double quote-এর জন্য `\"` এবং backslash-এর জন্য `\\` ব্যবহার করুন। `\n` ও `\t`-সহ অন্য escape unsupported। Quotation mark-এর ভেতরে `=` character গ্রহণযোগ্য।

Blank line skip হয়। `.lang` format-এ comment নেই; quotation mark-এর ভেতরের `#` text-এর অংশ। Windows line ending (CRLF) এবং file-এর শুরুতে একটি BOM সমর্থিত।

Malformed line skip হয়, অন্য valid translation ব্যবহৃত থাকে। একই message একাধিকবার থাকলে last valid entry জয়ী হয়। Translation-এ control character ও terminal color code অনুমোদিত নয়।

*(বি.দ্র.: Localization file text data হিসেবে বিবেচিত। Variable expand হয় না এবং shell command execute হয় না।)*

### মেসেজের প্লেসহোল্ডার

কিছু string-এ brace-এর মধ্যে value থাকে, যেমন:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Runtime-এ script `{index}` ও `{total}`-কে device number ও total device count দিয়ে replace করে। Marker translate করবেন না: source string-এর প্রতিটি placeholder ঠিক একবার রাখুন। Sentence-এর মধ্যে position বদলাতে পারেন।

Placeholder invalid হলে ওই string-এর বদলে English message ব্যবহৃত হয়।

File save করার পরে selected language দিয়ে help ও interactive menu-তে translation পরীক্ষা করুন। Translation load না হওয়ার কারণ [সমস্যা সমাধান](TROUBLESHOOTING.md#language-problems)-এ আছে।
