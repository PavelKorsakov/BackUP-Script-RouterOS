# Baris perintah

[Daftar isi](../README_ID.md)

## Sintaks

```text
mikrotik-backup.sh [action] [parameters]
```

Parameter baris perintah dapat menggunakan bentuk panjang: `--parameter value` atau `--parameter=value`.
Parameter juga dapat menggunakan bentuk pendek: `-p=value`. Namun, jika **nilai** dimulai dengan `-`, hanya bentuk dengan `=` yang diterima: `--parameter=-value`.

Parameter yang tidak dikenal, argumen posisional, atau nilai yang tidak ada, kosong secara eksplisit, atau tidak valid menghasilkan kode galat `12` dan menghentikan skrip.

<br />

## Tindakan

| Tindakan | Kegunaan |
|---|---|
| `-i` | Menu interaktif utama |
| `-b` | BackUP Master |
| `-e` | Editor Konfigurasi (`option.cfg`) |
| `-h`, `--help` | Bantuan opsi CLI |
| `-v`, `--version` | Versi skrip |

Skrip tidak mengizinkan lebih dari satu opsi tindakan sekaligus. Sebagai contoh, `mikrotik-backup.sh -i -b` berhenti dengan kode galat `12`.

<br />

## Parameter

| Parameter | Nilai | Kegunaan |
|---|---|---|
| `--device-name` | Nama | Nama perangkat ketika `UseIdentityName=false` |
| `--address` | Alamat IP atau nama DNS | Alamat perangkat RouterOS |
| `--user` | Login | Pengguna perangkat RouterOS |
| `--password` | Kata sandi | Kata sandi perangkat RouterOS |
| `--port` | `1`–`65535` | Port SSH perangkat; default `22` |
| `--language` | `auto` atau dua huruf ASCII | Bahasa antarmuka saat ini dan log skrip |
| `--use-oxidized` | Nilai boolean* | Mengimpor daftar perangkat dari Oxidized |
| `--oxidized-home` | Jalur | Direktori pengaturan Oxidized yang berisi `config` dan `router.db` |
| `--use-identity-name` | Nilai boolean* | Mengambil nama dari RouterOS Identity |
| `--backup-root` | Jalur | Direktori akar untuk penyimpanan backup |
| `--use-net-folder` | Nilai boolean* | Memeriksa mount dalam mode batch |
| `--monthly-archive` | `false` atau angka dari `1` hingga `28`* | Mengaktifkan pengarsipan bulanan berbasis kalender |
| `--log-level` | `0`, `1`, `2`, `3` | Tingkat rincian log dan output terminal |
| `--main-log-path` | Jalur | Direktori hanya untuk `main.log` |
| `--backup-type` | `configuration`,`binary`,`both` | Format backup yang akan diambil |
| `--export-format` | `compact`, `terse`, `verbose` | Format ekspor teks |
| `--show-sensitive` | Nilai boolean* | Menyertakan nilai sensitif dalam ekspor |
| `--encrypt` | Kata sandi tidak kosong | Mengenkripsi `.backup` dengan AES-SHA256 |
| `--clear-dns-cache` | Nilai boolean* | Menghapus cache DNS sebelum backup biner |
| `--clear-console-history` | Nilai boolean* | Menghapus riwayat konsol sebelum backup biner |

`*` Nilai boolean adalah `true` atau `false`; skrip juga menerima `yes`/`no`, `1`/`0`, dan `on`/`off`, tanpa membedakan huruf besar-kecil.
Untuk `backup-type`, `config` dan `conf` juga diterima sebagai sinonim `configuration`.

Bentuk koneksi pendek:

```text
-a=VALUE    sama dengan --address VALUE
-u=VALUE    sama dengan --user VALUE
-p=VALUE    sama dengan --password VALUE
```

<br />

<a id="execution-mode"></a>
## Menjalankan skrip dari baris perintah

Skrip dapat membuat backup satu perangkat, tetapi memerlukan setidaknya tiga parameter untuk eksekusi tersebut:
**alamat IP**, **login**, dan **kata sandi** perangkat. Dengan kata lain, perintah berikut sudah dapat digunakan:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Semua parameter lain yang tercantum di atas bersifat opsional dalam hal ini.
*(Catatan: Satu hal yang sangat penting: skrip TIDAK dirancang untuk menggabungkan tiga parameter koneksi ini dengan opsi **tindakan**.)*

**Satu hal lagi!!!**
Untuk eksekusi satu perangkat, ketiga parameter koneksi harus diberikan melalui CLI. Skrip tidak mengambil login atau kata sandi yang tidak diberikan dari `option.cfg`.

<br />

## Prioritas pengaturan

Backup satu perangkat dan batch biasa menggunakan urutan yang dijelaskan dalam [OPTIONS.md](OPTIONS.md):
**Nilai bawaan** → **Baris `option.cfg` yang dapat digunakan** → **CLI**

Jika sebuah parameter sudah ada dalam `option.cfg`, tetapi eksekusi tertentu memerlukan nilai lain, berikan nilai tersebut melalui CLI. Anda tidak perlu menulis ulang berkas konfigurasi.

Eksekusi satu perangkat tidak menggunakan daftar perangkat atau impor Oxidized. Pengaturan lain dari `option.cfg` tetap berlaku kecuali digantikan oleh parameter baris perintah.

**BackUP Master memiliki urutannya sendiri untuk mengisi formulir.**
Kolom biasa menggunakan nilai bawaan dan parameter CLI yang diberikan, bukan `option.cfg`. `UseIncremental` merupakan pengecualian: nilainya diwarisi dari berkas atau menggunakan nilai default.
Nilai `LogLevel` dan `MainLogPath` yang dipilih dipertahankan untuk eksekusi, sedangkan pengarsipan bulanan dinonaktifkan. Lihat [INTERACTIVE.md](INTERACTIVE.md) untuk rincian tentang BackUP Master.

<br />

## Parameter baris perintah menurut kegunaan

### Koneksi dan nama perangkat

| Opsi | Nilai | Kegunaan |
|---|---|---|
| `--address` | Alamat IP atau nama DNS | Alamat perangkat RouterOS |
| `--user` | Login | Pengguna perangkat RouterOS |
| `--password` | Kata sandi | Kata sandi perangkat RouterOS |
| `--port` | `1` hingga `65535` | Port SSH perangkat; default `22` |
| `--device-name` | Nama | Nama perangkat ketika `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Mengambil nama dari RouterOS Identity |

Untuk menggunakan nama Anda sendiri, tentukan `--use-identity-name false` dan `--device-name NAME` secara bersamaan.

<br />

### Format dan isi backup

| Opsi | Nilai | Kegunaan |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Format backup yang akan diambil |
| `--export-format` | `compact`, `terse`, `verbose` | Format ekspor teks |
| `--show-sensitive` | `true` / `false` | Menyertakan nilai sensitif dalam ekspor |
| `--encrypt` | Kata sandi tidak kosong | Mengenkripsi `.backup` dengan AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Menghapus cache DNS sebelum backup biner |
| `--clear-console-history` | `true` / `false` | Menghapus riwayat konsol sebelum backup biner |

Untuk `--backup-type`, `config` dan `conf` juga berarti `configuration`.

*(Catatan: `UseIncremental` tidak memiliki opsi CLI tersendiri. Atur nilainya dalam `option.cfg`, Editor Konfigurasi, atau BackUP Master. Kegunaannya dijelaskan dalam [OPTIONS.md](OPTIONS.md).)*

<br />

### Penyimpanan, pengarsipan, dan log

| Opsi | Nilai | Kegunaan |
|---|---|---|
| `--backup-root` | Jalur | Direktori akar untuk penyimpanan backup |
| `--use-net-folder` | `true` / `false` | Memeriksa mount dalam mode batch |
| `--monthly-archive` | `false` atau angka dari `1` hingga `28` | Mengaktifkan pengarsipan bulanan berbasis kalender |
| `--log-level` | `0`, `1`, `2`, `3` | Tingkat rincian log dan output terminal |
| `--main-log-path` | Jalur direktori | Direktori hanya untuk `main.log` |

`--monthly-archive` memiliki aturan sendiri: `true`/`yes`/`1`/`on` berarti tanggal pertama setiap bulan, sedangkan `false`/`no`/`0`/`off` menonaktifkan pengarsipan. Nilai dari `2` hingga `28` memilih tanggal yang diperlukan.

Opsi ini memilih tanggal pengarsipan; opsi tersebut tidak langsung menjalankan pengarsipan. Lihat [BACKUPS.md](BACKUPS.md#monthly-archive) untuk aturan mode ini.

Untuk `--main-log-path`, tentukan direktori, bukan jalur lengkap yang berakhir dengan `main.log`. Pengaturan ini tidak memengaruhi log perangkat.

<br />

### Sumber daftar perangkat dan bahasa

| Opsi | Nilai | Kegunaan |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Mengimpor daftar perangkat dari Oxidized |
| `--oxidized-home` | Jalur | Direktori pengaturan Oxidized yang berisi `config` dan `router.db` |
| `--language` | `auto` atau kode dua huruf | Bahasa antarmuka saat ini dan log skrip |

Dengan `--language auto`, locale sistem operasi memilih bahasa. Anda dapat memilih bahasa secara eksplisit, seperti `ru`, `en`, atau `de`. Bahasa Rusia dan Inggris tidak memerlukan berkas terjemahan terpisah; terjemahan lain dimuat dari berkas di samping skrip. Jika terjemahan yang sesuai tidak ada, bahasa Inggris digunakan.
Lihat [LOCALIZATION.md](LOCALIZATION.md) untuk rinciannya.

<br />

## Contoh

**Perhatikan!!!**
Secara default, ekspor sensitif, pembersihan cache DNS, dan pembersihan riwayat konsol sebelum backup biner diaktifkan. Contoh satu perangkat di bawah ini menonaktifkan pembersihan dan ekspor sensitif.

*(Catatan: Kata sandi yang diberikan melalui CLI dapat terlihat dalam riwayat shell dan argumen proses. Hal ini juga berlaku untuk kata sandi enkripsi `.backup`, yang dapat terlihat dalam argumen proses anak `ssh`. Lihat [SECURITY.md](SECURITY.md) untuk rinciannya.)*

### Hanya konfigurasi `.rsc`, tanpa data sensitif

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Kedua format, nama perangkat khusus, dan tanpa pembersihan

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Backup biner terenkripsi

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Eksekusi batch dengan direktori terpisah dan pencatatan log terperinci

Contoh ini mengasumsikan bahwa `option.cfg` dan daftar perangkat sudah disiapkan:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Pengaturan lain untuk eksekusi batch ini berasal dari `option.cfg` dan nilai bawaan.

<br />

## Jika perintah ditolak

Opsi yang tidak dikenal, argumen posisional tambahan, atau nilai yang tidak ada maupun tidak valid menyebabkan galat `12`. Backup tidak dimulai. Gunakan `-h` untuk memeriksa ejaan opsi.

**Nilai kosong tidak dapat diberikan melalui CLI.**
`--encrypt=''` dan `--main-log-path=''` ditolak. Tetapkan nilai kosong `encrypt=` dan `MainLogPath=` dalam `option.cfg` atau melalui Editor Konfigurasi.

Kode hasil dan artinya tercantum di bagian [Pemecahan masalah](TROUBLESHOOTING.md#result-codes).
