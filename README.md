<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/9/92/Openwrt_Logo.svg" alt="OpenWrt Telegram Auto Sync NTP" width="200"/>

![License](https://img.shields.io/github/license/fahrulariza/OpenWRT-Auto-sync_ntp)
[![GitHub All Releases](https://img.shields.io/github/downloads/fahrulariza/OpenWRT-Auto-sync_ntp/total)](https://github.com/fahrulariza/OpenWRT-Auto-sync_ntp/releases)
![Total Commits](https://img.shields.io/github/commit-activity/t/fahrulariza/OpenWRT-Auto-sync_ntp)
![Top Language](https://img.shields.io/github/languages/top/fahrulariza/OpenWRT-Auto-sync_ntp)
[![Open Issues](https://img.shields.io/github/issues/fahrulariza/OpenWRT-Auto-sync_ntp)](https://github.com/fahrulariza/OpenWRT-Auto-sync_ntp/issues)

<h1>Auto Sync NTP sederhana melalui adb dan ntp di OpenWrt</h1>
<p>Kelola router OpenWrt Anda dengan mudah!</p>
</div>

Cara Kerja Script di OpenWRT
Script ini berfungsi untuk sinkronisasi waktu dengan prioritas ADB terlebih dahulu, lalu NTP sebagai cadangan, diikuti pengumuman audio dalam bahasa Indonesia tentang waktu saat ini.

Script shell Ini adalah solusi cerdas untuk sinkronisasi waktu pada perangkat OpenWrt yang mungkin tidak memiliki RTC (Real Time Clock) baterai, dengan menambahkan feedback suara.

Logika Kerja Script
Script ini bekerja dengan sistem prioritas bertingkat (fallback). Tujuannya adalah memastikan sistem OpenWrt mendapatkan waktu yang akurat, lalu "mengumumkannya" melalui speaker menggunakan perintah paplay.

1. Inisialisasi & Persiapan
Variabel: Script menetapkan lokasi file audio dan daftar server NTP (Google dan OpenWrt pool).

Fungsi Audio: Dibuat fungsi play_audio dan play_tens_number. Logika play_tens_number cukup pintar karena bisa memecah angka menjadi puluhan dan satuan (misal: 25 menjadi "dua puluh" + "lima").

Stop Service: Script menghentikan sysntpd bawaan agar tidak terjadi konflik saat script mencoba mengatur waktu secara manual.

2. Prioritas 1: Sinkronisasi via ADB (Offline/Kabel)
Script pertama kali mencari perangkat Android yang terhubung via kabel data (ADB).

Jika terdeteksi, script mengambil waktu dari HP Android tersebut.

Ini sangat berguna jika OpenWrt tidak punya akses internet tapi terhubung ke HP.

Jika berhasil, variabel SYNC_SUCCESS diatur ke angka 2.

3. Prioritas 2: Sinkronisasi via NTP (Online/Internet)
Jika ADB gagal (tidak ada HP), script beralih ke internet:

Script mendeteksi semua antarmuka jaringan (eth0, wlan0, dll).

Script mencoba satu per satu server NTP menggunakan perintah sntp.

Jika berhasil, variabel SYNC_SUCCESS diatur ke angka 1.

4. Output Suara (Text-to-Speech Manual)
Setelah waktu didapat, script menjalankan rentetan pemutaran audio:

Mengecek apakah ada proses paplay lain yang berjalan agar suara tidak tumpang tindih.

Memutar urutan: Tahun -> Bulan -> Tanggal -> Jam -> Menit.

Jika semua metode sinkronisasi gagal, script akan memutar audio pemberitahuan gagal.


Alur Utama:
1. Stop Service NTP - Menghentikan layanan NTP bawaan OpenWRT
2. Prioritas ADB - Mencoba sinkronisasi waktu dari perangkat Android yang terhubung via ADB
3. Cadangan NTP - Jika ADB gagal, mencoba sinkronisasi dengan server NTP
4. Pengumuman Audio - Memutar audio berdasarkan hasil sinkronisasi:
5. Berhasil via ADB/NTP: Mengumumkan tahun, bulan, tanggal, jam, menit
   - Gagal semua: Memutar audio gagal
   - Start Service NTP - Mengaktifkan kembali layanan NTP
