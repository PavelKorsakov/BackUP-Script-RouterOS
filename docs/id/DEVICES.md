# Daftar perangkat

[Daftar isi](../README_ID.md)

## Perangkat yang akan dicadangkan: berkas devicelist.cfg

Sesuai namanya, `devicelist.cfg` mencantumkan perangkat untuk backup batch dan data yang diperlukan untuk terhubung ke perangkat tersebut.
Letakkan berkas ini langsung di samping `mikrotik-backup.sh`.
Anda dapat membuat `devicelist.cfg` secara manual atau melalui BackUP Master.
Pilihan ketiga berguna ketika Oxidized berjalan pada server yang sama. Setelah Anda menambahkan pengaturan terkait ke berkas opsi,
skrip membuat `devicelist.cfg` secara dinamis pada setiap eksekusi dengan menggunakan data yang diperlukan dari berkas konfigurasi Oxidized.

<br />

## Membuat dan mengedit daftar

Untuk membuat daftar melalui BackUP Master, jalankan:

```bash
mikrotik-backup.sh -b
```

Isi nama perangkat, alamat, login, kata sandi, dan port SSH → pilih **2. Save device to devicelist.cfg**.
BackUP Master akan membuat berkas dengan entri yang diperlukan, atau menambahkan maupun memperbarui entri dalam berkas yang sudah ada.

Anda dapat mengedit daftar yang sudah dibuat menggunakan editor teks biasa. BackUP Master tidak memuat entri yang ada ke dalam formulirnya.

*(Catatan: Saat BackUP Master menyimpan port `22`, kolom yang ditulis kosong. Backup batch menggunakan `SshPort` dari pengaturan skrip untuk entri tersebut. Port nonstandar ditulis secara eksplisit.)*

<br />

## Format berkas

Tuliskan setiap perangkat pada baris terpisah. Pisahkan kolom dengan **karakter TAB**, bukan spasi. Urutan kolomnya sebagai berikut:

| Posisi | Kolom | Kegunaan |
|---|---|---|
| 1 | Nama | Nama perangkat; wajib |
| 2 | Alamat | Alamat IP atau nama DNS perangkat; wajib |
| 3 | Login | Pengguna perangkat RouterOS; jika dikosongkan, diwarisi dari `Login` dalam `option.cfg` |
| 4 | Kata sandi | Kata sandi perangkat RouterOS; jika dikosongkan, diwarisi dari `Password` dalam `option.cfg` |
| 5 | Port | Port SSH dari `1` hingga `65535`; jika dikosongkan, diwarisi dari `SshPort`, dengan nilai default `22` |
| 6 | Penanda perangkat | `MikroTik`; boleh kosong. Pencocokannya tidak membedakan huruf besar-kecil |

Kolom ketujuh dan seterusnya tidak digunakan. Entri dengan penanda perangkat lain akan dilewati.

### Contoh daftar

Kolom dalam contoh ini dipisahkan oleh karakter TAB yang sebenarnya:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

Port dikosongkan pada baris kedua: terdapat dua karakter TAB di antara kata sandi dan `MikroTik`. Ganti alamat dan kredensial dengan milik Anda.

### Login, kata sandi, dan port bersama

Jika semua perangkat menggunakan kredensial yang sama, tentukan nilainya satu kali dalam `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Setelah itu, `devicelist.cfg` hanya memerlukan nama dan alamat setiap perangkat:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Kredensial yang ditentukan dalam entri perangkat menggantikan nilai bersama.

*(Catatan: Berkas daftar perangkat memuat kata sandi. Batasi akses seperti yang dijelaskan dalam [SECURITY.md](SECURITY.md).)*

<br />

## Cara daftar dibaca

Baris kosong dan baris yang karakter pertama selain spasinya adalah `#` diabaikan. Letakkan komentar pada baris terpisah; karakter `#` di dalam kolom menjadi bagian dari nilainya.

Spasi di awal dan akhir nama, alamat, port, serta penanda dihapus. Login dan kata sandi dibaca secara harfiah, termasuk spasi dan tanda kutip. Berkas dengan akhir baris Windows (CRLF) didukung.

Jika suatu baris—yakni entri perangkat—melanggar sintaks yang diwajibkan, skrip melewatinya saat eksekusi dan mengeluarkan peringatan bahwa entri tersebut tidak valid.

Jika suatu baris terduplikasi karena alasan apa pun—yakni keempat parameter koneksinya (**alamat, login, kata sandi, dan port**) sama—skrip hanya terhubung satu kali ke perangkat tersebut dengan menggunakan data dari entri terakhir.
Jika koneksi yang berbeda memiliki nama yang sama, entri pertama yang dapat digunakan akan dipakai dan entri yang berkonflik dilewati.

<br />

<a id="device-names"></a>
## Nama perangkat

Nama digunakan dalam nama berkas backup dan, dalam mode batch, untuk subdirektori perangkat.
Pengaturan `UseIdentityName` dalam `option.cfg` menentukan sumber nama:

| Nilai | Sumber nama |
|---|---|
| `true` (default) | Nilai Identity pada perangkat RouterOS itu sendiri |
| `false` | Nama dari `devicelist.cfg`, kolom BackUP Master, atau `--device-name` dalam eksekusi satu perangkat melalui CLI |

### Nama dalam tanda kurung

Jika nama asli memuat tanda kurung, skrip menggunakan isi bagian lengkap pertama yang tidak kosong. Jika tidak ada bagian seperti itu, seluruh nama digunakan.

| Nama asli | Nama backup |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Karakter yang diperbolehkan

Nama akhir mempertahankan huruf, termasuk huruf Kiril, angka, titik, tanda hubung, dan garis bawah. Spasi dan karakter yang tidak valid diganti dengan `_`. Garis bawah yang berulang maupun yang berada di awal atau akhir dihapus, begitu pula titik di awal serta tanda hubung dan titik di akhir nama.

Sebagai contoh, `ЦОД Москва №1` menjadi `ЦОД_Москва_1`.

Panjang nama akhir harus **antara 1 dan 32 karakter**. Nama yang terlalu panjang tidak dipotong; nama tersebut menyebabkan galat. Nama yang dicadangkan, yaitu `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, dan `LPT1`–`LPT9`, tidak diperbolehkan.

Nama akhir harus unik tanpa membedakan huruf besar-kecil: `Router-A` dan `router-a` dianggap sama. Perangkat kedua dengan nama tersebut dilewati selama eksekusi saat ini.

*(Catatan: Mengubah nama akhir juga mengubah subdirektori perangkat. Backup lama tidak dipindahkan secara otomatis.)*

<br />

## Mengimpor dari Oxidized

Jika Anda sudah memelihara daftar perangkat dalam Oxidized, skrip dapat mengambilnya dari sana. Tambahkan pengaturan berikut ke `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Atur `OxidizedHome` ke direktori yang berisi `config` dan `router.db`. Skrip membuat `devicelist.cfg` dari keduanya. Skrip tidak mengubah berkas Oxidized.

*(Catatan: Impor menggantikan `devicelist.cfg`; impor tidak menambahkan isi ke berkas. Penambahan manual akan hilang saat pembaruan dari Oxidized berikutnya berhasil.)*

### Pengaturan sumber

Konfigurasi Oxidized harus menggunakan sumber `csv` dengan pemisah satu karakter. `source.csv.map` menentukan urutan kolom, dengan penomoran dimulai dari nol:

| Kolom peta | Nilai yang digunakan |
|---|---|
| `name` | Nama perangkat; kolom wajib |
| `ip` | Alamat perangkat; jika tidak ada, nilai `name` digunakan |
| `username` | Login; jika tidak ada, `Login` bersama dari `option.cfg` digunakan |
| `password` | Kata sandi; jika tidak ada, `Password` bersama dari `option.cfg` digunakan |
| `port` | Port SSH; jika tidak ada, `SshPort` digunakan |
| `model` | Model perangkat; jika kolom tidak ada, parameter akar `model` digunakan |

Aturan `model_map` diterapkan hingga kecocokan pertama. Hanya perangkat dengan model akhir `routeros` yang diimpor. Jika kolom `model` tersedia, parameter akar tidak menggantikan nilai kosong dalam kolom tersebut.

Data selalu dibaca dari `<OxidizedHome>/router.db`. Parameter Oxidized `source.csv.file` tidak mengubah jalur ini.

### Jika impor gagal

Jika berkas Oxidized tidak tersedia, formatnya tidak didukung, atau tidak ditemukan perangkat yang sesuai, `devicelist.cfg` sebelumnya dipertahankan.

Dengan `IgnoreOxiAccess=true`, skrip dapat menggunakan daftar sebelumnya yang masih dapat digunakan. Dengan `false`, backup tidak dilakukan dari daftar lama.

Galat impor memengaruhi hasil eksekusi meskipun pemrosesan backup dengan daftar sebelumnya berhasil.

Lihat [Pemecahan masalah](TROUBLESHOOTING.md) untuk rincian galat daftar dan impor.
