# রিলিজ

[সূচিপত্র](../README_BN.md)

## সংস্করণ 2.3.1

**প্রকাশিত 2.3.0 সংস্করণের পরের maintenance ও hotfix release।**

Single-file architecture এবং ন্যূনতম GNU Bash 4.4 requirement অপরিবর্তিত। `UseIncremental` এখন canonical boolean setting: `false` backup-এর পরের comparison ও incremental-retention ধাপ skip করে এবং নতুন তৈরি হওয়া প্রতিটি সফলভাবে validated artifact রেখে দেয়। এর জন্য আলাদা CLI switch নেই।

MonthlyArchive-এর calendar ordering সংশোধন করা হয়েছে এবং উপযুক্ত network storage-এর metadata handling আরও শক্ত করা হয়েছে; local filesystem-এর strict metadata check অপরিবর্তিত আছে। ছোট terminal-এ Configuration Editor ও BackUP Master এখন accepted viewport ব্যবহার করে, তাই form-এর সব row একসঙ্গে screen-এ ধরতে হয় না।

Russian ও English built-in আছে। Version 2.3.1 German, Spanish, Latvian, Polish ও Ukrainian (`de`, `es`, `lv`, `pl`, `uk`) external runtime translation এবং সম্পূর্ণ 245-key canonical translation template হিসেবে `en.lang` দেয়। User documentation 11টি language-এ পাওয়া যায়।

Notification এখনো implement করা হয়নি এবং এই release-এর scope-এর বাইরে আছে।

<br />

ফাইল সংগ্রহ, checksum যাচাই এবং ব্যবহারের জন্য স্ক্রিপ্ট প্রস্তুত করার নির্দেশনা পেতে [INSTALL.md](INSTALL.md) দেখুন।
