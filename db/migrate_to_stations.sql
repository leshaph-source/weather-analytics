-- Migration: add stations, sensors; add station_id to weather_data
-- Run on existing DB where init.sql was the old version (no stations/sensors).
\connect weather;

-- 1. Stations
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
INSERT INTO stations (name, latitude, longitude)
SELECT 'Moscow Central', 55.7558, 37.6173
WHERE NOT EXISTS (SELECT 1 FROM stations LIMIT 1);
INSERT INTO stations (name, latitude, longitude)
SELECT 'Saint Petersburg', 59.9343, 30.3351
WHERE (SELECT COUNT(*) FROM stations) = 1;
INSERT INTO stations (name, latitude, longitude)
SELECT 'Kazan', 55.8304, 49.0661
WHERE (SELECT COUNT(*) FROM stations) = 2;

-- 2. Sensors
CREATE TABLE IF NOT EXISTS sensors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);
INSERT INTO sensors (name, unit, description)
SELECT 'temperature', '°C', 'Air temperature'
WHERE NOT EXISTS (SELECT 1 FROM sensors LIMIT 1);
INSERT INTO sensors (name, unit, description)
SELECT 'humidity', '%', 'Relative humidity'
WHERE (SELECT COUNT(*) FROM sensors) = 1;
INSERT INTO sensors (name, unit, description)
SELECT 'pressure', 'hPa', 'Atmospheric pressure'
WHERE (SELECT COUNT(*) FROM sensors) = 2;
INSERT INTO sensors (name, unit, description)
SELECT 'wind_speed', 'm/s', 'Wind speed'
WHERE (SELECT COUNT(*) FROM sensors) = 3;

-- 3. Add station_id to weather_data if missing
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
