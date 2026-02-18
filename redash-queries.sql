-- =============================================================================
-- REDASH DASHBOARD QUERIES — Weather Analytics
-- Схема: stations, sensors, weather_data
-- =============================================================================
-- Рекомендации по визуализации указаны в комментариях к каждому запросу.
--
-- ИСТОЧНИК ДАННЫХ в Redash (подключение к БД из Docker):
--   Name:     любое (например Weather)
--   Host:     postgres    ← имя сервиса в docker-compose, не localhost
--   Port:     5432
--   User:     из .env (DB_USER, по умолчанию weather_user)
--   Password: из .env (DB_PASSWORD)
--   Database: weather_analytics  ← база с данными погоды (не redash_app)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. ДИАГНОСТИКА: проверка подключения и схемы (выполнить первым)
-- Показывает: база, список таблиц, есть ли station_id, диапазон дат в данных
-- -----------------------------------------------------------------------------
SELECT 'current_database' AS "Проверка", current_database()::text AS "Значение"
UNION ALL
SELECT 'tables', (SELECT string_agg(table_name, ', ' ORDER BY table_name) FROM information_schema.tables WHERE table_schema = 'public')
UNION ALL
SELECT 'weather_data.station_id', (
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'weather_data' AND column_name = 'station_id'
  )
)::text
UNION ALL
SELECT 'min_timestamp', COALESCE((SELECT MIN(timestamp)::text FROM weather_data), 'нет данных')
UNION ALL
SELECT 'max_timestamp', COALESCE((SELECT MAX(timestamp)::text FROM weather_data), 'нет данных');

-- -----------------------------------------------------------------------------
-- 1. KPI: Текущие средние за последний час (4 счётчика)
-- Визуализация: 4× Counter (по одному на колонку) или один Box с 4 метриками
-- -----------------------------------------------------------------------------
SELECT
    ROUND(AVG(temperature)::numeric, 1)  AS "Температура °C",
    ROUND(AVG(humidity)::numeric, 1)     AS "Влажность %",
    ROUND(AVG(pressure)::numeric, 1)     AS "Давление hPa",
    ROUND(AVG(wind_speed)::numeric, 1)  AS "Ветер м/с"
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '1 hour';


-- -----------------------------------------------------------------------------
-- 2. KPI по станциям: средние за 24 ч (таблица или барчарт)
-- Визуализация: Table или Bar Chart (X: station_name, Y: метрики)
-- -----------------------------------------------------------------------------
SELECT
    st.name                              AS "Станция",
    ROUND(AVG(w.temperature)::numeric, 1)  AS "Температура °C",
    ROUND(AVG(w.humidity)::numeric, 1)     AS "Влажность %",
    ROUND(AVG(w.pressure)::numeric, 1)     AS "Давление hPa",
    ROUND(AVG(w.wind_speed)::numeric, 1)    AS "Ветер м/с",
    COUNT(*)                               AS "Измерений"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY st.id, st.name
ORDER BY st.name;


-- -----------------------------------------------------------------------------
-- 3. Линия: температура по станциям за 24 часа
-- Визуализация: Line Chart — X: time, серии по колонкам или по "Станция"
-- (в Redash: X Column = time, Y Columns = temperature, Group by = station_name)
-- -----------------------------------------------------------------------------
SELECT
    w.timestamp                          AS "time",
    st.name                              AS "Станция",
    ROUND(w.temperature::numeric, 1)     AS "Температура °C"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY w.timestamp ASC;


-- -----------------------------------------------------------------------------
-- 4. Линия: все метрики в одном графике (агрегат по всем станциям)
-- Визуализация: Line Chart — X: time, несколько Y (нормализуйте шкалы или сделайте 4 графика)
-- -----------------------------------------------------------------------------
SELECT
    DATE_TRUNC('hour', w.timestamp)       AS "time",
    ROUND(AVG(w.temperature)::numeric, 1)  AS "Температура °C",
    ROUND(AVG(w.humidity)::numeric, 1)     AS "Влажность %",
    ROUND(AVG(w.pressure)::numeric, 1)     AS "Давление hPa",
    ROUND(AVG(w.wind_speed)::numeric, 1)   AS "Ветер м/с"
FROM weather_data w
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', w.timestamp)
ORDER BY 1;


-- -----------------------------------------------------------------------------
-- 5. Суточный цикл: средняя температура по часам (0–23) за 7 дней
-- Визуализация: Line Chart или Bar Chart — X: час, Y: температура
-- -----------------------------------------------------------------------------
SELECT
    LPAD((EXTRACT(HOUR FROM timestamp)::int)::text, 2, '0') || ':00' AS "Час",
    EXTRACT(HOUR FROM timestamp)::int   AS "hour_sort",
    ROUND(AVG(temperature)::numeric, 1) AS "Температура °C",
    ROUND(MIN(temperature)::numeric, 1) AS "Мин °C",
    ROUND(MAX(temperature)::numeric, 1) AS "Макс °C"
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM timestamp)
ORDER BY hour_sort;


-- -----------------------------------------------------------------------------
-- 6. Суточный цикл по станциям: средняя температура по часам
-- Визуализация: Line Chart — X: Час, серии по станциям
-- -----------------------------------------------------------------------------
SELECT
    EXTRACT(HOUR FROM w.timestamp)::int  AS "hour_sort",
    LPAD((EXTRACT(HOUR FROM w.timestamp)::int)::text, 2, '0') || ':00' AS "Час",
    st.name                              AS "Станция",
    ROUND(AVG(w.temperature)::numeric, 1) AS "Температура °C"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM w.timestamp), st.id, st.name
ORDER BY hour_sort, st.name;


-- -----------------------------------------------------------------------------
-- 7. Статистика по дням за 7 дней
-- Визуализация: Table или Bar Chart (X: дата, Y: любая метрика)
-- -----------------------------------------------------------------------------
SELECT
    DATE(w.timestamp)                    AS "Дата",
    COUNT(*)                             AS "Измерений",
    ROUND(AVG(w.temperature)::numeric, 1) AS "Температура °C",
    ROUND(MIN(w.temperature)::numeric, 1) AS "Мин °C",
    ROUND(MAX(w.temperature)::numeric, 1) AS "Макс °C",
    ROUND(AVG(w.humidity)::numeric, 1)    AS "Влажность %",
    ROUND(AVG(w.pressure)::numeric, 1)    AS "Давление hPa",
    ROUND(AVG(w.wind_speed)::numeric, 1)   AS "Ветер м/с"
FROM weather_data w
WHERE w.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE(w.timestamp)
ORDER BY "Дата" DESC;


-- -----------------------------------------------------------------------------
-- 8. Распределение ветра по категориям (гистограмма)
-- Визуализация: Pie Chart или Bar Chart — X: категория, Y: count
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN wind_speed < 2   THEN '1. Штиль (0–2)'
        WHEN wind_speed < 5   THEN '2. Слабый (2–5)'
        WHEN wind_speed < 10  THEN '3. Умеренный (5–10)'
        WHEN wind_speed < 15  THEN '4. Сильный (10–15)'
        ELSE '5. Очень сильный (15+)'
    END AS "Категория ветра",
    COUNT(*) AS "Количество"
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1;


-- -----------------------------------------------------------------------------
-- 9. Доля измерений по станциям за 7 дней
-- Визуализация: Pie Chart — Label: Станция, Values: Количество
-- -----------------------------------------------------------------------------
SELECT
    st.name    AS "Станция",
    COUNT(*)   AS "Количество"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY st.id, st.name
ORDER BY COUNT(*) DESC;


-- -----------------------------------------------------------------------------
-- 10. Тепловая карта: температура по часу и дню недели (7 дней)
-- Визуализация: Heatmap или Pivot — строки: день недели, столбцы: час, значение: температура
-- -----------------------------------------------------------------------------
SELECT
    TO_CHAR(w.timestamp, 'Dy')           AS "День недели",
    EXTRACT(DOW FROM w.timestamp)::int    AS "dow_sort",
    EXTRACT(HOUR FROM w.timestamp)::int   AS "hour_sort",
    LPAD((EXTRACT(HOUR FROM w.timestamp)::int)::text, 2, '0') || ':00' AS "Час",
    ROUND(AVG(w.temperature)::numeric, 1) AS "Температура °C"
FROM weather_data w
WHERE w.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(DOW FROM w.timestamp), TO_CHAR(w.timestamp, 'Dy'), EXTRACT(HOUR FROM w.timestamp)
ORDER BY dow_sort, hour_sort;


-- -----------------------------------------------------------------------------
-- 11. Последние измерения по станциям (таблица)
-- Визуализация: Table
-- -----------------------------------------------------------------------------
SELECT
    st.name                               AS "Станция",
    w.timestamp                           AS "Время",
    ROUND(w.temperature::numeric, 1)     AS "Температура °C",
    ROUND(w.humidity::numeric, 1)         AS "Влажность %",
    ROUND(w.pressure::numeric, 1)        AS "Давление hPa",
    ROUND(w.wind_speed::numeric, 1)       AS "Ветер м/с"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
ORDER BY w.timestamp DESC
LIMIT 30;


-- -----------------------------------------------------------------------------
-- 12. Справочник станций (таблица)
-- Визуализация: Table
-- -----------------------------------------------------------------------------
SELECT
    name        AS "Станция",
    latitude    AS "Широта",
    longitude   AS "Долгота"
FROM stations
ORDER BY id;


-- -----------------------------------------------------------------------------
-- 13. Сравнение станций: средняя температура за 24 ч (один столбец по станциям)
-- Визуализация: Bar Chart — X: Станция, Y: Температура °C
-- -----------------------------------------------------------------------------
SELECT
    st.name AS "Станция",
    ROUND(AVG(w.temperature)::numeric, 1) AS "Температура °C"
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY st.id, st.name
ORDER BY "Температура °C" DESC;


-- -----------------------------------------------------------------------------
-- 14. Тренд: количество измерений по часам за 24 ч
-- Визуализация: Line Chart или Bar Chart — X: час, Y: измерений
-- -----------------------------------------------------------------------------
SELECT
    DATE_TRUNC('hour', timestamp) AS "time",
    COUNT(*)                     AS "Измерений"
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY 1;
