#!/bin/bash
set -u
DIR="${QA_WORKDIR:-$HOME/qa_test}"
mkdir -p "$DIR/logs"
LOG="$DIR/logs/os_check.log"
FAIL=0; SKIP=0
log() { printf '%s\n' "$*" | tee -a "$LOG"; }
log "=== Проверка ОС $(date -Is) ==="
if [ -f /etc/rosa-release ]; then
  log "[OK] ROSA: $(cat /etc/rosa-release)"
else
  log '[SKIP] Стенд не подтверждён как РОСА: отсутствует /etc/rosa-release'
  SKIP=$((SKIP+1))
fi
log "Ядро: $(uname -r)"
log "Свободно на /: $(df -h / | awk 'NR==2 {print $4}')"
log "Load average (1m): $(awk '{print $1}' /proc/loadavg)"
if [ -d /run/systemd/system ] && command -v systemctl >/dev/null; then
  for svc in sshd crond NetworkManager; do
    if systemctl is-active --quiet "$svc"; then log "[OK] $svc активен"
    else log "[FAIL] $svc не активен"; FAIL=$((FAIL+1)); fi
  done
else
  log '[SKIP] Нет работающего systemd: состояние служб не проверено'
  SKIP=$((SKIP+1))
fi
log "Итого: FAIL=$FAIL SKIP=$SKIP"
(( FAIL == 0 )) || exit 1
(( SKIP == 0 )) || exit 2
exit 0
