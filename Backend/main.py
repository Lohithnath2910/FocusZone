from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import os
import csv
import requests

# Load environment values before importing model module.
load_dotenv()

from model import ProductivitySystem, get_personalized_guidance

# --- INIT ---
app = FastAPI()

READ_API_KEY = os.getenv("THINGSPEAK_READ_API_KEY")
CHANNEL_ID   = os.getenv("THINGSPEAK_CHANNEL_ID")

# Instantiate ML system ONCE at startup — never inside a route
system = ProductivitySystem()

# --- THINGSPEAK FIELD MAPPING (matches ESP32 sketch) ---
# field1 → temperature
# field2 → humidity
# field3 → noise
# field4 → light

# --- CSV SETUP ---
if not os.path.exists('sensor_data.csv'):
    with open('sensor_data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "temperature", "humidity", "light", "noise"])

if not os.path.exists("feedback.csv"):
    with open("feedback.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "productivity"])

# --- MODELS ---
class FeedbackData(BaseModel):
    feedback: int

class SyncRequest(BaseModel):
    user_score: int  # 1–10, self-reported focus level from Flutter

class InsightRequest(BaseModel):
    user_score: int        # 1–5 session rating from Flutter (star rating)
    temperature: float
    humidity: float
    light: float
    noise: float = 100.0   # optional — defaults to neutral if not captured


# ------------------------------------------------------------------
# INTERNAL HELPER
# ------------------------------------------------------------------

def fetch_from_thingspeak() -> dict:
    """
    Fetches the latest sensor reading from ThingSpeak.
    Field mapping: field1=temp, field2=humid, field3=noise, field4=light
    Raises ValueError if fetch fails.
    """
    if not CHANNEL_ID or not READ_API_KEY:
        raise ValueError("THINGSPEAK_CHANNEL_ID and THINGSPEAK_READ_API_KEY must be set in .env")

    url = f"https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={READ_API_KEY}&results=1"

    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
    except requests.exceptions.Timeout:
        raise ValueError("ThingSpeak request timed out. ESP32 may not be transmitting.")
    except requests.exceptions.RequestException as e:
        raise ValueError(f"ThingSpeak fetch failed: {str(e)}")

    feeds = response.json().get("feeds", [])
    if not feeds:
        raise ValueError("No data available from ThingSpeak.")

    entry = feeds[0]

    # Guard: noise=0 is a known mic wiring issue — substitute neutral value
    noise_raw = float(entry.get("field3") or 0)
    if noise_raw == 0:
        print("⚠️  Warning: noise=0 received (possible mic wiring issue). Using neutral value.")
        noise_raw = 100.0

    return {
        "timestamp":   entry.get("created_at"),
        "temperature": float(entry.get("field1") or 0),
        "humidity":    float(entry.get("field2") or 0),
        "noise":       noise_raw,
        "light":       float(entry.get("field4") or 0),
    }


# ------------------------------------------------------------------
# ROUTES — FRONTEND (Flutter) CONNECTED
# ------------------------------------------------------------------

@app.get("/")
def check():
    """Health check — Flutter pings this to confirm server is alive."""
    return {"message": "API is working!"}


@app.post("/sync")
def sync(data: SyncRequest):
    """
    ★ MAIN ENDPOINT — called every 20 seconds by Flutter.

    Flutter sends:    { "user_score": 6 }
    Server fetches:   Latest sensor data from ThingSpeak
    Server runs:      ML pipeline → productivity score + direction vector
    Server calls:     Gemini (only if user_score < 8) → coaching advice
    Server returns:   Full JSON response to Flutter

    Response shape:
    {
        "predicted_score": 6,
        "user_score":      6,
        "sensor_data":     { "temperature": 24.5, "humidity": 60, "light": 250, "noise": 180 },
        "vector":          [0, 0, 1, -1],
        "labels":          ["v_temp", "v_humid", "v_light", "v_noise"],
        "guidance":        "PARAMETERS TO CHANGE: ..."
    }
    """
    if not (1 <= data.user_score <= 10):
        return {"error": "user_score must be between 1 and 10."}

    # Step 1: Fetch from ThingSpeak
    try:
        sensors = fetch_from_thingspeak()
    except ValueError as e:
        return {"error": str(e)}

    # Step 2: Log to CSV
    with open('sensor_data.csv', 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            sensors["timestamp"],
            sensors["temperature"],
            sensors["humidity"],
            sensors["light"],
            sensors["noise"]
        ])

    # Step 3: ML pipeline
    try:
        results = system.get_prediction_vector(
            temp=sensors["temperature"],
            humid=sensors["humidity"],
            lux=sensors["light"],
            noise=sensors["noise"],
        )
    except Exception as e:
        return {"error": f"Model prediction failed: {str(e)}"}

    response = {
        "predicted_score": results["score"],
        "user_score":      data.user_score,
        "sensor_data":     sensors,
        "vector":          results["vector"],
        "labels":          results["labels"],
        "guidance":        None,
    }

    # Step 4: Gemini — only if user_score < 8
    if data.user_score < 8:
        try:
            response["guidance"] = get_personalized_guidance(results)
        except Exception as e:
            response["guidance"] = f"Guidance unavailable: {str(e)}"

    return response


@app.post("/feedback")
def receive_feedback(data: FeedbackData):
    """
    ★ FRONTEND CONNECTED — Flutter sends manual feedback score.
    Stores it in feedback.csv for analysis.
    """
    timestamp = datetime.now()
    with open("feedback.csv", "a", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([timestamp, data.feedback])

    return {
        "message": "Feedback stored successfully",
        "data": {"timestamp": str(timestamp), "feedback": data.feedback}
    }


@app.get("/simulate-latest")
def simulate_latest():
    """
    ★ FRONTEND CONNECTED — Demo mode.
    Cycles through historical CSV data row by row.
    Use this when ESP32 hardware is unavailable during demo.
    Hit /pull-all-thingspeak first to populate the CSV.
    """
    global simulation_index

    if not os.path.exists('sensor_data.csv'):
        return {"error": "CSV not found. Please hit /pull-all-thingspeak first."}

    with open('sensor_data.csv', 'r') as f:
        reader = list(csv.reader(f))
        if simulation_index >= len(reader):
            simulation_index = 1
        row = reader[simulation_index]
        simulation_index += 1

    try:
        parsed_dt = datetime.strptime(row[0], "%Y-%m-%dT%H:%M:%SZ")
        clean_timestamp = parsed_dt.strftime("%b %d, %I:%M %p")
    except ValueError:
        clean_timestamp = row[0]

    return {
        "timestamp":   clean_timestamp,
        "temperature": float(row[1]) if row[1] else 0.0,
        "humidity":    float(row[2]) if row[2] else 0.0,
        "light":       float(row[3]) if row[3] else 0.0,
        "noise":       float(row[4]) if row[4] else 0.0,
    }


@app.post("/insight")
def get_insight(data: InsightRequest):
    """
    ★ FRONTEND CONNECTED — triggered when user taps 'Give me insight'.

    Called after a session ends with the session's snapshot data.
    Runs the ML pipeline + always calls Gemini regardless of score.

    Flutter sends:
    {
        "user_score":  4,
        "temperature": 24.5,
        "humidity":    60.0,
        "light":       250.0,
        "noise":       180.0   // optional, omit if not available
    }

    Returns:
    {
        "predicted_score": 5,
        "user_score":      4,
        "vector":          [0, 0, 1, -1],
        "labels":          ["v_temp", "v_humid", "v_light", "v_noise"],
        "guidance":        "PARAMETERS TO CHANGE: ..."
    }
    """
    if not (1 <= data.user_score <= 10):
        return {"error": "user_score must be between 1 and 10."}

    # Step 1: Run ML pipeline on the session snapshot
    try:
        results = system.get_prediction_vector(
            temp=data.temperature,
            humid=data.humidity,
            lux=data.light,
            noise=data.noise,
        )
    except Exception as e:
        return {"error": f"Model prediction failed: {str(e)}"}

    # Step 2: Always call Gemini — user explicitly asked for insight
    try:
        guidance = get_personalized_guidance(results)
    except Exception as e:
        guidance = f"Guidance unavailable: {str(e)}"

    return {
        "predicted_score": results["score"],
        "user_score":      data.user_score,
        "vector":          results["vector"],
        "labels":          results["labels"],
        "guidance":        guidance,
    }


# ------------------------------------------------------------------
# ROUTES — INTERNAL / UTILITY (not directly called by Flutter)
# ------------------------------------------------------------------

@app.get("/thingspeak-data")
def get_thingspeak_data():
    """
    Utility: manually pull and inspect latest ThingSpeak reading.
    Not part of the 20-second loop — use for debugging.
    """
    global latest_data
    try:
        data = fetch_from_thingspeak()
    except ValueError as e:
        return {"error": str(e)}

    latest_data = data
    with open('sensor_data.csv', 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            data["timestamp"],
            data["temperature"],
            data["humidity"],
            data["light"],
            data["noise"]
        ])
    return {"message": "Data pulled from ThingSpeak", "data": latest_data}


@app.get("/pull-all-thingspeak")
def pull_all_thingspeak():
    """
    Utility: pulls ALL historical data from ThingSpeak into sensor_data.csv.
    Run this once before using /simulate-latest for demo mode.
    """
    url = f"https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={READ_API_KEY}"
    response = requests.get(url)
    feeds = response.json().get("feeds", [])

    if not feeds:
        return {"message": "No data found on ThingSpeak."}

    with open('sensor_data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "temperature", "humidity", "light", "noise"])
        for entry in feeds:
            writer.writerow([
                entry.get("created_at"),
                entry.get("field1", 0),  # temperature
                entry.get("field2", 0),  # humidity
                entry.get("field4", 0),  # light
                entry.get("field3", 0),  # noise
            ])

    return {"message": f"Successfully pulled {len(feeds)} records from ThingSpeak to CSV."}


@app.get("/latest-data")
def get_latest_data():
    """Utility: returns the last sensor reading stored in memory."""
    if 'latest_data' in globals():
        return latest_data
    return {"message": "No data received yet."}


# --- SIMULATION BOOKMARK ---
simulation_index = 1
