-- ============================================
-- SQL Queries for Redash Visualization
-- Weather Analytics Dashboard (schema: stations, sensors, weather_data)
-- ============================================

-- ============================================
-- 0. Список станций и датчиков (Table)
-- ============================================
SELECT s.id, s.name AS station_name, s.latitude, s.longitude
FROM stations s
ORDER BY s.id;

SELECT id, name AS sensor_name, unit, description FROM sensors ORDER BY id;

-- ============================================
-- 1. Температура за последние 24 часа по станциям (Line Chart)
-- ============================================
SELECT 
    st.name AS station_name,
    w.timestamp,
    w.temperature
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY w.timestamp ASC;

-- ============================================
-- 2. Средние значения за последние 24 часа (Counter/Box)
-- ============================================
SELECT 
    ROUND(AVG(temperature)::numeric, 2) as avg_temperature,
    ROUND(AVG(humidity)::numeric, 2) as avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) as avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) as avg_wind_speed,
    ROUND(MIN(temperature)::numeric, 2) as min_temperature,
    ROUND(MAX(temperature)::numeric, 2) as max_temperature
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '24 hours';

-- ============================================
-- 2b. Средние по станциям за 24 часа (Table / Bar)
-- ============================================
SELECT 
    st.name AS station_name,
    st.latitude,
    st.longitude,
    ROUND(AVG(w.temperature)::numeric, 2) AS avg_temperature,
    ROUND(AVG(w.humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(w.pressure)::numeric, 2) AS avg_pressure,
    ROUND(AVG(w.wind_speed)::numeric, 2) AS avg_wind_speed,
    COUNT(*) AS readings_count
FROM weather_data w
JOIN stations st ON st.id = w.station_id
WHERE w.timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY st.id, st.name, st.latitude, st.longitude
ORDER BY st.name;

-- ============================================
-- 3. Суточный цикл температуры (Line Chart)
-- Средняя температура по часам за последние 7 дней
-- ============================================
SELECT 
    EXTRACT(HOUR FROM timestamp) as hour,
    ROUND(AVG(temperature)::numeric, 2) as avg_temperature,
    ROUND(MIN(temperature)::numeric, 2) as min_temperature,
    ROUND(MAX(temperature)::numeric, 2) as max_temperature
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM timestamp)
ORDER BY hour;

-- ============================================
-- 4. Статистика по дням (Table/Bar Chart)
-- ============================================
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as measurements_count,
    ROUND(AVG(temperature)::numeric, 2) as avg_temperature,
    ROUND(MIN(temperature)::numeric, 2) as min_temperature,
    ROUND(MAX(temperature)::numeric, 2) as max_temperature,
    ROUND(AVG(humidity)::numeric, 2) as avg_humidity,
    ROUND(AVG(pressure)::numeric, 2) as avg_pressure,
    ROUND(AVG(wind_speed)::numeric, 2) as avg_wind_speed
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- ============================================
-- 6. Распределение скорости ветра (Histogram/Bar Chart)
-- ============================================
SELECT 
    CASE 
        WHEN wind_speed < 2 THEN '0-2 m/s (Calm)'
        WHEN wind_speed < 5 THEN '2-5 m/s (Light)'
        WHEN wind_speed < 10 THEN '5-10 m/s (Moderate)'
        WHEN wind_speed < 15 THEN '10-15 m/s (Fresh)'
        ELSE '15+ m/s (Strong)'
    END as wind_category,
    COUNT(*) as count
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY wind_category
ORDER BY MIN(wind_speed);

-- ============================================
-- 7. Последние измерения по станциям (Table)
-- ============================================
SELECT 
    st.name AS station_name,
    st.latitude,
    st.longitude,
    w.timestamp,
    ROUND(w.temperature::numeric, 2) AS temperature,
    ROUND(w.humidity::numeric, 2) AS humidity,
    ROUND(w.pressure::numeric, 2) AS pressure,
    ROUND(w.wind_speed::numeric, 2) AS wind_speed
FROM weather_data w
JOIN stations st ON st.id = w.station_id
ORDER BY w.timestamp DESC
LIMIT 50;

-- ============================================
-- 8. Тренд температуры (Line Chart с трендом)
-- Средняя температура по часам за последние 24 часа
-- ============================================
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    ROUND(AVG(temperature)::numeric, 2) as avg_temperature,
    COUNT(*) as measurements
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour;
