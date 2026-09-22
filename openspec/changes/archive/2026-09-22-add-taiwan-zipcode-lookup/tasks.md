## 1. 專案骨架與資料準備

- [x] 1.1 建立目錄結構：`TaiwanZipLookup/`（App 原始碼）、`TaiwanZipLookup/Resources/`、`TaiwanZipLookupTests/`
- [x] 1.2 將公開郵遞區號資料集轉換為扁平 JSON `TaiwanZipLookup/Resources/zipcodes.json`，每筆含 `zipCode`、`city`、`cityEnglish`、`district`、`districtEnglish`
- [x] 1.3 驗證轉換結果：總筆數為 374、縣市數為 24、郵遞區號皆為 3 位數字、無欄位為空
- [x] 1.4 撰寫 `TaiwanZipLookup/Info.plist`（App 名稱、bundle identifier、最低系統版本 13.0、非 agent App）

## 2. 資料層（capability: zipcode-data）

- [x] 2.1 實作 `ZipCodeRecord`：不可變 `struct`，符合 `Codable`/`Identifiable`/`Hashable`，並於初始化時預先計算小寫搜尋索引欄位
- [x] 2.2 實作 `ZipCodeDataError`：`resourceNotFound(name:)`、`decodingFailed(underlying:)`，符合 `LocalizedError` 並提供繁體中文描述
- [x] 2.3 實作 `ZipCodeRepository.loadRecords(from bundle:)`：由 bundle 讀取並解碼 `zipcodes.json`，失敗時 throw `ZipCodeDataError`
- [x] 2.4 以 `os.Logger` 記錄載入成功筆數與失敗原因
- [x] 2.5 實作 `ZipCodeRepository.cities(from records:)`：推導不重複縣市清單並保留首次出現順序

## 3. 查詢層（capability: zipcode-search）

- [x] 3.1 實作純函式 `ZipCodeQuery.filter(records:keyword:city:)`：關鍵字 trim、大小寫不敏感子字串比對，縣市與關鍵字為 AND 關係
- [x] 3.2 實作 `ZipCodeQuery.sorted(_:)`：依郵遞區號遞增，相同時依縣市名再依行政區名排序
- [x] 3.3 確認空關鍵字與未選縣市時回傳全部紀錄，且查無結果時回傳空集合而非錯誤

## 4. 介面層（capability: macos-app-ui）

- [x] 4.1 實作 `TaiwanZipLookupApp`（SwiftUI App entry）與視窗設定（可調整大小、預設尺寸）
- [x] 4.2 實作 `ZipCodeViewModel`（`ObservableObject`）：持有 `keyword`、`selectedCity`、`records`、`loadError`，過濾委派給 `ZipCodeQuery`
- [x] 4.3 實作 `ContentView`：搜尋列、縣市 `Picker`（含「全部縣市」選項）、結果筆數顯示、結果清單
- [x] 4.4 實作 `ZipCodeRow`：強調顯示郵遞區號，並顯示縣市、行政區與英文名稱
- [x] 4.5 實作空狀態畫面（查無結果提示）與資料載入失敗的錯誤畫面
- [x] 4.6 實作 `PasteboardService`：以 `NSPasteboard` 提供「複製郵遞區號」與「複製完整地址前綴（`100 臺北市中正區`）」
- [x] 4.7 實作複製後的短暫「已複製」回饋提示
- [x] 4.8 確認淺色／深色外觀下皆可正常閱讀

## 5. Xcode 專案檔

- [x] 5.1 手寫 `TaiwanZipLookup.xcodeproj/project.pbxproj`：App target（macOS 13.0、Swift 5.9、ad-hoc 簽章）與 Unit Test target
- [x] 5.2 將 `zipcodes.json` 與 `Assets.xcassets` 加入 App target 的 Resources build phase
- [x] 5.3 建立 shared schemes `TaiwanZipLookup`，供 `xcodebuild -scheme` 使用
- [x] 5.4 驗證 `xcodebuild -list` 可正確列出 target 與 scheme

## 6. 測試

- [x] 6.1 撰寫 `ZipCodeRepositoryTests`：載入成功筆數、縣市清單、識別值唯一、欄位格式
- [x] 6.2 撰寫資料載入失敗測試：資源不存在與 JSON 格式錯誤各自回傳對應錯誤
- [x] 6.3 撰寫 `ZipCodeQueryTests`：涵蓋 spec 中每個查詢 Scenario（中文名、郵遞區號前綴、英文大小寫、前後空白、空關鍵字、查無結果）
- [x] 6.4 撰寫縣市篩選測試：僅縣市、縣市＋關鍵字、不限縣市
- [x] 6.5 撰寫排序測試：遞增性與決定性
- [x] 6.6 撰寫 `PasteboardService` 與 ViewModel 篩選行為測試
- [x] 6.7 執行 `xcodebuild test` 並確認全部測試通過

## 7. 建置驗證與文件

- [x] 7.1 執行 `xcodebuild -scheme TaiwanZipLookup -configuration Debug build` 確認建置成功且無警告
- [x] 7.2 實際啟動產出的 `.app`，確認視窗顯示、查詢與複製功能可用
- [x] 7.3 撰寫繁體中文 `README.md`：專案簡介、系統需求、建置與執行方式、測試方式、資料來源與更新說明、專案結構
- [x] 7.4 新增 `.gitignore`（排除 `build/`、`*.xcuserdatad`、`DerivedData/`）
- [x] 7.5 初始化 git repository 並提交
