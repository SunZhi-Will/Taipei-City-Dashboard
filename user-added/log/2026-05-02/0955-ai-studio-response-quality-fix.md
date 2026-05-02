# AI Studio 回覆品質修正 / AI Studio Response Quality Fix

## 2026-05-02 09:55

- objective:
  - 用戶展示兩筆實際 AI Studio 對話輸出，指出以下問題：
    1. 回覆缺少開頭問候語與結尾鼓勵句（「需要有開頭跟結尾」）
    2. 「若您要延伸比較」結尾句重複出現兩次
    3. 「延伸比較」建議顯示與查詢無關的組件（空氣品質 → 電動巴士比例、自行車道路）
    4. `selectFocusedComponents` 中 `dominant` 旗標雖然計算，但兩個 if/else 分支都 return 同一個變數，實際上為死碼

- files:
  - Taipei-City-Dashboard-FE/src/services/aiChatService.js

- summary:
  - **[Fix 1] `selectFocusedComponents` 死碼 + dominant 未生效**
    - 原邏輯：`if (directIntent && dominant) { return normalized; } return normalized;` — 兩個分支完全相同，`dominant` 從未影響結果
    - 修正：讓 `dominant` 真正生效 → `limit = dominant ? 2 : (directIntent ? 3 : 4)`
    - 當主要組件遠超其餘（score gap ≥ 25），only 2 items 被選入；避免長尾的低相關組件填入 related
    - 同步清除冗餘 `selected`/`normalized` 中間變數，直接 return

  - **[Fix 2] `buildComponentNarrative` 過濾無關 related 組件**
    - `summarizeRelatedComponents` 原本對所有 related 組件生成「延伸比較」建議
    - 新增 `keywordRelated = related.filter(item => item.__matchScore >= 20)`：只有與查詢有關鍵字交集（分數 ≥ 20）的組件才被納入延伸建議
    - `__matchScore < 20` 代表僅有向量相似度貢獻（score × 10 ≈ 7-8），無關鍵字命中，視為語意無關
    - 效果：「空氣品質」查詢的「電動巴士比例」（__matchScore ≈ 7.8）被過濾出局

  - **[Fix 3] `buildComponentNarrative` 重複結尾句**
    - 原邏輯：`return [normalizedAiContent, relatedHint]` — 若 AI 已自行輸出「若您要延伸比較...」，再次 append relatedHint 造成重複
    - 修正：`alreadyHasHint = /若您要延伸比較|延伸比較/.test(normalizedAiContent)` → `hint = alreadyHasHint ? '' : relatedHint`

  - **[Fix 4] `buildComponentNarrative` 補開頭 & 結尾**
    - 開頭：`hasNaturalOpening` 檢測 AI 回覆是否以「您好/根據/以下/我已/很高興/這裡/依據/幫您」開頭；若否，前置 `根據您的查詢，以下是相關資訊：\n\n`
    - 結尾：`hasClosing` 檢測是否已有鼓勵語（歡迎繼續/若有...問題/希望...幫助/有任何疑問/隨時...詢問）；若否，append `若有其他問題，歡迎繼續詢問！`
    - genericAiReply fallback 路徑也同步加入 `CLOSING` 結尾

  - **[Fix 5] 系統提示詞（buildTwaiMessages）**
    - 新增明確指令：「每次回覆必須以親切的開場白開始（例如「您好！」），並以一句鼓勵繼續詢問的結語作結；回覆中不要自行加入「若您要延伸比較」的建議，系統已自動附加」
    - 從 AI model 行為層面根治開頭/結尾缺失問題，與前端兜底機制形成雙保險

- change-type:
  - Fixed

- technical-details:
  - `__matchScore` 評分組成：向量 score × 10（基礎）+ 名稱完全包含查詢（+120）+ index 完全包含（+90）+ 分詞命中名稱（+25/項）+ 分詞命中 index（+15/項）
  - 「無相關性」門檻 `__matchScore < 20`：對應到向量 score 0.78 → 7.8，無任何關鍵字加分，安全地排除語意無關組件
  - `dominant` 門檻 `score gap ≥ 25`：對應到如 一個有名稱命中（+120）vs 其他只有向量基礎分（≈8）→ gap ≈ 112，遠超 25，安全觸發
  - system prompt 長度從 ~220 字增至 ~310 字，控制在 token 預算範圍內

- verification:
  - `get_errors` 對修改的 aiChatService.js 回報「No errors found」
  - 確認 `selectFocusedComponents` 不再有死碼：舊的 if/else 雙 return 已被單一 return 取代
  - 確認 `buildComponentNarrative` 有 `alreadyHasHint` 檢查防重複
  - 確認系統提示詞字串末尾正確結尾無截斷

- performance-impact:
  - `keywordRelated.filter()` 額外一次陣列過濾（O(n), n≤4），可忽略
  - 系統提示詞增加 ~90 字 token，每次 TWAI 呼叫 input_tokens 略增（< 50 tokens）

- impact-risk:
  - `dominant` 讓 limit 從最多 4 降至最多 2：若查詢有多個同等相關組件（score gap < 25），不受影響（limit 仍為 3-4）
  - `__matchScore < 20` 過濾：若某組件因為 index 縮寫命中而有分，仍可保留；只排除零關鍵字命中的純向量結果
  - `hasNaturalOpening` regex：若未來 AI 回覆新的慣用開頭語未列入，會被前置 prefix → 視覺上多一行但不影響功能

- regression-test:
  - 測試：輸入「空氣品質」→ 確認回覆有開頭問候句 + 結尾鼓勵句 + 不重複「若您要延伸比較」
  - 測試：輸入「空氣品質與交通壅塞」→ 確認兩個組件都出現在 related（都有關鍵字命中）
  - 測試：輸入具體組件名稱（directIntent）→ 確認 limit 正確（dominant=true→2，dominant=false→3）
  - 測試：genericAiReply fallback（斷網情境）→ 確認 intro+summary+hint+closing 完整輸出

- traceability:
  - 用戶回饋：AI Studio 實際對話截圖（2026-05-02 session）
  - 關聯 log：user-added/log/2026-05-02/0940-ai-studio-comprehensive-optimization.md

- next-actions:
  - 建議監測 `__matchScore < 20` 的過濾率（可在 console.debug 加 log），確認過濾幅度合理
  - 若 AI model 仍偶爾遺漏開頭，可進一步收緊 `hasNaturalOpening` regex 或考慮 hardcode prefix
