# Pemasangan

[Daftar isi](../README_ID.md)

## Persyaratan host

Skrip memerlukan Linux dengan GNU Bash **4.4 atau yang lebih baru** serta utilitas berkas GNU standar.
Skrip itu sendiri tidak memerlukan kompilasi, Python, kontainer, atau basis data.
Namun, utilitas yang tercantum di bagian [Dependensi](#dependensi) tetap diperlukan.

Penanganan nama perangkat memerlukan locale **`C.UTF-8`** yang berfungsi untuk menghitung karakter multibyte, mengenali huruf, dan mengubah kapitalisasi huruf.
Skrip memeriksa kemampuan ini sebelum menangani perangkat. Ini merupakan persyaratan sistem, bukan program terpisah bernama `C.UTF-8`.

Tentu saja, host harus sudah memiliki akses jaringan ke layanan SSH RouterOS dan izin tulis ke penyimpanan yang dipilih.

**Sangat disarankan!!!**
Skrip terhubung ke perangkat RouterOS melalui SSH menggunakan autentikasi kata sandi, bukan autentikasi berbasis kunci.
*(Lihat [SECURITY.md](SECURITY.md) untuk kebijakan transport yang tepat.)*
Karena itu, buatlah pengguna khusus pada perangkat dan batasi login pengguna tersebut berdasarkan alamat IP host yang menjalankan skrip ini.

<br />

## Dependensi

### Wajib untuk backup

**Semua** utilitas berikut diperlukan untuk membuat backup:

| Utilitas | Kegunaan |
|---|---|
| `ssh`, `scp`, `sshpass` | Terhubung ke RouterOS, menjalankan perintah, dan mengambil berkas |
| GNU `timeout`, `sleep` | Membatasi waktu operasi dan memberikan jeda |
| `sha256sum` | Menghitung checksum |
| `realpath` | Menentukan jalur absolut |
| `flock` | Penguncian untuk mencegah konflik antareksekusi serentak |

**Jika utilitas yang diperlukan tidak tersedia, skrip melaporkan dependensi yang tidak terpenuhi
dan menghentikan percobaan backup.
Kode galat dependensi adalah `30`. Ini adalah perilaku yang semestinya.**

Daftar ini sama untuk backup satu perangkat dan backup batch, terlepas dari apakah
skrip membuat `.rsc`, `.backup`, atau kedua format.

Keberadaan perintah dengan nama tersebut saja tidak cukup. OpenSSH yang terpasang harus
mendukung opsi yang digunakan skrip, termasuk mode SCP lama yang dipilih melalui `scp -O`.
GNU `timeout` harus mendukung `--signal` dan `--kill-after`.
Kemampuan ini diperiksa secara lokal, tanpa menghubungi router.

<br />

### Wajib untuk fitur tertentu

Alat berikut bukan bagian dari daftar persyaratan umum. Alat tersebut hanya diperlukan
ketika fitur yang terkait digunakan.

| Fitur | Persyaratan | Yang terjadi jika tidak tersedia |
|---|---|---|
| Mode batch dengan `UseNetFolder=true` | `findmnt` | Backup tidak dimulai dalam mode ini; galat dependensi `30` |
| Eksekusi ketika pengarsipan bulanan jatuh tempo | Info-ZIP `zip`, `unzip`, GNU `mv` | Eksekusi berhenti saat pemeriksaan dependensi, sebelum backup apa pun dibuat; galat `30` |
| Menu interaktif, Editor Konfigurasi, dan BackUP Master | `stty` dan terminal pada input serta output standar | Layar interaktif tidak terbuka; galat terminal `31` |
| **Copy console command** di BackUP Master | GNU `base64` yang mendukung `--wrap=0` | Perintah tidak dapat disalin; galat `30` |

Sebagai contoh, tidak tersedianya `zip` tidak menghalangi eksekusi backup biasa ketika pengarsipan bulanan belum jatuh tempo.
Tidak tersedianya `base64` tidak menghalangi pembuatan backup.
*(Catatan: Utilitas ini diperlukan ketika Anda memilih **Copy console command**.)*

Pemeriksaan dependensi umum dijalankan sebelum backup, bukan setiap kali program dibuka.
Karena itu, bantuan, informasi versi, atau menu mungkin tetap tersedia meskipun utilitas backup belum terpasang.

<br />

### Lingkungan dasar Linux

Skrip juga mengasumsikan bahwa perintah sistem umum untuk menangani berkas
dan direktori tersedia, termasuk `date`, `stat`, `mkdir`, `cp`, `ln`, dan `rm`.

Perintah tersebut merupakan bagian dari lingkungan dasar sistem operasi. Daftar dependensi
yang diperiksa sebelumnya bukanlah daftar lengkap semua perintah eksternal yang digunakan
skrip. Jika suatu perintah sistem dasar tidak tersedia, operasi terkait dapat gagal
tanpa menghasilkan pesan dependensi yang tidak terpenuhi.

<br />

### Memasang paket yang diperlukan di Debian/Ubuntu

Contoh ini memasang alat wajib dan alat opsional yang disebutkan di atas:
*(Catatan: Di sini dan selanjutnya, pengguna diasumsikan memiliki hak administrator.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Memperoleh berkas skrip

Metode instalasi utama untuk versi 2.3.1 adalah aset GitHub Release lengkap `mikrotik-backup-2.3.1.zip`. Arsip ini diekstrak langsung ke direktori instalasi tanpa direktori pembungkus tambahan.
*(Catatan: Untuk contoh yang menempatkan berkas di bawah `/opt`, jalankan perintah dengan izin untuk membuat dan menulis ke direktori tersebut.)*

### Opsi 1: Paket rilis lengkap

Unduh `mikrotik-backup-2.3.1.zip` dari GitHub Release MikroTik Backup Script 2.3.1, lalu jalankan:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Setelah diekstrak, tata letak siap pakainya adalah:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Jika verifikasi checksum gagal, jangan jalankan skrip sebelum penyebabnya ditemukan.

<br />

### Opsi 2: Instalasi mandiri minimal

Unduh aset `mikrotik-backup.sh` dan `SHA256SUMS` dari Release yang sama ke direktori terlindungi, verifikasi keduanya, lalu jadikan skrip dapat dieksekusi:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Unduh kedua aset Release ke direktori ini.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Untuk bahasa runtime eksternal, gunakan paket lengkap atau ambil berkas `.lang` yang sesuai dari sumber bertag dengan versi yang sama.

<br />

### Opsi lanjutan: Git atau arsip kode sumber

Klon Git atau arsip **Code → Download ZIP** dari repositori ini juga merupakan pohon sumber produk lengkap. Struktur root yang relevan adalah:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` adalah aset Release dan mungkin tidak ada pada checkout sumber. Untuk instalasi biasa, paket Release berversi tetap direkomendasikan karena menyertakan berkas checksum dan tepat mewakili versi yang dipublikasikan.

<br />

## Berkas di samping skrip

Setelah paket Release lengkap diekstrak, direktori yang dipilih memuat skrip dan berkas pendampingnya:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Berkas atau direktori | Kegunaan |
|---|---|
| mikrotik-backup.sh | Skrip backup itu sendiri |
| SHA256SUMS | Checksum untuk memverifikasi berkas hasil unduhan |
| README.md | Deskripsi produk dan tautan ke dokumentasi terperinci |
| lang/ | Berkas pelokalan. Salin berkas bahasa yang diperlukan dari direktori ini ke direktori skrip. |
| docs/ | Dokumentasi terperinci tentang pemasangan, konfigurasi, dan penggunaan |

Untuk pengoperasian sebenarnya, hanya `mikrotik-backup.sh` yang diperlukan.
Untuk mengubah pengaturan, buat **option.cfg** dan letakkan di samping skrip.
Jika Anda berencana memeriksa dan membuat backup beberapa perangkat secara berurutan, buat juga **devicelist.cfg** di samping skrip.
Berkas pelokalan bernama `<xx>.lang` diperlukan jika Anda ingin menu dan entri log tampil dalam bahasa Anda. Letakkan berkas tersebut dalam direktori yang sama dengan `mikrotik-backup.sh`.
Bahasa Rusia dan Inggris tidak memerlukan berkas pelokalan terpisah karena keduanya sudah terintegrasi dalam skrip.

**Dalam mode interaktif, skrip dapat membuat dan menyimpan:**
Daftar perangkat—**devicelist.cfg**—melalui BackUP Master.
Berkas konfigurasi—**option.cfg**—melalui Editor Konfigurasi.
Anda juga dapat menyiapkannya sendiri:
*Format TSV untuk daftar perangkat dijelaskan secara terperinci dalam [DEVICES.md](DEVICES.md).*
*Format `Key=value` untuk berkas konfigurasi dijelaskan secara terperinci dalam [OPTIONS.md](OPTIONS.md).*

<br />

## Menyiapkan penyimpanan dan log

Dengan pengaturan backup default, skrip membuat direktori `./backups` di sampingnya dan menyimpan backup perangkat di sana.
Perbedaan antarmode hanyalah bahwa eksekusi satu perangkat menempatkan berkas yang dibuat langsung dalam `./backups`, sedangkan mode batch membuat subdirektori bernama perangkat di bawah `./backups` dan menyimpan backup perangkat tersebut di sana.

Skrip membuat sendiri direktori penyimpanan yang diperlukan dengan izin yang sesuai.
*(Skrip tidak otomatis mengubah pemilik atau mode akses direktori yang sudah dibuat administrator.)*

Secara default, log utama skrip, `main.log`, disimpan dalam `./backups`.
Dalam mode batch, log perangkat disimpan dalam subdirektori perangkat tersebut.

Perlu diketahui juga bahwa ketika direktori backup berada pada penyimpanan jaringan,
skrip dapat memeriksa ketersediaan direktori tersebut selama pemrosesan batch. Opsi ini dinonaktifkan secara default dan harus dikonfigurasi sebelum digunakan.
*(Cara direktori dipasang tidak menjadi masalah.)*

Semua opsi ini dapat diubah dengan menetapkan parameter yang diperlukan dalam `option.cfg`.
Lihat [Konfigurasi](OPTIONS.md) untuk petunjuk dan sintaks parameter.

<br />

## Menjalankan skrip secara otomatis

Sebelum mengaktifkan jadwal, siapkan pengaturan dan daftar perangkat.
Jika tidak, eksekusi otomatis tidak dapat menjalankan backup batch.

Anda tidak wajib membuat pengguna terpisah untuk menjalankan skrip, tetapi menjalankan operasi semacam ini sebagai **root** dianggap sebagai praktik buruk. Contoh berikut membuat pengguna khusus.

Buat pengguna **bsmt** *(Anda dapat memilih nama lain; ganti **bsmt** dalam contoh)* dan berikan hanya izin yang diperlukan:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Jika skrip sudah pernah dijalankan sebagai root**

*(Catatan: Jika sebelumnya Anda menjalankan skrip sebagai **root**, direktori, backup,
dan log yang dibuatnya mungkin tidak dapat diakses oleh **bsmt**.
Alihkan penyimpanan yang ada kepada pengguna tersebut sebelum mengaktifkan jadwal.)*

Contoh ini menggunakan direktori lokal `/opt/mikrotik-backup/backups`.
Perintah berikut mengubah pemilik dan grup direktori beserta seluruh isinya:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(Catatan: Tentukan direktori backup milik skrip ini, bukan direktori bersama yang juga memuat data program lain.
Jika penyimpanan atau log utama berada di tempat lain, konfigurasikan akses ke masing-masing lokasi secara terpisah sesuai izin dan pengaturan penyimpanan yang dipilih, dengan mengikuti pola yang sama.)*

Contoh ini membuka Editor Konfigurasi sebagai **bsmt** setelah pengguna tersebut diberi akses ke direktori dan berkas skrip:
*(Catatan: Jalankan perintah sebagai root atau sebagai pengguna yang diizinkan melakukannya melalui sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Membuat jadwal untuk skrip**

Contoh berikut membuat jadwal dengan systemd,
tetapi Anda dapat menggunakan crontab atau metode lain yang disukai.

Kita akan membuat layanan yang menjalankan skrip sebagai pengguna khusus dan timer yang memulainya sesuai jadwal.
*(Contoh dijalankan setiap hari pukul 1 pagi, tetapi jadwal sepenuhnya terserah Anda.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` tidak mengaktifkan eksekusi susulan setelah timer sempat mati.
`Restart=no` tidak menjadwalkan mulai ulang layanan secara otomatis setelah terjadi galat.*
