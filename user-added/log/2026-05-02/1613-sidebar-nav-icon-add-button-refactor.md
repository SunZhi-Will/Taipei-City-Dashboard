# 側欄導覽列 icon 與新增按鈕重構 / Sidebar Nav Icon & Add Button Refactor

## 2026-05-02 16:13

- objective:
  - 收起時（sidebar collapsed）私人儀表板內的子項目（我的最愛、個人儀表板）無 icon，需補上
  - 展開時（sidebar expanded）個人儀表板 h2 右側有新增按鈕，應移至第三層項目列表內部

- files:
  - Taipei-City-Dashboard-FE/src/components/utilities/bars/SideBar.vue

- summary:
  - 在「我的最愛」h2 加入 `star_border` icon
  - 在「個人儀表板」h2 加入 `person` icon
  - 將原本的 `sidebar-sub-add` wrapper（h2 + button 並排）改為純 h2（含 icon）
  - 將新增按鈕移入 personal 區段的第三層，僅在 isExpanded 時顯示（v-if="isExpanded"）
  - 修正 `sidebar-sub-no` 的條件，補上 `!collapsedStates.personal`，避免折疊時也顯示空狀態訊息
  - 移除舊的 `&-sub-add` CSS，新增 `&-add-item` button 樣式（對齊第三層 SideBarTab 外觀）
  - 在 h2 block 加入 `.sidebar-icon` 字型/尺寸/邊距設定（對齊 h1 的 sidebar-icon）
  - 在 `&-collapse h2` 加入 `.sidebar-icon { margin-left: calc((3.5rem - 16px) / 2) }` 使 icon 在收起時置中；並將 padding 從 `0 12px` 改為 `0`

- change-type:
  - Changed

- technical-details:
  - `我的最愛` h2：加 `<span class="sidebar-icon material-icons-round">star_border</span>`
  - `個人儀表板` h2：加 `<span class="sidebar-icon material-icons-round">person</span>`
  - 原 `<div class="sidebar-sub-add">` wrapper 移除，改為直接的 `<h2>`
  - 新增按鈕改為：`<button v-if="isExpanded" class="sidebar-add-item" ...>` 放在 transition > div 內，SideBarTab loop 之後
  - collapse transition div 條件由 `!collapsedStates.personal && personalDashboards?.length > 0` 簡化為 `!collapsedStates.personal`
  - `.sidebar-add-item` CSS：height 2.25rem、padding 0 10px、border-radius 999px、color complement-text、hover 效果與 sidebar 其他 item 一致
  - 收起狀態 h2 padding 設為 0（原為 0 12px），icon 透過 margin-left: calc((3.5rem - 16px) / 2) 置中

- verification:
  - `get_errors` 對 SideBar.vue 回傳 "No errors found"
  - 視覺驗證：需在瀏覽器中切換展開/收起狀態確認 icon 與按鈕位置

- impact-risk:
  - 僅影響 SideBar.vue 的 UI 呈現，不涉及資料流或 API
  - `sidebar-sub-no` 條件補上 `!collapsedStates.personal`，修正了原本折疊時也顯示空訊息的 bug

- regression-test:
  - 登入後確認 sidebar 展開：我的最愛、個人儀表板 h2 正常顯示 icon 與文字
  - 收起 sidebar：我的最愛、個人儀表板 h2 只顯示 icon（置中）
  - 展開 個人儀表板 區段：新增按鈕在列表最下方（第三層）
  - 無個人儀表板時：「尚無個人儀表板」訊息正常顯示（非折疊狀態）；折疊後不顯示
  - 收折 個人儀表板 區段：新增按鈕消失、列表消失

- traceability:
  - N/A

- next-actions:
  - N/A
