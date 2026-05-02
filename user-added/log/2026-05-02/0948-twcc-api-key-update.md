# 更新 TWCC API 金鑰（黑客松隊伍金鑰）/ Update TWCC API Key (Hackathon Team Key)

## 2026-05-02 09:48

- objective:
  - 將 docker/.env 中的 TWCC_API_KEY 更新為雙北程式設計節黑客松分配的隊伍金鑰

- files:
  - docker/.env

- summary:
  - 依照現場桌牌（隊伍編號 3、隊伍名稱 Agent Team、API 名稱 hackteam3）所示金鑰，將舊金鑰更新為新分配金鑰
  - 舊金鑰：f7896822-6a1a-48fa-bbf7-212ab8d5e60e
  - 新金鑰：ca0d519a-7026-4c05-97c0-09a013d4e176

- change-type:
  - Changed

- technical-details:
  - 僅修改 TWCC_API_KEY 欄位，其餘 TWCC 相關設定（URL、模型、Timeout 等）維持不變
  - TWCC_MODEL 維持 llama3.3-ffm-70b-16k-chat

- verification:
  - 檢查指令：`grep TWCC_API_KEY docker/.env`
  - 預期輸出：`TWCC_API_KEY=ca0d519a-7026-4c05-97c0-09a013d4e176`

- impact-risk:
  - 僅影響後端對 TWCC AI Foundry Service 的 API 認證
  - 若金鑰無效，AI 相關功能（聊天機器人、圖表問答）將回傳 401 錯誤
  - 降級策略：還原為舊金鑰 f7896822-6a1a-48fa-bbf7-212ab8d5e60e

- regression-test:
  - 重新啟動 Docker 後，測試 AI 聊天功能是否正常回應
  - 驗證環境：本地 Docker Compose 開發環境

- traceability:
  - 隊伍桌牌照片（黑客松現場）
  - 隊伍名稱：Agent Team｜API 名稱：hackteam3

- next-actions:
  - 確認 Docker 服務重啟後 AI 功能正常運作
