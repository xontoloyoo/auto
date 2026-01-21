#!/bin/bash

# =================================================================================
# Skrip Uninstall Rclone Otomatis
# Menghapus service, konfigurasi, cache, dan mount point berdasarkan skrip instalasi.
# =================================================================================

echo "--- Memulai Proses Pembersihan Rclone ---"

# 1. Menghentikan dan menghapus Service Systemd
echo "Menghentikan service rclone..."
sudo systemctl stop rclone.service 2>/dev/null
sudo systemctl disable rclone.service 2>/dev/null

echo "Menghapus file service rclone..."
sudo rm -f /etc/systemd/system/rclone.service
sudo systemctl daemon-reload
sudo systemctl reset-failed

# 2. Melepaskan Mount Point (Unmount)
echo "Melepaskan mount point /mnt/gdrive..."
# Mencoba unmount secara paksa jika masih tersangkut
sudo fusermount -uz /mnt/gdrive 2>/dev/null
sudo umount -f /mnt/gdrive 2>/dev/null

# 3. Menghapus Direktori dan File Konfigurasi
echo "Menghapus direktori cache, mount point, dan konfigurasi..."
sudo rm -rf /opt/rclone_cache
sudo rm -rf /mnt/gdrive
sudo rm -rf /etc/rclone

# 4. Menghapus Biner Rclone (Opsional)
# Jika kamu ingin menghapus aplikasi rclone sepenuhnya dari sistem:
read -p "Apakah Anda ingin menghapus aplikasi Rclone dari sistem? (y/n): " REMOVE_BIN
if [[ $REMOVE_BIN == "y" ]]; then
    echo "Menghapus biner rclone..."
    sudo rm -f /usr/bin/rclone
    sudo rm -f /usr/local/share/man/man1/rclone.1
    echo "Rclone telah dihapus dari sistem."
fi

# 5. Membersihkan Sisa Log
sudo journalctl --vacuum-time=1s > /dev/null 2>&1

echo "------------------------------------------"
echo "Pembersihan Selesai!"
echo "Sistem sekarang bersih dan siap untuk menjalankan skrip instalasi baru."
echo "------------------------------------------"
