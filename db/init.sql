-- =============================================================================
-- Weather Analytics: единый скрипт инициализации БД (init + миграция)
-- Выполняется при первом запуске Postgres (docker-entrypoint-initdb.d).
-- Идемпотентные части (DO-блок) безопасны при повторном запуске вручную.
-- Имена баз: redash_app (Redash), weather_analytics (данные погоды).
-- =============================================================================

-- Базы данных (только при первом запуске с пустым volume)
CREATE DATABASE redash_app;
CREATE DATABASE weather_analytics;

\connect weather_analytics;

-- -----------------------------------------------------------------------------
-- 1. Станции (название, широта, долгота)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 2. Датчики (типы, единицы измерения)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);

-- -----------------------------------------------------------------------------
-- 3. Погодные измерения по станциям
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS weather_data (
    id SERIAL PRIMARY KEY,
    station_id INTEGER NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    temperature REAL NOT NULL,
    humidity REAL NOT NULL,
    pressure REAL NOT NULL,
    wind_speed REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_weather_timestamp ON weather_data(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_weather_station_id ON weather_data(station_id);
CREATE INDEX IF NOT EXISTS idx_weather_station_timestamp ON weather_data(station_id, timestamp DESC);

-- Справочники: станции
INSERT INTO stations (name, latitude, longitude) VALUES
    ('Moscow Central', 55.7558, 37.6173),
    ('Saint Petersburg', 59.9343, 30.3351),
    ('Kazan', 55.8304, 49.0661);

-- Справочники: датчики
INSERT INTO sensors (name, unit, description) VALUES
    ('temperature', '°C', 'Air temperature'),
    ('humidity', '%', 'Relative humidity'),
    ('pressure', 'hPa', 'Atmospheric pressure'),
    ('wind_speed', 'm/s', 'Wind speed');

-- Миграция: добавить station_id в weather_data, если таблица была создана по старой схеме
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'weather_data' AND column_name = 'station_id'
    ) THEN
        ALTER TABLE weather_data ADD COLUMN station_id INTEGER;
        UPDATE weather_data SET station_id = 1;
        ALTER TABLE weather_data ALTER COLUMN station_id SET NOT NULL;
        ALTER TABLE weather_data ADD CONSTRAINT weather_data_station_id_fkey
            FOREIGN KEY (station_id) REFERENCES stations(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_weather_station_id ON weather_data(station_id);
        CREATE INDEX IF NOT EXISTS idx_weather_station_timestamp ON weather_data(station_id, timestamp DESC);
    END IF;
END $$;
