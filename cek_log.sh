#!/bin/bash

LOG_DIR="/www/wwwlogs"
PANEL_LOG="/www/server/panel/logs"
THRESHOLD=90 # Batas persentase penggunaan disk (90%)

check_emergency() {
    # Mengambil angka persentase penggunaan disk /
    USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
    
    if [ "$USAGE" -gt "$THRESHOLD" ]; then
        echo "!!! PERINGATAN: Disk hampir penuh ($USAGE%) !!!"
        echo "Menjalankan pembersihan darurat..."
        
        # Kosongkan log tanpa hapus file (Truncate)
        find $LOG_DIR -name "*.log" -exec truncate -s 0 {} +
        find $PANEL_LOG -name "*.log" -exec truncate -s 0 {} +
        
        # Bersihkan journalctl
        journalctl --vacuum-time=1h
        
        # Bersihkan cache Rclone jika ada
        [ -d "/opt/rclone_cache" ] && rm -rf /opt/rclone_cache/vfs/*
        
        echo "Pembersihan darurat selesai. Disk sekarang:"
        df -h /
    fi
}

show_menu() {
    clear
    # Jalankan pengecekan otomatis setiap kali script dibuka
    check_emergency
    
    echo "============================================"
    echo "      MONITORING LOG & EMERGENCY CLEAN      "
    echo "============================================"
    df -h / | grep / | awk '{print "Sisa Disk: " $4 " (" $5 " Terpakai)"}'
    echo "--------------------------------------------"
    echo "1) Lihat 10 File Log Terbesar"
    echo "2) Kosongkan (Flush) Semua Log Manual"
    echo "3) Monitor Log Masuk (Live Stream)"
    echo "4) Cek 20 Error Terakhir"
    echo "5) Bersihkan Log Sistem (Journalctl)"
    echo "0) Keluar"
    echo "--------------------------------------------"
    read -p "Pilih aksi [0-5]: " log_choice
}

# --- Fungsi pendukung dengan proteksi error log kosong ---

list_big_logs() {
    echo "Mencari file log terbesar..."
    find $LOG_DIR -name "*.log" -exec du -h {} + 2>/dev/null | sort -rh | head -n 10
}

live_monitor() {
    if ls $LOG_DIR/*.log 1> /dev/null 2>&1; then
        echo "Menampilkan log masuk (Ctrl+C untuk berhenti)..."
        tail -f $LOG_DIR/*.log
    else
        echo "Info: Belum ada file log di $LOG_DIR."
    fi
}

check_errors() {
    echo "Mencari pesan error terbaru..."
    if ls $LOG_DIR/*.log 1> /dev/null 2>&1; then
        grep -i "error" $LOG_DIR/*.log | tail -n 20
    else
        echo "Info: Tidak ada file log untuk diperiksa."
    fi
}

# --- Main Logic ---
while true; do
    show_menu
    case $log_choice in
        1) list_big_logs ;;
        2) 
            find $LOG_DIR -name "*.log" -exec truncate -s 0 {} +
            echo "Semua log dikosongkan." ;;
        3) live_monitor ;;
        4) check_errors ;;
        5) journalctl --vacuum-time=1d && echo "Log sistem dibersihkan." ;;
        0) exit 0 ;;
    esac
    echo -e "\nTekan Enter..."
    read
done
