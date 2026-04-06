import requests
import mysql.connector
from datetime import datetime, timedelta
from dotenv import load_dotenv
import os

# ==============================
# CONFIG
# ==============================

load_dotenv()

API_KEY = os.getenv("WEATHER_API_KEY")

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

# ==============================
# GET DB CONNECTION
# ==============================

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

# ==============================
# FETCH RAINFALL DATA
# ==============================

def fetch_rainfall(lat, lon):
    """
    Returns:
        yesterday_actual_mm,
        today_forecast_mm,
        tomorrow_forecast_mm
    """

    # -------- Forecast (Today + Tomorrow) --------
    forecast_url = "http://api.weatherapi.com/v1/forecast.json"
    forecast_params = {
        "key": API_KEY,
        "q": f"{lat},{lon}",
        "days": 2
    }

    forecast_response = requests.get(forecast_url, params=forecast_params)
    forecast_data = forecast_response.json()

    if "forecast" not in forecast_data:
        raise Exception(f"Forecast API error: {forecast_data}")

    today_forecast = forecast_data["forecast"]["forecastday"][0]["day"]["totalprecip_mm"]
    tomorrow_forecast = forecast_data["forecast"]["forecastday"][1]["day"]["totalprecip_mm"]

    # -------- Yesterday Actual --------
    yesterday_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

    history_url = "http://api.weatherapi.com/v1/history.json"
    history_params = {
        "key": API_KEY,
        "q": f"{lat},{lon}",
        "dt": yesterday_date
    }

    history_response = requests.get(history_url, params=history_params)
    history_data = history_response.json()

    if "forecast" not in history_data:
        raise Exception(f"History API error: {history_data}")

    yesterday_actual = history_data["forecast"]["forecastday"][0]["day"]["totalprecip_mm"]

    return yesterday_actual, today_forecast, tomorrow_forecast


# ==============================
# UPDATE ONE GRID (SAFE)
# ==============================

def update_grid(lat, lon):

    today_date = datetime.now().date()

    conn = get_connection()
    cursor = conn.cursor()

    # Check if already updated today
    cursor.execute("""
        SELECT last_updated 
        FROM grid_rainfall_history 
        WHERE latitude=%s AND longitude=%s
    """, (lat, lon))

    result = cursor.fetchone()

    if result and result[0] == today_date:
        print(f"Skipping {lat}, {lon} — already updated today")
        cursor.close()
        conn.close()
        return

    # Fetch rainfall only if needed
    yesterday, today_fc, tomorrow_fc = fetch_rainfall(lat, lon)

    # Shift + Update
    update_query = """
    UPDATE grid_rainfall_history
    SET
        day6 = day5,
        day5 = day4,
        day4 = day3,
        day3 = day2,
        day2 = day1,
        day1 = %s,
        today_forecast = %s,
        tomorrow_forecast = %s,
        last_updated = CURDATE()
    WHERE latitude = %s AND longitude = %s
    """

    cursor.execute(update_query, (
        yesterday,
        today_fc,
        tomorrow_fc,
        lat,
        lon
    ))

    conn.commit()

    cursor.close()
    conn.close()

    print(f"Updated grid {lat}, {lon}")


# ==============================
# UPDATE ALL GRIDS
# ==============================

def update_all_grids():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT latitude, longitude FROM grid_rainfall_history")
    grids = cursor.fetchall()

    cursor.close()
    conn.close()

    for lat, lon in grids:
        try:
            update_grid(lat, lon)
        except Exception as e:
            print(f"Error updating {lat},{lon}: {e}")


# ==============================
# RUN MANUALLY
# ==============================

if __name__ == "__main__":
    update_all_grids()