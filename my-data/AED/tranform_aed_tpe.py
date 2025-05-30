import pandas as pd

# 台北市行政區對照表
# 引用共通性資料標準之「地址_行政區域代碼」。
# 可參考內政部戶政司全球資訊網 (https://www.ris.gov.tw/) 公告之代碼(RSCD0103)
district_code_map = {
    63000010: "松山區",
    63000020: "信義區",
    63000030: "大安區",
    63000040: "中山區",
    63000050: "中正區",
    63000060: "大同區",
    63000070: "萬華區",
    63000080: "文山區",
    63000090: "南港區",
    63000100: "內湖區",
    63000110: "士林區",
    63000120: "北投區"
}

# 讀取原始檔案
df = pd.read_csv("aed_tpe_raw.csv")

# 欄位重新命名
df = df.rename(columns={
    "場所名稱": "name",
    "場所地址": "address",
    "區域代碼": "district_code",
    "緯度": "latitude",
    "經度": "longitude",
    "場所分類": "category",
    "場所類型": "type",
    "AED放置地點": "location_desc"
})

# 將區域代碼轉為行政區名稱
df["district"] = df["district_code"].map(district_code_map)

# 儲存為新檔案
df.to_csv("aed_tpe.csv", index=False)

print("✅ 已完成欄位重新命名與行政區欄位新增，儲存為 aed_tpe.csv")
