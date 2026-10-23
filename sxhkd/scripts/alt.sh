#!/bin/bash
# bspwm-drag-split.sh
# Зависимости: xdotool, xinput, bspc
#
# Устройство определяется автоматически:
#   1. Переменная ALT_DEVICE (частичное совпадение имени)   — наивысший приоритет
#   2. Первая внешняя мышь (не Synaptics, не тачпад, не XTEST, не Keyboard)
#   3. Тачпад как fallback (если внешней мыши нет)
#
# Пример ручного override:
#   ALT_DEVICE="G102" ~/.config/sxhkd/scripts/alt.sh

set -u

# --- Защита от повторного/параллельного запуска ---
# Если предыдущий инстанс каким-то образом ещё жив (завис, не
# отработал release) — новый запуск не плодит второй preview_loop,
# который будет конфликтовать с первым, а просто выходит.
LOCK_FILE="/tmp/bspwm_altdrag.lock"

if [ -f "$LOCK_FILE" ]; then
    OLD_PID="$(cat "$LOCK_FILE" 2>/dev/null)"
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        notify-send -u low "alt.sh" "Предыдущий запуск ещё активен, пропускаю" 2>/dev/null
        exit 0
    fi
    # lock-файл осиротел (процесс мёртв) — можно перезаписать
fi
echo "$$" > "$LOCK_FILE"

_find_pointer_device() {
    if [ -n "${ALT_DEVICE:-}" ]; then
        xinput list --name-only 2>/dev/null \
            | grep -i "$ALT_DEVICE" \
            | grep -iv "keyboard\|consumer" \
            | head -1
        return
    fi

    local xinput_out
    xinput_out=$(xinput list 2>/dev/null)

    # Приоритет 1: внешняя мышь (slave pointer, не тачпад, не Keyboard)
    local external
    external=$(echo "$xinput_out" \
        | grep "slave  pointer" \
        | grep -iv "xtest\|keyboard\|touchpad\|consumer\|synaptics\|syna[0-9]" \
        | grep -oP '↳ \K[^\t]+(?=\s+id=)' \
        | sed 's/[[:space:]]*$//' \
        | head -1)

    if [ -n "$external" ]; then
        echo "$external"
        return
    fi

    # Fallback: тачпад
    echo "$xinput_out" \
        | grep "slave  pointer" \
        | grep -iv "xtest\|keyboard\|consumer" \
        | grep -oP '↳ \K[^\t]+(?=\s+id=)' \
        | sed 's/[[:space:]]*$//' \
        | head -1
}

# --- Определяем устройство ---
DEVICE=$(_find_pointer_device)

if [ -z "$DEVICE" ]; then
    notify-send -u low "alt.sh" "Не найдено pointer-устройство" 2>/dev/null
    rm -f "$LOCK_FILE"
    exit 1
fi

# xinput query-state работает надёжнее по числовому id, чем по имени
DEVICE_ID=$(xinput list --id-only "$DEVICE" 2>/dev/null)
if [ -z "$DEVICE_ID" ]; then
    notify-send -u low "alt.sh" "Не удалось получить id устройства" 2>/dev/null
    rm -f "$LOCK_FILE"
    exit 1
fi

# --- 1. Запоминаем окно A ---
NODE_A=$(bspc query -N -n focused 2>/dev/null)
if [ -z "$NODE_A" ]; then
    rm -f "$LOCK_FILE"
    exit 1
fi

WIN_A=$(xdotool getactivewindow 2>/dev/null)
if [ -z "$WIN_A" ]; then
    rm -f "$LOCK_FILE"
    exit 1
fi

LAST_NODE_B=""
LAST_DIR=""

# --- Сохраняем и отключаем presel-подсветку ---
ORIG_PRESEL_COLOR=$(bspc config presel_feedback_color 2>/dev/null)
ORIG_PRESEL_FEEDBACK=$(bspc config presel_feedback 2>/dev/null)
bspc config presel_feedback_color "#00000000" 2>/dev/null
bspc config presel_feedback false 2>/dev/null

PREVIEW_PID=""
WATCHDOG_PID=""

# --- ЕДИНАЯ функция очистки. Один trap, ничего не затирается. ---
cleanup() {
    [ -n "$PREVIEW_PID" ] && kill "$PREVIEW_PID" 2>/dev/null
    [ -n "$WATCHDOG_PID" ] && kill "$WATCHDOG_PID" 2>/dev/null
    [ -n "$PREVIEW_PID" ] && wait "$PREVIEW_PID" 2>/dev/null
    bspc config presel_feedback_color "$ORIG_PRESEL_COLOR" 2>/dev/null
    bspc config presel_feedback "$ORIG_PRESEL_FEEDBACK" 2>/dev/null
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT INT TERM HUP

# --- 2. Фоновый цикл предпросмотра пока зажата кнопка ---
preview_loop() {
    while true; do
        INFO=$(xdotool getmouselocation --shell 2>/dev/null)
        WIN_B=$(echo "$INFO" | grep "^WINDOW=" | cut -d= -f2)

        if [ -z "$WIN_B" ] || [ "$WIN_B" = "0" ] || [ "$WIN_B" = "$WIN_A" ]; then
            sleep 0.05
            continue
        fi

        NODE_B=$(bspc query -N -n "$WIN_B" 2>/dev/null)
        if [ -z "$NODE_B" ] || [ "$NODE_B" = "$NODE_A" ]; then
            sleep 0.05
            continue
        fi

        CX=$(echo "$INFO" | grep "^X=" | cut -d= -f2)
        CY=$(echo "$INFO" | grep "^Y=" | cut -d= -f2)

        GEOM=$(xdotool getwindowgeometry --shell "$WIN_B" 2>/dev/null)
        WIN_X=$(echo "$GEOM" | grep "^X="      | cut -d= -f2)
        WIN_Y=$(echo "$GEOM" | grep "^Y="      | cut -d= -f2)
        WIN_W=$(echo "$GEOM" | grep "^WIDTH="  | cut -d= -f2)
        WIN_H=$(echo "$GEOM" | grep "^HEIGHT=" | cut -d= -f2)

        CENTER_X=$(( WIN_X + WIN_W / 2 ))
        CENTER_Y=$(( WIN_Y + WIN_H / 2 ))

        # Форма окна определяет ось, курсор — сторону
        if [ "${WIN_W:-0}" -gt "${WIN_H:-0}" ]; then
            [ "${CX:-0}" -lt "$CENTER_X" ] && DIR="west" || DIR="east"
        else
            [ "${CY:-0}" -lt "$CENTER_Y" ] && DIR="north" || DIR="south"
        fi

        if [ "$NODE_B" != "$LAST_NODE_B" ] || [ "$DIR" != "$LAST_DIR" ]; then
            NODE_A=$(bspc query -N -n focused 2>/dev/null)
            [ -z "$NODE_A" ] && { sleep 0.05; continue; }

            bspc node "$NODE_B" --presel-dir "$DIR" 2>/dev/null
            bspc node "$NODE_A" --to-node "$NODE_B" --follow 2>/dev/null
            bspc node "$NODE_B" --presel-dir cancel 2>/dev/null

            LAST_NODE_B="$NODE_B"
            LAST_DIR="$DIR"
        fi

        sleep 0.05
    done
}

preview_loop &
PREVIEW_PID=$!

# --- Вотчдог: жёсткий предохранитель ---
# Если по каким-то причинам основной цикл ожидания отпускания кнопки
# (ниже) никогда не увидит release — этот таймер через WATCHDOG_TIMEOUT
# секунд сам убьёт весь процесс (включая preview_loop через trap EXIT),
# чтобы скрипт физически не мог зависнуть навечно и оставить зомби,
# бесконечно двигающего окна.
WATCHDOG_TIMEOUT="${ALT_WATCHDOG_TIMEOUT:-120}"
(
    sleep "$WATCHDOG_TIMEOUT"
    notify-send -u low "alt.sh" "Вотчдог: принудительное завершение по таймауту" 2>/dev/null
    kill -TERM "$$" 2>/dev/null
) &
WATCHDOG_PID=$!
disown "$WATCHDOG_PID" 2>/dev/null

# --- 3. Ждём отпускания ЛКМ ---
# Опрос состояния кнопки через xinput query-state гораздо надёжнее,
# чем парсинг текстового вывода `xinput test` (формат которого зависит
# от версии xinput/локали и может не совпасть с ожидаемой строкой,
# из-за чего скрипт раньше мог зависать навсегда).
while true; do
    STATE=$(xinput query-state "$DEVICE_ID" 2>/dev/null)
    if [ -z "$STATE" ]; then
        # устройство исчезло (отключили мышь на ходу и т.п.) — выходим
        break
    fi
    echo "$STATE" | grep -q "button\[1\]=down" || break
    sleep 0.03
done

exit 0
