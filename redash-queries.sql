-- ============================================
-- SQL Queries for Redash Visualization
-- Weather Analytics Dashboard
-- ============================================

-- ============================================
-- 1. Температура за последние 24 часа (Line Chart)
-- ============================================
SELECT 
    timestamp,
    temperature
FROM weather_data
WHERE timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp ASC;

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
-- 7. Последние измерения (Table)
-- ============================================
SELECT 
    timestamp,
    ROUND(temperature::numeric, 2) as temperature,
    ROUND(humidity::numeric, 2) as humidity,
    ROUND(pressure::numeric, 2) as pressure,
    ROUND(wind_speed::numeric, 2) as wind_speed
FROM weather_data
ORDER BY timestamp DESC
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
