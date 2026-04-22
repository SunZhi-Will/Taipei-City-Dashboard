# AIChatHub Widget Clean Demo

這個資料夾是可攜式的乾淨展示版本，目標是避免不同網站環境導致樣式差異。

## 內容

- `index.html`: 獨立展示頁，已內建 mock API。
- `aichathub-widget-v2.js`: 從專案目前版本複製的 widget 腳本。

## 為什麼這版比較穩

- JS 使用相對路徑 `./aichathub-widget-v2.js`，避免不同站台解析成其他檔案。
- `baseUrl` 固定為 `https://demo.local`，並由 `window.fetch` mock 攔截，不依賴任何後端。
- `projectId/chatBotId/themeColor/chatBackgroundColor` 都已固定。
- `persistHistory` 關閉，避免 localStorage 汙染展示結果。

## 展示方式

1. 直接開 `index.html`。
2. 或使用本機靜態伺服器後再開啟（建議，最接近正式環境）。

PowerShell 範例（若有 Python）:

```powershell
cd artifacts/widget-demo-clean
python -m http.server 8010
```

然後開瀏覽器到 `http://localhost:8010`。

## 快速驗證詞

- 長條圖
- 折線圖
- 圓餅圖
- 地圖
- 綜合示例
