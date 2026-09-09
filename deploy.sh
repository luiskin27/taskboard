#!/bin/sh
set -e

# перемениые
APP_NAME="TaskBoard"
APP_DIR="taskboard"
REPOSITORY_URL="https://github.com/sharton/taskboard"
DB_NAME="taskboard"
DB_USER="taskboard"
DB_PASSWORD="taskboard"
APP_PORT="8000"

# проверям пакети
REQUIRED_PKGS="git python3 python3-pip python3-venv postgresql postgresql-contrib curl"

for pkg in $REQUIRED_PKGS; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "ставим $pkg"
        sudo apt-get update -y
        sudo apt-get install -y $pkg
    fi
done

# качаем код если папки нету
if [ ! -f "requirements.txt" ]; then
    if [ ! -d "$APP_DIR" ]; then
        git clone "$REPOSITORY_URL" "$APP_DIR"
        cd "$APP_DIR"
    else
        cd "$APP_DIR"
    fi
fi

# создам венв
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# ставим зависимомти
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

# настраеваем базу и юзера
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql -c "DO \$DO\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD' LOGIN; END IF; END \$DO\$;"
sudo -u postgres psql -c "DO \$DO\$ BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN CREATE DATABASE $DB_NAME OWNER $DB_USER; END IF; END \$DO\$;"

export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"

# запуск ювикорна
if pgrep -f "uvicorn.*$APP_PORT" > /dev/null; then
    pkill -f "uvicorn.*$APP_PORT" || true
    sleep 2
fi

nohup .venv/bin/uvicorn main:app --host 0.0.0.0 --port $APP_PORT > app.log 2>&1 &
sleep 3

# проверям хелсчек
HEALTH_URL="http://localhost:$APP_PORT/api/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || true)

if [ "$RESPONSE" = "200" ]; then
    echo "Application deployed successfully."
    echo "Application is available at: http://localhost:$APP_PORT"
    exit 0
else
    echo "ошибка запуска"
    cat app.log
    exit 1
fi
