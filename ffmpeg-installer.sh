#!/bin/bash

# --- Variabel ---
FFMPEG_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2024-09-30-15-36/ffmpeg-n7.1-linux64-lgpl-7.1.tar.xz"
FFMPEG_FILENAME="ffmpeg-n7.1-linux64-lgpl-7.1.tar.xz"
FFMPEG_FOLDER="ffmpeg-n7.1-linux64-lgpl-7.1"
WORK_DIR="/tmp/ffmpeg_install"

echo "--- Memulai Instalasi FFmpeg 7.1 ---"

# 1. Persiapan folder kerja
mkdir -p $WORK_DIR
cd $WORK_DIR

# 2. Download FFmpeg
echo "Sedang mengunduh FFmpeg..."
wget -q --show-progress $FFMPEG_URL

# 3. Ekstrak file
echo "Mengekstrak file..."
tar -xvf $FFMPEG_FILENAME > /dev/null

# 4. Pindahkan biner ke /usr/local/bin (agar bisa diakses global)
# Kita hanya mengambil file biner: ffmpeg, ffprobe, dan ffplay
echo "Menginstal biner ke sistem..."
sudo cp $FFMPEG_FOLDER/bin/* /usr/local/bin/

# 5. Berikan izin eksekusi
sudo chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

# 6. Bersihkan file sampah otomatis
echo "Membersihkan sisa instalasi..."
cd ~
rm -rf $WORK_DIR

# 7. Verifikasi
echo "--- Instalasi Selesai! ---"
ffmpeg -version | head -n 1
