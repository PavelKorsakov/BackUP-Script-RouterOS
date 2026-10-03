# Pencatatan log

[Daftar isi](../README_ID.md)

## Log utama dan log perangkat

Skrip mencatat progres keseluruhan dalam log utama, `main.log`, sedangkan rincian pekerjaan pada setiap perangkat disimpan dalam log perangkat terpisah.

Dalam `main.log`, Anda dapat melihat cara daftar perangkat disiapkan, mengikuti pemrosesan batch, dan meninjau hasil pemeriksaan perangkat. Galat yang terjadi sebelum perangkat tertentu dikenali juga dicatat di sini.

Log perangkat memuat informasi tentang pengambilan berkas `.rsc` dan `.backup`, percobaan ulang, perbandingan backup, dan pengarsipan. Dengan kata lain, jika Anda perlu mengetahui apa yang terjadi saat backup perangkat tertentu dibuat, periksa log perangkat tersebut. Rincian ini tidak diduplikasi dalam `main.log`.

<br />

## Lokasi penyimpanan log

Secara default, log utama disimpan dalam direktori `backups` di samping skrip. Log perangkat disimpan bersama backup perangkat tersebut:

| Log | Lokasi |
|---|---|
| Log utama | `<BackupRoot>/main.log` |
| Perangkat dalam mode batch | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Perangkat dalam eksekusi satu perangkat | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

Dalam mode batch, entri baru ditambahkan ke log perangkat yang sama. Untuk backup satu perangkat, nama log memuat tanggal dan waktu yang sama dengan nama berkas backup dari eksekusi tersebut.

### Direktori terpisah untuk main.log

Jika Anda ingin memisahkan log utama dari backup, tentukan direktorinya dalam pengaturan `MainLogPath` di `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

Log kemudian ditulis ke `/var/log/mikrotik-backup/main.log`. Log perangkat tetap berada di lokasi biasanya.

`MainLogPath=` yang kosong menggunakan `BackupRoot` saat ini. Jalur relatif, seperti `MainLogPath=logs`, merujuk ke direktori di samping skrip, bukan di dalam penyimpanan backup.

*(Catatan: `MainLogPath` menentukan direktori, bukan nama berkas lengkap. Direktori tersebut harus sudah ada dan dapat ditulisi oleh pengguna yang menjalankan skrip.)*

<br />

## Tingkat rincian log

Pengaturan `LogLevel` mengendalikan banyaknya informasi yang ditampilkan dan dicatat. Nilai default-nya adalah `2`:

| Nilai | Progres di terminal | Entri dalam berkas log |
|---|---|---|
| `0` | Hanya galat | Hanya galat |
| `1` | Tahap utama dan hasilnya | Log singkat |
| `2` | Tahap utama dan hasilnya | Log terperinci |
| `3` | Tahap utama dan suboperasi saat ini | Log terperinci |

**Galat dicatat pada setiap tingkat.** Log singkat memuat tahap utama dan hasilnya; log terperinci juga mencatat operasi yang dilakukan dalam tahap tersebut.

Anda dapat mengubah tingkat ini dalam `option.cfg` atau melalui Editor Konfigurasi:

```ini
LogLevel=3
```

Untuk mengubahnya bagi satu eksekusi backup batch yang sudah dikonfigurasi, gunakan CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Tindakan ini tidak mengubah nilai dalam berkas opsi. Dengan cara yang sama, `--main-log-path` dapat menetapkan lokasi log utama untuk eksekusi saat ini.

BackUP Master tidak memiliki kolom terpisah untuk `LogLevel` atau `MainLogPath`. BackUP Master menggunakan pengaturan log yang berlaku untuk eksekusi saat ini.

<br />

## Bentuk entri log

Log adalah berkas teks biasa. Setiap entri memuat tanggal dan waktu menurut jam host yang menjalankan skrip. Warna dan indikator progres tidak ditulis ke berkas.

Contoh entri dalam `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Memproses perangkat secara batch
[2026-10-01 01:00:15] [PID:12345] [OK] Memproses perangkat secara batch
```

Log utama juga memuat PID proses. Dengan PID, Anda dapat membedakan entri yang ditulis oleh beberapa instans skrip yang berjalan bersamaan.

PID tidak ditambahkan ke log perangkat. Berikut cuplikan log terperinci:

```text
[2026-10-01 01:00:05] Mengambil backup biner
[2026-10-01 01:00:06] [1] Menghapus cache DNS
[2026-10-01 01:00:07] [2] Menghapus riwayat konsol
[2026-10-01 01:00:12] [OK] Mengambil backup biner
```

`[OK]` berarti operasi selesai dengan sukses. Galat ditandai dengan `[ER]` dan menyertakan kodenya, misalnya `[53]`. Suboperasi diberi nomor `[1]`, `[2]`, dan seterusnya, dimulai lagi pada setiap tahap utama.

Jika percobaan ulang berhasil setelah percobaan yang gagal, log mempertahankan galat sebelumnya dan hasil sukses setelahnya.

Entri log menggunakan bahasa yang sama dengan antarmuka, yang dipilih melalui pengaturan `Language`. Untuk informasi selengkapnya mengenai pemilihan bahasa dan penggunaan terjemahan, lihat [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Output terminal

Selama eksekusi manual, progres terlihat di layar. Ketika operasi sedang berlangsung, indikator tunggu muncul di sampingnya. Setelah selesai, indikator berubah menjadi `[OK]` hijau atau `[ER]` merah beserta kode galat.

Tingkat `1` dan `2` menampilkan tahap utama. Pada tingkat `3`, suboperasi saat ini juga ditampilkan di bawah tahap yang sedang dilakukan dan berubah seiring pekerjaan berlangsung. Dalam mode batch, tampilan juga menunjukkan perangkat yang sedang diproses.

*(Catatan: Ketika skrip berjalan tanpa terminal—misalnya dari penjadwal atau dengan output yang dialihkan—output di layar ini tidak tersedia. Pencatatan ke berkas tetap berjalan pada tingkat yang dipilih.)*

<br />

## Akumulasi dan pengarsipan log

Berkas log dibuat ketika entri pertamanya ditulis. Dengan `LogLevel=0` dan tanpa galat, berkas log baru tidak dibuat, sedangkan berkas yang sudah ada tidak berubah.

Entri ditambahkan ke log utama dan log perangkat mode batch, bukan menimpanya pada setiap eksekusi. Satu baris kosong memisahkan eksekusi yang berurutan.

`main.log` tidak diarsipkan maupun dihapus berdasarkan usia. Anda sendiri yang mengatur rotasinya.

Ketika pengarsipan bulanan diaktifkan, seluruh log perangkat mode batch yang telah terakumulasi dimasukkan ke ZIP bersama backup perangkat tersebut. Setelah arsip berhasil disimpan, log yang diarsipkan dihapus dari direktori perangkat; hasil pengarsipan dan pekerjaan berikutnya kemudian ditulis ke berkas log baru.

Jika ZIP yang sama diperbarui lagi, riwayat di dalamnya diperpanjang, bukan diganti dengan log baru. Jika arsip tidak dapat disimpan, log sebelumnya tetap di tempatnya dan galat dicatat di dalamnya.

Log dari eksekusi satu perangkat melalui CLI diarsipkan bersama backup dari direktori bersama. Pengarsipan dalam kedua mode dijelaskan dalam [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Jika log tidak dapat ditulis

Izin yang tidak memadai, direktori yang tidak tersedia, atau galat penulisan log lainnya tidak menghentikan backup itu sendiri. Skrip mencatat peringatan dan melanjutkan jika memungkinkan.

`main.log` yang tidak tersedia dilaporkan satu kali per eksekusi, dan log perangkat yang tidak tersedia satu kali selama perangkat tersebut diproses. Jika log utama tersedia, kegagalan penulisan log perangkat dicatat di sana.

Jika tidak ada galat lain, eksekusi keluar dengan kode `1`, yang berarti selesai dengan peringatan. Peringatan ini tidak menggantikan galat dari operasi backup itu sendiri.

Untuk kode hasil dan bantuan menemukan penyebab galat, lihat [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(Catatan: Tingkat terperinci `3` tidak mencatat kata sandi atau perintah koneksi lengkap. Untuk informasi tentang perlindungan kredensial dan berkas skrip, lihat [SECURITY.md](SECURITY.md).)*
