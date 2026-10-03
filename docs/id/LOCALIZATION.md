# Pelokalan

[Daftar isi](../README_ID.md)

## Bahasa antarmuka dan log

Bahasa Rusia (`ru`) dan Inggris (`en`) terintegrasi dalam skrip. Keduanya tidak memerlukan berkas terjemahan terpisah. Versi 2.3.1 menyertakan terjemahan eksternal untuk antarmuka dan log berikut: `de.lang`, `es.lang`, `lv.lang`, `pl.lang`, dan `uk.lang`.

Bahasa dokumentasi tidak bergantung pada ketersediaan terjemahan runtime eksternal. Karena itu, dokumentasi dapat tersedia dalam bahasa yang tidak memiliki berkas `.lang` terkait dalam distribusi.

Bahasa yang dipilih digunakan dalam menu, bantuan, pesan skrip, dan entri log. Tidak ada pengaturan bahasa terpisah untuk log.

<br />

## Memilih bahasa

Pengaturan `Language` dalam `option.cfg` mengendalikan pilihan. Nilai default-nya adalah `auto`:

| Nilai | Bahasa yang digunakan |
|---|---|
| `auto` | Ditentukan dari locale sistem operasi |
| `ru` | Bahasa Rusia bawaan |
| `en` | Bahasa Inggris bawaan |
| Kode dua huruf lain, seperti `de` | Terjemahan dari berkas terkait, seperti `de.lang` |

Untuk memilih bahasa Rusia secara permanen, tetapkan baris berikut dalam `option.cfg`:

```ini
Language=ru
```

Untuk satu eksekusi, Anda dapat memilih bahasa melalui CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

Opsi `--language` lebih diprioritaskan daripada pengaturan dalam berkas opsi, tetapi tidak mengubah berkas itu sendiri. Gunakan `auto` atau kode bahasa dua huruf; kapitalisasi huruf tidak berpengaruh.

### Pemilihan otomatis

Dengan `auto`, skrip mengambil nilai pertama yang tidak kosong dari `LC_ALL`, `LC_MESSAGES`, dan `LANG`, dalam urutan tersebut.

Sebagai contoh, `ru_RU.UTF-8` memilih bahasa Rusia, sedangkan `de_DE.UTF-8` memilih terjemahan bahasa Jerman dari `de.lang`. Bahasa Inggris digunakan untuk `C`, `C.UTF-8`, `POSIX`, atau ketika bahasa tidak dapat ditentukan.

Pesan juga tetap dalam bahasa Inggris jika terjemahan eksternal yang dipilih tidak tersedia.

<br />

## Menghubungkan terjemahan eksternal

Direktori `lang/` memuat terjemahan eksternal siap pakai `de.lang`, `es.lang`, `lv.lang`, `pl.lang`, dan `uk.lang`, serta templat kanonis `en.lang`. Untuk menggunakan terjemahan eksternal, salin berkas yang diperlukan ke direktori yang memuat `mikrotik-backup.sh`.

Sebagai contoh, jalankan perintah berikut dalam direktori skrip untuk memasang bahasa Jerman:

```bash
cp -- lang/de.lang de.lang
```

Kemudian pilih `de` dalam pengaturan atau tentukan saat memulai skrip:

```bash
mikrotik-backup.sh --language=de --help
```

Nama berkas terdiri dari dua huruf Latin dan ekstensi `.lang`—misalnya `de.lang`. Berkas harus berupa berkas biasa yang dapat dibaca, bukan tautan simbolis.

*(Catatan: Direktori `lang/` menyimpan koleksi terjemahan. Skrip tidak otomatis memuatnya dari direktori tersebut: berkas yang diperlukan harus ditempatkan di samping skrip itu sendiri.)*

`en.lang` memuat seluruh 245 kunci versi 2.3.1 dan merupakan templat kanonis untuk membuat terjemahan pihak ketiga. Berkas ini tidak menggantikan bahasa Inggris bawaan dan tidak digunakan sebagai bahasa runtime eksternal. Berkas `ru.lang`, jika dibuat, juga tidak menggantikan bahasa Rusia bawaan dan akan diabaikan.

<br />

## Memilih bahasa dalam Editor Konfigurasi

Buka editor dengan:

```bash
mikrotik-backup.sh -e
```

Pindah ke baris bahasa → tekan **Enter** hingga nilai yang diperlukan muncul → pilih “Save.”

Opsi berputar dalam urutan berikut:

```text
auto → ru → en → bahasa eksternal yang terdeteksi menurut urutan alfabet → auto
```

Bahasa formulir langsung berubah. Sebelum disimpan, perubahan ini hanya berupa pratinjau; “Cancel” mengembalikan bahasa antarmuka sebelumnya. Jika `--language` ditentukan saat skrip dimulai, opsi CLI tersebut kembali berlaku setelah Anda keluar dari editor.

Komentar dalam `option.cfg` yang disimpan menggunakan bahasa yang dipilih oleh pengaturan `Language` itu sendiri, bukan opsi CLI sementara. Dengan `auto`, locale sistem operasi juga digunakan untuk komentar tersebut.

Untuk informasi selengkapnya tentang editor, lihat [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Membuat dan mengedit terjemahan

Jika terjemahan yang diperlukan belum ada, Anda dapat menyiapkannya sendiri. Ambil `lang/en.lang` dari versi skrip yang sama, lalu simpan salinannya sebagai `<xx>.lang`, dengan `xx` sebagai kode dua huruf bahasa baru. Templat versi 2.3.1 memuat seluruh 245 kunci.

Formatnya sederhana: setiap pesan memiliki baris tersendiri. Sebagai contoh, templat bahasa Inggris memuat:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Setiap kunci dimulai dengan `msg_`, diikuti nama pesan (`version`, `menu_title`) dan sufiks bahasa `_en`.

Untuk bahasa baru, ganti sufiks `_en` dengan `_xx` pada semua kunci dan terjemahkan hanya nilai di dalam tanda kutip. Jangan ubah nama pesan dan pertahankan semua placeholder secara tepat. Untuk memperbaiki terjemahan yang sudah ada, cukup ubah teks yang diperlukan di sebelah kanan `=`.

Anda tidak harus menerjemahkan seluruh berkas sekaligus: pesan yang belum tersedia ditampilkan dalam bahasa Inggris. Skrip tidak menggunakan kunci baru yang dibuat sembarangan.

### Aturan format berkas

Simpan berkas sebagai UTF-8. Apit setiap nilai dengan tanda kutip ganda dan pastikan nilainya tidak kosong. Jangan tambahkan spasi sebelum kunci, di sekitar `=`, atau setelah tanda kutip penutup.

Gunakan `\"` untuk tanda kutip ganda di dalam teks dan `\\` untuk garis miring terbalik. Escape lain, termasuk `\n` dan `\t`, tidak didukung. Karakter `=` di dalam tanda kutip diperbolehkan.

Baris kosong dilewati. Format `.lang` tidak mendukung komentar; karakter `#` di dalam tanda kutip merupakan bagian dari teks. Akhir baris Windows (CRLF) dan satu BOM di awal berkas didukung.

Baris berformat salah dilewati sementara terjemahan valid lainnya tetap digunakan. Jika suatu pesan ditentukan lebih dari sekali, entri valid terakhir yang berlaku. Karakter kontrol dan kode warna terminal tidak diizinkan dalam terjemahan.

*(Catatan: Berkas pelokalan diperlakukan sebagai data teks. Variabel tidak diekspansi dan perintah shell tidak dieksekusi darinya.)*

### Placeholder dalam pesan

Beberapa string memuat nilai dalam kurung kurawal, misalnya:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Saat dijalankan, skrip mengganti `{index}` dan `{total}` dengan nomor perangkat dan jumlah total perangkat. Jangan terjemahkan penanda ini: pertahankan setiap placeholder dari string sumber tepat satu kali. Anda boleh mengubah posisinya dalam kalimat.

Jika placeholder tidak valid, pesan bahasa Inggris digunakan sebagai pengganti string tersebut.

Setelah menyimpan berkas, periksa terjemahan dalam bantuan dan menu interaktif dengan bahasa tersebut dipilih. Penyebab terjemahan tidak dapat dimuat dibahas di bagian [Pemecahan masalah](TROUBLESHOOTING.md#language-problems).
