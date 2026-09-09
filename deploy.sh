#!/bin/sh
set -e

APP_NAME="TaskBoard"
APP_DIR="taskboard"
REPOSITORY_URL="https://github.com/sharton/taskboard"
DB_NAME="taskboard"
DB_USER="taskboard"
DB_PASSWORD="taskboard"
APP_PORT="8000"

echo "=== [1/7] Проверка системных пакетов ==="
REQUIRED_PKG="git python3 python3-pip python3-venv postgresql postgresql-contrib curl"

for pkg in $REQUIRED_PKG; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "становка отсутствующего пакета: $pkg"
        sudo apt-get update -y && sudo apt-get install -y $pkg
    fi
done


echo "=== [2/7] Проверка исходного кода ==="
if [ ! -f "requirements.txt" ]; then
    if [ ! -d "$APP_DIR" ]; then
        git clone "$REPOSITORY_URL" "$APP_DIR"
        cd "$APP_DIR"
    else
        cd "$APP_DIR"
    fi
fi

echo "=== [3/7] Создание виртуального окружения ==="
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

echo "=== [4/7] Установка Python-зависимостей ==="
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt




