import os
import pandas as pd
import numpy as np
from google import genai
from sklearn.ensemble import RandomForestClassifier
from sklearn.multioutput import MultiOutputClassifier
from sklearn.preprocessing import StandardScaler
import joblib

# --- CONFIGURATION ---
# Set your API key as an environment variable: GEMINI_API_KEY=your_key
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
MODEL_PATH = "rf_model.joblib"
SCALER_PATH = "scaler.joblib"

# --- OPTIMAL RANGES (the "Hoodie & Low-Light" profile) ---
OPTIMAL = {
    "temp":  {"min": 19.0, "max": 23.0},
    "humid": {"min": 40.0, "max": 60.0},
    "lux":   {"min": 150.0, "max": 400.0},
    "noise": {"min": 0.0,   "max": 220.0},
}


def _generate_synthetic_data(n_samples: int = 2000) -> pd.DataFrame:
    """
    Generates a realistic synthetic dataset for training.
    Scores and direction vectors are derived from how far each
    sensor reading deviates from the optimal range.
    """
    np.random.seed(42)
    temp  = np.random.uniform(15.0, 35.0, n_samples)
    humid = np.random.uniform(20.0, 90.0, n_samples)
    lux   = np.random.uniform(0.0,  1000.0, n_samples)
    noise = np.random.uniform(0.0,  600.0, n_samples)

    def direction(val, lo, hi):
        """Returns -1 (decrease), 0 (ok), or 1 (increase)."""
        if val < lo:
            return 1
        elif val > hi:
            return -1
        return 0

    def penalty(val, lo, hi):
        """Normalised deviation from the optimal range (0 = perfect)."""
        if val < lo:
            return (lo - val) / lo
        elif val > hi:
            return (val - hi) / hi
        return 0.0

    records = []
    for i in range(n_samples):
        p_t = penalty(temp[i],  OPTIMAL["temp"]["min"],  OPTIMAL["temp"]["max"])
        p_h = penalty(humid[i], OPTIMAL["humid"]["min"], OPTIMAL["humid"]["max"])
        p_l = penalty(lux[i],   OPTIMAL["lux"]["min"],   OPTIMAL["lux"]["max"])
        p_n = penalty(noise[i], OPTIMAL["noise"]["min"], OPTIMAL["noise"]["max"])

        total_penalty = (p_t + p_h + p_l + p_n) / 4.0
        base_score = 10.0 * (1.0 - total_penalty)
        noise_jitter = np.random.normal(0, 0.4)
        score = int(np.clip(round(base_score + noise_jitter), 1, 10))

        records.append({
            "temp":   temp[i],
            "humid":  humid[i],
            "lux":    lux[i],
            "noise":  noise[i],
            "user_score": score,
            "v_t": direction(temp[i],  OPTIMAL["temp"]["min"],  OPTIMAL["temp"]["max"]),
            "v_h": direction(humid[i], OPTIMAL["humid"]["min"], OPTIMAL["humid"]["max"]),
            "v_l": direction(lux[i],   OPTIMAL["lux"]["min"],   OPTIMAL["lux"]["max"]),
            "v_n": direction(noise[i], OPTIMAL["noise"]["min"], OPTIMAL["noise"]["max"]),
        })

    return pd.DataFrame(records)


class ProductivitySystem:
    def __init__(self):
        self.scaler = StandardScaler()
        self.score_clf = RandomForestClassifier(n_estimators=100, random_state=42)
        self.vec_clf = MultiOutputClassifier(
            RandomForestClassifier(n_estimators=100, random_state=42)
        )
        self._load_or_train()

    # ------------------------------------------------------------------
    # Training / persistence
    # ------------------------------------------------------------------

    def _load_or_train(self):
        """Load saved models from disk, or train fresh if not found."""
        if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
            saved = joblib.load(MODEL_PATH)
            self.score_clf = saved["score_clf"]
            self.vec_clf   = saved["vec_clf"]
            self.scaler    = joblib.load(SCALER_PATH)
            print("✅ Models loaded from disk.")
        else:
            self._train_and_save()

    def _train_and_save(self):
        """Train on synthetic data and persist to disk."""
        print("⚙️  No saved model found — generating synthetic data and training...")
        df = _generate_synthetic_data()

        X  = df[["temp", "humid", "lux", "noise"]]
        ys = df["user_score"]
        yv = df[["v_t", "v_h", "v_l", "v_n"]]

        self.scaler.fit(X)
        X_scaled = self.scaler.transform(X)

        self.score_clf.fit(X_scaled, ys)
        self.vec_clf.fit(X_scaled, yv)

        joblib.dump(
            {"score_clf": self.score_clf, "vec_clf": self.vec_clf},
            MODEL_PATH,
        )
        joblib.dump(self.scaler, SCALER_PATH)
        print("✅ Models trained and saved to disk.")

    # ------------------------------------------------------------------
    # Inference
    # ------------------------------------------------------------------

    def get_prediction_vector(self, temp: float, humid: float, lux: float, noise: float) -> dict:
        """
        Takes sensor input and returns predicted score + recommendation vector.
        Handles the known hardware bug where noise can be reported as 0.
        """
        # Guard: noise=0 is a known mic wiring issue — substitute a neutral value
        if noise == 0:
            print("⚠️  Warning: noise=0 received (possible mic wiring issue). Using neutral value.")
            noise = 100.0  # mid-range neutral, won't skew the vector

        input_df = pd.DataFrame(
            [[temp, humid, lux, noise]],
            columns=["temp", "humid", "lux", "noise"],
        )
        input_scaled = self.scaler.transform(input_df)

        predicted_score  = self.score_clf.predict(input_scaled)[0]
        predicted_vector = self.vec_clf.predict(input_scaled)[0]

        return {
            "score":  int(predicted_score),
            "vector": predicted_vector.tolist(),
            "labels": ["v_temp", "v_humid", "v_light", "v_noise"],
        }


# ------------------------------------------------------------------
# Gemini guidance (standalone function — called by Flask only when needed)
# ------------------------------------------------------------------

def get_personalized_guidance(prediction_results: dict) -> str:
    """Calls Gemini 2.0 Flash for structured coaching advice."""
    gemini_api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not gemini_api_key:
        return "Error: GEMINI_API_KEY environment variable not set."

    client = genai.Client(
        api_key=gemini_api_key,
        http_options={"api_version": "v1"},
    )

    score = prediction_results["score"]
    v     = prediction_results["vector"]

    prompt = f"""
Productivity Score: {score}/10
Recommendation Vector [Temp, Humidity, Light, Noise]: {v}
(1=Increase, -1=Decrease, 0=No change)

Respond in this EXACT format, no extra text:

PARAMETERS TO CHANGE:
- [Parameter]: [Increase/Decrease]

ACTIONS:
[Parameter]:
1. [action]
2. [action]
3. [action]

Only list parameters where the vector value is not 0. Be brief.
"""

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
        )
        return response.text
    except Exception as e:
        return f"Error fetching guidance: {str(e)}"


# --- QUICK SMOKE TEST ---
if __name__ == "__main__":
    system = ProductivitySystem()

    sensors = {"temp": 24.5, "humid": 60, "lux": 45, "noise": 350}
    results = system.get_prediction_vector(**sensors)
    print(f"\nModel Output: Score {results['score']} | Vector {results['vector']}")

    if results["score"] < 8:
        print("\n--- Gemini Personalized Guidance ---")
        guidance = get_personalized_guidance(results)
        print(guidance)
    else:
        print("\nEnvironment is optimal. Keep going!")
