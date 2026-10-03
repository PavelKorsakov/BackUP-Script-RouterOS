# Konfigurasi

[Daftar isi](../README_ID.md)

## Beberapa hal sebelum memulai

Berkas opsional `option.cfg` memungkinkan Anda mengubah pengaturan default yang digunakan skrip.
Agar skrip memuat pengaturan yang tercantum dalam berkas ini saat dijalankan,
`option.cfg` harus berada di samping `mikrotik-backup.sh` dalam direktori yang sama.

Struktur berkasnya sangat sederhana: daftar entri `Key=value`. Berkas ini bukan skrip shell.
Tidak ada ekspansi variabel atau eksekusi perintah di dalamnya.

## Kapan konfigurasi dapat digunakan untuk eksekusi

Satu baris yang valid dan dikenali sudah cukup untuk membuat konfigurasi dapat digunakan.
Anda tidak perlu mencantumkan setiap pengaturan: jika suatu nilai default sesuai, opsi tersebut tidak perlu ada dalam `option.cfg`.

Namun, jika berkas kosong atau hanya berisi komentar, kunci yang tidak dikenal, atau nilai yang tidak valid, skrip tidak memiliki apa pun untuk dimuat darinya.
Pengaturan kemudian tetap memakai nilai default.

**Dan di sinilah letak jebakannya!!!**
Jika Anda menjalankan skrip tanpa argumen dalam keadaan tersebut, backup tidak dimulai. Sebagai gantinya, skrip mencoba membuka Editor Konfigurasi.
Hal yang sama terjadi jika `option.cfg` sama sekali tidak ada.
Simpan pengaturan yang diperlukan lalu jalankan kembali skrip.
*(Catatan: Editor memerlukan terminal. Jika skrip dijalankan tanpa terminal—misalnya oleh penjadwal—skrip keluar dengan galat `31`.
Siapkan `option.cfg` sebelum mengonfigurasi eksekusi otomatis.)*

**Urutan pembacaan parameter opsional:**
Skrip menerapkan sumber parameter menurut urutan prioritas. Jika `option.cfg` tidak ada, skrip menggunakan nilai default yang tertanam.
Jika berkas tersedia dan berhasil dibaca, parameter <mark>valid</mark> di dalamnya menggantikan nilai default yang sesuai.

Dan yang terpenting!!! Jika parameter yang sama diberikan melalui CLI, nilai dari CLI lebih diprioritaskan.
Dengan demikian, untuk eksekusi satu perangkat atau batch biasa, urutan prioritasnya adalah:
**Nilai bawaan** → **Baris `option.cfg` yang dapat digunakan** → **CLI**

*(Catatan: Berkas yang tidak ada berbeda dari berkas yang tidak dapat dibaca.
Jika `option.cfg` tersedia tetapi tidak dapat dibaca oleh skrip, eksekusi berakhir dengan
galat konfigurasi `21`; skrip tidak melanjutkan dengan nilai default.)*

## Cara berkas dibaca

Setiap baris dipisahkan pada karakter `=` pertama. Nama kunci tidak membedakan huruf besar-kecil, tetapi tanda hubung dan garis bawah tidak dapat saling menggantikan.
Baris kosong dan baris yang karakter pertama selain spasinya adalah `#` diabaikan. Baris yang tidak dikenal atau tidak valid tidak membatalkan baris valid di dekatnya.
Jika suatu kunci muncul lebih dari sekali, nilai valid terakhir digunakan.

Spasi di awal dan akhir nilai biasa dihapus.
**Penting:** untuk `Login`, `Password`, dan `encrypt`, semua yang muncul setelah `=` pertama dipertahankan secara harfiah.
Jangan tambahkan tanda kutip mengikuti sintaks shell: tanda kutip akan menjadi bagian dari nilai.
Jangan letakkan komentar setelah kata sandi. Gunakan baris terpisah untuk komentar.

Satu BOM di awal berkas dan akhir baris CRLF didukung.
Tautan simbolis yang dapat dibaca menuju berkas biasa diperbolehkan.
Masalah akses atau jenis objek yang tidak sesuai tidak diperlakukan sebagai berkas kosong
dan menyebabkan galat konfigurasi.

## Membuat, mengedit, dan menyimpan `option.cfg`

Cara termudah untuk membuat berkas adalah menjalankan skrip dengan `-e`:

```bash
./mikrotik-backup.sh -e
```

Editor Konfigurasi terbuka dan menampilkan opsi utama.
Jika semua baris tidak muat di jendela terminal, daftar akan bergulir otomatis saat Anda bergerak ke atas dan bawah dengan tombol panah.
Item **Save** dan **Cancel** berada di bagian akhir daftar yang sama.
Telusuri menu, masukkan pengaturan yang diperlukan → pilih **Save** → dan (Anda luar biasa) berkas pun selesai dibuat.

Ingatlah bahwa selama Anda bekerja di menu interaktif, editor hanya mengubah pengaturan dalam memori.
Berkas *kanonis* yang lengkap baru ditulis setelah Anda memilih **Save**.

Jika `option.cfg` belum ada, editor mula-mula mengisi kolomnya dengan nilai default.
Jika berkas sudah ada dan Anda telah mengubah beberapa parameter, Editor Konfigurasi mengisi kolom dengan nilai Anda, bukan nilai default.

Cara kedua untuk membuat `option.cfg` adalah secara manual. Ya: buka editor teks favorit Anda dengan tangan sendiri dan masukkan pengaturan yang diperlukan.
Di mana pengaturan itu dapat ditemukan? Tepat di bawah ini:

## Pengaturan dan nilai default

| Kunci | Default | Nilai dan kegunaan |
|---|---|---|
| `Language` | `auto` | `auto` atau dua huruf ASCII, seperti `ru`, `en`, atau `de` |
| `SshPort` | `22` | Port `1`–`65535`; tersembunyi di editor, terlihat di BackUP Master |
| `UseOxidized` | `false` | Mengimpor perangkat dari Oxidized |
| `IgnoreOxiAccess` | `true` | Mengizinkan DeviceList sebelumnya setelah kegagalan pembacaan/penguraian Oxidized; hanya dalam berkas |
| `OxidizedHome` | Kosong | Direktori yang berisi `config` dan `router.db` |
| `UseIdentityName` | `true` | Menggunakan RouterOS Identity saat ini sebagai nama perangkat |
| `backup_type` | `both` | `configuration`, `binary`, atau `both` |
| `UseIncremental` | `true` | Membandingkan backup baru yang telah diverifikasi dengan backup sebelumnya; jika `false`, menyimpan setiap backup baru tanpa membandingkannya |
| `export_format` | `compact` | `compact`, `terse`, atau `verbose` |
| `show_sensitive` | `true` | Menyertakan nilai sensitif dalam `.rsc` |
| `encrypt` | Kosong | Kata sandi untuk mengenkripsi `.backup`; kosong berarti tanpa enkripsi |
| `encrypt_type` | `aes-sha256` | Algoritme tetap; hanya dalam berkas |
| `clear_dns_cache` | `true` | Menghapus cache DNS sebelum backup biner |
| `clear_console_history` | `true` | Menghapus riwayat konsol sebelum backup biner |
| `BackupRoot` | `backups` | Direktori akar untuk penyimpanan backup |
| `UseNetFolder` | `false` | Mewajibkan mount terpisah dalam mode batch |
| `MonthlyArchive` | `false` | Menonaktifkan pengarsipan (`false`) atau menetapkan tanggal dalam bulan dari `1` hingga `28` |
| `LogLevel` | `2` | Tingkat `0`, `1`, `2`, atau `3` |
| `MainLogPath` | Kosong | Direktori hanya untuk `main.log`; kosong berarti `BackupRoot` saat ini |
| `Login` | Kosong | Login bersama yang diwarisi oleh kolom DeviceList kosong; hanya dalam berkas |
| `Password` | Kosong | Kata sandi bersama yang diwarisi oleh kolom DeviceList kosong; hanya dalam berkas |

Dengan `Language=auto`, locale sistem operasi memilih bahasa antarmuka dan log.
Terjemahan eksternal menggunakan kode bahasa dua huruf dari locale tersebut: misalnya, `de_DE.UTF-8` memerlukan `de.lang` di samping skrip.
Jika terjemahan yang sesuai tidak tersedia, bahasa Inggris digunakan.

`MonthlyArchive` mengikuti aturan yang sedikit berbeda: `false`/`no`/`0`/`off` menonaktifkan pengarsipan; `true`/`yes`/`1`/`on` berarti tanggal pertama setiap bulan; dan nilai dari `2` hingga `28` memilih tanggal yang diperlukan.

Ketika Editor Konfigurasi menyimpan berkas, editor menulis
`MonthlyArchive=false` atau angka yang dipilih.

Parameter boolean menerima `true`/`false`, `yes`/`no`, `1`/`0`, dan `on`/`off`
tanpa membedakan huruf besar-kecil. Editor menulis `true`/`false`.

Kolom seperti `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login`, dan `Password` tidak muncul di Editor Konfigurasi.

Saat menyimpan berkas, editor menulis `IgnoreOxiAccess`, `encrypt_type`, dan `SshPort`.
Editor mempertahankan `Login` dan `Password` hanya jika baris tersebut sudah ada dalam `option.cfg`, termasuk baris dengan nilai kosong.

Kolom `SshPort`, `Login`, dan `Password` dapat berguna jika semua perangkat Anda menggunakan port SSH dan login yang sama—nama pengguna dan kata sandi yang sama. Dalam hal ini, setiap entri dalam `devicelist.cfg` hanya memerlukan dua nilai: **nama** perangkat dan **alamat IP**-nya.

## Contoh tanpa pembersihan atau ekspor sensitif

Ini adalah contoh kebijakan yang dipilih, **bukan daftar nilai default pabrik**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

Sebanyak 19 kunci pertama ditampilkan dalam urutan penulisan kanonis.
Baris `Login` dan `Password` lama yang kompatibel dipertahankan setelahnya.

Pengaturan yang tidak dicantumkan menggunakan nilai bawaan, bukan nilai dari contoh di dekatnya.
Sebagai contoh, berkas yang hanya berisi `Language=ru` tidak menonaktifkan pembersihan dan tidak mengubah `show_sensitive=true`.

## Jalur

```ini
BackupRoot=backups
MainLogPath=logs
```

Entri ini berarti direktori `backups` dan `logs` di samping skrip.
Jalur absolut mempertahankan artinya. `$HOME` dan `~` tidak diekspansi
sebagai variabel atau direktori home.

`BackupRoot` yang belum ada dibuat saat eksekusi jika izin memungkinkan.
Direktori akar sistem berkas, `/`, dilarang sebagai penyimpanan.
Untuk direktori yang sudah ada, program tidak otomatis memperbaiki kepemilikan atau izin.

`MainLogPath` yang tidak kosong harus menunjuk ke **direktori yang sudah ada dan dapat ditulisi**.
Pembuatan `main.log` sendiri ditunda hingga entri pertama ditulis;
hal ini tidak membuat direktori induknya. Jika log tidak dapat ditulis, pemrosesan
backup dilanjutkan dengan peringatan. Pengaturan ini tidak memindahkan log perangkat.

<a id="network-storage"></a>
## Jaringan dan penyimpanan terpisah

`UseNetFolder=true` berlaku dalam mode batch. Jalur tersebut harus tercakup oleh entri mount
selain entri untuk `/`. Penyimpanan terpisah dapat berupa penyimpanan jaringan,
disk lokal, atau bind mount; nama opsi tidak membatasi jenis sistem berkas.

Direktori biasa pada sistem berkas akar yang sama tidak memenuhi persyaratan ini.
Skrip memeriksa ketersediaan dan status mount, tetapi tidak memanggil `mount`, `umount`,
atau `sudo`, serta tidak diam-diam beralih ke penyimpanan lokal.

## Parameter terkait

Dengan `UseIncremental=false`, skrip tidak membandingkan backup baru dengan backup sebelumnya dan menyimpan setiap berkas baru yang berhasil dibuat serta diverifikasi.
Pengaturan ini tidak memengaruhi pembuatan backup itu sendiri maupun pengarsipan bulanan.
Nilai default-nya adalah `UseIncremental=true`. Jika `option.cfg` Anda belum memuat parameter ini, perbandingan tetap diaktifkan.

`backup_type=configuration` tidak menggunakan enkripsi backup biner
atau operasi pembersihan yang mendahului backup biner. `backup_type=binary` tidak menggunakan `export_format`
atau `show_sensitive`. `UseOxidized=false` tidak menggunakan `OxidizedHome`.

Dengan `UseIdentityName=true`, kegagalan membaca Identity tidak digantikan
dengan `--device-name` atau nama dari DeviceList. Untuk menggunakan nama yang ditentukan, nonaktifkan
`UseIdentityName`: lihat [aturan penamaan](DEVICES.md#device-names).

Dengan `MonthlyArchive=true`, pengarsipan dijalankan ketika skrip dimulai pada tanggal yang dipilih setiap bulan,
menurut waktu lokal host. Jam pelaksanaannya tidak berpengaruh.
Jika skrip tidak berjalan pada tanggal tersebut, percobaan pengarsipan yang terlewat tidak dikejar kemudian.

[BACKUPS.md](BACKUPS.md#monthly-archive) menjelaskan berkas yang dimasukkan ke arsip, lokasi pembuatannya, dan cara penamaannya.
Periode data, batas waktu, dan percobaan yang terlewat juga ditetapkan dalam
[BACKUPS.md](BACKUPS.md#monthly-archive).

Konfigurasi dapat memuat rahasia. Batasi akses dan jangan simpan
berkas tersebut dalam repositori publik: [SECURITY.md](SECURITY.md).
