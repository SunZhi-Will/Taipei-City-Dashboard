# AI 對話 fallback 根因修補與可觀測性強化 / AI Chat Fallback Root-Cause Fix and Observability Hardening

## 2026-04-24 16:18

- objective:
  - 針對「最近 AQI 變化」出現「AI 對話服務暫時忙碌」與「沒有相似組件」雙 fallback 的現象，完成根因取證與最小修補。

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js
  - Taipei-City-Dashboard-FE/src/store/chatStore.js
  - Taipei-City-Dashboard-FE/vite.config.js

- summary:
  - 以同一查詢實測 `/api/v1/ai/chat/twai` 與 `/api/v1/vector/component`，確認 TWAI 可成功，但向量檢索在高門檻下可回空。
  - 修正非 Docker 本地 Vite 代理，新增 `/api/dev` 專屬 rewrite，避免錯誤路徑落到 `/api/v1/dev/*`。
  - 強化向量 fallback：加入分數門檻階梯回退（0.8 -> 0.78 -> 0.72），降低「誤判無相似組件」機率。
  - 將 TWAI 失敗原因碼（如 `HTTP_500`/`NETWORK_OR_TIMEOUT`）顯示於聊天室 fallback 句，提升現場排障效率。

- change-type:
  - Fixed

- technical-details:
  - `queryByVector` 從單次 `score=0.8` 改為多次嘗試，逐步放寬門檻，回傳第一批有效結果。
  - `chatStore.addQueryData` 於 `twaiResult.ok=false` 時，訊息包含 `twaiResult.reason`，可直接從 UI 觀察失敗類型。
  - `vite.config.js` 非 Docker 分支新增 `/api/dev` 代理規則，rewrite `^/api/dev` 到 `/api/v1`，避免 API 路由偏移。

- verification:
  - 指令驗證：
    - `Invoke-RestMethod -Uri http://localhost:8088/api/v1/ai/chat/twai ...`，回傳 `status=success` 且含 `content`。
    - `Invoke-RestMethod -Uri http://localhost:8088/api/v1/vector/component -Body "query=最近 AQI 變化&limit=10&score=0.8" ...`，觀察到 `data=null`（可重現 fallback 空集合風險）。
  - 靜態檢查：
    - `get_errors` 檢查三個修改檔案，皆 `No errors found`。

- performance-impact:
  - 向量 fallback 最多增加 2 次請求（僅在前一次無結果時觸發），對整體延遲有小幅增加，但可顯著提升命中率與回答完整度。

- impact-risk:
  - 若後端向量服務本身不可用，仍可能回空；但 UI 可見 reason，有助快速定位是 TWAI 或向量層異常。
  - 代理規則新增後，需確認其他 `/api/*` 路由不受影響（已採 precedence：`/api/dev` 在 `/api` 之前）。

- regression-test:
  - 在非 Docker Vite 模式，測試 `最近 AQI 變化`、`AED 地圖`、`長照指標`，確認 API 不再落錯路徑。
  - 在 Docker Compose 模式重測同句，確認既有 `/api/dev -> /api/v1` 行為不回歸。
  - 驗證聊天室在 TWAI 失敗時會顯示 reason，且可續走向量推薦。

- traceability:
  - Related log: user-added/log/2026-04-24/1609-ai-data-grounded-tooling.md

- next-actions:
  - 針對 AQI 類語句新增同義詞正規化（AQI/空氣品質/空污）後再評估是否需要調整向量門檻預設值。
