# app.py - prediction service (FastAPI)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import pandas as pd
import joblib
from tensorflow.keras.models import load_model
import mysql.connector
from typing import List, Dict, Any

# ---------------- CONFIG ----------------
MODEL_PATH = "flood_regression_model.h5"
SCALER_PATH = "scaler_regression.pkl"
GRID_CSV = "Clean_Grid_Elevation_Slope.csv"

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "123987",
    "database": "flood_ai"
}

# ---------------- LOAD MODEL & SCALER ----------------
model = load_model(MODEL_PATH, compile=False)
scaler = joblib.load(SCALER_PATH)

# ---------------- APP ----------------
app = FastAPI(title="Flood Predictor")

# ---------------- DB ----------------
def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)


# ---------------- Helpers ----------------

def safe_float(x):
    try:
        if x is None:
            return 0.0
        v = float(x)
        if np.isnan(v):
            return 0.0
        return v
    except Exception:
        return 0.0


def fetch_grid_histories_from_db() -> pd.DataFrame:
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT latitude, longitude,
               day1, day2, day3, day4, day5, day6,
               today_forecast, tomorrow_forecast
        FROM grid_rainfall_history
    """)
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    cols = ["latitude", "longitude",
            "day1", "day2", "day3", "day4", "day5", "day6",
            "today_forecast", "tomorrow_forecast"]
    df = pd.DataFrame(rows, columns=cols)

    for c in cols[2:]:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0.0)

    df["latitude_r"] = df["latitude"].round(6)
    df["longitude_r"] = df["longitude"].round(6)
    return df


def load_grid_static_csv() -> pd.DataFrame:
    df = pd.read_csv(GRID_CSV)
    df["latitude_r"] = df["latitude"].round(6)
    df["longitude_r"] = df["longitude"].round(6)
    return df


def build_feature_sequence(row: pd.Series) -> np.ndarray:
    day6 = safe_float(row["day6"])
    day5 = safe_float(row["day5"])
    day4 = safe_float(row["day4"])
    day3 = safe_float(row["day3"])
    day2 = safe_float(row["day2"])
    day1 = safe_float(row["day1"])
    tomorrow = safe_float(row["tomorrow_forecast"])

    seq = [day6, day5, day4, day3, day2, day1, tomorrow]

    elevation = safe_float(row.get("elevation_m", 0.0))
    slope = safe_float(row.get("slope_deg", 0.0))

    features = []
    for i in range(len(seq)):
        rain_i = seq[i]

        start_3 = max(0, i - 2)
        rain_3 = sum(seq[start_3:i+1])

        start_5 = max(0, i - 4)
        rain_5 = sum(seq[start_5:i+1])

        start_7 = max(0, i - 6)
        rain_7 = sum(seq[start_7:i+1])

        extreme = 1 if rain_i >= 50 else 0

        features.append([
            float(rain_i),
            float(rain_3),
            float(rain_5),
            float(rain_7),
            float(extreme),
            float(elevation),
            float(slope)
        ])

    return np.array(features, dtype=float)


def build_dev_sequence(daily: float, rain3: float, rain5: float, rain7: float,
                       elevation: float, slope: float) -> np.ndarray:
    features = []
    for _ in range(7):
        extreme = 1 if daily >= 50 else 0
        features.append([
            float(daily),
            float(rain3),
            float(rain5),
            float(rain7),
            float(extreme),
            float(elevation),
            float(slope)
        ])
    return np.array(features, dtype=float)


def classify(prob: float) -> str:
    if prob < 0.4:
        return "GREEN"
    elif prob < 0.7:
        return "YELLOW"
    else:
        return "RED"


# ----------------- Main Prediction Endpoint -----------------

@app.get("/predict-all-grids")
def predict_all_grids() -> List[Dict[str, Any]]:
    try:
        histories = fetch_grid_histories_from_db()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB read error: {e}")

    try:
        static_df = load_grid_static_csv()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Grid CSV read error: {e}")

    merged = pd.merge(
        histories,
        static_df[["latitude_r", "longitude_r", "elevation_m", "slope_deg"]],
        how="left",
        on=["latitude_r", "longitude_r"]
    )

    merged["elevation_m"] = pd.to_numeric(merged["elevation_m"], errors="coerce").fillna(0.0)
    merged["slope_deg"] = pd.to_numeric(merged["slope_deg"], errors="coerce").fillna(0.0)

    results = []

    for _, row in merged.iterrows():
        lat = float(row["latitude"])
        lon = float(row["longitude"])
        elevation = float(row["elevation_m"])
        slope = float(row["slope_deg"])

        input_seq = build_feature_sequence(row)

        try:
            input_scaled = scaler.transform(input_seq)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Scaler transform error for {lat},{lon}: {e}")

        input_scaled = input_scaled.reshape(1, 7, 7)

        try:
            raw_prob = float(model.predict(input_scaled, verbose=0)[0][0])
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Model predict error for {lat},{lon}: {e}")

        elevation_factor = np.clip(1 - (elevation / 1500), 0.3, 1.0)
        slope_factor = np.clip(1 - (slope / 45), 0.4, 1.0)

        adjusted_prob = raw_prob * elevation_factor * slope_factor
        adjusted_prob = float(np.clip(adjusted_prob, 0.0, 1.0))

        alert = classify(adjusted_prob)

        results.append({
            "lat": lat,
            "lon": lon,
            "probability": round(adjusted_prob, 3),
            "alert": alert
        })

    return results


# ----------------- DEV Prediction Endpoint -----------------

class DevRainInput(BaseModel):
    daily: float
    rain_3: float
    rain_5: float
    rain_7: float


@app.post("/predict-dev")
def predict_dev(input_data: DevRainInput) -> List[Dict[str, Any]]:
    try:
        static_df = load_grid_static_csv()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Grid CSV read error: {e}")

    results = []

    for _, row in static_df.iterrows():
        lat = float(row["latitude"])
        lon = float(row["longitude"])
        elevation = safe_float(row.get("elevation_m", 0.0))
        slope = safe_float(row.get("slope_deg", 0.0))

        input_seq = build_dev_sequence(
            input_data.daily,
            input_data.rain_3,
            input_data.rain_5,
            input_data.rain_7,
            elevation,
            slope
        )

        try:
            input_scaled = scaler.transform(input_seq)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Scaler transform error for {lat},{lon}: {e}")

        input_scaled = input_scaled.reshape(1, 7, 7)

        try:
            raw_prob = float(model.predict(input_scaled, verbose=0)[0][0])
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Model predict error for {lat},{lon}: {e}")

        elevation_factor = np.clip(1 - (elevation / 1500), 0.3, 1.0)
        slope_factor = np.clip(1 - (slope / 45), 0.4, 1.0)

        adjusted_prob = raw_prob * elevation_factor * slope_factor
        adjusted_prob = float(np.clip(adjusted_prob, 0.0, 1.0))

        alert = classify(adjusted_prob)

        results.append({
            "lat": lat,
            "lon": lon,
            "probability": round(adjusted_prob, 3),
            "alert": alert
        })

    return results
