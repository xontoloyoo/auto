echo "--- Membersihkan Log Sistem ---"
journalctl --vacuum-time=1d

echo "--- Membersihkan Cache APT & Paket Tua ---"
apt-get autoremove -y
apt-get autoclean
apt-get clean

echo "--- Membersihkan Cache Rclone ---"
rm -rf /opt/rclone_cache/vfs/*

echo "--- Membersihkan Log aaPanel & Nginx ---"
rm -f /www/wwwlogs/*.log
rm -f /www/server/panel/logs/*.log
find /www/server/panel/pyenv -name "__pycache__" -type d -exec rm -rf {} +

echo "--- Membersihkan Folder Temp ---"
rm -rf /tmp/*

echo "--- Mulai Ulang ---"
/etc/init.d/php-fpm-83 restart
bt 1

echo "Pembersihan selesai! Cek sisa disk:"
df -h /
