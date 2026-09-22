## Why

在 macOS 上查詢臺灣郵遞區號目前只能開瀏覽器連上中華郵政網站，操作慢、離線無法使用，且無法快速把結果貼到表單或信件。一個原生、離線可用的 macOS 查詢工具能把「輸入地名 → 取得郵遞區號」縮短到數秒內完成。

## What Changes

- 新增一個以 Swift + SwiftUI 開發、可在 macOS 13 (Ventura) 以上執行的 Xcode 專案 `TaiwanZipLookup`。
- 內建（bundle 內）完整的臺灣 3 碼郵遞區號資料集，共 24 個縣市／374 個行政區，含中英文名稱，啟動後完全離線運作。
- 提供即時搜尋：可用郵遞區號、縣市名、行政區名、英文名稱（含大小寫不敏感）進行查詢，輸入即篩選。
- 提供縣市下拉篩選，並可與關鍵字搜尋同時套用。
- 查詢結果以清單呈現「郵遞區號 / 縣市 / 行政區 / 英文名」，支援點選複製郵遞區號或完整地址前綴到剪貼簿。
- 加入單元測試涵蓋資料載入與查詢邏輯，並以 `xcodebuild` 可在命令列建置與測試。
- 加入繁體中文 README.md 說明建置、執行與資料來源。

## Capabilities

### New Capabilities
- `zipcode-data`: 郵遞區號資料模型與內建資料集的載入、驗證與索引建立。
- `zipcode-search`: 依關鍵字與縣市條件過濾郵遞區號的查詢邏輯與排序規則。
- `macos-app-ui`: macOS 原生 SwiftUI 介面，包含搜尋列、縣市篩選、結果清單與複製到剪貼簿。

### Modified Capabilities
<!-- 無：本專案為全新建立，尚無既有 spec。 -->

## Impact

- 新增程式碼：`TaiwanZipLookup/`（App 原始碼、`Assets.xcassets`、`zipcodes.json` 資料檔）、`TaiwanZipLookupTests/`（單元測試）。
- 新增專案檔：`TaiwanZipLookup.xcodeproj`（App target 與 Test target，部署目標 macOS 13.0）。
- 新增文件：`README.md`。
- 外部依賴：無第三方套件，僅使用 SwiftUI / Foundation / AppKit。
- 資料來源：中華郵政 3 碼郵遞區號（經公開整理之 JSON 資料集），為靜態內建檔案，需要時手動更新。
