# 戰情室輪播智慧升級 / War Room Carousel Intelligence Upgrade

## 2026-04-24 16:53

- objective:
  - 使用者反映 AI Studio 輪播「不夠聰明」：地圖組件沒顯示圖表、多圖表組件只佔一格、投影片固定5個、有無謂首尾頁，不適合戰情室播映。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue
  - Taipei-City-Dashboard-FE/src/components/ai-studio/AIStudioPresentationCanvas.vue
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **DashboardComponent**: 新增 `initialChartType` prop，讓外部可指定初始顯示的圖表類型，而非固定用 `types[0]`。
  - **Canvas - buildAutoComponentSlides**: 從「每組件一張投影片」改為「每圖表類型一張投影片」。有 N 種 chart_config.types 的組件會展開成 N 張，並帶 `chartType` 欄位傳入 DashboardComponent。
  - **Canvas - slides computed**: 移除有組件時強制加 `default-hero` 首頁包裝；有組件直接輪播組件投影片（戰情室模式）。
  - **Canvas - template**: 地圖投影片（`slide.type === 'map'`）改為與組件投影片相同邏輯，渲染 `DashboardComponent` 並傳入 `initialChartType`，不再顯示無用佔位字樣。
  - **aiChatService - buildPresentationSlides**: 移除 `slice(0, 4)` 上限（組件全數納入）；移除固定 heroSlide / closingSlide；同樣做多圖表類型展開，帶 `chartType`。

- change-type:
  - Changed

- technical-details:
  - `initialChartType` 使用 `props.config.chart_config.types.includes(...)` 驗證後才生效，防止無效值。
  - `buildAutoComponentSlides` 與 `buildPresentationSlides` 均檢查 `Array.isArray(types) && types.length > 1` 才展開，單圖表組件行為不變。
  - 移除 `slide-main--map` CSS class 條件，地圖投影片使用 `slide-main--component`，維持視覺一致性。
  - map/component 的 `v-if` 條件統一為 `slide.type === 'component' || slide.type === 'map'`，簡化分支。

- verification:
  - `get_errors` 針對三個修改檔案回傳 `No errors found`。

- impact-risk:
  - 若組件有5種圖表類型，輪播投影片數量增加5倍，自動播放時間加長。可在 `durationSec` 中加入每種類型的估算權重優化。
  - `isUnknownSlideType` 判斷不受影響（'map' 已從 known types 中保留）。
  - hero/closing slides 被移除後，若 TWAI 後端回傳的 `displayPlan.slides` 包含 hero，仍可正常顯示（strictRender path 不受影響）。

- regression-test:
  - 測試有地圖組件（map_config 非空）時投影片正確顯示圖表而非佔位。
  - 測試有多圖表類型組件（types.length > 1）時展開為正確數量的投影片。
  - 測試無組件時仍顯示 default-hero。
  - 測試 explicitSlides + strictRender=true 時行為不變。

- traceability:
  - N/A

- next-actions:
  - 可考慮加入「地圖同步預覽」：地圖組件投影片切換時仍觸發 syncMapLayersForSlide，使側邊地圖同步更新。
  - 考慮為 dots-navigation 超過 20 個時改為進度條模式，避免視覺過密。
