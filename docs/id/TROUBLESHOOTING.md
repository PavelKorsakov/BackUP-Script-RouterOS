# Pemecahan masalah

[Daftar isi](../README_ID.md)

## Langkah awal

Jika backup tidak dimulai atau berakhir dengan galat, periksa log terlebih dahulu. `main.log` memuat tahap keseluruhan eksekusi, sedangkan rincian backup perangkat tertentu ditulis ke log perangkat tersendiri.

Cari entri bertanda `[ER]` dan kode galat. Kode dijelaskan [di bawah](#result-codes), dan lokasi log dijelaskan dalam [LOGGING.md](LOGGING.md).

Gunakan perintah berikut untuk menampilkan versi skrip yang terpasang dan referensi opsi:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Untuk mengulangi eksekusi batch yang sudah dikonfigurasi dengan output terperinci:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

Perintah kedua menampilkan hasil eksekusi yang telah selesai. Perintah tersebut tidak mengubah tingkat log dalam `option.cfg`.

<br />

## Skrip tidak memulai backup

### Editor terbuka alih-alih backup

Jika skrip dimulai tanpa opsi, ini berarti `option.cfg` tidak ada dalam direktori skrip atau tidak memuat pengaturan yang dapat digunakan. Berkas kosong, berkas yang hanya berisi komentar, atau pengaturan yang tidak dikenal tidak mengubah hasilnya.

Buka Editor Konfigurasi, pilih pengaturan yang diperlukan, simpan berkas, lalu jalankan kembali skrip:

```bash
mikrotik-backup.sh -e
```

Menyimpan perangkat melalui BackUP Master membuat `devicelist.cfg`, tetapi tidak menggantikan penyiapan `option.cfg`.

*(Catatan: Jika eksekusi seperti ini dimulai oleh penjadwal, editor tidak dapat terbuka dan skrip keluar dengan kode `31`. Pengaturan untuk eksekusi otomatis harus disiapkan sebelumnya.)*

### Galat opsi, kode 12

Periksa nama opsi, nilainya, dan kombinasi tindakan. Kemungkinan penyebabnya meliputi opsi yang tidak dikenal, nilai kosong, beberapa tindakan berbeda yang diminta sekaligus, atau kredensial yang tidak lengkap untuk koneksi satu perangkat.

Eksekusi satu perangkat melalui CLI memerlukan alamat, login, dan kata sandi. Kredensial yang tidak diberikan tidak diisi dari `option.cfg`.

Opsi koneksi pendek harus menggunakan `=`: `-a=`, `-u=`, dan `-p=`. Perhatikan bahwa `-p` menentukan kata sandi; gunakan `--port` untuk port SSH.

Semua opsi dan contoh yang diterima tercantum dalam [CLI.md](CLI.md).

### option.cfg tidak dapat dibaca, kode 21

Pastikan `option.cfg` merupakan berkas biasa yang dapat dibaca oleh pengguna yang menjalankan skrip. Tautan simbolis yang dapat dibaca menuju berkas tersebut juga diperbolehkan.

Berkas yang tidak ada dan berkas yang tidak dapat dibaca merupakan situasi berbeda. Jika berkas tersedia tetapi tidak dapat dibaca, skrip tidak melanjutkan dengan pengaturan default.

### Dependensi tidak tersedia, kode 30

Periksa utilitas utama dengan:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Pengoperasian batch dengan `UseNetFolder=true` juga memerlukan `findmnt`. Pada tanggal pengarsipan bulanan, `zip`, `unzip`, dan GNU `mv` diperlukan. Penyalinan perintah konsol dari BackUP Master memerlukan GNU `base64` yang mendukung `--wrap=0`.

**Keberadaan utilitas yang sudah terpasang saja tidak cukup.** OpenSSH yang terpasang harus mendukung opsi yang digunakan dan `scp -O`; GNU `timeout` harus mendukung `--signal` dan `--kill-after`.

Daftar dependensi lengkap dan perintah pemasangan tersedia dalam [INSTALL.md](INSTALL.md#dependensi).

### Menu tidak terbuka, kode 31

Menu, editor, dan BackUP Master memerlukan terminal serta utilitas `stty` yang berfungsi. Jangan memulainya melalui pipe atau dengan input maupun output standar yang dialihkan.

Jika pesan menyatakan terminal terlalu kecil, perbesar jendela. Layar utama memerlukan lebar setidaknya 46 kolom, sedangkan petunjuk bawaan memerlukan 80. Daftar panjang dalam editor dan BackUP Master bergulir dengan tombol panah; seluruh formulir tidak harus muat sekaligus di layar.

Kontrol antarmuka dijelaskan dalam [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Daftar perangkat tidak dimuat

### Berkas devicelist.cfg, kode 22 dan 23

Periksa lokasi berkas dan aksesnya. `devicelist.cfg` harus berada di samping `mikrotik-backup.sh`, terlepas dari direktori tempat Anda memulai skrip.

Kolom dipisahkan oleh karakter TAB yang sebenarnya, bukan spasi. Perangkat harus memiliki nama, alamat, login, kata sandi, dan port SSH yang valid. Kredensial bersama dapat berasal dari `option.cfg` jika kolom entri terkait kosong.

Entri yang tidak valid dilewati dengan peringatan. Jika tidak ada perangkat yang memenuhi syarat, tidak ada perangkat yang dapat dicadangkan dan skrip keluar dengan galat daftar.

Periksa juga koneksi duplikat serta perangkat berbeda dengan nama yang sama. Format berkas, pewarisan kredensial, dan aturan penanganan duplikat dibahas dalam [DEVICES.md](DEVICES.md).

### Mengimpor dari Oxidized, kode 24 dan 25

Kode `24` berarti berkas `config` atau `router.db` dalam `OxidizedHome` tidak dapat dibaca. Kode `25` berkaitan dengan isinya: skema yang tidak didukung, data yang tidak valid, atau tidak adanya perangkat MikroTik yang memenuhi syarat.

Periksa jalur, akses ke kedua berkas, sumber `csv`, pemisah, peta kolom, dan definisi model `routeros`. Data secara khusus dibaca dari `<OxidizedHome>/router.db`; pengaturan Oxidized `source.csv.file` tidak mengubah jalur tersebut.

Dengan `IgnoreOxiAccess=true`, skrip dapat melanjutkan dengan daftar sebelumnya yang memenuhi syarat. Namun, kegagalan impor tetap menjadi bagian dari hasil eksekusi. Dengan `false`, daftar lama tidak digunakan untuk eksekusi tersebut.

Konfigurasi impor dijelaskan dalam [DEVICES.md](DEVICES.md#mengimpor-dari-oxidized).

<br />

## Penyimpanan dan penguncian

### Kunci sedang digunakan, kode 32

Periksa apakah tugas lain sedang menggunakan direktori backup yang sama. Untuk eksekusi oleh satu pengguna, backup batch berkonflik dengan backup lain yang menggunakan `BackupRoot` yang sama. Dua eksekusi satu perangkat untuk perangkat yang sama juga tidak dapat berjalan bersamaan dalam penyimpanan tersebut.

Tunggu hingga tugas aktif selesai, lalu jalankan kembali skrip.

**Jangan hapus berkas pengunci untuk “membebaskan” penyimpanan.** Berkas tersebut tetap ada setelah skrip selesai; proses itu sendiri yang memegang kunci. Keberadaan berkas dalam `/tmp/mikrotik-backup-${UID}/` tidak berarti kunci sedang digunakan.

### Tidak ada akses ke direktori

Periksa jalur `BackupRoot`, izin pengguna, ruang kosong, dan ketersediaan perangkat penyimpanan itu sendiri. Jalur relatif ditafsirkan terhadap direktori skrip. Akar sistem berkas, `/`, tidak dapat digunakan untuk menyimpan backup.

Jika skrip sebelumnya berjalan sebagai root dan sekarang berjalan sebagai **bsmt**, pengguna tersebut mungkin tidak dapat mengakses direktori dan berkas lama. Penyiapan izin dibahas dalam [INSTALL.md](INSTALL.md#menjalankan-skrip-secara-otomatis).

Pengoperasian batch dengan `UseNetFolder=true` memerlukan mount terpisah. Periksa dengan:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Ganti jalur pertama dengan jalur Anda. Jika kedua jalur termasuk dalam entri mount yang sama, direktori biasa pada sistem berkas akar tidak memenuhi `UseNetFolder=true`. Skrip tidak memasang penyimpanan dengan sendirinya.

Kode `64` berarti terjadi kegagalan pada direktori perangkat atau arsipnya ketika penyimpanan bersama masih tersedia. Pemrosesan perangkat lain dapat berlanjut. Kode `65` berarti penyimpanan bersama terputus atau keadaannya menjadi tidak valid, sehingga sisa pemrosesan batch dihentikan.

Aturan penyimpanan jaringan dijelaskan dalam [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Galat saat menangani perangkat

### SSH dan transfer berkas, kode 40–43

Periksa alamat perangkat, ketersediaan layanan SSH-nya, login, kata sandi, dan port. Jika port tidak ditentukan dalam `devicelist.cfg`, nilai `SshPort` dari pengaturan digunakan; nilai default-nya `22`.

Pengguna RouterOS harus memiliki izin untuk operasi yang dipilih: mengekspor konfigurasi, membuat dan mengambil backup, menghapus berkas sementara, serta melakukan operasi pembersihan yang diaktifkan.

**Dan ada satu hal yang perlu dicermati!!!** Koneksi yang berhasil dengan perintah SSH biasa Anda tidak berarti skrip menggunakan pengaturan yang sama. Skrip bekerja dengan kata sandi dan tidak menggunakan agen SSH, kunci, atau `~/.ssh/config` biasa. Berkas diambil melalui `scp -O`.

Kode `40` berkaitan dengan koneksi atau transport SSH/SCP, `41` dengan autentikasi, `42` dengan perintah RouterOS atau responsnya, dan `43` dengan transfer berkas. Pengaturan koneksi dijelaskan lebih lanjut dalam [SECURITY.md](SECURITY.md#menghubungkan-ke-routeros).

### Galat penamaan, kode 50 dan 52

Kode `50` berarti nama akhir perangkat tidak valid. Periksa sumber nama yang dipilih dan isi tanda kurung: dalam versi saat ini, bagian lengkap pertama yang tidak kosong di dalam tanda kurung digunakan sebagai nama.

Setelah diproses, nama harus terdiri dari 1 hingga 32 karakter. Nama yang terlalu panjang tidak dipotong. Nama yang dicadangkan seperti `CON` dan `NUL` juga ditolak.

Kode `52` berarti nama akhir menduplikasi nama perangkat lain dalam eksekusi yang sama. Perbandingan tidak membedakan huruf besar-kecil: `Router-A` dan `router-a` dianggap identik.

Sumber nama dan aturan pemrosesan dijelaskan dalam [DEVICES.md](DEVICES.md#device-names).

### Validasi backup gagal, kode 51 dan 53

Kode `51` berlaku untuk `.rsc`, dan kode `53` untuk `.backup`. Berkas yang diambil gagal divalidasi—misalnya berkas kosong atau ukurannya tidak sama dengan berkas pada perangkat.

Periksa tahap ketika galat terjadi, serta ruang kosong dan izin pada host maupun RouterOS. Setelah percobaan gagal, skrip mencoba sekali lagi setelah 2 detik. Percobaan untuk kedua format dilakukan secara terpisah, sehingga satu berkas dapat berhasil diambil sementara berkas lain gagal.

Peringatan tentang kegagalan menghapus berkas sementara RouterOS setelah backup berhasil diambil tidak dengan sendirinya berarti backup lokal rusak.

<br />

## Tidak ada backup baru, tetapi juga tidak ada galat

Periksa `UseIncremental` terlebih dahulu. Ketika perbandingan diaktifkan, backup baru dapat dihapus sebagai duplikat sementara backup sebelumnya dipertahankan. Untuk `.rsc`, isi dibandingkan tanpa tanggal dalam header standar; untuk `.backup`, hanya ukuran berkas yang dibandingkan.

Dengan `UseIncremental=false`, backup baru yang valid dipertahankan tanpa perbandingan ini.

Perlu diingat juga bahwa dua eksekusi untuk perangkat dan direktori yang sama dalam satu menit menggunakan nama berkas yang sama. Versi terpisah tidak dibuat untuk eksekusi kedua.

Jika pengarsipan bulanan berjalan pada hari tersebut, periksa juga ZIP. Dalam mode satu perangkat melalui CLI, backup baru juga mungkin berada di dalamnya. Aturan retensi lengkap tersedia dalam [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## Arsip bulanan tidak muncul

Periksa nilai `MonthlyArchive` dan tanggal eksekusi menurut waktu lokal host. `false` menonaktifkan pengarsipan; `true` atau `1` memilih tanggal pertama, sedangkan angka dari `2` hingga `28` memilih tanggal tersebut dalam bulan.

Pada tanggal yang dipilih, jam eksekusi tidak berpengaruh. Jika tanggal tersebut terlewat, eksekusi biasa setelahnya tidak mengejar percobaan yang terlewat. Pengarsipan bulanan tidak dilakukan melalui BackUP Master.

Jika tidak ada yang perlu diarsipkan, ZIP kosong tidak dibuat.

### Lokasi ZIP

Nama arsip mengikuti hari kalender sebelumnya. Sebagai contoh, eksekusi pada 1 Oktober 2026 membuat `30.09.2026.zip`:

| Mode | Lokasi |
|---|---|
| Batch | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Satu perangkat melalui CLI | `<BackupRoot>/30.09.2026.zip` |

Nama direktori `archive/` ditulis dengan huruf kecil. Eksekusi lain pada hari yang sama memperbarui ZIP yang sama.

### Pengarsipan berakhir dengan galat

Untuk kode `70` dan `71`, periksa log perangkat, akses ke direktori arsip, ruang kosong, dan keadaan ZIP yang sudah ada. Ruang diperlukan baik di penyimpanan maupun dalam `/tmp` lokal.

Pada disk lokal, direktori `archive/` harus dimiliki oleh pengguna skrip dan bermode `0700`. Dalam mode batch dengan penyimpanan jaringan terverifikasi dan `UseNetFolder=true`, pemilik berbeda atau izin yang ditetapkan NAS tidak dengan sendirinya menjadi alasan kegagalan. Galat penyimpanan selama pengarsipan juga dapat menghasilkan kode `64` atau `65`.

Periksa arsip yang sudah ada dengan perintah berikut dan ganti jalurnya dengan jalur sebenarnya:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Berkas sumber tidak dihapus hingga ZIP yang telah diverifikasi berhasil disimpan. Jika arsip tersimpan tetapi beberapa berkas sumber tidak dapat dihapus, ZIP dan berkas yang tidak terhapus tetap ada. Arsip lama yang rusak tidak otomatis diganti dengan arsip baru.

**Jangan hapus backup atau log yang tersisa sebelum Anda memeriksa isi arsip.** Urutan pengarsipan dijelaskan dalam [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Tidak ada log atau output di layar

Dengan `LogLevel=0` dan tanpa galat, log baru tidak dibuat. Jika tidak demikian, periksa `BackupRoot`, `MainLogPath`, dan izin tulis yang dipilih.

`MainLogPath=` yang kosong membiarkan `main.log` dalam `BackupRoot`. Jika direktori terpisah ditentukan, direktori tersebut harus sudah ada dan dapat diakses oleh pengguna skrip. Pengaturan ini tidak memindahkan log perangkat.

Setelah pengarsipan bulanan, riwayat perangkat sebelumnya berada di dalam ZIP. Pekerjaan berikutnya ditulis ke log baru di samping backup.

Ketika skrip berjalan dari penjadwal atau dengan output yang dialihkan, log di layar beserta indikator dan tanda berwarnanya tidak tampil. Pencatatan ke berkas tidak dinonaktifkan oleh hal ini.

Galat penulisan log tidak menghentikan backup itu sendiri, tetapi muncul dalam hasil eksekusi sebagai peringatan. Lihat [LOGGING.md](LOGGING.md) untuk rinciannya.

<br />

<a id="language-problems"></a>
## Terjemahan tidak diterapkan

Periksa bahasa yang dipilih dan lokasi berkas. Sebagai contoh, `Language=de` memerlukan berkas biasa yang dapat dibaca bernama `de.lang` di samping `mikrotik-backup.sh`, bukan di dalam direktori `lang/`. Tautan simbolis tidak digunakan sebagai berkas terjemahan.

Dengan `Language=auto`, lingkungan sistem operasi menentukan bahasa. Anda dapat memilihnya secara eksplisit untuk satu eksekusi, misalnya saat menampilkan bantuan:

```bash
mikrotik-backup.sh --language=de --help
```

Pesan yang belum diterjemahkan ditampilkan dalam bahasa Inggris. Baris berformat salah dalam berkas dilewati. Berkas bernama `ru.lang` dan `en.lang` tidak menggantikan terjemahan bawaan.

Format baris, nama kunci, dan aturan pemuatan terjemahan dijelaskan dalam [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Pengaturan tidak berpengaruh

Periksa nama pengaturan, nilai yang diterima, dan entri duplikat dalam `option.cfg`. Ketika pengaturan diulang, nilai terakhir yang dapat digunakan akan berlaku. Nama kunci tidak membedakan huruf besar-kecil, tetapi tanda hubung dan garis bawah tidak dapat saling menggantikan.

Opsi CLI menggantikan nilai yang sesuai dari berkas. Untuk eksekusi satu perangkat dan batch biasa, urutannya adalah:

**Nilai bawaan** → **Baris `option.cfg` yang dapat digunakan** → **CLI**

BackUP Master mengisi formulirnya dengan cara berbeda: kolom biasa berasal dari nilai bawaan dan CLI, bukan berkas opsi. `UseIncremental` merupakan pengecualian. Pengaturan log dari berkas juga dipatuhi ketika backup dijalankan melalui BackUP Master.

Aturan pembacaan pengaturan tersedia dalam [OPTIONS.md](OPTIONS.md), dan perilaku BackUP Master dibahas dalam [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Kode hasil

| Kode | Arti |
|---:|---|
| `0` | Berhasil tanpa galat atau peringatan yang tercatat |
| `1` | Selesai dengan peringatan dan tanpa galat eksekusi yang tercatat |
| `12` | Galat pada opsi CLI, nilainya, atau kombinasinya |
| `21` | `option.cfg` tidak dapat dibaca |
| `22` | Daftar perangkat tidak dapat diperoleh |
| `23` | Daftar perangkat tidak valid atau tidak memiliki entri yang memenuhi syarat |
| `24` | Berkas Oxidized tidak dapat dibaca |
| `25` | Skema tidak didukung atau data Oxidized tidak valid; tidak ada entri MikroTik yang memenuhi syarat |
| `30` | Utilitas yang diperlukan tidak tersedia atau tidak mendukung kemampuan yang diperlukan |
| `31` | Terminal tidak tersedia, galat `stty`, atau ukuran jendela tidak memadai |
| `32` | Kunci yang diperlukan sedang dipegang oleh eksekusi lain |
| `33` | Jalur atau objek penyimpanan tidak valid untuk eksekusi satu perangkat |
| `34` | Direktori eksekusi satu perangkat tidak dapat dibuat atau disiapkan |
| `35` | Galat saat mengakses atau memvalidasi objek layanan lokal, termasuk kunci |
| `36` | Penyimpanan eksekusi satu perangkat gagal dalam pemeriksaan ketersediaan sebelum pengambilan berkas |
| `37` | Berkas layanan tidak dapat ditulis atau diganti |
| `40` | Galat koneksi atau transport SSH/SCP |
| `41` | Galat autentikasi perangkat |
| `42` | Galat pada perintah RouterOS atau respons yang diharapkan |
| `43` | Galat transfer berkas melalui SCP |
| `50` | Nama akhir perangkat tidak valid |
| `51` | Berkas `.rsc` gagal divalidasi |
| `52` | Nama akhir perangkat terduplikasi |
| `53` | Berkas `.backup` gagal divalidasi |
| `61` | Penyimpanan bersama tidak tersedia saat menyiapkan eksekusi batch |
| `62` | Mount terpisah untuk `UseNetFolder=true` tidak dapat dikonfirmasi atau diaktifkan |
| `63` | Galat saat menyiapkan atau memvalidasi direktori backup batch bersama |
| `64` | Galat penyimpanan perangkat atau arsip ketika penyimpanan bersama tetap tersedia |
| `65` | Penyimpanan bersama terputus atau menjadi tidak valid selama eksekusi; pemrosesan batch berhenti |
| `70` | Galat saat membuat atau memperbarui arsip |
| `71` | ZIP atau objek arsip tujuan gagal divalidasi |
| `80` | Galat internal atau persyaratan sistem tidak terpenuhi, termasuk kemampuan `C.UTF-8` |
| `81` | Galat internal driver MikroTik |
| `129` | Dihentikan oleh sinyal HUP |
| `130` | Dihentikan oleh sinyal INT, misalnya dengan menekan Ctrl+C |
| `143` | Dihentikan oleh sinyal TERM |

Kode akhir mencerminkan galat eksekusi pertama yang tercatat. Peringatan `1` digantikan oleh galat pertama tersebut, dan keberhasilan setelahnya tidak menghapus galat itu. Karena itu, kode akhir belum tentu sama dengan pesan terakhir dalam log.

Jika percobaan ulang pengambilan berkas berhasil, tahap dapat berakhir dengan `[OK]` meskipun galat dari percobaan pertama tetap ada dalam log. Kode akhir nonnol dari eksekusi batch juga tidak berarti semua perangkat gagal: periksa setiap hasil secara terpisah.

Untuk kode `80`, perhatikan persyaratan sistem: GNU Bash 4.4 atau yang lebih baru dan locale `C.UTF-8` yang berfungsi. Rinciannya tersedia dalam [INSTALL.md](INSTALL.md#persyaratan-host).

<br />

## Jika Anda memerlukan bantuan

Berikan versi skrip, sistem operasi dan versi Bash, cara skrip dimulai, kode keluarnya, serta cuplikan log yang relevan. Untuk masalah pada satu perangkat, sertakan log perangkatnya; untuk galat saat menyiapkan eksekusi, mulailah dengan `main.log`.

**Jangan kirim kata sandi asli atau berkas pengaturan kerja lengkap.** Sebelum mengirim log, tangkapan layar, atau perintah, periksa apakah isinya memuat data sensitif. Pertimbangan perlindungan kata sandi dijelaskan dalam [SECURITY.md](SECURITY.md).

Anda dapat menghubungi penulis melalui informasi dalam [deskripsi produk](../README_ID.md#hubungi-penulis).
