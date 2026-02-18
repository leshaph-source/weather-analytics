- **PostgreSQL:** порт `5432`. Две БД: `redash_app` (метаданные Redash), `weather_analytics` (заполняется генератором).
- **Генератор** (`generator.py`): добавляет значения погодных условий `weather_analytics`.
- **Redash:** UI на порту `5000`. Базы данных


## Запуск

**Одна команда** (из корня проекта):

```shell
docker compose up -d
```

При первом запуске будут собраны образы (`--build` не обязателен, но при изменении `generator/` пересоберите: `docker compose up -d --build`).

- **Redash:** [http://localhost:5000](http://localhost:5000) — при первом заходе создайте учётную запись администратора.
- **PostgreSQL (схема магазина):** порт `5432`. В Redash добавьте Data Source → PostgreSQL: Host `postgres`, Port `5432`, User/Password `weather_user`/`weather_secret_change_me` (по умолчанию), Database `weather_analytics`.

Переменные окружения заданы по умолчанию в `docker-compose.yml`.

Инициализация БД: `init.sql`.

## Работа с редаш 
Регистриуермся, подключаем бд, создаем дашборды
![[2026-02-18_22-05-53.png]]
![[2026-02-18_22-05-33.png]]
![[2026-02-18_22-05-21.png]]

Список запросов 
![[2026-02-18_22-08-02.png]]
