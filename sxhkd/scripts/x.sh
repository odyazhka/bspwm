#!/bin/sh

# Файлы состояния для конкретного рабочего стола, чтобы zen mode на
# разных мониторах/десктопах не мешал друг другу
DESK="$(bspc query -D -d)"
STATE_FILE="/tmp/bspwm_zen_mode_${DESK}"
PID_FILE="/tmp/bspwm_zen_watcher_${DESK}.pid"

# Функция для восстановления окон (используется при ручном выходе)
restore_windows() {
    if [ -f "$STATE_FILE" ]; then
        while read -r wid; do
            if bspc query -N -n "$wid" > /dev/null 2>&1; then
                bspc node "$wid" -g hidden=off
            fi
        done < "$STATE_FILE"
        rm -f "$STATE_FILE"
    fi
}

# Убить именно СВОЕГО наблюдателя (по process group, не по имени команды),
# чтобы не задеть наблюдателя другого рабочего стола/монитора
kill_watcher() {
    if [ -f "$PID_FILE" ]; then
        pgid="$(cat "$PID_FILE")"
        [ -n "$pgid" ] && kill -- "-${pgid}" 2>/dev/null
        rm -f "$PID_FILE"
    fi
}

if [ -f "$STATE_FILE" ]; then
    # Если файл есть — принудительно восстанавливаем (ручной выход из Zen)
    restore_windows
    kill_watcher
else
    # ВХОД В ZEN MODE
    CUR_WID=$(bspc query -N -n)
    [ -z "$CUR_WID" ] && exit 0

    ALL_WIDS=$(bspc query -N -d -n .window)
    > "$STATE_FILE"

    for wid in $ALL_WIDS; do
        if [ "$wid" != "$CUR_WID" ]; then
            bspc node "$wid" -g hidden=on
            echo "$wid" >> "$STATE_FILE"
        fi
    done

    # Фоновый наблюдатель запускается через setsid в своей ОТДЕЛЬНОЙ
    # process group. Это позволяет потом убить именно его целиком
    # (сам процесс + "bspc subscribe" + цикл чтения), а не искать по
    # системе первый процесс с похожим именем команды.
    setsid sh -c "
        trap 'rm -f \"$STATE_FILE\" \"$PID_FILE\"' EXIT
        bspc subscribe node_remove | while read -r _ _ _ wid; do
            if [ \"\$wid\" = \"$CUR_WID\" ]; then
                while read -r rid; do
                    bspc query -N -n \"\$rid\" >/dev/null 2>&1 && bspc node \"\$rid\" -g hidden=off
                done < \"$STATE_FILE\"
                rm -f \"$STATE_FILE\"
                break
            fi
        done
    " &

    # PID процесса, запущенного через setsid, совпадает с PID лидера
    # его новой process group — по нему потом и будем убивать группу.
    echo "$!" > "$PID_FILE"
fi
