import pandas as pd

# Read three Big5 encoded CSV files
prefix = "by_group_TPE_"
encoding = "big5"
df_109 = pd.read_csv(f"{prefix}109.csv", encoding=encoding)
df_110 = pd.read_csv(f"{prefix}110.csv", encoding=encoding)
df_since_111 = pd.read_csv(f"{prefix}since111.csv", encoding=encoding)

# Field mapping (Chinese → English)
rename_dict = {
    "年份": "year",
    "月份": "month",
    "性別": "gender",
    "總計": "total",
    "阿美族數量": "population_amis",
    "泰雅族數量": "population_atayal",
    "排灣族數量": "population_paiwan",
    "布農族數量": "population_bunun",
    "魯凱族數量": "population_rukai",
    "卑南族數量": "population_pinan",
    "鄒族數量": "population_tsou",
    "賽夏族數量": "population_saisiyat",
    "雅美族數量": "population_yami",
    "邵族數量": "population_thao",
    "噶瑪蘭族數量": "population_kavalan",
    "太魯閣族數量": "population_truku",
    "撒奇萊雅族數量": "population_sakizaya",
    "賽德克族數量": "population_seediq",
    "拉阿魯哇族數量": "population_laaruwa",
    "卡那卡那富族數量": "population_kanakanavu",
    "尚未申報": "unreported"
}

# Standardize columns and select order
def transform_df(df):
    df = df.rename(columns=rename_dict)
    return df[list(rename_dict.values())]

# Convert and merge
df_109_clean = transform_df(df_109)
df_110_clean = transform_df(df_110)
df_since_111_clean = transform_df(df_since_111)
df_combined = pd.concat([df_109_clean, df_110_clean, df_since_111_clean], ignore_index=True)

# Sort by year, month, gender
df_combined = df_combined.sort_values(by=["year", "month", "gender"])

# Save to CSV
df_combined.to_csv(f"{prefix}combined.csv", index=False, encoding="utf-8")
print(f"✅ Saved to {prefix}combined.csv")

