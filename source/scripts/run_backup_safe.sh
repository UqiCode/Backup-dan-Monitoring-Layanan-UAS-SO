#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Menjalankan pengecekan kesehatan sistem..."
"$DIR/monitor.sh" nginx
MONITOR_RESULT=$?

if [ $MONITOR_RESULT -eq 0 ]; then
    echo "Sistem sehat. Melanjutkan backup..."
    "$DIR/backup.sh"
else
    echo "Sistem tidak sehat (kode: $MONITOR_RESULT). Backup DIBATALKAN."
    exit 1
fi
