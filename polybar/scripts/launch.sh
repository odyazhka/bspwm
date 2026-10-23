#!/bin/sh

# Имя бара должно совпадать с секциями в config.ini (main_0, main_1, ...),
# поэтому из DISPLAY (":0") просто удаляем двоеточие, а не заменяем его.
BAR_NAME="main_$(printf '%s' "$DISPLAY" | tr -d ':')"

# Отдельный идентификатор сессии — только для имён временных файлов
# (FIFO/флагов в /tmp), формат тут не важен, лишь бы был уникальным.
SESSION_ID="$(printf '%s' "${DISPLAY:-notty}" | tr -c 'a-zA-Z0-9' '_')"

# Завершить уже запущенные процессы панели этой сессии
# (реальная командная строка — "polybar --reload main_0", поэтому паттерн
# должен включать --reload, иначе pkill/pgrep вообще ничего не находят)
pkill -f "polybar --reload ${BAR_NAME}\$" 2>/dev/null

# Убить хвостовые скрипты от прошлого запуска
pkill -f "date.sh loop" 2>/dev/null
pkill -f "battery.sh loop" 2>/dev/null
pkill -f "stol.sh loop" 2>/dev/null

# Почистить старые FIFO и флаги состояния, относящиеся к этой сессии
rm -f /tmp/polybar_${BAR_NAME}* 2>/dev/null
rm -f /tmp/polybar_*_${SESSION_ID}_* 2>/dev/null
rm -f /tmp/polybar_date_toggle_${SESSION_ID} 2>/dev/null
rm -f /tmp/polybar_battery_collapsed_${SESSION_ID} 2>/dev/null

# Дождаться закрытия процессов панели этой сессии
i=0
while pgrep -f "polybar --reload ${BAR_NAME}\$" >/dev/null; do
    sleep 0.1
    i=$((i + 1))
    # Страховка: если через 5 секунд всё ещё живы (завис/D-state) — добиваем
    if [ "$i" -ge 50 ]; then
        pkill -9 -f "polybar --reload ${BAR_NAME}\$" 2>/dev/null
        break
    fi
done

# Запустить панель на каждом подключённом мониторе текущей сессии
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR="$m" polybar --reload "$BAR_NAME" &
    sleep 0.5
done
