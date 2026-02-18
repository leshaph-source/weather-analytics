# База данных Weather Analytics

## Подключение

Параметры задаются в корневом файле **`.env`**. По умолчанию:

| Параметр   | Переменная .env | Значение по умолчанию   |
|-----------|------------------|--------------------------|
| **Host**  | `DB_HOST`        | `postgres`               |
| **Port**  | —                | `5432`                   |
| **User**  | `DB_USER`        | `weather_user`           |
| **Password** | `DB_PASSWORD` | см. `.env`               |
| **Database** (данные погоды) | `DB_NAME` | `weather_analytics` |
| **Database** (Redash) | `REDASH_DB_NAME` | `redash_app` |

**Важно:** Redash работает внутри Docker-сети. В настройках источника данных указывайте **Host: `postgres`** (имя сервиса), **Database: `weather_analytics`**.

## Проверка подключения

При запущенном `docker compose up`:

```powershell
docker exec wa_postgres psql -U weather_user -d weather_analytics -c "SELECT current_database(), (SELECT count(*) FROM stations) AS stations, (SELECT count(*) FROM weather_data) AS readings;"
```

В Redash выполните запрос **0. ДИАГНОСТИКА** из `redash-queries.sql`.
