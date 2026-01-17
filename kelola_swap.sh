#!/bin/bash

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
  echo "Harap jalankan sebagai root (sudo)."
  exit
fi

SWAP_PATH="/swapfile"

show_menu() {
    clear
    echo "============================================"
    echo "      PENGELOLA SWAP FILE INTERAKTIF v2     "
    echo "============================================"
    
    # Info Disk
    df -h / | grep / | awk '{print "Sisa Disk  : " $4}'
    
    # Info RAM (Fitur Tambahan)
    free -h | grep Mem | awk '{print "Penggunaan RAM: " $3 " / " $2}'
    
    # Cek Status Swap Secara Akurat
    SWAP_STATUS=$(swapon --show --noheadings)
    if [ -n "$SWAP_STATUS" ]; then
        SIZE=$(free -h | grep Swap | awk '{print $2}')
        USED=$(free -h | grep Swap | awk '{print $3}')
        echo "Status Swap: AKTIF (Size: $SIZE, Used: $USED)"
    elif [ -f "$SWAP_PATH" ]; then
        echo "Status Swap: TERSEDIA TAPI NONAKTIF (Off)"
    else
        echo "Status Swap: TIDAK ADA"
    fi
    
    echo "--------------------------------------------"
    echo "1) Buat Swap File Baru"
    echo "2) Edit Ukuran Swap File"
    echo "3) Hapus Swap File (Total)"
    echo "4) Nonaktifkan Sementara (OFF)"
    echo "5) Aktifkan Kembali (ON)"
    echo "0) Keluar"
    echo "--------------------------------------------"
    read -p "Pilih menu [0-5]: " menu_choice
}

create_swap() {
    local size=$1
    echo "--- Memproses pembuatan swap sebesar ${size}MB ---"
    
    # Matikan swap jika sedang jalan
    swapoff $SWAP_PATH 2>/dev/null
    
    # Buat file
    dd if=/dev/zero of=$SWAP_PATH bs=1M count=$size status=progress
    
    chmod 600 $SWAP_PATH
    mkswap $SWAP_PATH
    swapon $SWAP_PATH
    
    # Atur fstab agar permanen
    if ! grep -q "$SWAP_PATH" /etc/fstab; then
        echo "$SWAP_PATH none swap sw 0 0" >> /etc/fstab
    fi
    echo "--------------------------------------------"
    echo "BERHASIL! Swap ${size}MB aktif."
}

# --- Fungsi lainnya tetap sama dengan perbaikan logika ---
delete_swap() {
    echo "Menghapus total..."
    swapoff $SWAP_PATH 2>/dev/null
    rm -f $SWAP_PATH
    sed -i "\|$SWAP_PATH|d" /etc/fstab
    echo "Bersih! File dihapus & fstab diperbarui."
}

edit_size_menu() {
    echo "Pilih Ukuran Baru:"
    echo "1) 512MB"
    echo "2) 1GB"
    echo "3) 2GB"
    echo "4) Kustom"
    read -p "Pilihan: " size_choice
    case $size_choice in
        1) create_swap 512 ;;
        2) create_swap 1024 ;;
        3) create_swap 2048 ;;
        4) read -p "Ukuran (MB): " cs; create_swap $cs ;;
        *) echo "Batal." ;;
    esac
}

while true; do
    show_menu
    case $menu_choice in
        1) [ -f "$SWAP_PATH" ] && echo "Sudah ada file swap!" || edit_size_menu ;;
        2) [ ! -f "$SWAP_PATH" ] && echo "File swap tidak ditemukan!" || edit_size_menu ;;
        3) delete_swap ;;
        4) swapoff $SWAP_PATH && echo "Swap dimatikan." ;;
        5) [ -f "$SWAP_PATH" ] && swapon $SWAP_PATH && echo "Swap dihidupkan." || echo "File swap tidak ada!" ;;
        0) exit 0 ;;
    esac
    read -p "Tekan Enter..."
done
