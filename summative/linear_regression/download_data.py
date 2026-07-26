"""
Quick script to download the WHO Life Expectancy dataset.
Source: https://www.kaggle.com/datasets/kumarajarshi/life-expectancy-who
"""
import urllib.request
import os

# Try multiple known GitHub mirrors of this popular Kaggle dataset
urls = [
    "https://raw.githubusercontent.com/MainakRepositor/Datasets/master/Life%20Expectancy%20Data.csv",
    "https://raw.githubusercontent.com/rashida048/Datasets/master/Life%20Expectancy%20Data.csv",
    "https://raw.githubusercontent.com/dsrscientist/dataset1/master/life-expectancy.csv",
]

save_path = os.path.join(os.path.dirname(__file__), "Life_Expectancy_Data.csv")

for url in urls:
    try:
        print(f"Trying: {url}")
        urllib.request.urlretrieve(url, save_path)
        # Quick check the file is valid CSV with expected columns
        with open(save_path, "r") as f:
            header = f.readline()
            if "Adult Mortality" in header or "adult_mortality" in header.lower():
                print(f"SUCCESS! Dataset saved to: {save_path}")
                print(f"Header columns: {header.strip()}")
                # Count rows
                lines = sum(1 for _ in f)
                print(f"Total data rows: {lines}")
                break
            else:
                print(f"File downloaded but wrong format. Header: {header[:100]}")
                os.remove(save_path)
    except Exception as e:
        print(f"Failed: {e}")
else:
    print("\nCould not auto-download. Will create the dataset manually from WHO data.")
