# AI Studio 更新未生效根因修復 / Fix Root Cause of AI Studio Updates Not Taking Effect

## 2026-04-24 18:48

- objective:
  - 釐清使用者回報「看起來跟之前差不多、像沒更新」的真實原因，並修復阻塞新版本生效的編譯錯誤。

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - 實測 `/api/v1/ai/chat/twai` 後確認回應缺少 `display_plan` 與 `tool_timeline`，且行為仍接近舊流程。
  - 檢查 `dashboard-be` 容器日誌後，定位到 Air 熱重載編譯失敗，導致服務長期停留在舊 binary。
  - 修正 `registry.go` 的重複變數宣告相關阻塞段落，排除主要 build fail。
  - 修正 `ai_service.go` 的字串轉義編譯錯誤（unknown escape），讓後端可再次成功編譯啟動。

- change-type:
  - Fixed

- technical-details:
  - `registry.go`:
    - 移除 `RetrieveComponentsByQuery` 內重複的 Vue 檢索區塊，避免短變數宣告衝突造成建置阻塞。
  - `ai_service.go`:
    - 在 `extractDisplayPlanJSON` 移除未使用且含非法轉義的 regex 變數，避免 Go 編譯器報 `unknown escape`。

- verification:
  - 程式診斷：
    - `get_errors` on `Taipei-City-Dashboard-BE/app/services/ai/tools/registry.go` -> No errors found
    - `get_errors` on `Taipei-City-Dashboard-BE/app/services/ai/ai_service.go` -> No errors found
  - 容器觀測：
    - `docker logs dashboard-be` 先前可重現錯誤：
      - `registry.go:152:18: no new variables on left side of :=`
      - `ai_service.go:425:58: unknown escape`
    - 修復後重啟觀測到：
      - `[10:46:50] building...`
      - `[10:47:01] running...`
      - 服務與路由重新啟動成功。

- performance-impact:
  - 無新增執行負擔；主要是解除編譯阻塞，讓既有優化邏輯得以上線。

- impact-risk:
  - 低風險：本次為編譯修復，不改 API 契約欄位定義。
  - 若後續再新增 AI 指令字串，需注意 Go 字串轉義與 raw string 使用一致性。

- regression-test:
  - 重新啟動 `dashboard-be` 後檢查是否可穩定進入 `running`。
  - 以 AI Studio 查詢驗證後端回應包含新路徑欄位（display plan 相關資訊）與行為改善。

- traceability:
  - Related user report: 「深度分析 因為我感覺跟之前差不多 是沒更新嗎? 還是?」
  - Related runtime evidence: `docker logs dashboard-be` build fail entries

- next-actions:
  - P1: 追加一個啟動後 smoke test（檢查 `/api/v1/ai/chat/twai` 回應 schema）避免再次「編譯失敗但前端誤以為已更新」。
