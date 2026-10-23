#!/bin/sh
# monitors.sh — раскладка мониторов: встроенный экран + внешние.
#
# Использование:
#   monitors.sh               применить раскладку и перезапустить bspwm
#                             (bspwmrc заново поднимет панель и рабочие столы)
#   monitors.sh --no-restart  только xrandr (для вызова из bspwmrc)
#
# Лог последнего запуска: /tmp/monitors.log

set -u

# ---------- Настройки ----------
INTERNAL="${MONITOR_INTERNAL:-eDP-1}"

# Встроенный экран: кастомный режим 1280x720
INT_MODE="1280x720_60.00"
INT_MODELINE="74.50 1280 1344 1472 1664 720 723 728 748 -hsync +vsync"
INT_W=1280
INT_Y=200            # сдвиг по вертикали, когда подключён внешний монитор

# Первый внешний монитор (он же primary)
EXT_MODE="1920x1080"
EXT_RATE="120"
# --------------------------------

LOG="/tmp/monitors.log"
: > "$LOG"

log()    { printf '%s %s\n' "$(date +%T)" "$*" >> "$LOG"; }
notify() { notify-send -u low "monitors.sh" "$1" 2>/dev/null || true; }

connected()    { xrandr --query | awk '$2 == "connected"    { print $1 }'; }
disconnected() { xrandr --query | awk '$2 == "disconnected" { print $1 }'; }

# Есть ли у выхода $1 режим $2 (строка режима под заголовком выхода)
has_mode() {
    xrandr --query | awk -v out="$1" -v mode="$2" '
        $1 == out   { f = 1; next }
        /^[^ \t]/   { f = 0 }
        f && $1 == mode { found = 1 }
        END { exit !found }'
}

# Сразу после подключения HDMI выход бывает "connected", но без режимов —
# ждём до 5 секунд, пока они появятся.
wait_for_mode() {
    n=0
    while [ "$n" -lt 20 ]; do
        has_mode "$1" "$2" && return 0
        sleep 0.25
        n=$((n + 1))
    done
    return 1
}

# Собирает аргументы xrandr для ОДНОГО вызова (одна пересборка экрана,
# без промежуточных состояний и миганий).
# $1 — параметры режима для первого внешнего монитора
build_args() {
    ext_mode="$1"
    args=""
    if [ -z "$EXTERNALS" ]; then
        args="--output $INTERNAL --primary --mode $INT_MODE --pos 0x0"
    else
        first=1
        prev=""
        for out in $EXTERNALS; do
            if [ "$first" = 1 ]; then
                args="$args --output $out --primary $ext_mode --pos ${INT_W}x0"
                first=0
            else
                args="$args --output $out --auto --right-of $prev"
            fi
            prev="$out"
        done
        args="$args --output $INTERNAL --mode $INT_MODE --pos 0x${INT_Y}"
    fi
    for out in $OFF; do
        args="$args --output $out --off"
    done
    printf '%s' "$args"
}

apply() {
    log "xrandr $*"
    xrandr "$@" >> "$LOG" 2>&1
}

# ---------- Определяем мониторы ----------
CONNECTED=$(connected)

if ! printf '%s\n' "$CONNECTED" | grep -qx "$INTERNAL"; then
    log "встроенный экран $INTERNAL не найден среди: $CONNECTED"
    notify "Не найден $INTERNAL (задай MONITOR_INTERNAL)"
    exit 1
fi

EXTERNALS=$(printf '%s\n' "$CONNECTED" | grep -vx "$INTERNAL")
OFF=$(disconnected)
log "подключены: $(printf '%s' "$CONNECTED" | tr '\n' ' ')"

# ---------- Кастомный режим встроенного экрана ----------
if ! has_mode "$INTERNAL" "$INT_MODE"; then
    # shellcheck disable=SC2086
    xrandr --newmode "$INT_MODE" $INT_MODELINE >> "$LOG" 2>&1   # "уже существует" — не страшно
    xrandr --addmode "$INTERNAL" "$INT_MODE"   >> "$LOG" 2>&1
fi

# ---------- Ждём режимы внешнего монитора ----------
FIRST_EXT=$(printf '%s\n' "$EXTERNALS" | head -1)
if [ -n "$FIRST_EXT" ]; then
    wait_for_mode "$FIRST_EXT" "$EXT_MODE" \
        || log "$FIRST_EXT: режим $EXT_MODE не появился за 5 с"
fi

# ---------- Применяем раскладку ----------
ARGS=$(build_args "--mode $EXT_MODE --rate $EXT_RATE")
# shellcheck disable=SC2086
if ! apply $ARGS; then
    log "не вышло, повтор с --auto для внешнего монитора"
    ARGS=$(build_args "--auto")
    # shellcheck disable=SC2086
    if ! apply $ARGS; then
        notify "xrandr не смог применить раскладку (лог: $LOG)"
        exit 1
    fi
fi

COUNT=$(printf '%s\n' "$CONNECTED" | wc -l)
log "готово, мониторов: $COUNT"

[ "${1:-}" = "--no-restart" ] && exit 0

# ---------- Перезапуск bspwm ----------
# bspwmrc заново назначит рабочие столы (1-5 / 6-10) и запустит panel.
notify "Мониторов: $COUNT"
sleep 0.3
if command -v bspc >/dev/null 2>&1; then
    bspc wm -r
fi
