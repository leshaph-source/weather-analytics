-- Create separate databases
CREATE DATABASE redash;
CREATE DATABASE weather;


\connect weather;

-- Weather table
CREATE TABLE IF NOT EXISTS weather_data (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    temperature REAL NOT NULL,
    humidity REAL NOT NULL,
    pressure REAL NOT NULL,
    wind_speed REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_weather_timestamp
ON weather_data(timestamp DESC);
