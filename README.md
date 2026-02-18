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
<img width="1920" height="1080" alt="2026-02-18_22-05-21" src="https://github.com/user-attachments/assets/f229f8ec-fe3f-426d-9bce-bb2653a8db5b" />
<img width="1920" height="1080" alt="2026-02-18_22-05-33" src="https://github.com/user-attachments/assets/3cf6aa2c-77f0-460e-94f7-42f7940c0da4" />
<img width="1920" height="1080" alt="2026-02-18_22-05-53" src="https://github.com/user-attachments/assets/8551c67e-eab3-4fca-911e-6af2d386c6a1" />


Список запросов 
<img width="1920" height="1080" alt="2026-02-18_22-08-02" src="https://github.com/user-attachments/assets/cb05416b-8b56-4945-af7d-41145015a7f0" />
