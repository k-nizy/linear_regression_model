# Adult Mortality Rate Prediction in African Nations 🌍

## 1. Mission & Problem Statement
Premature adult deaths (ages 15-60) severely undermine socio-economic development across African nations. This project implements a machine learning linear regression pipeline to predict Adult Mortality Rates using national health and economic indicators. By identifying high-impact variables like HIV prevalence and schooling, public health officials can allocate intervention resources effectively.

## 2. Dataset Description & Source
- **Source:** [WHO Life Expectancy & Health Indicators Dataset (Kaggle)](https://www.kaggle.com/datasets/kumarajarshi/life-expectancy-who)
- **Description:** Filtered specifically for African countries (2000-2015). Features include immunization coverage (Hepatitis B, Polio, Diphtheria), disease metrics (HIV/AIDS, Measles), economic metrics (GDP, Healthcare Expenditure), and social factors (Schooling, BMI).

## 3. Public API Endpoint (Swagger UI)
- **Public Render API URL:** `https://adult-mortality-api.onrender.com`
- **Swagger Documentation:** [https://adult-mortality-api.onrender.com/docs](https://adult-mortality-api.onrender.com/docs)

## 4. Video Demo Link
- **YouTube Demo (Max 7 Minutes):** `[INSERT YOUR YOUTUBE VIDEO LINK HERE]`

## 5. How to Run the Mobile App (Flutter)
1. Ensure Flutter SDK is installed: `flutter doctor`
2. Navigate to the app directory:
   ```bash
   cd FlutterApp
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application on an emulator or connected device:
   ```bash
   flutter run -d chrome
   ```
5. Tap the **⚡ (bolt) icon** in the top bar to cycle through 5 sample country profiles, then tap **"Predict"**.

## 6. How to Run the API Locally using `uv`
1. From the project root directory, create a virtual environment and sync dependencies using `uv`:
   ```bash
   uv venv
   uv pip install -r API/requirements.txt
   ```
2. Run the FastAPI dev server:
   ```bash
   uvicorn API.prediction:app --reload --port 8000
   ```
3. Open Swagger UI locally at: `http://localhost:8000/docs`

## 7. CORS Middleware Configuration Rationale
The CORS middleware is explicitly configured on the FastAPI application (`allow_origins=["*"]`, `allow_methods=["GET", "POST"]`) to ensure seamless communication with web, mobile (Flutter), and local development environments without origin blocking.
