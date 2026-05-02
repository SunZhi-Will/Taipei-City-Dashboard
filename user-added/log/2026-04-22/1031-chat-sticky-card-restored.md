# 置頂公告卡片樣式恢復 / Restore Sticky Notice Card Style

## 2026-04-22 10:31

- objective:
  - 依需求將「置頂公告：小幫手使用須知」恢復為卡片樣式，避免與聊天訊息混在一起。

- files:
  - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue

- summary:
  - 將置頂公告區塊由扁平樣式改回卡片視覺：白底、邊框、圓角、輕陰影。
  - 恢復 header 與 body 的卡片內邊距，並保留可讀文字色。
  - 移除先前對公告區所有子元素的 `!important` 強制顏色，改為元件內明確字色控制。

- change-type:
  - Changed

- technical-details:
  - `.sticky-message`
    - `border: 1px solid #e4e4e7`
    - `border-radius: 10px`
    - `background: #ffffff`
    - `position: sticky; top: 0; z-index: 10`
    - `box-shadow: 0 1px 2px rgba(0,0,0,0.04)`
  - `.sticky-header`
    - padding 改為 `8px 12px`
    - 背景 `#fafafa`
    - 底線改為實線 `#ececef`
  - `.sticky-body`
    - padding 改為 `10px 12px`
    - 背景 `#ffffff`

- verification:
  - Problems 檢查：
    - Taipei-City-Dashboard-FE/src/components/dialogs/ChatBox.vue -> No errors found

- performance-impact:
  - 無效能影響，純視覺樣式調整。

- impact-risk:
  - 低風險；僅影響置頂公告區塊外觀。

- regression-test:
  - 展開/收合置頂公告後，卡片邊框與字色可讀性正常。
  - 與聊天訊息區的視覺層次明確分離。

- traceability:
  - related-log:
    - user-added/log/2026-04-22/1017-chat-sticky-flat-and-color-fix.md

- next-actions:
  - N/A
