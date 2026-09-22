//
//  ZipCodeRepositoryTests.swift
//  TaiwanZipLookupTests
//
//  驗證 capability: zipcode-data 的需求。
//

import XCTest
@testable import TaiwanZipLookup

/// 郵遞區號資料載入與索引的測試。
final class ZipCodeRepositoryTests: XCTestCase {

    /// 資料集中預期的紀錄總數（374 個行政區）。
    ///
    /// 若資料檔更新，此常數需同步調整——這是刻意的設計，
    /// 讓資料變動一定會被測試攔下來檢視。
    private static let expectedRecordCount = 374

    /// 資料集中預期的縣市總數。
    private static let expectedCityCount = 24

    /// 測試用的資料集（整個測試類別共用一次載入結果）。
    private var records: [ZipCodeRecord] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        records = try ZipCodeRepository.loadRecords(from: .main)
    }

    // MARK: - Scenario: 由 bundle 載入資料集

    /// 應能從 bundle 成功載入，且筆數符合資料集大小。
    func testLoadRecordsFromBundleReturnsExpectedCount() throws {
        XCTAssertEqual(records.count, Self.expectedRecordCount, "載入筆數應等於資料集的行政區總數")
    }

    // MARK: - Scenario: 紀錄具備完整欄位

    /// 每筆紀錄的郵遞區號應為 3 位數字，且中文欄位皆非空。
    func testEveryRecordHasWellFormedFields() throws {
        for record in records {
            XCTAssertEqual(record.zipCode.count, 3, "郵遞區號應為 3 碼：\(record.id)")
            XCTAssertTrue(
                record.zipCode.allSatisfy(\.isNumber),
                "郵遞區號應僅包含數字：\(record.zipCode)"
            )
            XCTAssertFalse(record.city.trimmingCharacters(in: .whitespaces).isEmpty, "縣市名稱不應為空")
            XCTAssertFalse(record.district.trimmingCharacters(in: .whitespaces).isEmpty, "行政區名稱不應為空")
            XCTAssertFalse(record.cityEnglish.isEmpty, "縣市英文名稱不應為空")
            XCTAssertFalse(record.districtEnglish.isEmpty, "行政區英文名稱不應為空")
        }
    }

    // MARK: - Scenario: 識別值唯一

    /// 所有紀錄的識別值應互不重複。
    func testAllRecordIdentifiersAreUnique() throws {
        let identifiers = Set(records.map(\.id))
        XCTAssertEqual(identifiers.count, records.count, "識別值應唯一，不得重複")
    }

    /// 搜尋索引應為小寫，且包含所有可搜尋欄位。
    func testSearchIndexIsLowercasedAndComplete() throws {
        let record = ZipCodeRecord(
            zipCode: "100",
            city: "臺北市",
            cityEnglish: "Taipei City",
            district: "中正區",
            districtEnglish: "Zhongzheng Dist."
        )
        XCTAssertEqual(record.searchIndex, record.searchIndex.lowercased(), "搜尋索引應全為小寫")
        XCTAssertTrue(record.searchIndex.contains("100"))
        XCTAssertTrue(record.searchIndex.contains("臺北市"))
        XCTAssertTrue(record.searchIndex.contains("taipei city"))
        XCTAssertTrue(record.searchIndex.contains("中正區"))
        XCTAssertTrue(record.searchIndex.contains("zhongzheng dist."))
    }

    /// 衍生的顯示字串應符合預期格式。
    func testDerivedDisplayStrings() throws {
        let record = ZipCodeRecord(
            zipCode: "100",
            city: "臺北市",
            cityEnglish: "Taipei City",
            district: "中正區",
            districtEnglish: "Zhongzheng Dist."
        )
        XCTAssertEqual(record.fullAddressPrefix, "100 臺北市中正區")
        XCTAssertEqual(record.localizedName, "臺北市中正區")
        XCTAssertEqual(record.englishName, "Zhongzheng Dist., Taipei City")
        XCTAssertEqual(record.id, "100-臺北市-中正區")
    }

    // MARK: - Scenario: 取得縣市清單

    /// 縣市清單應不重複、數量正確，且保留首次出現順序。
    func testCitiesAreUniqueAndPreserveFirstAppearanceOrder() throws {
        let cities = ZipCodeRepository.cities(from: records)

        XCTAssertEqual(cities.count, Self.expectedCityCount, "應有 24 個縣市")
        XCTAssertEqual(Set(cities).count, cities.count, "縣市清單不應重複")
        XCTAssertEqual(cities.first, "臺北市", "第一個縣市應為資料集中首次出現的臺北市")

        // 清單順序應等於「依資料集首次出現順序」推導的結果
        var expected: [String] = []
        for record in records where !expected.contains(record.city) {
            expected.append(record.city)
        }
        XCTAssertEqual(cities, expected, "縣市順序應保留首次出現順序")
    }

    /// 每個縣市都應至少對應一筆紀錄。
    func testEveryCityHasAtLeastOneRecord() throws {
        let cities = ZipCodeRepository.cities(from: records)
        for city in cities {
            let count = records.filter { $0.city == city }.count
            XCTAssertGreaterThan(count, 0, "縣市 \(city) 應至少有一個行政區")
        }
    }

    /// 已知的代表性資料應存在且正確。
    func testKnownRecordsExist() throws {
        let lookup = Dictionary(grouping: records, by: \.id)

        XCTAssertNotNil(lookup["100-臺北市-中正區"], "臺北市中正區應為 100")
        XCTAssertNotNil(lookup["106-臺北市-大安區"], "臺北市大安區應為 106")
        XCTAssertNotNil(lookup["800-高雄市-新興區"], "高雄市新興區應為 800")
        XCTAssertNotNil(lookup["300-新竹市-東區"], "新竹市東區應為 300")
    }

    // MARK: - Scenario: 資料檔不存在 / 格式錯誤

    /// 找不到資源時應回傳 resourceNotFound，且訊息包含檔名。
    func testLoadRecordsWithMissingResourceThrowsResourceNotFound() {
        do {
            _ = try ZipCodeRepository.loadRecords(from: .main, resourceName: "不存在的資料檔")
            XCTFail("應拋出 resourceNotFound 錯誤")
        } catch let error as ZipCodeDataError {
            XCTAssertEqual(error, .resourceNotFound(name: "不存在的資料檔.json"))
            let description = error.errorDescription ?? ""
            XCTAssertTrue(description.contains("不存在的資料檔.json"), "錯誤描述應包含所查找的檔名")
        } catch {
            XCTFail("錯誤型別應為 ZipCodeDataError，實際為 \(error)")
        }
    }

    /// JSON 結構錯誤時應回傳 decodingFailed，並保留底層描述。
    func testDecodeRecordsWithMalformedJSONThrowsDecodingFailed() {
        let malformed = Data("{ 這不是合法的 JSON".utf8)
        do {
            _ = try ZipCodeRepository.decodeRecords(from: malformed)
            XCTFail("應拋出 decodingFailed 錯誤")
        } catch let error as ZipCodeDataError {
            guard case .decodingFailed(let description) = error else {
                return XCTFail("錯誤應為 decodingFailed，實際為 \(error)")
            }
            XCTAssertFalse(description.isEmpty, "應保留底層解碼錯誤描述")
        } catch {
            XCTFail("錯誤型別應為 ZipCodeDataError，實際為 \(error)")
        }
    }

    /// 欄位缺失時同樣應回傳 decodingFailed。
    func testDecodeRecordsWithMissingFieldThrowsDecodingFailed() {
        let missingField = Data(#"[{"zipCode":"100","city":"臺北市"}]"#.utf8)
        XCTAssertThrowsError(try ZipCodeRepository.decodeRecords(from: missingField)) { error in
            guard case ZipCodeDataError.decodingFailed = error else {
                return XCTFail("錯誤應為 decodingFailed，實際為 \(error)")
            }
        }
    }

    /// 合法 JSON 應能正確解碼，且自動補上搜尋索引。
    func testDecodeRecordsWithValidJSONSucceeds() throws {
        let json = Data("""
        [
          {
            "zipCode": "100",
            "city": "臺北市",
            "cityEnglish": "Taipei City",
            "district": "中正區",
            "districtEnglish": "Zhongzheng Dist."
          }
        ]
        """.utf8)

        let decoded = try ZipCodeRepository.decodeRecords(from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.zipCode, "100")
        XCTAssertEqual(decoded.first?.searchIndex.contains("taipei city"), true, "解碼後應補上搜尋索引")
    }
}
