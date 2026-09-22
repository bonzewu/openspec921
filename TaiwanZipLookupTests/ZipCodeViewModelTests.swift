//
//  ZipCodeViewModelTests.swift
//  TaiwanZipLookupTests
//
//  驗證 capability: macos-app-ui 中介面狀態與即時查詢的需求。
//

import XCTest
@testable import TaiwanZipLookup

/// ViewModel 的測試。
///
/// ViewModel 標記為 `@MainActor`，因此測試類別同樣標記，
/// 讓所有斷言都在主執行緒上執行。
@MainActor
final class ZipCodeViewModelTests: XCTestCase {

    private var spy: SpyPasteboard!
    private var viewModel: ZipCodeViewModel!

    override func setUp() {
        super.setUp()
        spy = SpyPasteboard()
        viewModel = ZipCodeViewModel(pasteboardService: PasteboardService(pasteboard: spy))
    }

    override func tearDown() {
        spy = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Scenario: 啟動後顯示完整資料

    /// 初始化後應完成載入，且無錯誤、結果為全部紀錄。
    func testInitialStateLoadsAllRecords() {
        XCTAssertNil(viewModel.loadErrorMessage, "正常情況下不應有載入錯誤")
        XCTAssertEqual(viewModel.allRecords.count, 374, "應載入全部紀錄")
        XCTAssertEqual(viewModel.results.count, viewModel.allRecords.count, "初始結果應為全部紀錄")
        XCTAssertEqual(viewModel.cities.count, 24, "應取得 24 個縣市")
        XCTAssertFalse(viewModel.hasActiveFilter, "初始狀態不應有查詢條件")
    }

    // MARK: - Scenario: 輸入即篩選

    /// 變更關鍵字後，結果應立即反映（無需額外觸發查詢）。
    func testChangingKeywordUpdatesResultsImmediately() {
        viewModel.keyword = "大安"

        XCTAssertLessThan(viewModel.results.count, viewModel.allRecords.count, "結果應被收斂")
        XCTAssertTrue(
            viewModel.results.contains { $0.zipCode == "106" && $0.district == "大安區" },
            "結果應包含臺北市大安區"
        )
        XCTAssertTrue(viewModel.hasActiveFilter, "有關鍵字時應視為已套用條件")
    }

    /// 變更縣市篩選後，結果應立即反映。
    func testChangingCityUpdatesResultsImmediately() {
        viewModel.selectedCityTag = "高雄市"

        XCTAssertEqual(viewModel.selectedCity, "高雄市")
        XCTAssertEqual(viewModel.results.count, 40, "高雄市應有 40 個行政區")
        XCTAssertTrue(viewModel.results.allSatisfy { $0.city == "高雄市" })
    }

    /// 關鍵字與縣市應同時套用。
    func testKeywordAndCityApplyTogether() {
        viewModel.keyword = "中正"
        viewModel.selectedCityTag = "臺北市"

        XCTAssertEqual(viewModel.results.count, 1, "臺北市只有一個中正區")
        XCTAssertEqual(viewModel.results.first?.zipCode, "100")
    }

    /// 「全部縣市」標籤應轉換為不限縣市。
    func testAllCitiesTagMeansNoCityFilter() {
        viewModel.selectedCityTag = ZipCodeViewModel.allCitiesTag

        XCTAssertNil(viewModel.selectedCity, "全部縣市應對應 nil")
        XCTAssertEqual(viewModel.results.count, viewModel.allRecords.count)
    }

    // MARK: - Scenario: 清除查詢條件

    /// 清除條件後應回復顯示全部紀錄。
    func testClearFiltersRestoresFullList() {
        viewModel.keyword = "大安"
        viewModel.selectedCityTag = "臺北市"

        viewModel.clearFilters()

        XCTAssertEqual(viewModel.keyword, "")
        XCTAssertEqual(viewModel.selectedCityTag, ZipCodeViewModel.allCitiesTag)
        XCTAssertNil(viewModel.selectedCity)
        XCTAssertEqual(viewModel.results.count, viewModel.allRecords.count, "應回復全部紀錄")
        XCTAssertFalse(viewModel.hasActiveFilter)
    }

    // MARK: - Scenario: 查無結果提示

    /// 查無結果時應進入空狀態，而非錯誤狀態。
    func testUnmatchedKeywordEntersEmptyState() {
        viewModel.keyword = "不存在的地名ZZZ"

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertTrue(viewModel.isShowingEmptyResult, "應顯示查無結果的空狀態")
        XCTAssertNil(viewModel.loadErrorMessage, "查無結果不是載入錯誤")
    }

    // MARK: - Scenario: 複製與回饋

    /// 複製郵遞區號後應寫入剪貼簿並顯示提示。
    func testCopyZipCodeWritesAndShowsNotice() {
        let record = viewModel.allRecords.first { $0.id == "100-臺北市-中正區" }
        let target = try! XCTUnwrap(record)

        viewModel.copyZipCode(of: target)

        XCTAssertEqual(spy.lastWritten, "100")
        XCTAssertEqual(viewModel.copiedNotice, "已複製郵遞區號 100", "應顯示複製成功提示")
    }

    /// 複製完整地址後應寫入剪貼簿並顯示提示。
    func testCopyFullAddressWritesAndShowsNotice() {
        let record = viewModel.allRecords.first { $0.id == "100-臺北市-中正區" }
        let target = try! XCTUnwrap(record)

        viewModel.copyFullAddress(of: target)

        XCTAssertEqual(spy.lastWritten, "100 臺北市中正區")
        XCTAssertEqual(viewModel.copiedNotice, "已複製「100 臺北市中正區」")
    }

    /// 底層寫入失敗時應顯示失敗提示。
    func testCopyFailureShowsFailureNotice() {
        spy.writeResult = false
        let target = try! XCTUnwrap(viewModel.allRecords.first)

        viewModel.copyZipCode(of: target)

        XCTAssertEqual(viewModel.copiedNotice, "複製失敗，請再試一次")
    }

    // MARK: - 載入失敗

    /// 從缺少資料檔的 bundle 載入時，應進入錯誤狀態而非崩潰。
    func testLoadFailureEntersErrorState() {
        // 使用 XCTest 自身的 bundle：其中不含 zipcodes.json
        let bundleWithoutData = Bundle(for: XCTestCase.self)
        let failingViewModel = ZipCodeViewModel(bundle: bundleWithoutData)

        XCTAssertTrue(failingViewModel.allRecords.isEmpty, "載入失敗時不應有紀錄")
        XCTAssertTrue(failingViewModel.cities.isEmpty, "載入失敗時不應有縣市清單")
        let message = failingViewModel.loadErrorMessage ?? ""
        XCTAssertTrue(message.contains("zipcodes.json"), "錯誤訊息應指出缺少的資料檔，實際為：\(message)")
        XCTAssertFalse(failingViewModel.isShowingEmptyResult, "載入錯誤不應被視為查無結果")
    }
}
