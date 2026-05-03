---
name: ai-feature-development
description: "Use when: 開發 AI/LLM 功能，整合 LangChain + ONNX Runtime、Qdrant 向量搜尋；實作聊天機器人、智能搜尋、資料分析助手；優化推理效能、快取與成本。適用於 AI 對話、KPI 分析、知識庫檢索。"
applyTo: "Taipei-City-Dashboard-BE/**"
---

# AI/LLM 特性開發 Skill

## 📊 目標與里程碑

| 里程碑 | 目標 | KPI | 優先級 |
|--------|------|-----|--------|
| M1: 需求與設計 | 使用案例、模型選型、成本評估 | 決策文件通過 | P0 |
| M2: 核心邏輯 | LangChain 整合、向量搜尋、提示詞調優 | 90% 回答準確率 | P1 |
| M3: 效能與成本 | 推理最佳化、快取策略、Token 控制 | 推理 <2s, 成本議價 | P1 |
| M4: 監控與安全 | 使用者日誌、內容過濾、成本追蹤 | 無害內容過濾率 >95% | P2 |

---

## 🎯 AI 功能類型矩陣

| 功能 | 模型 | 複雜度 | 成本 | 延遲 |
|------|------|--------|------|------|
| **聊天機器人** | GPT-4 / Claude 3 | 中 | 中等 | 2-5s |
| **知識檢索** (RAG) | 開源向量模型 + LLM | 高 | 低-中 | 1-3s |
| **KPI 分析** | 輕量 LLM | 低 | 低 | <1s |
| **資料視覺化推薦** | Vision LLM | 高 | 高 | 5-10s |
| **即時監控告警** | ONNX 小模型 | 低 | 低 | <500ms |

---

## 🔄 工作流程

### Phase 1: 需求與模型選型
```
1. 定義 AI 使用案例
   ├─ 使用者故事 (誰、怎麼用、為什麼)
   ├─ 預期準確率與 SLA
   ├─ 不同模型成本對比
   │  ├─ 雲端模型 (GPT-4, Claude 3): 按 token 計費
   │  └─ 開源模型 (Mistral, Llama 2): 自託管
   ├─ 隱私/法規需求
   │  ├─ 是否能上傳至雲端?
   │  └─ 資料保留政策
   └─ 使用者量預測 (DAU, 月成本)

2. 架構設計
   ├─ 單次查詢 vs 對話歷史?
   ├─ 是否需增強檢索 (RAG)?
   ├─ 本地推理 vs API?
   ├─ 推理硬體 (GPU, TPU, CPU)
   └─ 成本估算
       ├─ 模型訪問費用
       ├─ 向量存儲成本 (Qdrant)
       ├─ 推理主機成本
       └─ 月度成本預算

3. 模型選擇決策樹
   ├─ 需要即時反應 (<500ms)?
   │  └─ 是 → ONNX 小模型 (本地推理)
   │  └─ 否 → 標準 LLM
   ├─ 需要上下文記憶?
   │  └─ 是 → 對話邏輯 + Token 計數
   │  └─ 否 → 單次無狀態查詢
   └─ 需要增強檢索 (RAG)?
      └─ 是 → 向量 DB + embedding model
      └─ 否 → 純 LLM 推理
```

### Phase 2: 向量搜尋與 RAG 基礎設施
```
4. 設定 Qdrant 向量資料庫
   ├─ Docker/K8s 部署 (已包含在 docker-compose.yaml)
   ├─ Collection 建立
   │  ├─ Schema: id, vector, payload (metadata)
   │  ├─ Vector 維度: 768 (OpenAI embedding) 或 384 (ONNX)
   │  └─ 索引策略 (HNSW for scaling)
   ├─ 向量 upsert 批量操作
   └─ 搜尋配置 (similarity metric: cosine)

5. Embedding 模型選擇
   ├─ 雲端 (OpenAI text-embedding-3-small)
       ├─ 維度: 1536, 精準度最高
       ├─ 成本: $0.02/100k tokens
       └─ 每次呼叫須計費
   ├─ 開源 (ONNX 本地)
       ├─ all-MiniLM-L6-v2: 輕量, 推理快
       ├─ multilingual-e5: 支援多語言
       └─ 一次性成本 (GPU 推理)

6. 知識庫構建 (Indexing)
   ├─ 資料來源
   │  ├─ 儀表板文件與幫助中心
   │  ├─ 政策白皮書與指南
   │  ├─ FAQ 與常見問題
   │  └─ 即時資料摘要 (仪表板統計)
   ├─ 文本分塊 (Chunking)
   │  ├─ 分塊大小: 256-512 tokens
   │  ├─ 重疊策略: 10-20% 重疊防斷裂
   │  └─ 保留原文本位置與連結
   ├─ Embedding 與索引
   │  ├─ 批量生成 embeddings
   │  ├─ Qdrant 插入
   │  └─ 版本管理與更新策略
   └─ 品質檢查
       ├─ 採樣測試: 查詢相似度檢查
       └─ 定期重新索引 (增量or全量)
```

### Phase 3: LangChain 集成與提示詞工程
```
7. LangChain 架構設定
   ├─ LLMs: 多模型支援
   │  ├─ OpenAI API → langchain.llms.OpenAI()
   │  ├─ 本地 LLM (Ollama/vLLM) → langchain.llms.LlamaCpp()
   │  └─ 後備模型 (成本/可用性)
   ├─ Embeddings: 向量嵌入
   │  └─ langchain.embeddings.OpenAIEmbeddings()
   ├─ Vector Stores: 向量儲存
   │  └─ langchain.vectorstores.Qdrant()
   └─ Retrievers: 檢索策略
       ├─ 基礎相似度搜尋
       ├─ MMR (Maximal Marginal Relevance)
       └─ 時間衰減 (近期資料優先)

8. 提示詞 (Prompt) 工程
   ├─ 系統提示詞 (System Prompt)
   │  └─ 定義 AI 角色: "你是台北市儀表板助手..."
   │  └─ 邊界與限制: "關於非台北市資料..."
   │  └─ 回應格式與語言風格
   ├─ RAG 提示詞範例
   │  ```
   │  已知資訊:
   │  {context}
   │
   │  使用者提問: {question}
   │
   │  基於上述資訊回答，如不知道回答"未在知識庫中"
   │  ```
   ├─ Few-shot 範例 (示範回答)
   │  └─ 2-3 個典型 Q&A 對
   └─ 提示詞版本管理
       └─ 版本控制 (git) + A/B 測試

9. 對話管理
   ├─ 上下文管理
   │  ├─ 對話歷史 (Chat History)
   │  ├─ Token 計數與限制 (max_tokens = 4000)
   │  └─ 記憶體摘要 (長對話壓縮)
   ├─ 狀態追蹤
   │  ├─ 使用者 session ID
   │  ├─ 對話 turn 序列
   │  └─ 中斷恢復邏輯
   └─ 行為自定義
       ├─ 工具調用 (Tool Use)
       │  ├─ "查詢最新統計數據"
       │  └─ "繪製圖表"
       └─ 流程控制 (Agent Logic)

10. 推理代碼範例
    ```go
    // Go + LangChain 簡化示意
    retriever := NewQdrantRetriever(client)
    
    // 檢索相關文件
    docs := retriever.GetRelevant(question, topK=3)
    
    // 組建提示詞
    context := JoinDocs(docs)
    prompt := fmt.Sprintf("已知資訊:\n%s\n\n提問: %s", context, question)
    
    // 調用 LLM
    response := llm.Generate(prompt)
    
    return response
    ```
```

### Phase 4: 效能、安全、監控
```
11. 效能最佳化
    ├─ 快取策略
    │  ├─ Query 快取 (相同提問重複回應)
    │  ├─ Embedding 快取 (避免重複計算)
    │  └─ Redis 存儲，TTL 1 小時
    ├─ 批版本化
    │  └─ 批量 embedding (N queries → 1 API call)
    ├─ 向量檢索最佳化
    │  ├─ Qdrant HNSW 參數調優
    │  └─ 搜尋結果前 K 限制 (K=3-5)
    └─ 推理資源
        ├─ GPU 分配 (共享 vs 獨占)
        └─ 批推理 (batched inference)

12. 安全與內容過濾
    ├─ 輸入驗證
    │  ├─ SQL injection 防禦
    │  ├─ Prompt injection 檢測
    │  └─ 使用者權限檢查
    ├─ 輸出過濾
    │  ├─ 有害內容偵測 (OpenAI Moderation API)
    │  ├─ 個資/敏感資訊遮蔽
    │  └─ 事實性驗證 (比對知識庫)
    └─ 金鑰管理
        └─ API 金鑰在環境變數，不硬編碼

13. 監控與成本追蹤
    ├─ 使用者日誌
    │  ├─ 每次查詢: user_id, question, response_time, token_count
    │  ├─ 回答品質評分 (👍/👎)
    │  └─ 誤導或錯誤標記
    ├─ 效能指標
    │  ├─ 平均回應時間 (target: <2s)
    │  ├─ 推理成功率 (target: >99%)
    │  └─ 向量檢索準確率 (NDCG@5)
    ├─ 成本監控
    │  ├─ LLM API 成本 (daily/monthly)
    │  ├─ 向量 embedding 成本
    │  └─ 基礎設施成本 (Qdrant, GPU)
    └─ 告警
        ├─ 推理失敗率 >3%
        ├─ 成本超預算
        └─ 回應時間 >5s
```

---

## 💡 技術決策點

### 模型成本對比 (月度估算，DAU=1000)
| 模型 | 用途 | 月成本 | 優缺點 |
|------|------|--------|--------|
| GPT-4 | 通用 LLM | $500+ | 精準但貴 |
| Claude 3 Opus | 通用 LLM | $300-500 | 長上下文 |
| Mistral 7B | 本地推理 | $50-100 | 便宜好維護 |
| 開源 embedding | 重排序 | <$50 | 維護成本 |

### Token 成本計算
```
GPT-4o:
- Prompt: $5 per 1M tokens
- Completion: $15 per 1M tokens

月成本 = (Prompt tokens + Completion*3) * 1000 users * 10 queries/day * 30 days * 費率
```

### Qdrant 性能 (1M vectors, 768 dim)
- 搜尋延遲: <50ms (p99)
- QPS capacity: >1000 (單節點)
- 存儲空間: ~3GB

---

## 🛡️ 實踐檢查清單

- [ ] 模型選型決策文件已簽核
- [ ] 成本預算已批准 (月額度)
- [ ] API 金鑰已加密存儲 (環境變數)
- [ ] Qdrant 向量 DB 已部署與備份測試
- [ ] 知識庫索引已驗證 (抽樣檢查相似度)
- [ ] 提示詞已多輪測試 (20+ 查詢)
- [ ] 輸入/輸出驗證已實現
- [ ] Moderation API 過濾已啟用
- [ ] 使用者日誌與分析儀表板已設定
- [ ] E2E 效能測試通過 (p99 <2s)
- [ ] 成本監控告警已設定
- [ ] Runbook 與故障排查文件已完成

---

## 📚 參考檔案

- **AI Controller**: [Taipei-City-Dashboard-BE/app/controllers/ai.go](../Taipei-City-Dashboard-BE/app/controllers/ai.go)
- **Qdrant 配置**: [docker/docker-compose.yaml](../docker/docker-compose.yaml) (搜尋 qdrant)
- **模型導出**: [Taipei-City-Dashboard-BE/export_model.py](../Taipei-City-Dashboard-BE/export_model.py)
- **LangChain 文檔**: https://python.langchain.com/
- **Qdrant 官方**: https://qdrant.tech/documentation/
