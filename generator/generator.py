import time
import random
import psycopg2
from datetime import datetime
import math

DB_HOST = "db"
DB_NAME = "weather"
DB_USER = "postgres"
DB_PASSWORD = "postgres"

def generate_weather():
    current_hour = datetime.now().hour

    # Суточный цикл температуры
    base_temp = 10 + 10 * math.sin((current_hour / 24) * 2 * math.pi)
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

    while True:
        data = generate_weather()
        cursor.execute("""
            INSERT INTO weather_data
            (timestamp, temperature, humidity, pressure, wind_speed)
            VALUES (%s, %s, %s, %s, %s)
        """, (datetime.now(), *data))

        print("Inserted:", data)
        time.sleep(300)

if __name__ == "__main__":
    main()
