#!/bin/bash
SOURCE_DIR="${1:-./source/data}"
BACKUP_DIR="${2:-./backups}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
LOG_FILE="/tmp/sysguard/backup.log"
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR" "Source directory $SOURCE_DIR not found"
    exit 1
fi

tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

if [ $? -eq 0 ]; then
    CHECKSUM=$(sha256sum "$BACKUP_FILE" | awk '{print $1}')
    echo "$CHECKSUM" > "$BACKUP_FILE.sha256"
    log "INFO" "Backup created: $BACKUP_FILE (checksum: $CHECKSUM)"
    exit 0
else
    log "ERROR" "Backup failed"
    exit 1
fi
