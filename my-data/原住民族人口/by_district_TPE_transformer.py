import pandas as pd

# Read three Big5 encoded CSV files
prefix = "by_district_TPE_"
encoding = "big5"
df_109 = pd.read_csv(f"{prefix}109.csv", encoding=encoding)
df_110 = pd.read_csv(f"{prefix}110.csv", encoding=encoding)
df_since_111 = pd.read_csv(f"{prefix}since111.csv", encoding=encoding)

# Define field cleaning and transformation function
def transform_df(df):
    df["year"] = df["年月"].str.extract(r"(\d+)年").astype(int)
    df["month"] = df["年月"].str.extract(r"(\d+)月").astype(int)
    df = df.rename(columns={
        "區域別": "district",
        "性別": "gender",
        "原住民人口數_合計數量": "total",
        "原住民人口數_平地原住民數量": "population_plains",
        "原住民人口數_山地原住民數量": "population_mountains"
    })
    df = df[[
		"year", "month", "district", "gender", "total", "population_plains", "population_mountains"
	]]
    return df

# Apply transformation
df_109_clean = transform_df(df_109)
df_110_clean = transform_df(df_110)
df_since_111_clean = transform_df(df_since_111)

# Combine all data
df_combined = pd.concat([df_109_clean, df_110_clean, df_since_111_clean], ignore_index=True)

# Sort by year, month, district, gender
df_combined = df_combined.sort_values(by=["year", "month", "district", "gender"])

# Save to CSV
df_combined.to_csv(f"{prefix}combined.csv", index=False, encoding="utf-8")
print(f"✅ Saved to {prefix}combined.csv")
