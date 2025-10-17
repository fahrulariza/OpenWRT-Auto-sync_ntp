#!/bin/sh

# Daftar server NTP yang akan dicoba (dipisahkan oleh spasi)
NTP_SERVERS="time.google.com 0.openwrt.pool.ntp.org 1.openwrt.pool.ntp.org"
# Lokasi file audio
AUDIO_DIR="/www/audio"
PAPLAY_CMD="sudo -u pulse /usr/bin/paplay --volume=45536"

# Fungsi untuk memutar audio
play_audio() {
  local file_path=$1
  echo "Memutar file audio: $file_path"
  if [ -f "$file_path" ]; then
    $PAPLAY_CMD "$file_path"
    sleep 0.0
  else
    echo "Warning: Audio file not found: $file_path"
  fi
}

# Fungsi untuk memutar angka
play_tens_number() {
    local num=$1
    local path_to_angka="$AUDIO_DIR/angka"
    
    # Hapus nol di depan jika ada
    num=$(echo "$num" | sed 's/^0*//')

    if [ -z "$num" ]; then
        play_audio "$path_to_angka/0.wav"
    elif [ "$num" -ge 0 ] && [ "$num" -le 10 ]; then
        play_audio "$path_to_angka/$num.wav"
    elif [ "$num" -gt 10 ] && [ "$num" -le 19 ]; then
        play_audio "$path_to_angka/$num.wav"
    elif [ "$num" -ge 20 ]; then
        local puluhan=$(($num / 10 * 10))
        local satuan=$(($num % 10))
        play_audio "$path_to_angka/${puluhan}.wav"
        if [ "$satuan" -ne 0 ]; then
            play_audio "$path_to_angka/${satuan}.wav"
        fi
    fi
}

echo "Memulai proses sinkronisasi waktu."

# Langkah 1: Hentikan layanan sysntpd bawaan
echo "Menghentikan layanan sysntpd..."
/etc/init.d/sysntpd stop
echo "Menunggu 2 detik..."
sleep 2

# Langkah 2: UTAMAKAN SINKRONISASI ADB TERLEBIH DAHULU
SYNC_SUCCESS=0
echo "======================"
echo "MENGUTAMAKAN SINKRONISASI DENGAN ADB..."
ADB_DEVICE=$(adb devices | grep -E '^[a-zA-Z0-9]{8,}' | awk '{print $1}')
if [ ! -z "$ADB_DEVICE" ]; then
    # Mendapatkan tanggal dari ADB dengan format yang benar
    ADB_DATE_PROCESSED=$(adb -s "$ADB_DEVICE" shell date +%Y-%m-%d\ %H:%M:%S)
    
    if [ $? -eq 0 ] && [ ! -z "$ADB_DATE_PROCESSED" ]; then
        echo "Waktu dari ADB: $ADB_DATE_PROCESSED"
        echo "Mencoba sinkronisasi dengan waktu ADB..."
        
        # Mengatur waktu sistem
        date -s "$ADB_DATE_PROCESSED" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            SYNC_SUCCESS=2
            echo "Sinkronisasi berhasil dengan ADB."
        else
            echo "Gagal mengatur waktu sistem dari ADB."
        fi
    else
        echo "Gagal mendapatkan waktu dari ADB."
    fi
else
    echo "Tidak ada perangkat ADB yang terhubung."
fi

# Langkah 3: Jika ADB gagal, baru coba sinkronisasi dengan NTP
if [ $SYNC_SUCCESS -eq 0 ]; then
    echo "======================"
    echo "Sinkronisasi ADB gagal, mencoba sinkronisasi dengan NTP..."
    echo "Mencari semua antarmuka internet..."
    INTERFACES=$(ip route | grep default | awk '{print $5}')
    echo "Antarmuka yang terdeteksi: $INTERFACES"
    for INTERFACE in $INTERFACES; do
        for NTP_SERVER in $NTP_SERVERS; do
            echo "Mencoba sinkronisasi melalui $INTERFACE dengan $NTP_SERVER"
            START_TIME=$(date +%s%N)
            sntp -s "$INTERFACE" -t 2 "$NTP_SERVER" > /dev/null 2>&1
            END_TIME=$(date +%s%N)
            if [ $? -eq 0 ]; then
                SYNC_SUCCESS=1
                echo "======================"
                DURATION_MS=$((($END_TIME - $START_TIME) / 1000000))
                if [ "$DURATION_MS" -ge 1000 ]; then
                    DURATION_SEC=$(printf "%.1f" $(echo "scale=1; $DURATION_MS / 1000" | bc -l))
                    echo "Sinkronisasi berhasil melalui $INTERFACE dengan $NTP_SERVER. [${DURATION_SEC} detik]"
                else
                    echo "Sinkronisasi berhasil melalui $INTERFACE dengan $NTP_SERVER. [${DURATION_MS}ms]"
                fi
                break 2
            else
                echo "Gagal melalui $INTERFACE dengan $NTP_SERVER."
            fi
        done
    done
fi

# Langkah 4: Pemutaran audio dan pembaruan log berdasarkan hasil sinkronisasi
if [ $SYNC_SUCCESS -eq 2 ]; then
    # Sinkronisasi ADB berhasil (PRIORITAS)
    CURRENT_DATE=$(date +"%Y %m %d")
    CURRENT_TIME=$(date +"%H %M")
    CURRENT_TIME_FULL=$(date +"%Y-%m-%d %H:%M:%S")

    set -- $CURRENT_DATE
    YEAR=$1
    MONTH=$2
    DAY=$3

    set -- $CURRENT_TIME
    HOUR=$1
    MINUTE=$2

    echo "Sinkronisasi waktu berhasil (melalui ADB). Waktu saat ini: $CURRENT_TIME_FULL"
    echo "======================"
    
    while pgrep -f "paplay" > /dev/null; do
      echo "Pengecekan Proses: paplay sedang berjalan, menunda 5 detik..."
      sleep 5
    done
    echo "Pengecekan Proses: paplay tidak ditemukan, melanjutkan pemutaran."

    play_audio "$AUDIO_DIR/pembuka/ntp_pembuka_berhasil.wav"
    play_audio "$AUDIO_DIR/angka/tahun.wav"

    tahun_ribuan=$(echo $YEAR | cut -c1-2)
    tahun_sisa=$(echo $YEAR | cut -c3-4)
    play_audio "$AUDIO_DIR/angka/${tahun_ribuan}00.wav"
    
    if [ "$tahun_sisa" != "00" ]; then
        play_tens_number "$tahun_sisa"
    fi

    play_audio "$AUDIO_DIR/bulan/bulan.wav"
    case "$MONTH" in
        01) play_audio "$AUDIO_DIR/bulan/januari.wav";;
        02) play_audio "$AUDIO_DIR/bulan/februari.wav";;
        03) play_audio "$AUDIO_DIR/bulan/maret.wav";;
        04) play_audio "$AUDIO_DIR/bulan/april.wav";;
        05) play_audio "$AUDIO_DIR/bulan/mei.wav";;
        06) play_audio "$AUDIO_DIR/bulan/juni.wav";;
        07) play_audio "$AUDIO_DIR/bulan/juli.wav";;
        08) play_audio "$AUDIO_DIR/bulan/agustus.wav";;
        09) play_audio "$AUDIO_DIR/bulan/september.wav";;
        10) play_audio "$AUDIO_DIR/bulan/oktober.wav";;
        11) play_audio "$AUDIO_DIR/bulan/november.wav";;
        12) play_audio "$AUDIO_DIR/bulan/desember.wav";;
    esac

    play_audio "$AUDIO_DIR/angka/tanggal.wav"
    play_tens_number "$DAY"

    play_audio "$AUDIO_DIR/angka/jam.wav"
    play_tens_number "$HOUR"
    play_audio "$AUDIO_DIR/angka/lewat.wav"
    play_tens_number "$MINUTE"
    
    play_audio "$AUDIO_DIR/angka/wib.wav"
elif [ $SYNC_SUCCESS -eq 1 ]; then
    # Sinkronisasi NTP berhasil (CADANGAN)
    CURRENT_DATE=$(date +"%Y %m %d")
    CURRENT_TIME=$(date +"%H %M")
    CURRENT_TIME_FULL=$(date +"%Y-%m-%d %H:%M:%S")

    set -- $CURRENT_DATE
    YEAR=$1
    MONTH=$2
    DAY=$3

    set -- $CURRENT_TIME
    HOUR=$1
    MINUTE=$2

    echo "Sinkronisasi waktu berhasil (melalui NTP). Waktu saat ini: $CURRENT_TIME_FULL"
    echo "======================"
    
    while pgrep -f "paplay" > /dev/null; do
      echo "Pengecekan Proses: paplay sedang berjalan, menunda 5 detik..."
      sleep 5
    done
    echo "Pengecekan Proses: paplay tidak ditemukan, melanjutkan pemutaran."

    play_audio "$AUDIO_DIR/pembuka/ntp_pembuka_berhasil.wav"
    play_audio "$AUDIO_DIR/angka/tahun.wav"

    tahun_ribuan=$(echo $YEAR | cut -c1-2)
    tahun_sisa=$(echo $YEAR | cut -c3-4)
    play_audio "$AUDIO_DIR/angka/${tahun_ribuan}00.wav"
    
    if [ "$tahun_sisa" != "00" ]; then
        play_tens_number "$tahun_sisa"
    fi

    play_audio "$AUDIO_DIR/bulan/bulan.wav"
    case "$MONTH" in
        01) play_audio "$AUDIO_DIR/bulan/januari.wav";;
        02) play_audio "$AUDIO_DIR/bulan/februari.wav";;
        03) play_audio "$AUDIO_DIR/bulan/maret.wav";;
        04) play_audio "$AUDIO_DIR/bulan/april.wav";;
        05) play_audio "$AUDIO_DIR/bulan/mei.wav";;
        06) play_audio "$AUDIO_DIR/bulan/juni.wav";;
        07) play_audio "$AUDIO_DIR/bulan/juli.wav";;
        08) play_audio "$AUDIO_DIR/bulan/agustus.wav";;
        09) play_audio "$AUDIO_DIR/bulan/september.wav";;
        10) play_audio "$AUDIO_DIR/bulan/oktober.wav";;
        11) play_audio "$AUDIO_DIR/bulan/november.wav";;
        12) play_audio "$AUDIO_DIR/bulan/desember.wav";;
    esac

    play_audio "$AUDIO_DIR/angka/tanggal.wav"
    play_tens_number "$DAY"

    play_audio "$AUDIO_DIR/angka/jam.wav"
    play_tens_number "$HOUR"
    play_audio "$AUDIO_DIR/angka/lewat.wav"
    play_tens_number "$MINUTE"
    
    play_audio "$AUDIO_DIR/angka/wib.wav"
else
    # Kedua opsi gagal
    echo "======================"
    echo "Gagal mendapatkan waktu. Semua metode (ADB & NTP) gagal."
    echo "Periksa koneksi ADB dan koneksi internet."
    echo "======================"
    while pgrep -f "paplay" > /dev/null; do
      echo "Pengecekan Proses: paplay sedang berjalan, menunda 5 detik..."
      sleep 5
    done
    echo "Pengecekan Proses: paplay tidak ditemukan, melanjutkan pemutaran."
    play_audio "$AUDIO_DIR/pembuka/ntp_pembuka_gagal.wav"
fi

# Langkah 5: Mulai kembali layanan sysntpd
echo "Memulai kembali layanan layanan sysntpd..."
/etc/init.d/sysntpd start
echo "Proses sinkronisasi selesai."
exit 0
