# Лабораторная работа: Развертывание TaskBoard

## Цель работы

Развернуть учебное веб-приложение `TaskBoard` на `FastAPI` и `PostgreSQL`, запустить его вручную и настроить автоматический запуск как системного сервиса.

## Что должно получиться

После выполнения лабораторной работы у вас должно быть:

- запущенное приложение `TaskBoard`;
- работающая база данных `PostgreSQL`;
- доступ к веб-интерфейсу;
- доступ к REST API;
- настроенный автозапуск приложения через `systemd`.

## Структура проекта

- [app/main.py] — основной файл приложения
- [app/config.py] — настройки подключения к БД
- [app/models.py] — модель задачи
- [requirements.txt] — зависимости Python

## Задание

Нужно:

1. установить необходимые компоненты;
2. подготовить базу данных;
3. установить зависимости Python;
4. запустить приложение вручную;
5. проверить веб-интерфейс и API;
6. настроить автоматический запуск приложения.

## Часть 1. Подготовка окружения

Установите:

- `Python 3.13` или новее;
- `PostgreSQL`;
- `git`.

Проверьте версии:

```bash
python --version
psql --version
git --version
```

## Часть 2. Получение проекта

Если проект находится в репозитории, склонируйте его:

```bash
git clone <URL_РЕПОЗИТОРИЯ>
```

Перейдите в каталог проекта:

```bash
cd taskboard
```

Если проект уже выдан преподавателем в архиве, распакуйте его и перейдите в папку проекта.

## Часть 3. Создание виртуального окружения

Создайте виртуальное окружение:

```bash
python -m venv .venv
```

Активируйте его.

Для Linux:

```bash
source .venv/bin/activate
```

Для Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Установите зависимости:

```bash
pip install -r requirements.txt
```

## Часть 4. Настройка PostgreSQL

Подключитесь к PostgreSQL:

```bash
psql -U postgres
```

Создайте базу данных:

```sql
CREATE DATABASE taskboard;
```

Создайте пользователя:

```sql
CREATE USER taskboard WITH PASSWORD 'taskboard';
```

Выдайте права:

```sql
GRANT ALL PRIVILEGES ON DATABASE taskboard TO taskboard;
```

Выйдите из `psql`:

```sql
\q
```

## Часть 5. Проверка настроек приложения

Откройте файл [app/config.py](/D:/IUCA/DevOps - 2026/project/app/config.py:1).

Убедитесь, что строка подключения к базе данных выглядит так:

```python
database_url: str = "postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard"
```

Если вы использовали другие имя пользователя, пароль, порт или имя базы данных, измените эту строку.

## Часть 6. Ручной запуск приложения

Запустите приложение:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Если запуск успешный, откройте в браузере:

- `http://localhost:8000/`
- `http://localhost:8000/docs`
- `http://localhost:8000/api/health`

## Часть 7. Проверка работы

### Проверка через браузер

1. Откройте главную страницу.
2. Создайте новую задачу.
3. Измените статус задачи.
4. Отредактируйте задачу.
5. Удалите задачу.

### Проверка через API

Создание задачи:

```bash
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Подготовить сервер\",\"description\":\"Установить PostgreSQL и Python\",\"status\":\"new\"}"
```

Получение списка задач:

```bash
curl http://localhost:8000/api/tasks
```

Изменение статуса:

```bash
curl -X PATCH http://localhost:8000/api/tasks/1/status \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"done\"}"
```

Удаление задачи:

```bash
curl -X DELETE http://localhost:8000/api/tasks/1
```

## Часть 8. Настройка автозапуска через systemd

Создайте файл:

```bash
sudo nano /etc/systemd/system/taskboard.service
```

Добавьте в него:

```ini
[Unit]
Description=TaskBoard FastAPI application
After=network.target postgresql.service

[Service]
User=www-data
WorkingDirectory=/opt/taskboard
ExecStart=/opt/taskboard/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Примечание:

- `/opt/taskboard` нужно заменить на реальный путь к проекту;
- `User=www-data` можно заменить на имя пользователя, от которого должен запускаться сервис.

Перечитайте конфигурацию `systemd`:

```bash
sudo systemctl daemon-reload
```

Включите автозапуск:

```bash
sudo systemctl enable taskboard
```

Запустите сервис:

```bash
sudo systemctl start taskboard
```

Проверьте статус:

```bash
sudo systemctl status taskboard
```

## Часть 9. Что сдать

Студент должен показать:

- что PostgreSQL запущен;
- что приложение запускается вручную;
- что страница `http://localhost:8000/` открывается;
- что `http://localhost:8000/docs` доступен;
- что сервис `taskboard` добавлен в `systemd`;
- что после перезагрузки сервера приложение стартует автоматически.

## Контрольные вопросы

1. Для чего нужно виртуальное окружение Python?
2. Зачем приложению нужна строка подключения к базе данных?
3. Что делает `uvicorn`?
4. Для чего используется `systemd`?
5. Чем отличается ручной запуск приложения от автозапуска через сервис?

## Возможные ошибки

### Ошибка подключения к PostgreSQL

Проверьте:

- запущен ли `PostgreSQL`;
- существует ли база `taskboard`;
- существует ли пользователь `taskboard`;
- совпадает ли строка подключения в `app/config.py`.

### Ошибка `ModuleNotFoundError`

Проверьте:

- активировано ли виртуальное окружение;
- выполнена ли команда `pip install -r requirements.txt`.

### Ошибка `address already in use`

Это значит, что порт `8000` уже занят.

Запустите приложение на другом порту:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## Итог

В этой лабораторной работе вы вручную развернули приложение `TaskBoard`, подключили его к `PostgreSQL`, проверили REST API и настроили автоматический запуск через `systemd`.
