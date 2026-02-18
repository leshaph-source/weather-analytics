import os
import time
import random
import psycopg2
from datetime import datetime
from pathlib import Path
import math

from dotenv import load_dotenv

# Загрузка .env из корня проекта (рядом с docker-compose.yml)
_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)

# Параметры подключения — те же названия переменных, что в .env
DB_HOST = os.environ.get("DB_HOST", "postgres")
DB_NAME = os.environ.get("DB_NAME", "weather_analytics")
DB_USER = os.environ.get("DB_USER", "weather_user")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "weather_secret_change_me")


def generate_weather(station_id, station_lat=None):
    """Generate weather readings. Optionally vary by latitude (e.g. colder north)."""
    current_hour = datetime.now().hour

    # Base temperature with daily cycle; optionally cooler at higher latitude
    lat_factor = 1.0
    if station_lat is not None:
        lat_factor = 1.0 - (abs(station_lat) - 50) * 0.02  # rough latitude correction
    base_temp = (10 + 10 * math.sin((current_hour / 24) * 2 * math.pi)) * lat_factor
    temperature = base_temp + random.uniform(-1.5, 1.5)

    humidity = 70 - (temperature * 0.5) + random.uniform(-5, 5)
    humidity = max(30, min(95, humidity))

    pressure = 1010 + random.uniform(-10, 10)

    wind_speed = abs(random.gauss(5, 2))

    return temperature, humidity, pressure, wind_speed


def main():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            conn.autocommit = True
            cursor = conn.cursor()
            break
        except Exception:
            print("Waiting for DB...")
            time.sleep(3)

    # Load stations (id, lat) for variation
    while True:
        cursor.execute(
            "SELECT id, latitude FROM stations ORDER BY id"
        )
        stations = cursor.fetchall()
        if stations:
            break
        print("No stations found. Waiting for init...")
        time.sleep(5)

    station_ids = [s[0] for s in stations]
    station_lats = {s[0]: s[1] for s in stations}

    while True:
        now = datetime.now()
        for station_id in station_ids:
            lat = station_lats.get(station_id)
            data = generate_weather(station_id, station_lat=lat)
            cursor.execute("""
                INSERT INTO weather_data
                (station_id, timestamp, temperature, humidity, pressure, wind_speed)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (station_id, now, *data))
            print(f"Station {station_id}: {data}")
        time.sleep(2)


if __name__ == "__main__":
    main()
