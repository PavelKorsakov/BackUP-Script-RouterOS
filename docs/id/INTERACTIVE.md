# Antarmuka interaktif

[Daftar isi](../README_ID.md)

## Menu utama

Menu utama memungkinkan Anda mengonfigurasi skrip, membuat backup, menyiapkan daftar perangkat, atau membuka bantuan bawaan. Untuk membukanya, jalankan:

```bash
mikrotik-backup.sh -i
```

| Item | Yang dibuka atau dilakukan |
|---|---|
| `1` | BackUP Master untuk menangani satu perangkat |
| `2` | Backup batch menggunakan daftar perangkat |
| `3` | Editor Konfigurasi untuk membuat atau mengubah `option.cfg` |
| `4` | Referensi opsi CLI |
| `5` | Petunjuk penggunaan skrip |
| `6` | Keluar ke konsol |

Item `2` muncul ketika `devicelist.cfg` memuat setidaknya satu entri yang memenuhi syarat. Jika daftar belum ada atau tidak memuat perangkat yang sesuai, item tersebut disembunyikan. Nomor item lain tidak berubah.

Setelah backup batch, hasil ditampilkan dan skrip mengembalikan Anda ke konsol.

*(Catatan: Menjalankan skrip tanpa opsi tidak membuka menu utama. Jika `option.cfg` tidak ada atau tidak memuat pengaturan yang dapat digunakan, Editor Konfigurasi terbuka; jika pengaturan sudah disiapkan, skrip melanjutkan ke backup batch.)*

<br />

## Kontrol

Berpindahlah antaritem dengan tombol panah **Up** dan **Down**, lalu pilih item dengan **Enter**. Jika suatu tindakan memiliki nomor di sampingnya, Anda juga dapat memilihnya dengan tombol angka yang sesuai.

Di editor dan BackUP Master, deskripsi kolom yang dipilih muncul di atas daftar. Jika semua baris tidak muat di jendela terminal, daftar akan bergulir saat Anda bergerak dengan tombol panah. Judul dan deskripsi tetap terlihat, dan baris yang dipilih tetap berada di dalam jendela.

Tindakan simpan, jalankan, dan keluar berada di bagian akhir daftar yang sama. Baris yang diredupkan tidak tersedia dengan pengaturan yang dipilih dan dilewati saat navigasi.

Terminal dan utilitas `stty` diperlukan. Input standar dan output standar harus sama-sama terhubung ke terminal. Layar utama memerlukan lebar setidaknya 46 kolom; petunjuk bawaan memerlukan 80. Jika jendela terlalu kecil, skrip melaporkan galat `31`; perbesar jendela lalu jalankan kembali.

<br />

## Editor Konfigurasi

Buka editor melalui item `3` pada menu utama atau langsung dengan:

```bash
mikrotik-backup.sh -e
```

Jika `option.cfg` sudah disiapkan, formulir diisi dengan pengaturan Anda. Jika berkas belum ada, nilai default digunakan.

Editor memungkinkan Anda memilih bahasa, sumber daftar perangkat, pengaturan backup, penyimpanan, pengarsipan bulanan, dan pencatatan log. Pengaturan dan nilai yang diterima dijelaskan dalam [OPTIONS.md](OPTIONS.md).

### Mengubah pengaturan

Ubah sakelar Yes/No, jenis backup, format ekspor, dan tingkat log dengan menekan **Enter** pada baris terkait. Memilih jalur atau tanggal pengarsipan bulanan akan membuka dialog untuk memasukkan nilai.

Kolom “Use incremental backups” (`UseIncremental`) berada tepat setelah jenis backup. “Yes” mengaktifkan perbandingan; “No” mempertahankan setiap backup baru yang valid tanpa membandingkannya dengan backup sebelumnya.

Untuk pengarsipan bulanan, masukkan `false` untuk menonaktifkannya atau angka dari `1` hingga `28`. Formulir menampilkan keadaan nonaktif sebagai “No” dan keadaan aktif sebagai tanggal yang dipilih dalam bulan tersebut.

Kolom yang tidak berlaku untuk mode terpilih akan diredupkan. Sebagai contoh, ketika hanya `.rsc` yang dipilih, enkripsi backup biner dan operasi pembersihan sebelumnya tidak tersedia; ketika hanya `.backup` yang dipilih, pengaturan ekspor teks tidak tersedia. Peralihan mode mengembalikan pengaturan yang tidak lagi berlaku ke nilai default.

Kata sandi enkripsi dimasukkan dan ditampilkan sebagai tanda bintang.

### Menyimpan dan membatalkan

Pilih pengaturan yang diperlukan → pindah ke “Save” → tekan **Enter**. Pengaturan yang dipilih digunakan untuk membuat atau menimpa `option.cfg`.

Sebelum disimpan, perubahan hanya ada dalam memori. “Cancel” membiarkan berkas yang ada tetap utuh. Jika Anda telah mengubah sesuatu, editor meminta konfirmasi bahwa Anda ingin membuang perubahan tersebut.

Editor yang dibuka dari menu utama akan kembali ke menu tersebut. Jika Anda menjalankan editor secara terpisah dengan `-e`, menutupnya akan mengembalikan Anda ke konsol.

*(Catatan: `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login`, dan `Password` tidak ditampilkan dalam formulir. Pengaturan dan aturan untuk mempertahankan nilainya dibahas dalam [OPTIONS.md](OPTIONS.md).)*

### Memilih bahasa

Pada baris bahasa, setiap penekanan **Enter** memilih opsi berikutnya:

```text
auto → ru → en → bahasa eksternal yang terdeteksi menurut urutan alfabet → auto
```

Bahasa formulir langsung berubah agar Anda dapat melihat pratinjaunya. “Save” menulis bahasa yang dipilih ke `option.cfg`; pembatalan mengembalikan bahasa antarmuka sebelumnya. Jika `--language` diberikan secara eksplisit saat skrip dimulai, opsi tersebut kembali berlaku setelah Anda keluar dari editor.

Cara menghubungkan terjemahan eksternal dijelaskan dalam [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master memungkinkan Anda mengisi pengaturan untuk satu perangkat, membuat backup perangkat tersebut, menyimpan perangkat ke daftar, atau menyiapkan perintah untuk dijalankan dari konsol.

Pilih item `1` pada menu utama atau jalankan:

```bash
mikrotik-backup.sh -b
```

Berbeda dengan Editor Konfigurasi, BackUP Master tidak mengisi kolom biasa dari `option.cfg`. Nilainya berasal dari nilai bawaan dan opsi yang diberikan secara eksplisit melalui CLI. `UseIncremental` merupakan pengecualian: nilainya berasal dari berkas opsi, atau menggunakan default `true` jika pengaturan tersebut tidak ada.

Entri lama dari `devicelist.cfg` juga tidak dimuat ke dalam formulir. Anda mengisi nama, alamat, login, dan kata sandi untuk perangkat yang dipilih.

### Kolom BackUP Master

Kolom ditampilkan dalam urutan berikut. Berikut adalah namanya dalam antarmuka bahasa Inggris:

| Kolom | Kegunaan |
|---|---|
| Device name | Nama yang digunakan dalam daftar perangkat dan untuk backup ketika pengambilan RouterOS Identity dinonaktifkan |
| IP address | Alamat IP atau nama DNS perangkat |
| User | Pengguna perangkat RouterOS |
| Password | Kata sandi perangkat RouterOS |
| SSH port | Port koneksi; default `22` |
| Backup type | Konfigurasi `.rsc`, backup biner `.backup`, atau kedua format |
| Use incremental backups | Membandingkan backup baru dengan backup sebelumnya, atau mempertahankannya tanpa perbandingan |
| Export format | `compact`, `terse`, atau `verbose` |
| Sensitive data | Menyertakan nilai sensitif dalam ekspor teks |
| Encryption password | Mengenkripsi backup biner; nilai kosong menonaktifkan enkripsi |
| Clear DNS cache | Menghapus cache DNS sebelum membuat backup biner |
| Clear console history | Menghapus riwayat konsol sebelum membuat backup biner |
| Backup directory | Direktori tempat berkas disimpan |
| This is a network directory | Nilai `UseNetFolder`; verifikasi mount berlaku dalam mode batch |
| Use RouterOS Identity | Mengambil nama dari perangkat alih-alih menggunakan nama yang dimasukkan dalam formulir |

Sakelar, jenis backup, dan format ekspor diubah dengan **Enter**; nilai lainnya dimasukkan ke kolom masing-masing. Kedua kata sandi disamarkan dengan tanda bintang.

**Harap perhatikan!!!**
Data sensitif dalam ekspor teks, pembersihan cache DNS, dan pembersihan riwayat konsol sebelum backup biner diaktifkan secara default. Pilih pengaturan yang Anda perlukan sebelum menjalankan backup.

BackUP Master tidak memiliki kolom untuk `MonthlyArchive`, `LogLevel`, atau `MainLogPath`. Pengarsipan bulanan dinonaktifkan ketika backup dijalankan melalui BackUP Master, sedangkan pengaturan log berasal dari `option.cfg` bersama opsi CLI yang diberikan untuk eksekusi.

### 1. Menjalankan backup

Isi alamat, login, dan kata sandi; periksa port serta pengaturan backup → pilih “1. Execute backup.”

Ketika pengambilan RouterOS Identity diaktifkan, nama backup diambil dari perangkat. Ketika dinonaktifkan, Anda harus mengisi kolom “Device name”.

Backup satu perangkat dimulai. Setelah selesai, hasil dan kodenya ditampilkan, lalu skrip mengembalikan Anda ke konsol. Skrip tidak kembali ke formulir BackUP Master, baik backup berhasil maupun gagal.

Lokasi berkas dan aturan retensi dijelaskan dalam [BACKUPS.md](BACKUPS.md); pesan progres dibahas dalam [LOGGING.md](LOGGING.md).

### 2. Menyimpan perangkat ke devicelist.cfg

Nama perangkat, alamat, login, kata sandi, dan port SSH diperlukan untuk menyimpan. Hingga semua kolom wajib diisi, tindakan terkait tetap tidak tersedia.

BackUP Master membuat berkas, menambahkan entri baru, atau memperbarui entri lama dengan nama yang sama. Jika entri berkonflik atau penyimpanan gagal, daftar sebelumnya tetap utuh. Formulir tetap terbuka setelah penyimpanan.

**Hanya data perangkat yang disimpan ke `devicelist.cfg`.** Pengaturan backup dari formulir tidak ditulis ke `option.cfg`, dan tindakan ini tidak memulai backup.

*(Catatan: Port `22` disimpan sebagai kolom kosong. Pada eksekusi batch berikutnya, entri seperti ini menggunakan `SshPort` dari pengaturan skrip. Port nonstandar ditulis secara eksplisit.)*

Format daftar dan aturan pembaruan dijelaskan dalam [DEVICES.md](DEVICES.md).

### 3. Menyalin perintah konsol

BackUP Master menyusun perintah peluncuran dari formulir yang telah diisi dan mengirimkannya ke clipboard. Backup tidak dimulai, dan BackUP Master selesai dengan kembali ke konsol.

Fitur ini memerlukan GNU `base64` yang mendukung `--wrap=0` dan terminal yang mendukung OSC 52. Jika Anda bekerja melalui multiplexer terminal, multiplexer tersebut juga harus meneruskan perintah. Jika transfer ke clipboard tidak didukung, perintah tidak dicetak sebagai teks biasa di layar.

Parameter yang sama dengan nilai bawaan dapat dihilangkan dari perintah. Ketika kelak Anda menjalankannya, pengaturan dari `option.cfg` tetap berlaku, sehingga hasilnya dapat berbeda dari menjalankan backup langsung melalui BackUP Master.

Pengaturan `UseIncremental` tidak disertakan dalam perintah: pengaturan ini tidak memiliki opsi CLI khusus. Ketika perintah yang disalin dijalankan, nilainya berasal dari `option.cfg` atau nilai default.

*(Catatan: Perintah yang ditempatkan di clipboard memuat kata sandi. Ingat hal ini saat menggunakan riwayat clipboard dan saat menempelkan perintah ke shell. Untuk rinciannya, lihat [SECURITY.md](SECURITY.md).)*

### 0. Kembali ke Menu Utama

Hasilnya bergantung pada cara Anda membuka BackUP Master:

| Cara membukanya | Tujuan saat kembali |
|---|---|
| Dari menu utama dengan `-i` | Menu utama |
| Sebagai eksekusi terpisah dengan `-b` | Konsol |

Nilai formulir yang belum disimpan akan dibuang. Entri yang sudah disimpan dalam `devicelist.cfg` tetap berada di sana.

<br />

## Bantuan dan petunjuk

Item `4` pada menu utama membuka referensi opsi baris perintah, sedangkan item `5` membuka petunjuk singkat penggunaan skrip.

Jika teks tidak muat secara vertikal, teks dibagi menjadi beberapa halaman. Berpindahlah dengan **PageUp / PageDown**; nomor halaman saat ini ditampilkan di layar.

Item `0` kembali ke menu utama, dan item `6` keluar dari skrip. Anda dapat memilih tindakan ini dengan tombol panah dan **Enter**, atau dengan tombol angka yang sesuai.

Bantuan CLI yang sama tersedia langsung dari konsol:

```bash
mikrotik-backup.sh -h
```
