#!/bin/bash
BACKUP_FILE="$1"
RESTORE_DIR="${2:-./restored}"
LOG_FILE="/tmp/sysguard/restore.log"
mkdir -p "$RESTORE_DIR" "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    log "ERROR" "Backup file not specified or not found"
    exit 1
fi

if [ -f "$BACKUP_FILE.sha256" ]; then
    CURRENT_SUM=$(sha256sum "$BACKUP_FILE" | awk '{print $1}')
    STORED_SUM=$(cat "$BACKUP_FILE.sha256")
    if [ "$CURRENT_SUM" != "$STORED_SUM" ]; then
        log "ERROR" "Checksum mismatch! Backup may be corrupted"
        exit 1
    fi
    log "INFO" "Checksum verified"
fi

tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

if [ $? -eq 0 ]; then
    log "INFO" "Restore completed to $RESTORE_DIR"
    exit 0
else
    log "ERROR" "Restore failed"
    exit 1
fi
