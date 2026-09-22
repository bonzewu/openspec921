//
//  ZipCodeRepository.swift
//  TaiwanZipLookup
//
//  負責從 App bundle 載入內建的郵遞區號資料集。
//

import Foundation
import os

/// 郵遞區號資料的載入器。
///
/// 全部方法皆為靜態純函式（除了寫入日誌的副作用），
/// 不持有任何狀態，因此可安全地在任何情境呼叫與測試。
enum ZipCodeRepository {

    /// 內建資料檔的檔名（不含副檔名）。
    static let defaultResourceName = "zipcodes"

    /// 內建資料檔的副檔名。
    static let defaultResourceExtension = "json"

    /// 本模組的日誌記錄器。
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.bonzewu.TaiwanZipLookup",
        category: "ZipCodeRepository"
    )

    /// 從指定 bundle 載入並解碼全部郵遞區號紀錄。
    ///
    /// - Parameters:
    ///   - bundle: 要查找資料檔的 bundle，預設為 App 主 bundle。
    ///   - resourceName: 資料檔名稱（不含副檔名），預設為 `zipcodes`。
    ///   - resourceExtension: 資料檔副檔名，預設為 `json`。
    /// - Returns: 解碼後的郵遞區號紀錄陣列，順序與資料檔一致。
    /// - Throws: 載入或解碼失敗時拋出 ``ZipCodeDataError``。
    static func loadRecords(
        from bundle: Bundle = .main,
        resourceName: String = defaultResourceName,
        resourceExtension: String = defaultResourceExtension
    ) throws -> [ZipCodeRecord] {
        let fileName = "\(resourceName).\(resourceExtension)"

        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            logger.error("找不到郵遞區號資料檔：\(fileName, privacy: .public)")
            throw ZipCodeDataError.resourceNotFound(name: fileName)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            // 檔案存在於 bundle 索引中卻無法讀取，視為資料損毀。
            logger.error("讀取郵遞區號資料檔失敗：\(error.localizedDescription, privacy: .public)")
            throw ZipCodeDataError.decodingFailed(description: error.localizedDescription)
        }

        let records = try decodeRecords(from: data)
        logger.info("成功載入郵遞區號資料，共 \(records.count, privacy: .public) 筆")
        return records
    }

    /// 將 JSON 資料解碼為郵遞區號紀錄陣列。
    ///
    /// 獨立成公開函式，讓測試可以直接以任意 `Data` 驗證解碼行為，
    /// 不必真的在 bundle 中放入格式錯誤的檔案。
    ///
    /// - Parameter data: 預期為郵遞區號紀錄陣列的 JSON 資料。
    /// - Returns: 解碼後的紀錄陣列。
    /// - Throws: 解碼失敗時拋出 ``ZipCodeDataError/decodingFailed(description:)``。
    static func decodeRecords(from data: Data) throws -> [ZipCodeRecord] {
        do {
            return try JSONDecoder().decode([ZipCodeRecord].self, from: data)
        } catch {
            logger.error("郵遞區號資料解碼失敗：\(String(describing: error), privacy: .public)")
            throw ZipCodeDataError.decodingFailed(description: String(describing: error))
        }
    }

    /// 由紀錄陣列推導出不重複的縣市清單。
    ///
    /// 保留縣市在資料檔中首次出現的順序（而非重新排序），
    /// 讓下拉選單的順序與官方資料的排列一致、且每次啟動都相同。
    ///
    /// - Parameter records: 郵遞區號紀錄陣列。
    /// - Returns: 不重複的縣市名稱清單。
    static func cities(from records: [ZipCodeRecord]) -> [String] {
        records.reduce(into: [String]()) { result, record in
            if !result.contains(record.city) {
                result.append(record.city)
            }
        }
    }
}
