# FocusZone

FocusZone is an end-to-end IoT + AI productivity optimization system that converts environmental telemetry into personalized focus-improvement guidance. The platform combines ESP32-based sensing, cloud data capture, machine learning classification, and LLM-generated recommendations in a single user-facing experience.

## Abstract

Focused cognitive performance is strongly influenced by environmental factors that are often ignored in daily work. FocusZone observes temperature, humidity, light intensity, and noise levels, correlates them with user productivity feedback, and delivers actionable recommendations that help users adjust their surroundings for better focus.

## Introduction

Productivity drops and burnout are common in remote work and high-intensity academic settings, where ambient conditions can silently degrade concentration. FocusZone addresses this by learning each user's preferred environmental profile and translating raw IoT data into personalized, real-time guidance.

## Aim

Design and implement an intelligent, responsive workspace monitoring system that uses machine learning and generative AI to provide real-time environmental optimization strategies tailored to each user's productivity profile.

## Key Objectives

- Build a low-latency ESP32 hardware node for sensor acquisition.
- Establish a reliable pipeline using ThingSpeak for cloud buffering and FastAPI for backend processing.
- Use a Multi-Output Random Forest model to detect deviations from a user's optimal productivity zone.
- Use Gemini 2.0 Flash to convert technical outputs into context-aware recommendations.
- Deliver a Flutter app with live monitoring, session tracking, and historical insights.

## System Architecture

FocusZone follows a multi-layer architecture:

1. IoT Layer: ESP32 collects temperature, humidity, light, and noise data.
2. Cloud Layer: ThingSpeak stores and streams latest sensor feeds.
3. Intelligence Layer: FastAPI backend performs validation, data wrangling, ML inference, and Gemini prompt orchestration.
4. Experience Layer: Flutter app presents live metrics, session history, and personalized suggestions.

Data flow summary:

`ESP32 Sensors -> ThingSpeak -> FastAPI + Random Forest + Gemini -> Flutter App`

## Repository Structure

- `Backend/`: FastAPI service, ML pipeline artifacts, API integration logic.
- `Dasboard/focus_zone_fe/`: Flutter frontend application.
- `requirements.txt`: Frozen Python dependencies for the backend environment.
- `productivity_tournament.ipynb`: Notebook for exploratory or tournament analysis workflows.

## Backend Setup (FastAPI)

### Prerequisites

- Python 3.10+ (recommended)
- Internet access for ThingSpeak and Gemini API calls

### Environment Variables

Create `Backend/.env` with:

```env
THINGSPEAK_CHANNEL_ID=<your_channel_id>
THINGSPEAK_READ_API_KEY=<your_read_api_key>
GEMINI_API_KEY=<your_gemini_api_key>
```

### Installation and Run

From project root:

```powershell
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r ..\requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

- Open `http://127.0.0.1:8000/`

## Frontend Setup (Flutter)

### Prerequisites

Install and configure the following before running the app:

- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Android Studio (Android SDK + emulator tools)
- A connected Android device or running emulator
- Optional: VS Code Flutter and Dart extensions

Verify installation:

```powershell
flutter doctor
```

Resolve all critical issues reported by `flutter doctor` before continuing.

### Installation and Run

From project root:

```powershell
cd Dasboard\focus_zone_fe
flutter pub get
flutter run --release
```

## Notes

- The frontend folder name is intentionally `Dasboard` in this repository.
- Backend and frontend can be started independently during development.
- For production-like testing, run backend first, then launch the Flutter app.

## Future Documentation

Upcoming sections can include API endpoint reference, ML training notes, hardware wiring documentation, and deployment guides.
