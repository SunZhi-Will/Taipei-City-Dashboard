import pandas as pd

# 讀取原始 CSV
df = pd.read_csv("aed_ntpc_raw.csv")

# 選取所需欄位並重新命名
df_selected = df[["organizer", "district", "hosp_addr", "type", "location"]].rename(columns={
    "organizer": "name",
    "hosp_addr": "address",
    "type": "category",
    "location": "location_desc"
})

# 儲存為新 CSV（不含索引）
df_selected.to_csv("aed_ntpc.csv", index=False)
