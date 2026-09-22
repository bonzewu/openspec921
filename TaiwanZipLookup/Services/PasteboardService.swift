//
//  PasteboardService.swift
//  TaiwanZipLookup
//
//  複製查詢結果到系統剪貼簿。
//

import AppKit
import Foundation
import os

/// 可寫入字串的剪貼簿抽象。
///
/// 抽成 protocol 的目的是讓單元測試能替換成假的實作，
/// 避免測試過程污染使用者真正的剪貼簿內容。
protocol PasteboardWriting {

    /// 以指定字串覆寫剪貼簿內容。
    ///
    /// - Parameter string: 要寫入的字串。
    /// - Returns: 寫入是否成功。
    @discardableResult
    func write(_ string: String) -> Bool
}

/// 使用系統 `NSPasteboard` 的正式實作。
struct SystemPasteboard: PasteboardWriting {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.bonzewu.TaiwanZipLookup",
        category: "SystemPasteboard"
    )

    @discardableResult
    func write(_ string: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(string, forType: .string)
        if success {
            logger.debug("已複製到剪貼簿：\(string, privacy: .public)")
        } else {
            logger.error("寫入剪貼簿失敗：\(string, privacy: .public)")
        }
        return success
    }
}

/// 針對郵遞區號紀錄提供的複製服務。
///
/// 負責決定「複製什麼內容」，實際寫入動作委派給 ``PasteboardWriting``。
struct PasteboardService {

    /// 底層剪貼簿實作。
    private let pasteboard: PasteboardWriting

    /// 建立複製服務。
    ///
    /// - Parameter pasteboard: 底層剪貼簿實作，預設使用系統剪貼簿。
    init(pasteboard: PasteboardWriting = SystemPasteboard()) {
        self.pasteboard = pasteboard
    }

    /// 僅複製 3 碼郵遞區號。
    ///
    /// - Parameter record: 目標紀錄。
    /// - Returns: 寫入是否成功。
    @discardableResult
    func copyZipCode(of record: ZipCodeRecord) -> Bool {
        pasteboard.write(record.zipCode)
    }

    /// 複製「郵遞區號 + 完整地址前綴」，例如 `100 臺北市中正區`。
    ///
    /// - Parameter record: 目標紀錄。
    /// - Returns: 寫入是否成功。
    @discardableResult
    func copyFullAddress(of record: ZipCodeRecord) -> Bool {
        pasteboard.write(record.fullAddressPrefix)
    }
}
