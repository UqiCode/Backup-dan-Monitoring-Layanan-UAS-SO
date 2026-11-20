#!/bin/bash
LOG_FILE="/tmp/sysguard/monitor.log"
mkdir -p "$(dirname "$LOG_FILE")"

SERVICE_NAME="${1:-nginx}"
DISK_THRESHOLD=90

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

check_service() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null || pgrep -x "$SERVICE_NAME" > /dev/null; then
        log "INFO" "Service '$SERVICE_NAME' is running"
        return 0
    else
        log "ERROR" "Service '$SERVICE_NAME' is NOT running"
        return 1
    fi
}

check_disk() {
    USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
        log "ERROR" "Disk usage ${USAGE}% exceeds threshold ${DISK_THRESHOLD}%"
        return 1
    else
        log "INFO" "Disk usage ${USAGE}% is within safe limit"
        return 0
    fi
}

check_service; SERVICE_STATUS=$?
check_disk; DISK_STATUS=$?

if [ $SERVICE_STATUS -eq 0 ] && [ $DISK_STATUS -eq 0 ]; then
    log "INFO" "System health OK"; exit 0
elif [ $SERVICE_STATUS -ne 0 ] && [ $DISK_STATUS -ne 0 ]; then
    log "ERROR" "System health CRITICAL"; exit 2
else
    log "WARNING" "System health WARNING"; exit 1
fi
