# uptime-monitor

Revisión externa de disponibilidad cada 5 minutos con GitHub Actions. Complementa al watchdog
que corre dentro del VPS: si el VPS entero se cae, el watchdog no puede avisar; esto sí.

- `targets.txt`: una línea por sitio (`nombre url códigos_ok`). Agregar un proyecto = agregar una línea.
- Avisa por Telegram solo al cambiar de estado (falla / recuperado), tras 3 intentos fallidos.
- Secretos del repo: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.
- El primer día de cada mes reactiva su propio cron (GitHub apaga los cron de repos públicos sin actividad en 60 días).
