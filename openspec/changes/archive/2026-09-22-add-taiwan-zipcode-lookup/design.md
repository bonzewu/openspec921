## Context

本專案為全新建立的 macOS 桌面工具，沒有既有程式碼或既有 spec 需要相容。開發環境的限制如下：

- macOS 13.7.8 (Ventura)、Xcode 15.0、Swift 5.9、x86_64 機器。
- 機器上沒有安裝 XcodeGen / Tuist，因此 `.xcodeproj` 需以手寫 `project.pbxproj` 方式產生，並確保 Xcode 15 可直接開啟、`xcodebuild` 可在命令列建置與測試。
- 部署目標必須是 macOS 13.0，才能在本機直接執行（不能使用 macOS 14+ 才有的 API，例如 `.inspector`、`ContentUnavailableView`、新版 `Observation` 巨集）。
- 不引入任何第三方套件，僅使用 SwiftUI / Foundation / AppKit。
- 使用者偏好函式式風格與繁體中文註解、docstring。

資料來源為中華郵政 3 碼郵遞區號，經公開整理成 JSON（24 縣市、374 個行政區，含中英文名稱）。資料量極小（約 28 KB），適合完整內嵌於 App bundle。

## Goals / Non-Goals

**Goals:**

- 提供一個可離線、啟動即用的原生 macOS 郵遞區號查詢 App。
- 查詢邏輯以純函式實作，可獨立於 UI 進行單元測試（對應 `zipcode-search` spec 的每個 Scenario）。
- 資料載入具明確錯誤型別與日誌，不以未處理例外終止（對應 `zipcode-data` spec）。
- 命令列可重現建置：`xcodebuild -scheme TaiwanZipLookup build` 與 `test` 皆可通行。
- 全部文件與註解使用繁體中文。

**Non-Goals:**

- 不做 5 碼／6 碼（3+2、3+3）街道級郵遞區號查詢；街道資料量大且需定期更新，本次僅到行政區層級。
- 不做線上即時抓取中華郵政資料或自動更新機制；資料為靜態檔案，需要時手動替換。
- 不做 App Store 發佈、公證（notarization）與正式簽章設定，僅設定本機執行用的 ad-hoc 簽章。
- 不做 iOS / iPadOS 版本。
- 不做地址完整解析（例如「台北市信義路五段」→ 5 碼）。

## Decisions

### 決策 1：手寫 `project.pbxproj`，而非依賴專案產生工具

- **選擇**：直接撰寫 `TaiwanZipLookup.xcodeproj/project.pbxproj`，包含一個 App target 與一個 Unit Test target，並附上兩個 shared scheme（供 `xcodebuild -scheme` 使用）。
- **理由**：機器上沒有 XcodeGen/Tuist；透過 brew 安裝額外工具會增加環境依賴，而使用者要求「Xcode 專案」本身即為交付物，pbxproj 必須存在於 repo。
- **替代方案**：
  - *Swift Package Manager (`Package.swift`)*：Xcode 可開啟，但要產生具 `Info.plist` 的 `.app` bundle 並以 GUI App 執行較迂迴，且不是使用者要的 `.xcodeproj`。
  - *brew install xcodegen 後由 `project.yml` 產生*：需額外安裝，且 clone 專案的人也得先安裝才能重建專案檔。

### 決策 2：三層架構，查詢邏輯為無狀態純函式

- **選擇**：
  - `ZipCodeRecord`（`struct`，`Codable`、`Identifiable`、`Hashable`）：不可變值型別，載入時額外預先計算小寫化的搜尋索引欄位。
  - `ZipCodeRepository`：負責從 bundle 讀取並解碼 `zipcodes.json`，回傳 `Result` 或 throw 明確的 `ZipCodeDataError`；同時推導縣市清單。
  - `ZipCodeQuery`（純函式集合，無狀態）：`filter(records:keyword:city:)` 與排序，輸入相同必得相同輸出。
  - `ZipCodeViewModel`（`ObservableObject`）：只持有 `keyword`、`selectedCity`、`records` 等狀態，把過濾工作委派給 `ZipCodeQuery`。
  - SwiftUI Views：`ContentView`、`ZipCodeRow`、搜尋列與篩選器。
- **理由**：符合使用者偏好的函式式風格；純函式讓 `zipcode-search` 的每個 Scenario 都能直接寫成 XCTest，不需啟動 UI。
- **替代方案**：把過濾寫在 View 的 computed property 裡——較少程式碼，但無法單獨測試，且 View 與邏輯耦合。

### 決策 3：載入時預先計算小寫搜尋欄位

- **選擇**：在解碼後為每筆紀錄建立一個合併的小寫搜尋字串（郵遞區號＋中英文縣市／行政區名），查詢時只對該欄位做 `contains`。
- **理由**：`lowercased()` 在每次按鍵、每筆紀錄都重算會產生 374 × N 次字串配置；預先計算讓即時查詢的成本可忽略，同時滿足「英文比對大小寫不敏感」的需求。
- **替代方案**：查詢時逐欄位 `range(of:options: .caseInsensitive)`——程式碼較短，但每次輸入都要重複做 Unicode 折疊，且多欄位比對邏輯分散。

### 決策 4：資料以 JSON 形式放入 bundle，並在建置期複製

- **選擇**：`zipcodes.json` 為扁平陣列（每筆含 `zipCode`、`city`、`cityEnglish`、`district`、`districtEnglish`），列入 App target 的 `Resources` build phase。
- **理由**：扁平結構的 `Codable` 解碼最直接，也讓測試容易逐筆驗證；JSON 對後續手動更新最友善（可用文字工具 diff）。
- **替代方案**：
  - *巢狀（縣市 → 行政區陣列）*：接近原始資料集格式，但解碼後仍需攤平，且排序與過濾都要處理兩層。
  - *編譯進 Swift 原始碼的常數陣列*：省去 I/O 與解碼失敗路徑，但 374 筆會讓原始碼膨脹、編譯變慢，且資料更新等於改程式碼。

### 決策 5：錯誤處理與日誌

- **選擇**：定義 `ZipCodeDataError`（`resourceNotFound(name:)`、`decodingFailed(underlying:)`）符合 `LocalizedError`，訊息為繁體中文；使用 `os.Logger`（subsystem 為 bundle identifier）記錄載入結果與失敗原因。載入失敗時 UI 顯示錯誤狀態而非崩潰。
- **理由**：符合使用者偏好的「詳細錯誤處理與日誌記錄」，並對應 `zipcode-data` 的失敗處理需求。
- **替代方案**：`fatalError` / `try!`——程式碼最短，但違反 spec 中「MUST NOT 以未處理例外終止」。

### 決策 6：剪貼簿與複製回饋

- **選擇**：以 `NSPasteboard.general`（`clearContents()` 後 `setString(_:forType: .string)`）實作；回饋採用短暫顯示的「已複製」提示文字（以 `Task` 延遲後清除狀態）。
- **理由**：AppKit 剪貼簿 API 在 macOS 13 穩定可用；輕量提示不需額外依賴或 macOS 14+ 的新元件。
- **替代方案**：使用系統通知——會要求通知權限，對一個複製動作而言過重。

### 決策 7：簽章設定為本機執行用的 ad-hoc

- **選擇**：`CODE_SIGN_IDENTITY = "-"`（Sign to Run Locally）、`CODE_SIGN_STYLE = Automatic`、不啟用 App Sandbox（本 App 不需網路或檔案存取權限）。
- **理由**：讓任何人 clone 後不需開發者帳號即可 `xcodebuild` 建置並執行。
- **替代方案**：`CODE_SIGNING_ALLOWED = NO`——建置可過，但產生的 `.app` 在部分情況無法正常啟動。

## Risks / Trade-offs

- **手寫 pbxproj 容易有隱性格式錯誤，Xcode 可能拒絕開啟** → 完成後以 `xcodebuild -list` 與實際 `build`／`test` 驗證，並保持檔案結構最小化（單一 group、明確的 UUID 命名），避免使用 Xcode 15 才引入的實驗性設定。
- **郵遞區號資料會隨行政區調整而過期** → 資料集獨立為單一 JSON 檔並在 README 記載來源與更新方式；測試中對「總筆數 374」等常數斷言，資料更新時測試會立即提醒需同步調整。
- **資料集含「釣魚臺」、「南海島」等特殊條目** → 保留原始資料不做政治性裁切，但測試不對這些特殊條目做行為斷言，避免資料來源調整時測試失效。
- **只支援 3 碼，使用者可能期待 5 碼查詢** → README 明確說明範圍為行政區層級，並在 Non-Goals 記錄；未來若要擴充，`ZipCodeRecord` 可加上選擇性的街道層級欄位而不破壞既有查詢介面。
- **預先計算搜尋索引會讓每筆紀錄多佔一份字串記憶體** → 374 筆的額外記憶體在數十 KB 等級，對桌面 App 可忽略，換得即時查詢的順暢度。
- **不啟用 App Sandbox 會讓 App 無法直接送 App Store** → 本次為本機工具，非發佈目標；若日後要發佈，只需新增 entitlements 檔案並開啟沙盒，因 App 不存取網路與使用者檔案，預期無功能衝擊。

## Migration Plan

本專案為全新建立，無既有資料或使用者需要遷移。部署方式為：以 Xcode 開啟 `TaiwanZipLookup.xcodeproj` 後 `Cmd+R`，或以 `xcodebuild -scheme TaiwanZipLookup -configuration Release build` 產出 `.app` 後複製到 `/Applications`。回退方式即刪除該 `.app`，不留任何系統狀態（App 不寫入任何持久化資料）。

## Open Questions

- 是否需要「全域快捷鍵喚出查詢視窗」或選單列（menu bar extra）模式？目前先做標準視窗 App，待實際使用後再評估。
- 是否需要支援 5 碼／3+3 碼查詢與定期更新資料？視後續需求決定，會是獨立的 change。
