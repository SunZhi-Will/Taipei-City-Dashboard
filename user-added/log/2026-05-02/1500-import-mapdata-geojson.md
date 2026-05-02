# 匯入下載資料夾 MapData GeoJSON 檔案 / Import MapData GeoJSON Files from Downloads

## 2026-05-02 15:00

- objective:
  - 將 `/Users/sun/Downloads/mapData/` 中的所有 GeoJSON 地圖資料檔案匯入專案的 `public/mapData/`

- files:
  - Taipei-City-Dashboard-FE/public/mapData/air_station_map_taipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/labor_services_metrotaipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/labor_services_taipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/museums_metrotaipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/museums_taipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/shelters_metrotaipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/shelters_taipei.geojson (新增)
  - Taipei-City-Dashboard-FE/public/mapData/ (其餘 46 個已存在檔案皆更新同步)

- summary:
  - 使用 `rsync -av` 將下載資料夾的 53 個 GeoJSON 檔案同步至 `Taipei-City-Dashboard-FE/public/mapData/`
  - 新增 7 個原本缺少的檔案；更新其餘已存在的 46 個檔案確保為最新版本
  - 保留專案原有的 `test_air.geojson`（未在下載資料夾中，故不刪除）

- change-type:
  - Added

- technical-details:
  - 目標目錄：`Taipei-City-Dashboard-FE/public/mapData/`（Vite 靜態資源目錄，對應前端路由 `/mapData/*.geojson`）
  - mapStore.js 透過 `fetchLocalGeoJson()` 以 axios GET `/mapData/${map_config.index}.geojson` 載入，新增檔案可直接被對應的 `map_config.index` 使用
  - 傳輸總大小：約 225 MB，全部 54 筆 transfer 成功，speedup 1.00
  - 新增檔案說明：
    - `air_station_map_taipei.geojson`：台北市空氣品質測站點位
    - `labor_services_metrotaipei.geojson`：雙北勞工服務據點
    - `labor_services_taipei.geojson`：台北市勞工服務據點
    - `museums_metrotaipei.geojson`：雙北博物館點位
    - `museums_taipei.geojson`：台北市博物館點位
    - `shelters_metrotaipei.geojson`：雙北防空避難所
    - `shelters_taipei.geojson`：台北市防空避難所

- verification:
  - 執行 `rsync` 輸出確認：54 files transferred, sent 225183717 bytes, 0 errors
  - 執行 `ls /Applications/Projects/Taipei-City-Dashboard/Taipei-City-Dashboard-FE/public/mapData/ | wc -l` 應為 47（含原有 test_air.geojson）

- impact-risk:
  - 影響範圍：僅靜態資源檔案，無後端邏輯變動
  - 風險：極低；新增檔案不影響現有功能，更新檔案內容若與原版不同可能改變地圖顯示內容
  - 已存在但內容不同的檔案（如 `air_station_map_metrotaipei.geojson`）會以下載版本覆蓋

- regression-test:
  - 啟動前端開發伺服器後，確認地圖頁面正常渲染
  - 在地圖上選取使用 `air_station_map_taipei`、`museums_taipei`、`shelters_taipei` 等圖層的元件，確認 GeoJSON 能正常載入
  - 瀏覽器 Network 面板確認 `/mapData/*.geojson` 回應 200

- traceability:
  - N/A

- next-actions:
  - 若需使用新增的 7 個 GeoJSON 檔案，需在 DB 中新增對應的 `component_maps` 設定與 `map_config.index` 對應值
  - 優先級：低（檔案已就位，待需求確認後再設定）
