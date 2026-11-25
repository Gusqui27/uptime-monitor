#!/usr/bin/env bash
set -uo pipefail

mkdir -p state
STATE=state/status.txt
touch "$STATE"
NEW=$(mktemp)
down=()
up=()

check() {
  local name="$1" url="$2" ok="$3" code=000 attempt
  for attempt in 1 2 3; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 -A 'gcodexa-uptime-monitor' "$url" || true)
    [[ " $ok " == *" $code "* ]] && break
    sleep 10
  done
  local prev
  prev=$(grep -E "^${name} " "$STATE" | awk '{print $2}')
  if [[ " $ok " == *" $code "* ]]; then
    echo "$name ok" >> "$NEW"
    [[ "$prev" == "down" ]] && up+=("$name (HTTP $code)")
    echo "OK    $code $name"
  else
    echo "$name down" >> "$NEW"
    [[ "$prev" != "down" ]] && down+=("$name (HTTP $code)")
    echo "FALLA $code $name"
  fi
}

while read -r name url ok; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  check "$name" "$url" "${ok//,/ }"
done < targets.txt

mv "$NEW" "$STATE"

send() {
  [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]] && { echo "Sin credenciales de Telegram"; return; }
  curl -s -o /dev/null --max-time 15 \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=$1" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" || echo "No se pudo enviar a Telegram"
}

if (( ${#down[@]} )); then
  send "$(printf '🔴 [FALLO EXTERNO] visto desde fuera del VPS\n\n'; printf -- '- %s\n' "${down[@]}")"
fi
if (( ${#up[@]} )); then
  send "$(printf '🟢 [RECUPERADO EXTERNO]\n\n'; printf -- '- %s\n' "${up[@]}")"
fi
exit 0
