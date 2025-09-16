#!/bin/sh

# Server NTP yang akan digunakan
NTP_SERVER="time.google.com"

# Mendapatkan antarmuka yang digunakan untuk internet
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Log: Memulai proses sinkronisasi waktu
logger -t ntp_sync_script "Memulai sinkronisasi waktu. Menghentikan layanan sysntpd sementara."

# Langkah 1: Hentikan layanan sysntpd bawaan
/etc/init.d/sysntpd stop

# Jeda singkat untuk memastikan layanan benar-benar berhenti
sleep 2

# Langkah 2: Jalankan sntp untuk menyinkronkan waktu
# Opsi -v (verbose) akan memberikan output yang lebih detail.
sntp -s "$NTP_SERVER" > /dev/null 2>&1

# Periksa status sntp
if [ $? -eq 0 ]; then
    # Mendapatkan tanggal dan waktu saat ini setelah sinkronisasi
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # Log: Berhasil dengan informasi lengkap
    logger -t ntp_sync_script "Sinkronisasi waktu berhasil ke ${CURRENT_TIME} menggunakan ${INTERFACE}."
else
    # Log: Gagal
    logger -t ntp_sync_script "Gagal mendapatkan waktu menggunakan sntp."
fi

# Langkah 3: Mulai kembali layanan sysntpd
/etc/init.d/sysntpd start

# Log: Menyelesaikan proses
logger -t ntp_sync_script "Proses sinkronisasi selesai. sysntpd telah diaktifkan kembali."

exit 0
