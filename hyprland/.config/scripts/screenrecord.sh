#!/bin/bash

# Папка для сохранения видео
DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"
FILE="$DIR/Recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Получаем геометрию активного монитора
MONITOR_GEOM=$(hyprctl monitors -j | jq -r '.[0] | "0,0 \(.width)x\(.height)"')

# 1. ПРОВЕРКА: Если запись уже идет - останавливаем
if pgrep -x "wf-recorder" > /dev/null; then
    # Отправляем сигнал мягкого завершения (Ctrl+C)
    killall -s SIGTERM wf-recorder

    # Ждем, пока процесс реально завершится и файл сохранится
    sleep 1
    while pgrep -x "wf-recorder" > /dev/null; do
        sleep 0.5
    done

    # Отправляем уведомление ТОЛЬКО когда файл реально готов
    notify-send "Screen recording finished" "Video saved to Recordings folder"

    # Обновляем модуль Waybar (убираем красную иконку)
    pkill -RTMIN+8 waybar
    exit 0
fi

# 2. Запуск записи всего монитора
nohup wf-recorder -g "$MONITOR_GEOM" -f "$FILE" -c libx264 >/dev/null 2>&1 &

# Ждем полсекунды для инициализации wf-recorder
sleep 0.5

# Проверяем, не упал ли wf-recorder при запуске
if pgrep -x "wf-recorder" > /dev/null; then
    # Уведомляем об успешном старте
    notify-send -u critical "Screen recording" "Recording started..."
    # Обновляем Waybar (показываем красную иконку)
    pkill -RTMIN+8 waybar
else
    # Если процесс не найден - значит произошла ошибка
    notify-send -u critical "Recording Error" "Failed to start wf-recorder"
fi
