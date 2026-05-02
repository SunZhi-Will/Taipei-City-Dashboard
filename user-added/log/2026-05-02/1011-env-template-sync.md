# 環境變數設定全面補齊 / Environment Variable Configuration Sync

## 2026-05-02 10:11

- objective:
  - 補齊 `docker/.env.template` 與 `docker/docker-compose.yaml` 中缺少的環境變數，消除設定漂移（config drift）問題：
    1. `TWCC_MAX_TOOL_LOOPS` — 後端已新增欄位（上次 commit），但兩個檔案均未補上
    2. `VITE_USE_TWAI_CHAT` — FE 程式碼使用但無法透過 Docker 環境控制
    3. `VITE_PERSONAL_BOARD_UPDATE` — App.vue 使用但缺少
    4. `DB_DASHBOARD_SSLMODE` / `DB_MANAGER_SSLMODE` — global.go 讀取但無範本值
    5. `TWCC_MODEL` 值不一致 — `.env.template` 寫 `16k` 但 global.go 預設 `32k`

- files:
  - docker/.env.template
  - docker/docker-compose.yaml

- summary:
  - **docker/.env.template**
    - Frontend 區塊新增 `VITE_USE_TWAI_CHAT=true`（附中文說明：設為 false 降級為純向量模式）
    - Frontend 區塊新增 `VITE_PERSONAL_BOARD_UPDATE=`（選填，逗號分隔的 index 白名單）
    - DB 區塊新增 `DB_DASHBOARD_SSLMODE=disable` 與 `DB_MANAGER_SSLMODE=disable`
    - TWCC 區塊新增 `TWCC_MAX_TOOL_LOOPS=5`（附中文說明）
    - 修正 `TWCC_MODEL` 從 `llama3.3-ffm-70b-16k-chat` → `llama3.3-ffm-70b-32k-chat`（與 global.go 預設值對齊）
  - **docker/docker-compose.yaml**
    - FE service environment 新增 `VITE_USE_TWAI_CHAT: ${VITE_USE_TWAI_CHAT:-true}`
    - FE service environment 新增 `VITE_PERSONAL_BOARD_UPDATE: ${VITE_PERSONAL_BOARD_UPDATE:-}`
    - BE service environment 新增 `TWCC_MAX_TOOL_LOOPS: ${TWCC_MAX_TOOL_LOOPS:-5}`（含 fallback 預設值）

- change-type:
  - Fixed

- technical-details:
  - `VITE_USE_TWAI_CHAT` 在 compose 使用 `:-true` fallback，確保不設定時行為與現有程式碼預設一致
  - `VITE_PERSONAL_BOARD_UPDATE` 使用 `:-` 空字串 fallback，對應 `App.vue` 的 `?.split(",") || []` 安全解析
  - `TWCC_MAX_TOOL_LOOPS` compose 使用 `:-5` fallback，確保未升級的 .env 不影響行為
  - `DB_DASHBOARD_SSLMODE` / `DB_MANAGER_SSLMODE` 未加入 docker-compose.yaml（這兩個在 compose 中直接用 postgres-data/postgres-manager 內網連線，disable 是正確預設，無需透過環境變數傳入）

- verification:
  - 比對 global.go 所有 getEnv/getIntEnv 呼叫 vs .env.template：現已全數對齊
  - 比對 FE import.meta.env.VITE_ 使用 vs .env.template + docker-compose.yaml：現已全數對齊
  - TWCC_MODEL 字串現在兩處一致：`llama3.3-ffm-70b-32k-chat`

- performance-impact:
  - 無，純設定檔變更

- impact-risk:
  - TWCC_MODEL 改為 32k 版本：僅影響新建或重建的 Docker 環境，現有 `.env` 以實際填寫值為準
  - VITE_USE_TWAI_CHAT 預設 true：與現有行為完全一致，無風險

- regression-test:
  - 執行 `docker compose --env-file docker/.env.template config` 驗證所有變數解析無警告
  - 確認 FE container 啟動後 `import.meta.env.VITE_USE_TWAI_CHAT` 能讀到正確值
  - 確認 BE container 啟動後 `TWCC_MAX_TOOL_LOOPS` 覆蓋 global.go 預設值

- traceability:
  - 關聯 log：user-added/log/2026-05-02/0940-ai-studio-comprehensive-optimization.md（TWCC_MAX_TOOL_LOOPS 來源）

- next-actions:
  - 若生產環境使用獨立 .env 檔，需人工同步新增這些 key
  - 可考慮增加 CI 步驟：diff global.go 的 getEnv keys vs .env.template，自動偵測漏填
