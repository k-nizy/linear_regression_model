import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.linear_model import SGDRegressor, LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import joblib
import os

# Load dataset
df_path = os.path.join(os.path.dirname(__file__), 'Life_Expectancy_Data.csv')
df = pd.read_csv(df_path)

# Filter for African nations
african_countries = [
    'Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cameroon', 'Central African Republic', 'Chad', 'Comoros',
    'Congo', "Cote d'Ivoire", 'Democratic Republic of the Congo',
    'Djibouti', 'Egypt', 'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia',
    'Gabon', 'Gambia', 'Ghana', 'Guinea', 'Guinea-Bissau', 'Kenya',
    'Lesotho', 'Liberia', 'Libya', 'Madagascar', 'Malawi', 'Mali',
    'Mauritania', 'Mauritius', 'Morocco', 'Mozambique', 'Namibia', 'Niger',
    'Nigeria', 'Rwanda', 'Sao Tome and Principe', 'Senegal', 'Seychelles',
    'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan', 'Sudan',
    'Swaziland', 'Togo', 'Tunisia', 'Uganda', 'United Republic of Tanzania',
    'Zambia', 'Zimbabwe', 'Tanzania'
]

df['Country'] = df['Country'].str.strip()
africa_df = df[df['Country'].isin(african_countries)].copy()

# Preprocessing
data = africa_df.dropna(subset=['Adult Mortality'])

label_enc = LabelEncoder()
data['Status'] = label_enc.fit_transform(data['Status'])

columns_to_drop = ['Country', 'under-five deaths ', ' thinness 5-9 years', 'Life expectancy ']
data = data.drop(columns=columns_to_drop)

for col in data.columns:
    if data[col].isnull().sum() > 0:
        data[col] = data[col].fillna(data[col].median())

X = data.drop('Adult Mortality', axis=1)
y = data['Adult Mortality']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train models
models = {
    'SGD Linear Regression': SGDRegressor(max_iter=1000, learning_rate='adaptive', eta0=0.01, random_state=42),
    'Linear Regression': LinearRegression(),
    'Random Forest': RandomForestRegressor(n_estimators=200, max_depth=10, random_state=42),
    'Decision Tree': DecisionTreeRegressor(max_depth=8, random_state=42)
}

best_name = None
best_mse = float('inf')
best_model = None

print("--- Model Evaluation ---")
for name, m in models.items():
    m.fit(X_train_scaled, y_train)
    preds = m.predict(X_test_scaled)
    mse = mean_squared_error(y_test, preds)
    r2 = r2_score(y_test, preds)
    print(f"{name} -> Test MSE: {mse:.2f}, R2: {r2:.4f}")
    if mse < best_mse:
        best_mse = mse
        best_name = name
        best_model = m

print(f"\nBest Model: {best_name} with MSE = {best_mse:.2f}")

# Save artifacts
save_dir = os.path.dirname(__file__)
joblib.dump(best_model, os.path.join(save_dir, 'best_model.pkl'))
joblib.dump(scaler, os.path.join(save_dir, 'scaler.pkl'))
joblib.dump(list(X.columns), os.path.join(save_dir, 'feature_columns.pkl'))

print("Artifacts successfully saved (best_model.pkl, scaler.pkl, feature_columns.pkl)!")
