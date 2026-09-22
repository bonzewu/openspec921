//
//  PasteboardServiceTests.swift
//  TaiwanZipLookupTests
//
//  驗證 capability: macos-app-ui 中「複製到剪貼簿」的需求。
//

import XCTest
@testable import TaiwanZipLookup

/// 測試用的假剪貼簿。
///
/// 紀錄所有寫入內容，避免測試污染使用者真正的剪貼簿。
final class SpyPasteboard: PasteboardWriting {

    /// 依序記錄每次寫入的字串。
    private(set) var writtenStrings: [String] = []

    /// 控制 `write(_:)` 的回傳值，用於模擬寫入失敗。
    var writeResult = true

    /// 最後一次寫入的字串。
    var lastWritten: String? { writtenStrings.last }

    @discardableResult
    func write(_ string: String) -> Bool {
        writtenStrings.append(string)
        return writeResult
    }
}

/// 複製服務的測試。
final class PasteboardServiceTests: XCTestCase {

    private var spy: SpyPasteboard!
    private var service: PasteboardService!

    /// 測試用紀錄：臺北市中正區。
    private let record = ZipCodeRecord(
        zipCode: "100",
        city: "臺北市",
        cityEnglish: "Taipei City",
        district: "中正區",
        districtEnglish: "Zhongzheng Dist."
    )

    override func setUp() {
        super.setUp()
        spy = SpyPasteboard()
        service = PasteboardService(pasteboard: spy)
    }

    override func tearDown() {
        spy = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Scenario: 複製郵遞區號

    /// 「複製郵遞區號」應只寫入 3 碼數字。
    func testCopyZipCodeWritesOnlyTheZipCode() {
        let success = service.copyZipCode(of: record)

        XCTAssertTrue(success, "複製應回報成功")
        XCTAssertEqual(spy.writtenStrings.count, 1, "應只寫入一次")
        XCTAssertEqual(spy.lastWritten, "100", "剪貼簿內容應為 3 碼郵遞區號")
    }

    // MARK: - Scenario: 複製完整地址前綴

    /// 「複製完整地址」應寫入「區號 縣市行政區」格式。
    func testCopyFullAddressWritesZipCodeAndAddressPrefix() {
        let success = service.copyFullAddress(of: record)

        XCTAssertTrue(success, "複製應回報成功")
        XCTAssertEqual(spy.lastWritten, "100 臺北市中正區", "剪貼簿內容應為「100 臺北市中正區」")
    }

    /// 寫入失敗時應如實回報 false。
    func testCopyReportsFailureWhenPasteboardWriteFails() {
        spy.writeResult = false

        XCTAssertFalse(service.copyZipCode(of: record), "底層寫入失敗時應回傳 false")
        XCTAssertFalse(service.copyFullAddress(of: record), "底層寫入失敗時應回傳 false")
    }

    /// 連續複製應依序覆寫，且每次都寫入對應內容。
    func testConsecutiveCopiesRecordEachWrite() {
        service.copyZipCode(of: record)
        service.copyFullAddress(of: record)

        XCTAssertEqual(spy.writtenStrings, ["100", "100 臺北市中正區"], "應依呼叫順序寫入")
    }
}
