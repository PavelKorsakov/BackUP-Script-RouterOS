# MikroTik Backup Script

**Buat backup perangkat MikroTik RouterOS.**

Skrip ini membuat backup perangkat yang menjalankan RouterOS, baik secara manual maupun otomatis melalui penjadwal *(yang dikonfigurasi secara terpisah)*.
Berkas `mikrotik-backup.sh` merupakan skrip mandiri, meskipun beberapa fiturnya dapat dikonfigurasi melalui `option.cfg`.

<br>

## Fitur skrip

| Fitur | Cara kerja |
|---|---|
| Mode satu perangkat | Membuat backup satu perangkat menggunakan opsi CLI |
| Pemrosesan batch | Memproses perangkat yang tercantum dalam DeviceList secara berurutan; dapat mengimpor daftar dari Oxidized |
| Format backup | Membuat `.rsc`, `.backup`, atau kedua format secara berurutan |
| Mode backup | Mendukung ekspor `compact`, `terse`, dan `verbose`, serta enkripsi backup biner |
| Backup inkremental | Dapat menyimpan backup hanya ketika perubahan terdeteksi |
| Pengarsipan bulanan | Dapat mengarsipkan backup dan log lama saat batas kalender tercapai |
| Pencatatan log | Mencatat tahap umum dalam `main.log` dan operasi perangkat dalam `devicename.log` |
| Menu konfigurasi | Menyediakan menu interaktif untuk memudahkan konfigurasi dan pengoperasian |
| Pelokalan | Menyertakan bahasa Rusia dan Inggris serta mendukung berkas pelokalan eksternal |
| Penyimpanan backup | Dapat menggunakan direktori backup apa pun, termasuk NAS |
| Penggunaan NAS | Memastikan penyimpanan tersedia sebelum membuat backup |

<br>

## Persyaratan sistem dan langkah awal

**Wajib:**
GNU Bash 4.4 atau yang lebih baru dan utilitas berikut yang sudah terpasang: **SSH**, **SCP**, dan **SSHPass**.
**zip** hanya diperlukan untuk pengarsipan backup bulanan. Semua utilitas yang diperlukan beserta perintah pemasangannya tercantum di bagian [Dependensi](id/INSTALL.md#dependensi).
*(Catatan: Jika utilitas yang diperlukan tidak tersedia, skrip berhenti dengan galat. Ini adalah perilaku yang semestinya.)*

**Opsional:**
**autofs**, **davfs2**, **rclone**, dan alat lain untuk memasang penyimpanan eksternal.

**Pemasangan:**
Lihat [Pemasangan](id/INSTALL.md) untuk petunjuk pengunduhan dan konfigurasi.

Jalankan perintah berikut di direktori yang berisi berkas hasil unduhan:

Blok perintah di bawah mengasumsikan berkas diperoleh dari GitHub Release. Checkout sumber melalui Git tidak menyertakan `SHA256SUMS` yang dihasilkan untuk Release; untuk checkout sumber, mulai dari `chmod 700 mikrotik-backup.sh`, lalu lanjutkan dengan pemeriksaan versi dan bantuan.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Jika verifikasi checksum gagal, **jangan jalankan berkas tersebut!!!**

<br>

## Cara menjalankan skrip

**Jalankan berkas TANPA opsi tambahan** *(ketika `option.cfg` tidak ada atau tidak valid)*
Jika tidak ada `option.cfg` di samping skrip, atau berkas itu tidak berisi pengaturan yang dapat digunakan, Editor Konfigurasi akan terbuka agar Anda dapat membuat atau mengedit `option.cfg`.

**Jalankan berkas TANPA opsi tambahan** *(ketika `option.cfg` dan `devicelist.cfg` yang valid tersedia)*
Jika pengaturan yang dapat digunakan sudah tersedia, skrip memulai pemrosesan batch.

**Jalankan skrip dengan sebuah opsi:**

| Tugas | Perintah |
|---|---|
| Buka menu interaktif | `./mikrotik-backup.sh -i` |
| Buka BackUP Master | `./mikrotik-backup.sh -b` |
| Buat atau edit `option.cfg` | `./mikrotik-backup.sh -e` |
| Tampilkan bantuan CLI lengkap | `./mikrotik-backup.sh -h` |
| Jalankan backup satu perangkat | Berikan tiga parameter CLI lengkap: alamat perangkat, pengguna, dan kata sandi |

Opsi terpenting di sini adalah `-i`, yang membuka menu interaktif. Dari sana Anda dapat:

- menggunakan BackUP Master untuk memasukkan parameter perangkat, membuat backup perangkat tersebut, serta membuat atau menambahkan parameter perangkat yang dipilih ke `devicelist.cfg`;
- menggunakan Editor Konfigurasi untuk membuat atau mengedit `option.cfg`;
- melihat bantuan CLI;
- membaca panduan singkat mengenai fitur skrip.

Untuk referensi CLI lengkap, termasuk bentuk persis `-a=...`, `-u=...`, dan `-p=...`, lihat [referensi baris perintah](id/CLI.md).

<br>

## Di mana hasilnya, atau “Di mana backup saya???”

Secara default, backup perangkat disimpan dalam direktori `backups` di samping skrip. Jika direktori tersebut belum ada, skrip akan membuatnya.
*(Catatan: Jalur relatif `backups` ditafsirkan terhadap direktori skrip, bukan direktori kerja saat ini!)*

Dalam eksekusi satu perangkat, subdirektori khusus perangkat tidak dibuat:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Dalam mode batch, setiap perangkat memiliki direktorinya sendiri:

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

Susunan ini hanyalah contoh, bukan jaminan bahwa setiap berkas akan tersedia setelah setiap eksekusi.
Log dibuat saat entri pertama yang berlaku ditulis.
Opsi `MainLogPath` dalam `option.cfg` dapat memindahkan `main.log` ke `/var/log/` atau direktori lain yang sesuai.
Lihat [Konfigurasi](id/OPTIONS.md) untuk rincian tentang konfigurasi direktori backup, arsip, dan log.

<br>

## Pengarsipan bulanan

Fitur ini dinonaktifkan secara default. Jika skrip berjalan menurut jadwal, tetapkan `MonthlyArchive=true|1...28` dalam `option.cfg` untuk memilih saat semua backup dari periode sebelumnya diarsipkan.

Pada hari tersebut, urutan kerja eksekusi batch berubah: mula-mula semua data yang memenuhi syarat dan telah terkumpul di direktori backup diarsipkan, kemudian backup untuk tanggal saat ini dibuat.

Nama arsip mengikuti hari kalender sebelumnya. Sebagai contoh, eksekusi pada 1 Oktober membuat `30.09.YYYY.zip`.

*(Catatan: Jika skrip TIDAK berjalan setiap hari, Anda harus membuat tugas terjadwal terpisah untuk tanggal yang diperlukan. Tugas terpisah tidak diperlukan jika skrip berjalan setiap hari atau lebih sering.)*

Percobaan bulanan yang terlewat—apa pun alasannya—tidak dikejar oleh eksekusi harian.
Percobaan bulanan terjadwal berikutnya mengumpulkan semua data lama yang telah terakumulasi ke dalam satu arsip, meskipun backlog mencakup beberapa bulan. `main.log` tidak diarsipkan.

Lihat [Pengarsipan bulanan](id/BACKUPS.md#pengarsipan-bulanan) untuk aturan lengkap, contoh, dan perilaku saat terjadi kegagalan.

<br>

## Dokumentasi terperinci

| Topik | Halaman |
|---|---|
| Persyaratan, dependensi, dan penempatan berkas | [Pemasangan](id/INSTALL.md) |
| Parameter dan pemilihan mode | [CLI](id/CLI.md) |
| Nilai default dan `option.cfg` | [Konfigurasi](id/OPTIONS.md) |
| DeviceList, nama, dan Oxidized | [Perangkat](id/DEVICES.md) |
| Format, perbandingan, penyimpanan, dan arsip ZIP | [Backup](id/BACKUPS.md) |
| Tingkat log, jalur, dan pesan | [Pencatatan log](id/LOGGING.md) |
| Menu, editor, dan BackUP Master | [Antarmuka interaktif](id/INTERACTIVE.md) |
| Pemilihan bahasa dan berkas `.lang` | [Pelokalan](id/LOCALIZATION.md) |
| Kredensial, SSH, dan izin akses | [Keamanan](id/SECURITY.md) |
| Diagnosis berdasarkan gejala atau kode hasil | [Pemecahan masalah](id/TROUBLESHOOTING.md) |
| Verifikasi rilis dan pembaruan | [Rilis](id/RELEASES.md) |
| Riwayat dan rencana pengembangan | [Roadmap](id/ROADMAP.md) |

<br>

## Cakupan dan batasan

Skrip membuat backup, tetapi tidak memulihkan konfigurasi router.
Versi saat ini tidak mengirim notifikasi melalui surel atau layanan perpesanan dan tidak menghapus berkas ZIP lama berdasarkan usianya.
Administrator bertanggung jawab atas prosedur pemulihan, retensi eksternal, dan pemantauan hasil.

Profil SSH menggunakan autentikasi kata sandi dan menonaktifkan verifikasi kunci host.
Mengenkripsi berkas `.backup` tidak mengenkripsi berkas `.rsc`, berkas konfigurasi, atau arsip ZIP.
Baca [model keamanan](id/SECURITY.md) sebelum menggunakannya dalam produksi.

<br>

## Dokumentasi dalam bahasa lain

[English](../README.md).  
[Русский](README_RU.md).  
[Latviešu](README_LV.md).  
[Українська](README_UK.md).  
[Deutsch](README_DE.md).  
[Bahasa Indonesia](README_ID.md).  
[Português (Brasil)](README_PT-BR.md).  
[Tiếng Việt](README_VI.md).  
[Español](README_ES.md).  
[Polski](README_PL.md).  
[বাংলা](README_BN.md).

## Hubungi penulis

Kirim saran fitur, laporan bug, dan pertanyaan tentang skrip ke [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev),
atau hubungi penulis melalui Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
