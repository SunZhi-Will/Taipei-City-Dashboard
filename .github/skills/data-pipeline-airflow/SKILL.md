---
name: data-pipeline-airflow
description: "Use when: 設計與開發 Airflow DAG、Operator、Task、資料轉換腳本；資料品質檢查、排程、監控；支援 100+ 領域（AED、長照、學區等）。適用於新資料集整合、ETL 管道自動化、批次處理。"
applyTo: "Taipei-City-Dashboard-DE/**"
---

# 資料管道開發 Skill (Airflow)

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 需求與設計 | 資料源確認、Schema 設計、SLA 定義 | 0 data loss incidents | P0 |
| M2: DAG 工程化 | DAG 編碼、Task 依賴、錯誤處理 | 95% 排程成功率 | P0 |
| M3: 資料品質 | 驗證、去重、清理、異常偵測 | 99% 資料正確率 | P1 |
| M4: 監控與告警 | SLA 追蹤、失敗通知、資料新鮮度 | <15分鐘 告警回應 | P1 |

---

## 🔄 工作流程

### Phase 1: 需求分析與資料源
```
1. 收集需求
   ├─ 資料源：API、檔案、資料庫、爬蟲
   ├─ 更新頻率：日/週/月/事件驅動
   ├─ 資料量：預估記錄數、檔案大小
   ├─ 保留政策：熱/溫/冷資料分層
   └─ SLA：容許延遲、精準度要求

2. 資料探索
   ├─ 抽樣資料分析
   ├─ Schema 逆推（欄位類型、nullable）
   ├─ 異常值、缺失值識別
   ├─ 資料字典編寫
   └─ 資料血統圖 (lineage)
```

### Phase 2: DAG 設計與架構
```
3. DAG 設計
   ├─ Task 分解（Extract → Transform → Load）
   ├─ 依賴關係定義（>>> 運算子或 set_upstream）
   ├─ 並行化策略（pool 配置）
   ├─ 排程表達式（cron: @daily, @hourly）
   └─ 容錯機制 (retry, backoff, SLA)

4. Operator 選擇
   ├─ BashOperator: 外部腳本、shell 指令
   ├─ PythonOperator: 原生 Python 邏輯
   ├─ CustomOperator: 複雜轉換、API 呼叫
   ├─ PrestoOperator/SQLOperator: SQL 轉換
   └─ HttpOperator: REST API 資料抓取
```

### Phase 3: 資料轉換開發
```
5. 提取 (Extract)
   ├─ 源連線設定 (Airflow Connections)
   ├─ 增量 vs 全量邏輯
   ├─ 錯誤處理和重試
   ├─ 資料驗證（非空、格式檢查）
   └─ 臨時儲存（staging 表）

6. 轉換 (Transform)
   ├─ 資料清理（缺失、類型轉換、正規化）
   ├─ 商業邏輯轉換（計算、彙總、聯接）
   ├─ 地理編碼（Nominatim、座標轉換）
   ├─ 品質檢查（異常偵測、統計驗證）
   └─ 代碼：SQL 或 Python Pandas/Polars

7. 載入 (Load)
   ├─ 目標表設定 (upsert, append, truncate)
   ├─ 時間戳和分割鍵
   ├─ 索引最佳化
   ├─ 資料審計日誌
   └─ 通知下游系統
```

### Phase 4: 監控、測試、部署
```
8. 測試
   ├─ 單元測試 DAG 邏輯
   ├─ 小數據集整合測試
   ├─ SLA 驗證
   └─ Dry run 在預生產環境

9. 監控與告警
   ├─ DAG 執行時間 SLA
   ├─ Task 失敗率 <2%
   ├─ 資料新鮮度檢查
   ├─ 行數異常偵測（前日對比 ±20%）
   └─ Email/Slack 通知

10. 部署與文件
    ├─ DAG code 到 git
    ├─ 資料字典與轉換邏輯文件
    ├─ Runbook（手動重新執行、回溯）
    ├─ 效能基準（預期執行時間）
    └─ 版本控制與依賴追蹤
```

---

## 💡 技術決策點

### 📋 DAG 開發模板
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-team',
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
}

with DAG('aed_data_pipeline',
         default_args=default_args,
         schedule_interval='@daily',
         start_date=datetime(2026, 1, 1),
         catchup=False,
         tags=['health', 'location']) as dag:

    start = DummyOperator(task_id='start')
    
    extract = PythonOperator(
        task_id='extract_aed_data',
        python_callable=extract_aed,
        op_kwargs={'source': 'health_api'},
    )
    
    transform = PythonOperator(
        task_id='transform_aed',
        python_callable=transform_aed,
    )
    
    validate = PythonOperator(
        task_id='validate_aed',
        python_callable=validate_quality,
    )
    
    load = PythonOperator(
        task_id='load_to_db',
        python_callable=load_aed,
    )
    
    # 依賴關係
    start >> extract >> transform >> validate >> load
```

### 🎯 資料品質檢查表
| 檢查項 | 方法 | 失敗動作 |
|--------|------|--------|
| 非空驗證 | COUNT(col) WHERE col IS NULL | 告警，跳過 load |
| 格式驗證 | REGEX match, 型態轉換 | 拒絕行 |
| 範圍檢查 | MIN/MAX 邊界 | 告警，人工審查 |
| 重複檢查 | COUNT(DISTINCT id) vs 預期 | 回退到舊資料 |
| 異常偵測 | 前日對比、IQR | 告警，趨勢分析 |

### 🔀 並行化與資源
```yaml
# airflow.cfg 重要設定
parallelism = 32  # 全域最大並行 task
dag_concurrency = 8  # 單 DAG 最大並行
pool: default_pool = 16  # 資源預約
```

### 📅 排程表達式常用
| 頻率 | 表達式 | 說明 |
|------|--------|------|
| 每日凌晨2點 | 0 2 * * * | 台北時區 |
| 每週一早上8點 | 0 8 * * 1 | 周報資料 |
| 每6小時 | 0 */6 * * * | 即時監控資料 |
| 每月1日 | 0 0 1 * * | 月度結算 |

### 🗂️ 領域DAG分類 (proj_city_dashboard/)
```
dags/
├─ health/              # AED、長照、老人福利
├─ education/           # 學區、校數
├─ society/             # 新住民、移工、失業
├─ environment/         # 垃圾清運、空氣品質
├─ economy/             # 失業率、薪資
├─ infrastructure/      # 交通、停車、公用設施
└─ common_dags/         # 跨領域共用
```

---

## 🛡️ 實踐檢查清單

- [ ] DAG 語法驗證 (`airflow dags list`)
- [ ] 排程表達式正確性檢查
- [ ] 連線設定已加密存儲 (Airflow Variables/Connections)
- [ ] Error handling 與 retry 邏輯已測試
- [ ] SLA 告警已配置
- [ ] 資料品質檢查涵蓋 >90% 欄位
- [ ] 異常檢測基線已建立（前 30 日統計）
- [ ] 增量邏輯已驗證（無資料遺漏）
- [ ] Runbook 文件已寫（失敗排查步驟）
- [ ] 預生產環境試執行通過
- [ ] 資料血統和依賴圖已文件化
- [ ] 效能基準測試（>10k, >100k 記錄）

---

## 📚 參考檔案

- **DAG 目錄**: [dags/proj_city_dashboard/](../Taipei-City-Dashboard-DE/dags/proj_city_dashboard/)
- **常用 Operators**: [dags/operators/](../Taipei-City-Dashboard-DE/dags/operators/)
- **Airflow 配置**: [config/airflow.cfg](../Taipei-City-Dashboard-DE/config/airflow.cfg)
- **工具函數**: [dags/utils/](../Taipei-City-Dashboard-DE/dags/utils/)
- **範例**: [dags/tutorial/](../Taipei-City-Dashboard-DE/dags/tutorial/)
