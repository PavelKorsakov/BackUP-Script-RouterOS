# Rilis

[Daftar isi](../README_ID.md)

## Versi 2.3.1

**Rilis pemeliharaan dan hotfix setelah versi 2.3.0 yang telah dipublikasikan.**

Arsitektur satu berkas dan GNU Bash minimum versi 4.4 tidak berubah. `UseIncremental` kini merupakan pengaturan boolean kanonis: `false` melewati perbandingan setelah backup dan tahap retensi inkremental, serta mempertahankan setiap artefak baru yang berhasil dibuat dan divalidasi. Tidak tersedia opsi CLI khusus untuk pengaturan ini.

Urutan kalender pada pengarsipan bulanan telah diperbaiki dan penanganan metadata untuk penyimpanan jaringan yang memenuhi syarat telah diperkuat, sedangkan pemeriksaan metadata sistem berkas lokal tetap ketat. Editor Konfigurasi dan BackUP Master kini menggunakan viewport yang telah diterima pada terminal yang lebih pendek sehingga seluruh baris formulir tidak harus tampil sekaligus.

Bahasa Rusia dan Inggris tetap terintegrasi. Versi 2.3.1 menyertakan terjemahan runtime eksternal untuk bahasa Jerman, Spanyol, Latvia, Polandia, dan Ukraina (`de`, `es`, `lv`, `pl`, `uk`), serta `en.lang` sebagai templat terjemahan kanonis lengkap dengan 245 kunci. Dokumentasi pengguna tersedia dalam 11 bahasa.

Notifikasi belum diimplementasikan dan tetap berada di luar cakupan rilis ini.

<br />

Lihat [INSTALL.md](INSTALL.md) untuk petunjuk memperoleh berkas, memverifikasi checksum, dan menyiapkan skrip agar siap digunakan.
