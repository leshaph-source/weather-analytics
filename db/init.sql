-- Create separate databases
CREATE DATABASE redash;
CREATE DATABASE weather;


\connect weather;

-- 1. Stations: name, latitude, longitude
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2. Sensors: sensor types used by stations
CREATE TABLE IF NOT EXISTS sensors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);

-- 3. Weather readings per station (uses all sensors: temperature, humidity, pressure, wind_speed)
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

-- Default stations
INSERT INTO stations (name, latitude, longitude) VALUES
    ('Moscow Central', 55.7558, 37.6173),
    ('Saint Petersburg', 59.9343, 30.3351),
    ('Kazan', 55.8304, 49.0661);

-- Default sensors (used by all stations in this model)
INSERT INTO sensors (name, unit, description) VALUES
    ('temperature', '°C', 'Air temperature'),
    ('humidity', '%', 'Relative humidity'),
    ('pressure', 'hPa', 'Atmospheric pressure'),
    ('wind_speed', 'm/s', 'Wind speed');
