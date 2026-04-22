# 變更紀錄：AI 穩定性修正（第一批） / Change Log: AI Stability Fix Batch 1

## 2026-04-17 10:15

- objective / 目標:
  - 修正 AI/Qdrant 路徑中可能造成服務中止（process exit）與資料集不一致（collection mismatch）的高風險問題。
  - 將 AI 模組由「啟動強依賴」調整為「可降級依賴」，優先保障核心 API 可用性。

- files / 修改檔案:
  - Taipei-City-Dashboard-BE/app/models/qdrant.go
  - Taipei-City-Dashboard-BE/app/app.go
  - Taipei-City-Dashboard-BE/app/services/qdrant.go

- summary / 變更摘要:
  - 將 qdrant 向量生成與推理流程中多處致命中止邏輯由 log.Fatalf 改為錯誤回傳，避免單筆查詢異常拖垮整個服務。
  - 調整 app 啟動流程：LM session 與 tokenizer 初始化失敗時改為 warning + 降級啟動，而非直接啟動失敗。
  - 補強 shutdown 安全性：在 session destroy 前加入 nil guard，避免未初始化時 panic。
  - 統一 Qdrant collection 解析順序，避免重建與查詢落到不同 collection。
  - 解析順序調整為：QDRANT_COLLECTION_NAME -> QDRANT_COLLECTION -> query_charts。

- technical-details / 技術細節:
  - qdrant 初始化函式回傳型別由單純物件改為物件加錯誤，讓呼叫端可控制降級策略。
  - GenVector 內部改為全路徑 error propagation，讓 controller/service 可決定錯誤回應與重試策略。
  - app 啟動期改為「記錄問題 + 繼續服務」，將 AI 模組故障隔離在功能層，不擴散到整體 API 可用性。

- change-type / 變更類型:
  - Fixed

- verification / 驗證結果:
  - 已檢查修改檔案診斷（type/lint）無新增錯誤。
  - 已人工確認 fallback 鏈與啟動降級路徑存在於對應程式檔。
  - 已確認本次變更不影響既有非 AI API 路由註冊與啟動流程。

- impact-risk / 影響與風險:
  - 影響範圍：AI 向量查詢、Qdrant 重建流程、BE 啟動容錯行為。
  - 正向影響：降低 AI 模組異常造成全站中斷的機率。
  - 已知風險：AI 模組降級啟動時，相關功能會回錯但主服務仍存活；需配合監控與告警辨識降級狀態。

- traceability / 追溯資訊:
  - related-log: user-added/log/2026-04-17/1015-ai-stability-fix-batch1.md
  - ticket: N/A
  - pr: N/A
  - commit: N/A

- next-actions / 後續行動:
  - P0: 補齊 AI 模組降級狀態的監控指標與告警規則。
  - P1: 增加 collection fallback 與初始化失敗情境的自動化測試。
