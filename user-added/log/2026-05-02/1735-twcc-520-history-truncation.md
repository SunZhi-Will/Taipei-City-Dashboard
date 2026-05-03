# 修正 TWCC 520 錯誤：對話歷史截斷 / Fix TWCC 520 Error: Conversation History Truncation

## 2026-05-02 17:35

- objective:
  - 修正 AI Studio 對話過長時，TWCC API 回傳 HTTP 520 導致前端收到 500 的問題

- files:
  - Taipei-City-Dashboard-BE/app/services/ai/ai_service.go

- summary:
  - **根本原因**：`prepareMessages` 直接將 `s.req.Messages` 全部送給 TWCC，未做截斷。當 session 對話累積到 30 則時，TWCC 回應 `{"detail":"None"}` / `{"detail":"0"}` 的 HTTP 520 error，表示 context 超過模型限制。
  - **修正**：在 `prepareMessages` 中分離 system 訊息與對話歷史；對話歷史超過 `maxHistoryMessages=12` 則時，只保留最後 12 則（約 6 個 user/assistant 回合）。System 訊息始終完整保留並與 instruction 合併。

- change-type:
  - Fixed

- technical-details:
  - **TWCC 520 觸發條件**：`messages=30` 時 100% 觸發；`messages=8-10` 偶發（可能是單則 tool result 內容過長）
  - **截斷策略**：
    ```go
    const maxHistoryMessages = 12
    if len(historyMsgs) > maxHistoryMessages {
        historyMsgs = historyMsgs[len(historyMsgs)-maxHistoryMessages:]
    }
    ```
  - 保留最後 12 則 = 最近 6 個完整對話回合（user + assistant），足夠 AI 理解上下文
  - System 訊息（含 instruction 合併後）不計入截斷範圍，確保行為指引始終存在
  - `maxHistoryMessages = 12` 為常數，可未來改為環境變數（如需要）

- verification:
  - `docker exec dashboard-be sh -c "go build -o /tmp/test-build ."` → 無輸出（build 成功）
  - `docker logs dashboard-be` → BE 已用新 binary 重啟，路由正常
  - 日誌模式：`messages=30` → 520 的情況應消失，TWCC request 穩定在 ≤14 messages（12 history + 1 system + 工具呼叫中間增量）

- performance-impact:
  - 截斷後每次 TWCC request tokens 減少，預期延遲降低，cost 降低
  - 代價：超長 session 的早期對話內容不再傳給模型（最後 6 回合可覆蓋絕大多數使用場景）

- impact-risk:
  - **低風險**：僅影響 messages 超過 12 則的長 session
  - 短 session（messages ≤ 12）完全不受影響
  - 極端情況：使用者在第 7 回合以後詢問第 1 回合提到的細節，AI 可能遺忘；實際應用此情況罕見
  - 未引入新依賴或介面變更

- regression-test:
  - [ ] 新 session 首次問答（messages=2）應正常
  - [ ] 超過 12 則的長 session 應不再出現 500 錯誤
  - [ ] AI Studio display_plan 生成仍正確（truncation 不影響 system prompt）
  - [ ] 工具呼叫（get_component_list、get_chart_data 等）仍正常

- traceability:
  - 錯誤來源：browser console `POST http://localhost:8080/api/dev/ai/chat/twai 500`
  - BE log 診斷：`messages=30 → TWCC 520 {"detail":"None"}`

- next-actions:
  - 若 `messages=8` 仍偶發 520，考慮對 tool result 內容也做長度截斷（單則訊息 token 估算）
  - 可將 `maxHistoryMessages` 改為環境變數 `TWCC_MAX_HISTORY_MESSAGES`（彈性調整）
