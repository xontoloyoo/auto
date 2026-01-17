#!/bin/bash

# ================= K O N F I G U R A S I =================
# Data Gcore (Jangan lupa kutip satu utk Token)
API_TOKEN='26596$755e464c996f7e4aaf3d2b4eb3dab1728534332b8edf79a2cd3462166544045e094c386b0be60a11f8400b2be0a0dea3eddfa4dce5dd3ae305a8fd7895c955f2'
ORIGIN_GROUP_ID="1321853"
RESOURCE_ID="910211"

# PORT NGINX KAMU
LOCAL_PORT="8743"

# DATA TOKEN PINGGY
TOKEN_A="Q4EUCuHaZvN"
TOKEN_B="JHa5Yq7cxD9"

# FILE SYSTEM
STATE_FILE="/root/pinggy_state.txt"
LOG_FILE="/root/pinggy_smart.log"
# =========================================================

# --- 1. LOGIKA CEK GILIRAN ---
if [ ! -f $STATE_FILE ]; then
    LAST_TOKEN="B"
else
    LAST_TOKEN=$(cat $STATE_FILE)
fi

if [ "$LAST_TOKEN" == "A" ]; then
    CURRENT_TOKEN=$TOKEN_B
    CURRENT_NAME="B"
    OLD_TOKEN=$TOKEN_A
else
    CURRENT_TOKEN=$TOKEN_A
    CURRENT_NAME="A"
    OLD_TOKEN=$TOKEN_B
fi

echo "[$(date)] --- GILIRAN TOKEN $CURRENT_NAME (Zero Downtime Mode) ---"

# --- 2. NYALAKAN TUNNEL BARU ---
# PERBAIKAN 1: Tambah -T (Disable Pseudo-tty) agar tidak muncul kotak pink
# PERBAIKAN 2: Hapus -L4300... agar tidak bentrok port debugger
CMD="ssh -T -p 443 -R0:localhost:$LOCAL_PORT -o StrictHostKeyChecking=no -o ServerAliveInterval=30 ${CURRENT_TOKEN}@ap.free.pinggy.io"

echo "[INFO] Menyalakan Pinggy $CURRENT_NAME..."
nohup $CMD > $LOG_FILE 2>&1 &
NEW_PID=$!
sleep 10

# --- 3. AMBIL URL BARU ---
# PERBAIKAN 3: Tambah -a pada grep agar bisa membaca file meski dianggap binary
RAW_URL=$(grep -a -o "https://[^ ]*.pinggy.link" $LOG_FILE | head -1)
CLEAN_URL=$(echo $RAW_URL | sed 's/https:\/\///')

if [ -z "$CLEAN_URL" ]; then
    echo "[ERROR] Gagal start Token $CURRENT_NAME. Membatalkan proses!"
    echo "[INFO] Cek Log: $LOG_FILE"
    echo "[INFO] Tunnel Lama ($OLD_TOKEN) TIDAK dimatikan agar website tetap online."
    exit 1
fi

echo "[INFO] URL Baru ($CURRENT_NAME): $CLEAN_URL"

# --- 4. UPDATE GCORE (Silent) ---
echo "[INFO] Update Gcore ke jalur $CURRENT_NAME..."

# Update Origin (Gudang)
curl -s -X PUT "https://api.gcore.com/cdn/origin_groups/$ORIGIN_GROUP_ID" \
     -H "Authorization: APIKey $API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{ "name": "TES", "sources": [{ "source": "'$CLEAN_URL'", "backup": false, "enabled": true }] }' > /dev/null

# Update Resource (Toko) - KITA HAPUS "edge_cache_settings" DI SINI
# Agar Gcore mengikuti settingan Dashboard (30 Hari)
curl -s -X PUT "https://api.gcore.com/cdn/resources/$RESOURCE_ID" \
     -H "Authorization: APIKey $API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{ 
           "originGroup": '$ORIGIN_GROUP_ID', 
           "options": { 
               "hostHeader": { 
                   "enabled": true, 
                   "value": "'$CLEAN_URL'" 
               }, 
               "staticRequestHeaders": { 
                   "enabled": true, 
                   "value": { "X-Pinggy-No-Screen": "true" } 
               }
           } 
         }' > /dev/null

# --- 5. FASE OVERLAP ---
echo "[INFO] Menunggu 60 detik... (Biarkan Tunnel Lama hidup sebentar)"
sleep 60

# --- 6. BERSIH-BERSIH (KILL LAMA) ---
echo "[INFO] Mematikan Tunnel Lama ($OLD_TOKEN)..."
pkill -f "${OLD_TOKEN}@ap.free.pinggy.io"

# --- 7. SIMPAN STATE ---
echo "$CURRENT_NAME" > $STATE_FILE

echo "[SUCCESS] Rotasi ke Token $CURRENT_NAME Selesai."
