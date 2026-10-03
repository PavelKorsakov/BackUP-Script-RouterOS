# Keamanan

[Daftar isi](../README_ID.md)

## Akun

Skrip tidak memerlukan hak **root**. Pengguna biasa hanya memerlukan akses ke berkas pengaturan dan izin tulis ke penyimpanan serta log yang dipilih.

Pembuatan pengguna khusus **bsmt** dan konfigurasi skrip agar berjalan dengan akun tersebut dibahas dalam [INSTALL.md](INSTALL.md#menjalankan-skrip-secara-otomatis).

Pada perangkat RouterOS, sebaiknya buat juga pengguna khusus backup dan batasi akses login pengguna tersebut ke alamat IP host yang menjalankan skrip. Izin akun tersebut harus mengizinkan operasi yang dipilih: mengambil konfigurasi, membuat dan mengunduh backup, menghapus berkas sementara, serta menjalankan operasi pembersihan yang diaktifkan.

<br />

## Menghubungkan ke RouterOS

Skrip terhubung melalui SSH dengan autentikasi kata sandi. Kunci SSH dan agen tidak digunakan. Berkas diambil dengan protokol SCP lama, yaitu `scp -O`.

Skrip menggunakan pengaturan koneksinya sendiri. Skrip tidak membaca `~/.ssh/config` milik pengguna atau konfigurasi SSH sistem karena klien dijalankan dengan `-F /dev/null`. Penerusan agen, X11, dan port dinonaktifkan.

**Harap perhatikan!!! Verifikasi kunci host server dinonaktifkan.**

Profil saat ini menggunakan pengaturan berikut:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Berkas `known_hosts` yang biasa digunakan tidak dibaca maupun diubah. Karena itu, skrip tidak memverifikasi apakah server yang merespons benar-benar perangkat yang diharapkan dan bukan penyusup. Pertimbangkan hal ini saat mengatur akses jaringan ke router Anda.

<br />

<a id="secrets"></a>
## Kata sandi saat memulai skrip

Kata sandi yang diberikan melalui `--password` atau `-p=` menjadi bagian dari perintah peluncuran. Kata sandi dapat terlihat dalam argumen proses dan tersimpan dalam riwayat shell. Hal yang sama berlaku untuk kata sandi enkripsi yang diberikan melalui `--encrypt`.

### Memasukkan kata sandi melalui BackUP Master

Untuk menghindari penempatan kata sandi SSH pada baris perintah, jalankan BackUP Master:

```bash
mikrotik-backup.sh -b
```

Isi kredensial perangkat dalam formulir lalu pilih tindakan yang diperlukan. Kedua kata sandi ditampilkan sebagai tanda bintang, dan nilai yang dimasukkan dalam formulir tidak masuk ke riwayat perintah shell.

Saat terhubung, skrip meneruskan kata sandi SSH ke `sshpass` melalui deskriptor berkas (`-d`), bukan melalui argumen `sshpass -p` atau variabel lingkungan `SSHPASS`.

### Kata sandi enkripsi .backup

Kata sandi enkripsi disertakan dalam perintah RouterOS yang diteruskan ke proses anak `ssh`. Karena itu, pengguna host dengan izin yang memadai untuk memeriksa argumen proses dapat melihatnya saat backup biner sedang dibuat.

Memasukkan kata sandi melalui BackUP Master atau menyimpannya dalam `option.cfg` tidak mengubah cara kata sandi diteruskan. Enkripsi berkas tidak memberikan perlindungan terhadap administrator host backup itu sendiri.

### Menyalin perintah konsol

Tindakan “Copy console command” dalam BackUP Master mengirim ke clipboard sebuah perintah yang memuat kredensial koneksi—dan, jika ditetapkan untuk backup biner, kata sandi enkripsi.

Ingat hal ini saat menggunakan riwayat clipboard dan saat menempelkan perintah ke shell. Penyamaran kata sandi dengan tanda bintang dalam formulir tidak berarti kata sandi tersebut disamarkan dalam perintah yang disalin.

<br />

## Berkas yang memuat data sensitif

| Berkas | Isi yang mungkin terdapat di dalamnya |
|---|---|
| `devicelist.cfg` | Alamat perangkat, login, dan kata sandi SSH dalam teks biasa |
| `option.cfg` | Nilai bersama `Login` dan `Password`, serta kata sandi enkripsi `encrypt` |
| `.rsc` dan `.backup` | Konfigurasi perangkat, kata sandi, dan data sensitif lainnya |
| ZIP bulanan | Backup dan log yang sama, dikumpulkan dalam satu arsip |

Jangan letakkan berkas pengaturan kerja atau backup dalam repositori publik maupun direktori yang dapat diakses publik.

### Data sensitif dalam berkas .rsc

Secara default, `show_sensitive=true`, sehingga nilai sensitif disertakan dalam ekspor teks. Untuk menonaktifkannya, tetapkan baris berikut dalam `option.cfg`:

```ini
show_sensitive=false
```

Meskipun demikian, berkas tersebut tetap merupakan konfigurasi perangkat Anda: alamat, struktur jaringan, komentar, dan string lain yang diberikan pengguna tidak hilang darinya.

### Enkripsi backup biner

Secara default, `encrypt` kosong dan `.backup` disimpan tanpa enkripsi. Untuk mengaktifkan enkripsi, tetapkan kata sandi dalam berkas opsi atau kolom BackUP Master yang sesuai:

```ini
encrypt=MySuperPassword
```

Algoritme AES-SHA256 digunakan. Algoritme ini mengenkripsi **hanya `.backup`**, bukan `.rsc`, `option.cfg`, daftar perangkat, log, maupun ZIP itu sendiri. Karena itu, akses ke arsip bulanan harus dibatasi dengan kehati-hatian yang sama seperti akses ke berkas di dalamnya.

<br />

## Izin berkas dan penyimpanan

Skrip berjalan dengan `umask 077`. Direktori penyimpanan lokal yang dibuatnya menerima mode `0700`, sedangkan `option.cfg` dan `devicelist.cfg` ditulis dengan mode `0600` saat disimpan oleh program.

Pemilik dan izin direktori penyimpanan lama yang dibuat administrator tidak diubah secara otomatis. Jika Anda menyiapkan direktori secara manual, Anda harus mengonfigurasi aksesnya sendiri.

Direktori pengarsipan bulanan lokal, `archive/`, harus bermode `0700` dan dimiliki oleh pengguna yang menjalankan skrip. Persyaratan ini juga berlaku untuk direktori yang sudah ada. Berkas arsip lokal yang dibuat skrip bermode `0600`.

Dalam mode batch, ketika penyimpanan jaringan terverifikasi digunakan dengan `UseNetFolder=true`, server NAS dapat menentukan pemilik dan izin objek arsip. Perbedaan dari nilai lokal saja tidak menghentikan pengarsipan. Konfigurasikan akses ke penyimpanan jaringan melalui sistem operasi dan NAS Anda.

Contoh penyiapan direktori dan pemberian akses kepada pengguna **bsmt** tersedia dalam [INSTALL.md](INSTALL.md).

*(Catatan: Skrip membaca konfigurasi, daftar perangkat, terjemahan, dan setiap pengaturan Oxidized yang digunakan sebagai data; skrip tidak mengeksekusinya sebagai skrip shell.)*

<br />

## Perubahan yang dilakukan pada perangkat

Secara default, cache DNS dan riwayat konsol RouterOS dihapus sebelum backup biner dibuat. Jika Anda tidak memerlukan tindakan ini, nonaktifkan dalam `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Anda dapat menonaktifkan fitur yang sama melalui Editor Konfigurasi, BackUP Master, atau opsi CLI terkait. Operasi pembersihan ini tidak dilakukan jika hanya `.rsc` yang diambil.

<br />

## Log dan berbagi informasi diagnostik

Tingkat terperinci `LogLevel=3` menambahkan informasi tentang tahap pemrosesan; tingkat ini tidak menampilkan kata sandi atau perintah koneksi lengkap.

Diagnostik SSH yang telah diproses menyamarkan nilai persis yang diketahui untuk alamat, login, kata sandi SSH, dan kata sandi enkripsi. Hal ini tidak membersihkan isi backup atau menjamin penghapusan setiap rahasia dari teks sembarang.

Berkas sementara yang berisi diagnostik yang belum diproses dapat memuat data sensitif. Berkas tersebut dibuat dengan mode `0600` dan dihapus selama pembersihan normal.

Sebelum mengirim log, tangkapan layar, atau output perintah kepada orang lain, periksa isinya. Output lengkap dari `devicelist.cfg`, daftar proses, atau isi clipboard dapat mengungkapkan data yang tidak ada dalam log biasa.

Untuk informasi selengkapnya tentang entri log, lihat [LOGGING.md](LOGGING.md); untuk bantuan menyelidiki galat, lihat [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Eksekusi serentak

Eksekusi oleh pengguna yang sama dengan `BackupRoot` yang sama menggunakan penguncian:

| Eksekusi serentak | Yang terjadi |
|---|---|
| Satu eksekusi batch dan eksekusi batch atau satu perangkat lainnya | Eksekusi kedua tidak memperoleh kunci |
| Dua eksekusi satu perangkat untuk perangkat yang sama | Eksekusi kedua tidak memperoleh kunci |
| Eksekusi satu perangkat untuk perangkat yang berbeda | Dapat berjalan serentak |

Jika kunci sedang digunakan, skrip keluar dengan kode `32`. Akar penyimpanan yang berbeda tidak dikoordinasikan sebagai satu area penyimpanan ketika salah satunya berada di dalam yang lain.

Berkas pengunci disimpan dalam `/tmp/mikrotik-backup-${UID}/` dan tetap ada setelah skrip selesai. Keberadaannya saja tidak berarti skrip masih berjalan.

**Jangan hapus berkas ini untuk “melepas penguncian lama”.** Kunci terikat pada deskriptor berkas proses yang terbuka, bukan pada keberadaan berkas. Penguncian ini juga tidak melindungi data dari program lain yang memodifikasinya secara langsung.

<br />

## Pengujian pemulihan

Memverifikasi checksum skrip dan berhasil mengambil berkas backup bukan pengganti pengujian pemulihan.

Skrip itu sendiri tidak memulihkan RouterOS. Anda harus memverifikasi secara terpisah bahwa backup dapat digunakan pada perangkat yang sesuai dan menentukan berapa lama backup dipertahankan. Untuk informasi selengkapnya, lihat [BACKUPS.md](BACKUPS.md).
