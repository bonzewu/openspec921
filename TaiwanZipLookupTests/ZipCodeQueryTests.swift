//
//  ZipCodeQueryTests.swift
//  TaiwanZipLookupTests
//
//  驗證 capability: zipcode-search 的需求。
//

import XCTest
@testable import TaiwanZipLookup

/// 查詢邏輯的測試。
///
/// 測試使用兩組資料：一組是小型的手造樣本（行為邊界最容易斷言），
/// 另一組是真實的內建資料集（確保在完整資料上也成立）。
final class ZipCodeQueryTests: XCTestCase {

    /// 真實資料集。
    private var realRecords: [ZipCodeRecord] = []

    /// 手造樣本資料。
    private let sample: [ZipCodeRecord] = [
        ZipCodeRecord(zipCode: "106", city: "臺北市", cityEnglish: "Taipei City",
                      district: "大安區", districtEnglish: "Da’an Dist."),
        ZipCodeRecord(zipCode: "100", city: "臺北市", cityEnglish: "Taipei City",
                      district: "中正區", districtEnglish: "Zhongzheng Dist."),
        ZipCodeRecord(zipCode: "800", city: "高雄市", cityEnglish: "Kaohsiung City",
                      district: "新興區", districtEnglish: "Xinxing Dist."),
        ZipCodeRecord(zipCode: "202", city: "基隆市", cityEnglish: "Keelung City",
                      district: "中正區", districtEnglish: "Zhongzheng Dist.")
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()
        realRecords = try ZipCodeRepository.loadRecords(from: .main)
    }

    // MARK: - Scenario: 以行政區中文名查詢

    /// 以「大安」查詢應命中臺北市大安區（106）。
    func testSearchByDistrictChineseName() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "大安", city: nil)

        XCTAssertFalse(results.isEmpty, "「大安」應至少命中一筆")
        XCTAssertTrue(
            results.contains { $0.zipCode == "106" && $0.city == "臺北市" && $0.district == "大安區" },
            "結果應包含臺北市大安區（106）"
        )
        for record in results {
            XCTAssertTrue(record.searchIndex.contains("大安"), "每筆結果都應包含關鍵字：\(record.id)")
        }
    }

    // MARK: - Scenario: 以郵遞區號前綴查詢

    /// 以「10」查詢應命中 100，且每筆結果皆含該字串。
    func testSearchByZipCodePrefix() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "10", city: nil)

        XCTAssertTrue(results.contains { $0.zipCode == "100" }, "結果應包含郵遞區號 100")
        for record in results {
            XCTAssertTrue(record.searchIndex.contains("10"), "每筆結果都應包含「10」：\(record.id)")
        }
    }

    // MARK: - Scenario: 以英文名稱查詢且大小寫不敏感

    /// 英文關鍵字的大小寫不應影響結果。
    func testSearchByEnglishNameIsCaseInsensitive() {
        let lowercase = ZipCodeQuery.search(records: realRecords, keyword: "taipei", city: nil)
        let uppercase = ZipCodeQuery.search(records: realRecords, keyword: "TAIPEI", city: nil)
        let mixedCase = ZipCodeQuery.search(records: realRecords, keyword: "TaiPei", city: nil)

        XCTAssertFalse(lowercase.isEmpty, "「taipei」應命中資料")
        XCTAssertEqual(lowercase.map(\.id), uppercase.map(\.id), "大小寫不應影響結果")
        XCTAssertEqual(lowercase.map(\.id), mixedCase.map(\.id), "大小寫混用不應影響結果")
        XCTAssertTrue(
            lowercase.contains { $0.cityEnglish == "Taipei City" },
            "結果應包含縣市英文名為 Taipei City 的紀錄"
        )
    }

    /// 以行政區英文名查詢應命中對應紀錄。
    func testSearchByDistrictEnglishName() {
        let results = ZipCodeQuery.search(records: sample, keyword: "zhongzheng", city: nil)

        XCTAssertEqual(results.count, 2, "樣本中有兩個 Zhongzheng Dist.")
        XCTAssertEqual(results.map(\.zipCode), ["100", "202"], "應依郵遞區號排序")
    }

    // MARK: - Scenario: 關鍵字含前後空白

    /// 關鍵字前後空白應被忽略。
    func testKeywordWhitespaceIsTrimmed() {
        let padded = ZipCodeQuery.search(records: realRecords, keyword: "  中正  ", city: nil)
        let plain = ZipCodeQuery.search(records: realRecords, keyword: "中正", city: nil)

        XCTAssertFalse(plain.isEmpty, "「中正」應命中資料")
        XCTAssertEqual(padded.map(\.id), plain.map(\.id), "前後空白不應影響結果")
    }

    // MARK: - Scenario: 空關鍵字

    /// 空字串或純空白關鍵字應回傳全部紀錄。
    func testEmptyKeywordReturnsAllRecords() {
        let empty = ZipCodeQuery.search(records: realRecords, keyword: "", city: nil)
        let blank = ZipCodeQuery.search(records: realRecords, keyword: "   ", city: nil)
        let newline = ZipCodeQuery.search(records: realRecords, keyword: "\n\t", city: nil)

        XCTAssertEqual(empty.count, realRecords.count, "空關鍵字應回傳全部紀錄")
        XCTAssertEqual(blank.count, realRecords.count, "純空白關鍵字應回傳全部紀錄")
        XCTAssertEqual(newline.count, realRecords.count, "換行與定位字元也應視為空關鍵字")
    }

    /// `filter` 在無任何條件時應原樣回傳輸入。
    func testFilterWithoutConditionsReturnsInputUnchanged() {
        let results = ZipCodeQuery.filter(records: sample, keyword: "", city: nil)
        XCTAssertEqual(results.map(\.id), sample.map(\.id), "無條件時應保留輸入順序")
    }

    // MARK: - Scenario: 查無結果

    /// 不存在的關鍵字應回傳空集合且不拋錯。
    func testUnmatchedKeywordReturnsEmptyResult() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "不存在的地名ZZZ", city: nil)
        XCTAssertTrue(results.isEmpty, "查無結果應回傳空集合")
    }

    // MARK: - Scenario: 僅套用縣市篩選

    /// 只指定縣市時，結果應全屬該縣市且數量正確。
    func testCityFilterOnly() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "", city: "高雄市")
        let expectedCount = realRecords.filter { $0.city == "高雄市" }.count

        XCTAssertEqual(results.count, expectedCount, "數量應等於該縣市的行政區數")
        XCTAssertEqual(results.count, 40, "高雄市應有 40 個行政區")
        XCTAssertTrue(results.allSatisfy { $0.city == "高雄市" }, "結果應全屬高雄市")
    }

    // MARK: - Scenario: 縣市與關鍵字同時套用

    /// 縣市與關鍵字為 AND 關係。
    func testCityAndKeywordAreCombinedWithAnd() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "區", city: "臺北市")

        XCTAssertFalse(results.isEmpty, "臺北市含「區」的紀錄不應為空")
        XCTAssertTrue(results.allSatisfy { $0.city == "臺北市" }, "結果不應包含其他縣市")
        XCTAssertTrue(results.allSatisfy { $0.searchIndex.contains("區") }, "結果都應包含關鍵字")
    }

    /// 縣市與關鍵字互斥時應回傳空集合。
    func testCityAndKeywordWithNoOverlapReturnsEmpty() {
        let results = ZipCodeQuery.search(records: sample, keyword: "新興", city: "臺北市")
        XCTAssertTrue(results.isEmpty, "臺北市沒有新興區，應回傳空集合")
    }

    // MARK: - Scenario: 不限縣市

    /// 縣市為 nil 時查詢範圍應涵蓋全部縣市。
    func testNilCityCoversAllCities() {
        let results = ZipCodeQuery.search(records: sample, keyword: "中正", city: nil)
        XCTAssertEqual(Set(results.map(\.city)), ["臺北市", "基隆市"], "應同時涵蓋不同縣市")
    }

    // MARK: - Scenario: 結果依郵遞區號遞增

    /// 排序後每筆的郵遞區號不應小於前一筆。
    func testResultsAreSortedByAscendingZipCode() {
        let results = ZipCodeQuery.search(records: realRecords, keyword: "", city: nil)

        XCTAssertGreaterThan(results.count, 1)
        for (previous, current) in zip(results, results.dropFirst()) {
            XCTAssertLessThanOrEqual(
                previous.zipCode, current.zipCode,
                "郵遞區號應遞增：\(previous.zipCode) 出現在 \(current.zipCode) 之前"
            )
        }
    }

    /// 相同郵遞區號時應以縣市、行政區作為次要排序鍵。
    ///
    /// 這裡刻意使用 `AA` / `AB` 這類 ASCII 名稱，讓排序期望值不依賴
    /// 中文字元的 Unicode 順序，測試才不會因為地名用字不同而失效。
    func testSortUsesCityAndDistrictAsTiebreaker() {
        let duplicated = [
            ZipCodeRecord(zipCode: "500", city: "AB市", cityEnglish: "AB City",
                          district: "B區", districtEnglish: "B Dist."),
            ZipCodeRecord(zipCode: "500", city: "AA市", cityEnglish: "AA City",
                          district: "B區", districtEnglish: "B Dist."),
            ZipCodeRecord(zipCode: "500", city: "AA市", cityEnglish: "AA City",
                          district: "A區", districtEnglish: "A Dist.")
        ]

        let sorted = ZipCodeQuery.sorted(duplicated)

        XCTAssertEqual(sorted.map(\.id), ["500-AA市-A區", "500-AA市-B區", "500-AB市-B區"],
                       "同區號時應先比縣市再比行政區")
    }

    /// 郵遞區號的排序應優先於縣市與行政區。
    func testZipCodeIsPrimarySortKey() {
        let records = [
            ZipCodeRecord(zipCode: "900", city: "AA市", cityEnglish: "AA City",
                          district: "A區", districtEnglish: "A Dist."),
            ZipCodeRecord(zipCode: "100", city: "ZZ市", cityEnglish: "ZZ City",
                          district: "Z區", districtEnglish: "Z Dist.")
        ]

        let sorted = ZipCodeQuery.sorted(records)

        XCTAssertEqual(sorted.map(\.zipCode), ["100", "900"], "郵遞區號應為主要排序鍵")
    }

    // MARK: - Scenario: 排序具備決定性

    /// 相同條件連續查詢兩次，順序應完全一致。
    func testSortingIsDeterministic() {
        let first = ZipCodeQuery.search(records: realRecords, keyword: "區", city: nil)
        let second = ZipCodeQuery.search(records: realRecords, keyword: "區", city: nil)

        XCTAssertEqual(first.map(\.id), second.map(\.id), "相同條件的結果順序應一致")

        // 輸入順序被打亂後，排序結果仍應相同
        let shuffled = ZipCodeQuery.search(records: realRecords.shuffled(), keyword: "區", city: nil)
        XCTAssertEqual(first.map(\.id), shuffled.map(\.id), "輸入順序不應影響排序結果")
    }

    // MARK: - normalize

    /// 關鍵字正規化應去除空白並轉小寫。
    func testNormalizeTrimsAndLowercases() {
        XCTAssertEqual(ZipCodeQuery.normalize("  TaiPei \n"), "taipei")
        XCTAssertEqual(ZipCodeQuery.normalize("   "), "")
        XCTAssertEqual(ZipCodeQuery.normalize("中正區"), "中正區")
    }
}
