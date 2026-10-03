# Backup dan arsip

[Daftar isi](../README_ID.md)

## Format backup

Skrip dapat menyimpan konfigurasi perangkat sebagai teks, membuat backup biner, atau mengambil kedua format.
Parameter `backup_type` dalam `option.cfg` memilih format:

| Nilai | Yang disimpan |
|---|---|
| `configuration` | Konfigurasi RouterOS dalam berkas `.rsc` |
| `binary` | Backup biner dalam berkas `.backup` |
| `both` | Kedua format: `.rsc` terlebih dahulu, lalu `.backup` |

Nilai default adalah `both`. Anda dapat mengubahnya dalam berkas opsi, Editor Konfigurasi, BackUP Master, atau dengan `--backup-type`.

### Konfigurasi teks: .rsc

Parameter `export_format` memilih format ekspor. Nilai yang valid adalah `compact`, `terse`, dan `verbose`; nilai default-nya `compact`.

Parameter `show_sensitive` menentukan apakah ekspor menyertakan data sensitif, termasuk kata sandi. Parameter ini diaktifkan secara default.
Untuk menonaktifkannya, tambahkan baris berikut ke `option.cfg`:

```ini
show_sensitive=false
```

### Backup biner: .backup

Anda dapat mengenkripsi backup biner. Tetapkan kata sandi yang diperlukan dalam `encrypt`:

```ini
encrypt=MySuperPassword
```

Dengan nilai `encrypt=` yang kosong, berkas disimpan tanpa enkripsi. Ini adalah perilaku default.

*(Catatan: Enkripsi AES-SHA256 hanya berlaku untuk `.backup`. Enkripsi ini tidak mengenkripsi konfigurasi teks, log, atau arsip ZIP.)*

Secara default, skrip menghapus cache DNS dan riwayat konsol RouterOS sebelum membuat backup biner. Jika Anda tidak memerlukan operasi ini, nonaktifkan parameter terkait:

```ini
clear_dns_cache=false
clear_console_history=false
```

Operasi pembersihan ini tidak dilakukan jika hanya konfigurasi teks yang diambil.

<br />

## Nama dan lokasi berkas

Secara default, backup disimpan dalam direktori `backups` di samping skrip. Tetapkan direktori lain melalui `BackupRoot` dalam berkas opsi.

Dalam eksekusi satu perangkat, berkas ditempatkan langsung dalam direktori tersebut:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Dalam mode batch, setiap perangkat memiliki subdirektorinya sendiri:

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

Nama berkas backup memuat nama perangkat serta tanggal dan waktu dari jam host yang menjalankan skrip. Kedua format yang dibuat dalam operasi backup yang sama menggunakan timestamp yang sama.
Pembentukan nama perangkat dijelaskan dalam [DEVICES.md](DEVICES.md#device-names).

**Perhatikan!!!**
Jika Anda membuat backup perangkat yang sama ke direktori yang sama dua kali dalam satu menit, nama berkasnya akan sama. Berkas dengan nama tersebut diganti; versi terpisah tidak dibuat untuk eksekusi kedua.

Anda juga dapat menggunakan direktori jaringan sebagai penyimpanan. Dalam mode batch, tetapkan `UseNetFolder=true` untuk memeriksa penyimpanan tersebut. Penyiapan direktori dijelaskan dalam [INSTALL.md](INSTALL.md), dan pengaturan jalur dalam [OPTIONS.md](OPTIONS.md#network-storage).

[LOGGING.md](LOGGING.md) menjelaskan lokasi dan isi log secara terperinci.

<br />

## Backup inkremental

Fitur ini mencegah penyimpanan backup duplikat ketika tidak ada perubahan yang terdeteksi. Parameter `UseIncremental` mengendalikannya:

| Nilai | Cara backup dipertahankan |
|---|---|
| `true` (default) | Jika backup baru dikenali sebagai duplikat, berkas baru dihapus dan backup sebelumnya dipertahankan |
| `false` | Setiap backup baru yang valid dipertahankan tanpa dibandingkan dengan backup sebelumnya |

Ketika perubahan terdeteksi atau backup sebelumnya belum ada, berkas baru dipertahankan. Jika perbandingan tidak dapat diselesaikan, berkas juga dipertahankan, tetapi skrip mengeluarkan peringatan.

**Dan di sinilah letak jebakannya!!!**
Cara perbandingan berbeda menurut format:

| Format | Yang dibandingkan |
|---|---|
| `.rsc` | Isi berkas. Tanggal dan waktu dalam header RouterOS standar diabaikan |
| `.backup` | Hanya ukuran berkas dalam byte |

Dengan demikian, dua berkas biner berukuran sama diperlakukan sebagai duplikat meskipun isinya berbeda. Pertimbangkan hal ini saat memilih pengaturan retensi.

Skrip membandingkan berkas dengan backup terdahulu yang paling baru untuk perangkat dan format yang sama di direktori perangkat tersebut. Backup yang sudah dikemas dalam ZIP tidak ikut dibandingkan.

Skrip mempertahankan berkas `.rsc` dan `.backup` biasa, bukan berkas perubahan terpisah. Menonaktifkan `UseIncremental` tidak menonaktifkan pengambilan dan verifikasi backup, pencatatan log, atau pengarsipan bulanan.

<br />

<a id="monthly-archive"></a>
## Pengarsipan bulanan

Fitur ini dinonaktifkan secara default. Tetapkan `MonthlyArchive` dalam `option.cfg` untuk memilih tanggal ketika backup dan log yang terkumpul diarsipkan:

| Nilai | Perilaku |
|---|---|
| `false` (default) | Pengarsipan dinonaktifkan |
| `true` atau `1` | Pengarsipan dijalankan pada tanggal pertama setiap bulan |
| `2` hingga `28` | Pengarsipan dijalankan pada tanggal yang ditentukan dalam bulan tersebut |

Jam eksekusi pada tanggal yang dipilih tidak berpengaruh. Konfigurasikan jadwal secara terpisah, seperti yang dijelaskan dalam [INSTALL.md](INSTALL.md#menjalankan-skrip-secara-otomatis).

### Yang dimasukkan ke arsip

Dalam mode batch, urutan kerja berubah pada tanggal tersebut: skrip terlebih dahulu mengumpulkan berkas perangkat yang telah terakumulasi ke dalam ZIP, lalu membuat backup baru. Backup yang dibuat oleh eksekusi saat ini tetap berada di luar arsip.

Arsip menyertakan berkas biasa yang berada langsung dalam direktori perangkat, termasuk seluruh log kumulatif perangkat. Isinya tidak terbatas pada `.rsc` dan `.backup`: berkas biasa lain yang Anda tempatkan dalam direktori tersebut juga dapat diarsipkan.

Subdirektori, tautan simbolis, objek layanan untuk eksekusi saat ini, dan berkas ZIP yang sebelumnya dibuat oleh skrip tidak dikemas lagi. **Log utama, `main.log`, tidak diarsipkan.**

Setelah ZIP yang selesai diverifikasi dan disimpan, berkas sumber yang disertakan di dalamnya dihapus dari direktori perangkat. Jika tidak ada yang perlu diarsipkan, ZIP kosong tidak dibuat.

### Nama dan lokasi arsip

Nama ZIP mengikuti hari kalender sebelumnya dalam format `DD.MM.YYYY.zip`. Sebagai contoh, eksekusi pada 1 Oktober 2026 membuat `30.09.2026.zip`; eksekusi pada 15 Oktober membuat `14.10.2026.zip`.

| Mode | Lokasi arsip |
|---|---|
| Batch | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| CLI satu perangkat | `<BackupRoot>/DD.MM.YYYY.zip` |

Eksekusi ulang pada hari yang sama memperbarui arsip dengan nama yang sama.

### Mode satu perangkat dan BackUP Master

Dalam eksekusi satu perangkat melalui CLI, urutannya dibalik: backup dijalankan terlebih dahulu, lalu pengarsipan. Karena itu, backup baru dari eksekusi saat ini juga dapat masuk ke dalam ZIP.

Dalam mode ini, berkas `.rsc`, `.backup`, dan `.log` yang berada langsung di dalam `BackupRoot` diarsipkan, kecuali `main.log`. Jika hasil eksekusi satu perangkat untuk beberapa perangkat menggunakan satu direktori bersama, berkasnya masuk ke arsip yang sama.

Pengarsipan bulanan tidak dijalankan ketika BackUP Master digunakan.

### Jika suatu eksekusi terlewat

Jika skrip tidak berjalan pada tanggal yang dipilih, percobaan pengarsipan yang terlewat tidak dikejar kemudian. Percobaan berikutnya dilakukan pada tanggal yang ditentukan di bulan berikutnya.

Semua berkas yang telah terkumpul masuk ke satu arsip pada percobaan berikutnya, meskipun berkas berasal dari dua, tiga, atau lebih banyak bulan. Berkas ZIP terpisah tidak dibuat untuk bulan yang terlewat.

### Jika pengarsipan gagal

Berkas sumber tidak dihapus sampai ZIP yang telah diverifikasi berhasil disimpan. Arsip lama yang rusak juga tidak ditimpa dengan arsip baru.

Jika ZIP sudah disimpan tetapi beberapa berkas sumber tidak dapat dihapus, arsip lengkap tetap berada di tempatnya, begitu pula berkas yang gagal dihapus. Periksa log untuk mengetahui penyebab galat.

*(Catatan: Arsip dibuat dalam direktori lokal `/tmp` meskipun backup disimpan pada NAS. Karena itu, ruang kosong juga diperlukan di luar penyimpanan.)*

<br />

## Jika backup gagal

Setelah percobaan pengambilan berkas gagal, skrip mencoba sekali lagi setelah 2 detik. Percobaan ulang untuk `.rsc` dan `.backup` dilakukan secara terpisah.

Galat biasa saat mengambil satu format tidak membatalkan percobaan mengambil format lain. Jika satu perangkat tidak tersedia, skrip melanjutkan dengan perangkat yang tersisa. Jika penyimpanan bersama terputus, pemrosesan batch berhenti.

Pesan galat dan kode hasil dijelaskan dalam [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Retensi dan pemulihan

Berkas ZIP lama tidak dihapus berdasarkan usia atau jumlah. Anda menentukan periode retensi dan kebijakan rotasi eksternalnya.

Skrip membuat backup, tetapi tidak memulihkan RouterOS. Uji pemulihan secara terpisah pada perangkat yang sesuai.

*(Catatan: Backup dan arsip dapat memuat kata sandi serta data rahasia lainnya. Batasi akses ke penyimpanan seperti yang dijelaskan dalam [SECURITY.md](SECURITY.md).)*
