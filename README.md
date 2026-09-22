# 臺灣郵遞區號查詢（TaiwanZipLookup）

一個以 Swift + SwiftUI 開發的 **macOS 原生桌面工具**，用來快速查詢臺灣 3 碼郵遞區號。
資料完整內建於 App 內，**啟動後完全離線可用**，不需要開瀏覽器、也不需要網路連線。

本專案使用 [OpenSpec](https://github.com/Fission-AI/OpenSpec) 以規格驅動（spec-driven）的方式開發：
先定義需求規格與設計決策，再依任務清單實作，規格文件保留在 `openspec/` 供後續追溯。

## 功能

- **即時查詢**：輸入即篩選，不需按下查詢按鈕。
- **多欄位搜尋**：可用郵遞區號、縣市中文名、鄉鎮市區中文名、以及英文名稱查詢（英文**大小寫不敏感**）。
- **縣市篩選**：下拉選單可限定縣市，並可與關鍵字同時套用。
- **結果排序**：依郵遞區號遞增，相同區號時依縣市、鄉鎮市區排序，結果順序固定。
- **一鍵複製**：每列提供兩個按鈕（也可用右鍵選單）
  - 複製郵遞區號 → `100`
  - 複製完整地址前綴 → `100 臺北市中正區`
- **淺色／深色外觀**：全部採用系統語意色，自動跟隨系統外觀。
- **完全離線**：資料為內建靜態 JSON，App 不發出任何網路請求。

## 系統需求

| 項目 | 版本 |
| --- | --- |
| macOS | 13.0 (Ventura) 或更新版本 |
| Xcode | 15.0 或更新版本 |
| Swift | 5.9 |
| 第三方套件 | 無 |

## 建置與執行

### 用 Xcode

```bash
open TaiwanZipLookup.xcodeproj
```

在 Xcode 中按 `Cmd + R` 執行。

### 用命令列

```bash
# Debug 建置
xcodebuild -project TaiwanZipLookup.xcodeproj \
           -scheme TaiwanZipLookup \
           -configuration Debug \
           -derivedDataPath build/DerivedData \
           build

# 執行建置好的 App
open build/DerivedData/Build/Products/Debug/TaiwanZipLookup.app
```

### 產出可安裝的 App

```bash
xcodebuild -project TaiwanZipLookup.xcodeproj \
           -scheme TaiwanZipLookup \
           -configuration Release \
           -derivedDataPath build/DerivedDataRelease \
           build

cp -R build/DerivedDataRelease/Build/Products/Release/TaiwanZipLookup.app /Applications/
```

專案使用 ad-hoc 簽章（Sign to Run Locally），**不需要 Apple 開發者帳號**即可建置與在本機執行。

## 測試

```bash
xcodebuild -project TaiwanZipLookup.xcodeproj \
           -scheme TaiwanZipLookup \
           -configuration Debug \
           -derivedDataPath build/DerivedData \
           test
```

共 44 個單元測試，對應規格中的每個 Scenario：

| 測試檔案 | 涵蓋範圍 |
| --- | --- |
| `ZipCodeRepositoryTests` | 資料載入筆數、欄位格式、識別值唯一性、縣市清單順序、資料檔缺失與 JSON 格式錯誤 |
| `ZipCodeQueryTests` | 中英文關鍵字、區號前綴、大小寫不敏感、前後空白、空關鍵字、查無結果、縣市篩選、排序遞增與決定性 |
| `PasteboardServiceTests` | 兩種複製格式、寫入失敗的回報 |
| `ZipCodeViewModelTests` | 初始載入狀態、即時篩選、清除條件、空狀態、複製回饋、載入失敗的錯誤狀態 |

## 專案結構

```
.
├── TaiwanZipLookup.xcodeproj/        # Xcode 專案（App target + 測試 target）
├── TaiwanZipLookup/
│   ├── TaiwanZipLookupApp.swift      # App 進入點
│   ├── Models/
│   │   ├── ZipCodeRecord.swift       # 郵遞區號資料模型（含預先計算的搜尋索引）
│   │   └── ZipCodeDataError.swift    # 資料載入錯誤型別
│   ├── Services/
│   │   ├── ZipCodeRepository.swift   # 從 bundle 載入與解碼資料、推導縣市清單
│   │   ├── ZipCodeQuery.swift        # 查詢與排序（無狀態純函式）
│   │   └── PasteboardService.swift   # 複製到剪貼簿
│   ├── ViewModels/
│   │   └── ZipCodeViewModel.swift    # 介面狀態，查詢委派給 ZipCodeQuery
│   ├── Views/
│   │   ├── ContentView.swift         # 搜尋列、縣市篩選、結果清單、空／錯誤狀態
│   │   └── ZipCodeRow.swift          # 單列呈現與複製按鈕
│   ├── Resources/
│   │   └── zipcodes.json             # 內建郵遞區號資料（374 筆）
│   ├── Assets.xcassets/              # App 圖示與主題色
│   └── Info.plist
├── TaiwanZipLookupTests/             # 單元測試
└── openspec/                         # OpenSpec 規格與設計文件
    ├── specs/                        # 目前生效的需求規格
    └── changes/archive/              # 已完成並歸檔的變更提案
```

## 架構

```
ContentView ──> ZipCodeViewModel ──> ZipCodeQuery（純函式：過濾 + 排序）
     │                 │
     │                 └────────────> ZipCodeRepository ──> zipcodes.json（bundle）
     └──> ZipCodeRow ──> PasteboardService ──> NSPasteboard
```

設計要點：

- **查詢邏輯是無狀態純函式**：`ZipCodeQuery` 不持有任何狀態，相同輸入必得相同輸出，因此規格中的每個 Scenario 都能直接寫成單元測試，不必啟動 UI。
- **搜尋索引預先計算**：載入時就把各欄位合併成一個小寫字串，避免每次按鍵時對 374 筆資料重複做字串轉換。
- **錯誤不吞不炸**：資料載入失敗會回傳明確的 `ZipCodeDataError`，寫入 `os.Logger`，並在畫面上顯示錯誤狀態與「重新載入」按鈕，不會讓程式崩潰。

## 資料來源與更新

郵遞區號資料為中華郵政 3 碼郵遞區號（經公開整理的 JSON 資料集），
涵蓋 **24 個縣市、374 個鄉鎮市區**，含中英文名稱。

資料是靜態檔案，若行政區或區號調整，請更新 `TaiwanZipLookup/Resources/zipcodes.json`，
格式為扁平陣列：

```json
[
  {
    "zipCode": "100",
    "city": "臺北市",
    "cityEnglish": "Taipei City",
    "district": "中正區",
    "districtEnglish": "Zhongzheng Dist."
  }
]
```

> 測試中對「總筆數 374」與「縣市數 24」有明確斷言，這是刻意的設計：
> 資料一旦變動，測試就會失敗並提醒你確認改動是否符合預期，同步調整常數即可。

## 已知範圍

- 只支援 **3 碼**（鄉鎮市區層級）查詢，不含 5 碼／3+3 碼的街道級郵遞區號。
- 資料需手動更新，App 不會自動連線下載新版資料。
- 未設定 App Sandbox 與公證（notarization），目前定位為本機工具，非 App Store 發佈版本。

## 授權

郵遞區號資料著作權屬中華郵政所有，本專案僅作查詢用途。
