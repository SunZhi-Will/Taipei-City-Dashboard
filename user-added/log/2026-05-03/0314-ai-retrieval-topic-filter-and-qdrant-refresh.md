# AI 推薦主題過濾與向量重建路由 / AI Retrieval Topic Filter and Qdrant Refresh Route

## 2026-05-03 03:14

- objective:
  - 修正 AI 查詢「食品業者衛生稽查地圖」時誤帶出空氣品質與勞工類建議
  - 提供可直接觸發的 Qdrant 重建路由，完成向量資料更新

- files:
  - Taipei-City-Dashboard-BE/app/models/componentConfig.go
  - Taipei-City-Dashboard-BE/app/routes/router.go

- summary:
  - 在向量檢索結果後處理加入主題過濾：當查詢屬於食安主題時，只保留食安相關 token 命中的組件
  - 新增文字匹配加權（lexical boost），使「食品業者衛生稽查地圖」可優先排序
  - 新增 `/api/v1/qdrant/rebuild` 路由接上既有 controller，支援即時重建公開組件向量庫

- change-type:
  - Changed
  - Fixed

- technical-details:
  - `GetComponentByQueryVectorRich`：
    - 新增 `detectQueryDomain` / `foodSafetyTokens` / `containsAnyToken`
    - 針對 `food_safety` 查詢，使用 `index + name + long_desc + use_case + short_desc` 做關聯過濾
    - 新增 `lexicalRelevanceBoost` 與 `queryTokens`，對名稱/索引/描述的關鍵字命中給予分數增益
    - 最終結果以調整後分數排序並依 `limit` 截斷
  - 路由：
    - `configureQdrantRoutes()` 新增 `POST /api/v1/qdrant/rebuild`
    - 於 `ConfigureRoutes()` 掛載該路由群組

- verification:
  - 重啟 BE：`docker restart dashboard-be`
  - 向量重建：`POST /api/v1/qdrant/rebuild` 成功回應 `status=success`，`data_count=14`
  - 查詢驗證：`POST /api/v1/vector/component`，query=`食品業者衛生稽查地圖`
    - 結果第一名為 `taipei_imap_food`
    - 不再出現空氣品質、勞工類組件

- performance-impact:
  - 檢索後處理增加少量字串比對與排序成本
  - 相對向量查詢與 DB 查詢成本可忽略

- impact-risk:
  - 關鍵字規則為啟發式，可能在少數邊界查詢造成召回降低
  - 已保留一般查詢路徑，僅在判定為食安主題時啟用嚴格過濾

- regression-test:
  - 查詢「食品業者衛生稽查地圖」應優先回 `taipei_imap_food`
  - 查詢非食安主題（如空氣品質）應仍可返回相關組件
  - 重建路由可重複呼叫，並能在重建期間回傳衝突提示（如已在重建）

- traceability:
  - related log: user-added/log/2026-05-03/0258-taipei-only-wholesale-component.md

- next-actions:
  - 建議後續把主題規則外部化為設定檔，便於運維調整關鍵字而不需改程式