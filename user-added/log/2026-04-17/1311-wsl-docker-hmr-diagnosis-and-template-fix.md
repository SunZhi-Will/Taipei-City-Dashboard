# WSL Docker 熱更新診斷與模板修復 / WSL Docker Hot Reload Diagnosis and Template Fix

## 2026-04-17 13:11

- objective:
  - 釐清 WSL Docker 為何看起來沒有熱更新。
  - 修復導致前端 HMR 編譯中斷的實際錯誤。

- files:
  - Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue

- summary:
  - 驗證容器掛載來源：`dashboard-fe` 與 `dashboard-be` 都正確掛載到 `/mnt/c/SoceCode/Sun/hack/Taipei-City-Dashboard/...`，非掛載路徑錯誤。
  - 驗證前端 dev 服務：`dashboard-fe` 內確實執行 `npm run dev`（Vite）。
  - 透過容器日誌確認 HMR 有觸發，但先前因 `DashboardComponent.vue` 缺少結尾標籤，造成 Vite 編譯錯誤，表現為畫面不更新或更新失敗。
  - 已補上缺失的關閉標籤，恢復編譯正常。

- change-type:
  - Fixed

- technical-details:
  - 檔案 `DashboardComponent.vue` 在 template 底部原本僅關閉內層容器，缺少外層 `.dashboardcomponent-fullscreen-container` 的 `</div>`。
  - 修正後結構：footer 區塊結束後，補上額外一層 `</div>`，再接 `Teleport`。
  - 修正後以 VS Code 診斷檢查，該檔案已無 compile error。

- verification:
  - 容器與掛載檢查（WSL）：
    - `docker ps`
    - `docker inspect dashboard-fe --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'`
    - `docker inspect dashboard-be --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'`
  - 前端 HMR 日誌檢查：
    - `docker logs dashboard-fe --tail 120`
    - 觀察到修正後出現 `hmr update /src/dashboardComponent/DashboardComponent.vue`，且不再新增同類模板錯誤。
  - IDE 診斷檢查：
    - `Taipei-City-Dashboard-FE/src/dashboardComponent/DashboardComponent.vue` -> No errors found。

- performance-impact:
  - 無顯著效能影響。
  - 此次為模板結構修正，不涉及演算法或渲染負載變更。

- impact-risk:
  - 低風險。僅補齊缺失閉合標籤，影響範圍限定於單一 Vue 元件 template 結構。
  - 若後續再發生 HMR 異常，優先檢查最近修改檔案是否出現模板/語法錯誤。

- regression-test:
  - 建議在 `/dashboard` 頁面操作下列流程：
    - 修改 `SettingsBar.vue` 文案或樣式，確認畫面即時更新。
    - 修改 `DashboardComponent.vue` 樣式，確認 HMR 正常。
    - 開啟瀏覽器 DevTools，確認 HMR websocket 連線穩定。

- traceability:
  - N/A

- next-actions:
  - 若開發時想避免代理層干擾，可優先使用 `http://localhost:8080` 直接連到 `dashboard-fe` 進行 HMR 驗證。
