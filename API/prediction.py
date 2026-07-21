"""
FastAPI Prediction API for Adult Mortality Rate in Africa

This API serves a trained machine learning model that predicts adult mortality
rates based on health, economic, and social indicators.
"""

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import numpy as np
import pandas as pd
import os
import io


# ============================================================
# Initialize the app
# ============================================================
app = FastAPI(
    title="Adult Mortality Prediction API",
    description=(
        "Predicts the Adult Mortality Rate (deaths per 1,000 population aged 15-60) "
        "for African nations based on WHO health indicators. "
        "Built as part of a regression analysis assignment."
    ),
    version="1.0.0",
)


# ============================================================
# CORS Middleware Configuration
# ============================================================
# We do NOT use allow_origins=["*"] because that is insecure.
# Instead, we explicitly list allowed origins.
#
# Reasoning:
# - Our Flutter mobile app communicates from localhost during development
#   and from the deployed domain in production.
# - We restrict methods to GET and POST because those are the only
#   HTTP methods our API needs.
# - We allow specific headers that are standard for JSON APIs.
# - credentials=True lets the browser send cookies if needed, but
#   only from the allowed origins listed above.
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://localhost:5000",
        "https://summative-flutter.onrender.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
)


# ============================================================
# Load the trained model, scaler, and feature columns
# ============================================================
MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "linear_regression")

model = joblib.load(os.path.join(MODEL_DIR, "best_model.pkl"))
scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
feature_columns = joblib.load(os.path.join(MODEL_DIR, "feature_columns.pkl"))


# ============================================================
# Pydantic Input Model — enforces data types and value ranges
# ============================================================
class MortalityInput(BaseModel):
    """
    Input data for predicting Adult Mortality Rate.
    Each field has a data type and realistic range constraint.
    """
    Year: int = Field(
        ..., ge=2000, le=2025,
        description="Year of observation (2000-2025)",
        json_schema_extra={"example": 2014}
    )
    Status: int = Field(
        ..., ge=0, le=1,
        description="Country status: 0 = Developing, 1 = Developed",
        json_schema_extra={"example": 0}
    )
    infant_deaths: int = Field(
        ..., ge=0, le=1800,
        description="Number of infant deaths per 1,000 population",
        json_schema_extra={"example": 64}
    )
    Alcohol: float = Field(
        ..., ge=0.0, le=20.0,
        description="Alcohol consumption per capita (litres of pure alcohol, age 15+)",
        json_schema_extra={"example": 1.5}
    )
    percentage_expenditure: float = Field(
        ..., ge=0.0, le=20000.0,
        description="Health expenditure as percentage of GDP per capita",
        json_schema_extra={"example": 50.0}
    )
    Hepatitis_B: float = Field(
        ..., ge=0.0, le=100.0,
        description="Hepatitis B immunization coverage among 1-year-olds (%)",
        json_schema_extra={"example": 72.0}
    )
    Measles: int = Field(
        ..., ge=0, le=250000,
        description="Number of reported measles cases per 1,000 population",
        json_schema_extra={"example": 500}
    )
    BMI: float = Field(
        ..., ge=1.0, le=90.0,
        description="Average Body Mass Index of the population",
        json_schema_extra={"example": 22.5}
    )
    Polio: float = Field(
        ..., ge=0.0, le=100.0,
        description="Polio (Pol3) immunization coverage among 1-year-olds (%)",
        json_schema_extra={"example": 65.0}
    )
    Total_expenditure: float = Field(
        ..., ge=0.0, le=30.0,
        description="Government expenditure on health as % of total govt expenditure",
        json_schema_extra={"example": 5.5}
    )
    Diphtheria: float = Field(
        ..., ge=0.0, le=100.0,
        description="DTP3 immunization coverage among 1-year-olds (%)",
        json_schema_extra={"example": 65.0}
    )
    HIV_AIDS: float = Field(
        ..., ge=0.1, le=50.0,
        description="Deaths per 1,000 live births due to HIV/AIDS (0-4 years)",
        json_schema_extra={"example": 3.5}
    )
    GDP: float = Field(
        ..., ge=0.0, le=120000.0,
        description="Gross Domestic Product per capita (USD)",
        json_schema_extra={"example": 1200.0}
    )
    Population: float = Field(
        ..., ge=0.0, le=1500000000.0,
        description="Population of the country",
        json_schema_extra={"example": 35000000.0}
    )
    thinness_1_19_years: float = Field(
        ..., ge=0.0, le=30.0,
        description="Prevalence of thinness among children/adolescents 10-19 years (%)",
        json_schema_extra={"example": 7.5}
    )
    Income_composition_of_resources: float = Field(
        ..., ge=0.0, le=1.0,
        description="Human Development Index in terms of income composition (0-1)",
        json_schema_extra={"example": 0.45}
    )
    Schooling: float = Field(
        ..., ge=0.0, le=25.0,
        description="Number of years of schooling",
        json_schema_extra={"example": 8.5}
    )


# ============================================================
# Pydantic Output Model
# ============================================================
class MortalityOutput(BaseModel):
    predicted_adult_mortality: float = Field(
        ..., description="Predicted adult mortality rate (deaths per 1,000 population)"
    )
    unit: str = "deaths per 1,000 population aged 15-60"


# ============================================================
# API Endpoints
# ============================================================

@app.get("/")
def root():
    """Health check and welcome message."""
    return {
        "message": "Adult Mortality Prediction API is running",
        "docs": "Visit /docs for Swagger UI",
        "model_features": feature_columns,
    }


@app.post("/predict", response_model=MortalityOutput)
def predict(data: MortalityInput):
    """
    Takes health indicator values and returns the predicted
    Adult Mortality Rate for an African nation.
    """
    # Map the Pydantic field names back to what the model expects
    input_values = [
        data.Year,
        data.Status,
        data.infant_deaths,
        data.Alcohol,
        data.percentage_expenditure,
        data.Hepatitis_B,
        data.Measles,
        data.BMI,
        data.Polio,
        data.Total_expenditure,
        data.Diphtheria,
        data.HIV_AIDS,
        data.GDP,
        data.Population,
        data.thinness_1_19_years,
        data.Income_composition_of_resources,
        data.Schooling,
    ]

    # Scale the input using the same scaler from training
    input_array = np.array(input_values).reshape(1, -1)
    input_scaled = scaler.transform(input_array)

    # Get prediction
    prediction = model.predict(input_scaled)[0]

    return MortalityOutput(
        predicted_adult_mortality=round(float(prediction), 2)
    )


@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    """
    Accepts a CSV file with new data and retrains the model.
    The CSV must have the same columns as the original dataset
    including 'Adult Mortality' as the target column.
    This allows the model to improve over time with new observations.
    """
    global model, scaler

    # Read the uploaded CSV
    try:
        contents = await file.read()
        new_data = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not read CSV file: {str(e)}")

    # Check that the target column exists
    if "Adult Mortality" not in new_data.columns:
        raise HTTPException(
            status_code=400,
            detail="CSV must contain an 'Adult Mortality' column as the target variable."
        )

    # Prepare the data the same way as training
    try:
        # Clean column names by stripping whitespace
        new_data.columns = new_data.columns.str.strip()

        # Drop non-numeric and leakage columns if they exist
        cols_to_drop = ["Country", "under-five deaths", "thinness 5-9 years", "Life expectancy"]
        for col in cols_to_drop:
            if col in new_data.columns:
                new_data = new_data.drop(columns=[col])

        # Encode Status if present
        if "Status" in new_data.columns and new_data["Status"].dtype == object:
            from sklearn.preprocessing import LabelEncoder
            le = LabelEncoder()
            new_data["Status"] = le.fit_transform(new_data["Status"])

        # Handle missing values with median
        new_data = new_data.fillna(new_data.median(numeric_only=True))

        # Split features and target
        X_new = new_data.drop("Adult Mortality", axis=1)
        y_new = new_data["Adult Mortality"]

        # Re-fit scaler and retrain model
        X_new_scaled = scaler.fit_transform(X_new)
        model.fit(X_new_scaled, y_new)

        # Save the updated model and scaler
        joblib.dump(model, os.path.join(MODEL_DIR, "best_model.pkl"))
        joblib.dump(scaler, os.path.join(MODEL_DIR, "scaler.pkl"))

        return {
            "message": "Model retrained successfully",
            "rows_used": len(X_new),
            "features_used": list(X_new.columns),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining failed: {str(e)}")
