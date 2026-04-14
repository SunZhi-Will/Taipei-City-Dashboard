import pandas as pd
from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter
import time
import os

# ---------- 設定 ----------
INPUT_CSV = "aed_ntpc.csv"
GEOCACHE_CSV = "geocache.csv"
OUTPUT_CSV = "aed_ntpc_with_coord.csv"
DELAY_SECONDS = 1
# --------------------------

# 1. 初始化 geolocator
geolocator = Nominatim(user_agent="taiwan_geocoder")
geocode = RateLimiter(geolocator.geocode, min_delay_seconds=DELAY_SECONDS)

# 2. 讀取主資料集
df = pd.read_csv(INPUT_CSV)

# 3. 清理地址欄位
all_addresses = df["hosp_addr"].dropna().drop_duplicates()

# 4. 嘗試載入舊快取
if os.path.exists(GEOCACHE_CSV):
    geocache = pd.read_csv(GEOCACHE_CSV)
    geocache_dict = dict(zip(geocache["hosp_addr"], zip(geocache["latitude"], geocache["longitude"])))
    print(f"✅ 已載入快取 {len(geocache_dict)} 筆地址")
else:
    geocache_dict = {}

# 5. 執行查詢（略過已有者）
new_records = []
for addr in all_addresses:
    if addr in geocache_dict:
        continue
    try:
        location = geocode("台灣" + addr)
        if location:
            lat, lng = location.latitude, location.longitude
        else:
            lat, lng = None, None
        geocache_dict[addr] = (lat, lng)
        new_records.append({"hosp_addr": addr, "latitude": lat, "longitude": lng})
        print(f"📍 {addr} → ({lat}, {lng})")
    except Exception as e:
        print(f"❌ 查詢失敗：{addr}，錯誤：{e}")
        geocache_dict[addr] = (None, None)
        new_records.append({"hosp_addr": addr, "latitude": None, "longitude": None})

    # 每查一筆就儲存快取
    pd.DataFrame(new_records).to_csv(GEOCACHE_CSV, index=False, mode='a', header=not os.path.exists(GEOCACHE_CSV))
    new_records.clear()

# 6. 快取查詢結果合併回主資料表
df["latitude"] = df["hosp_addr"].map(lambda x: geocache_dict.get(x, (None, None))[0])
df["longitude"] = df["hosp_addr"].map(lambda x: geocache_dict.get(x, (None, None))[1])

# 7. 輸出結果
df.to_csv(OUTPUT_CSV, index=False)
print(f"✅ 全部完成！結果儲存於 {OUTPUT_CSV}")
