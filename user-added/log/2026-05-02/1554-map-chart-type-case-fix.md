# 修正地圖圖表類型大小寫不一致 / Fix MapChartType Case Mismatch

## 2026-05-02 15:54

- objective:
  - 端對端 API 測試發現：DB 存 `"MapLegend"`（CamelCase），AI 生成 `"map_legend"`（snake_case），BE/FE 的 map type 集合只含 snake_case，導致識別邏輯走錯路徑（靠 fallback 僥倖正確）
  - BE `fixSlidesChartTypes` 無法將 AI 的 `"map_legend"` 修正為 DB 精確字串 `"MapLegend"`，造成 `DashboardComponent` 可能降級渲染

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go
  - Taipei-City-Dashboard-BE/app/services/ai/ai_normalize_test.go
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue

- summary:
  - BE `mapChartTypes` set 新增 CamelCase 變體（`"MapLegend"`, `"MapPin"`, `"MapHeat"`, `"MapLayer"`, `"MapDistrict"`），使 DB 回傳的 CamelCase 和 AI 的 snake_case 都能命中
  - BE `fixSlidesChartTypes` 新增 normalize 分支：當 AI 給 `"map_legend"` 且 DB 有 `"MapLegend"` 時，自動修正為 DB 精確字串，確保 `DashboardComponent.types.includes()` 精確匹配
  - FE 新增 `toSnakeCase()` helper 和 `isMapChartType(t)` helper（CamelCase→snake_case normalization），取代直接用 `MAP_CHART_TYPES.has(t)` 的不可靠比對
  - FE `resolveChartTypeForSlide` 改用 `isMapChartType` 並統一回傳 DB 精確字串（`mapType` 而非 `slide.chartType`）

- change-type:
  - Fixed

- technical-details:
  - 根本原因：`DashboardComponent` 用 `config.chart_config.types.includes(initialChartType)` 做精確比對；若 `initialChartType` 為 `"map_legend"` 但 types 陣列是 `["MapLegend"]` → mismatch → fallback `types[0]`，結果雖相同但邏輯不正確
  - BE 修正路徑：`mapChartTypes["MapLegend"] = true` → `fixSlidesChartTypes` 識別 DB 的 `"MapLegend"` 為 map type → `slide.ChartType` 正確設為 `"MapLegend"`
  - FE 修正路徑：`isMapChartType("MapLegend")` → `toSnakeCase("MapLegend") = "map_legend"` → `MAP_CHART_TYPES.has("map_legend") = true` → mapType 正確找到 → `resolveChartTypeForSlide` 回傳 `"MapLegend"`（DB 精確字串）
  - 額外新增 2 個 unit test cases 涵蓋此 case normalization 路徑

- verification:
  - `docker exec -w /opt/Taipei-City-Dashboard-BE dashboard-be go build ./...` → ✅ BUILD OK
  - `docker exec -w /opt/Taipei-City-Dashboard-BE dashboard-be go test ./app/services/ai/... -v` → 17 cases ALL PASS
  - 新增 test case `"map_slide,_AI_uses_snake_case_map_legend_but_DB_has_MapLegend"` → PASS
  - 新增 test case `"map_slide,_no_map_type_in_DB_list_→_fallback_map_legend"` → PASS
  - 端對端 API 測試（curl 含 tools）確認 `tool_used: true`、`display_plan` 正常生成

- performance-impact:
  - N/A（純邏輯修正，無 loop 複雜度影響）

- impact-risk:
  - 影響範圍：AI Studio map 投影片渲染路徑（`fixSlidesChartTypes` + `resolveChartTypeForSlide`）
  - 風險：低，只補強既有邏輯，且有 fallback 保護
  - 邊界情況：若 DB 同一組件同時有 `"map_legend"` 和 `"MapLegend"`（不可能但）→ 取第一個匹配

- regression-test:
  - 驗證空氣品質監測站（id=1, 219）在 AI Studio 生成地圖投影片後，`initialChartType` 傳入 DashboardComponent 為 `"MapLegend"`（CamelCase）
  - 驗證 has_map=false 的組件（id=216）不會生成 map 投影片
  - 驗證 AI Studio 全流程（問「空氣品質簡報含地圖」）→ 生成含 hero/text/map 投影片

- traceability:
  - 相關 log：user-added/log/2026-05-02/1313-map-location-search.md（本 session 前序）
  - 根據端對端 API 測試結果修正（curl POST /api/v1/ai/chat/twai 含 tools）

- next-actions:
  - 確認 AIStudioView 的 map 投影片架構是否符合使用者預期（Presentation mode 顯示 MapLegend 圖例，不是嵌入 Mapbox 地圖）
  - 若使用者期望 Presentation mode 也要顯示地圖，需要在投影片 template 加入 MapContainer 嵌入
