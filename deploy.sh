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

echo "=== [5/7] Подготовка PostgreSQL ==="
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Создание пользователя и БД без ошибок при повторном запуске
sudo -u postgres psql -c "DO \$DO\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD'; END IF; END \$DO\$;"
sudo -u postgres psql -c "DO \$DO\$ BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN CREATE DATABASE $DB_NAME OWNER $DB_USER; END IF; END \$DO\$;"

export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"


