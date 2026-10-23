#!/bin/sh

MONITOR="${MONITOR:-default}"

# Разные X/Wayland-сессии (tty1, tty2 и т.д.) не должны видеть чужие
# FIFO и флаг переключения. Формируем идентификатор сессии из DISPLAY,
# а если его нет (например, Wayland) — из WAYLAND_DISPLAY, иначе из tty.
SESSION_RAW="${DISPLAY:-${WAYLAND_DISPLAY:-$(tty 2>/dev/null)}}"
SESSION_ID="$(printf '%s' "${SESSION_RAW:-notty}" | tr -c '[:alnum:]' '_')"

FLAG="/tmp/polybar_date_toggle_${SESSION_ID}"
FIFO="/tmp/polybar_date_fifo_${SESSION_ID}_${MONITOR}"

render() {
    if [ -f "$FLAG" ]; then
        date +"%d.%m.%Y"
    else
        LANG=ru_RU.UTF-8 date +"%a, %-d %B"
    fi
}

action_toggle() {
    if [ -f "$FLAG" ]; then
        rm -f "$FLAG"
    else
        touch "$FLAG"
    fi
    # Уведомить все мониторы, но только внутри текущей сессии (того же DISPLAY/tty)
    for f in /tmp/polybar_date_fifo_"${SESSION_ID}"_*; do
        [ -p "$f" ] && echo "toggle" > "$f"
    done
}

run_loop() {
    rm -f "$FIFO"
    mkfifo "$FIFO"

    exec 3<>"$FIFO"

    ( while true; do sleep 60; echo "tick" >&3; done ) &
    ticker_pid=$!

    cleanup() { kill "$ticker_pid" 2>/dev/null; exec 3>&-; rm -f "$FIFO"; }
    trap cleanup EXIT

    render
    while read -r _event <&3; do
        render
    done
}

case "${1:-loop}" in
    loop)   run_loop ;;
    toggle) action_toggle ;;
    *)      echo "Usage: $0 [loop|toggle]" >&2; exit 1 ;;
esac
