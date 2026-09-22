//
//  ZipCodeQuery.swift
//  TaiwanZipLookup
//
//  郵遞區號查詢邏輯，全部以無狀態的純函式實作。
//

import Foundation

/// 郵遞區號查詢邏輯。
///
/// 這裡的每一個函式都是純函式：相同輸入必定得到相同輸出，
/// 沒有任何隱含狀態或副作用，因此可以完全脫離 UI 進行單元測試。
enum ZipCodeQuery {

    /// 依關鍵字與縣市條件過濾並排序郵遞區號紀錄。
    ///
    /// 這是介面層唯一需要呼叫的入口：先過濾、再排序。
    ///
    /// - Parameters:
    ///   - records: 要查詢的完整紀錄集合。
    ///   - keyword: 關鍵字；前後空白會被忽略，空字串代表不過濾。
    ///   - city: 指定縣市；`nil` 代表不限縣市。
    /// - Returns: 符合條件且已排序的紀錄。
    static func search(
        records: [ZipCodeRecord],
        keyword: String,
        city: String?
    ) -> [ZipCodeRecord] {
        sorted(filter(records: records, keyword: keyword, city: city))
    }

    /// 依關鍵字與縣市條件過濾紀錄（不排序）。
    ///
    /// 關鍵字會比對郵遞區號、縣市中英文名與行政區中英文名；
    /// 由於比對的是預先小寫化的 ``ZipCodeRecord/searchIndex``，
    /// 英文比對天然為大小寫不敏感。
    ///
    /// 關鍵字與縣市為 AND 關係：兩者同時指定時必須都滿足。
    ///
    /// - Parameters:
    ///   - records: 要查詢的完整紀錄集合。
    ///   - keyword: 關鍵字；前後空白會被忽略，空字串或純空白代表不過濾。
    ///   - city: 指定縣市；`nil` 代表不限縣市。
    /// - Returns: 符合條件的紀錄，順序與輸入一致。
    static func filter(
        records: [ZipCodeRecord],
        keyword: String,
        city: String?
    ) -> [ZipCodeRecord] {
        let normalizedKeyword = normalize(keyword)

        // 兩個條件都不存在時直接回傳原集合，省去不必要的走訪。
        guard !normalizedKeyword.isEmpty || city != nil else { return records }

        return records.filter { record in
            matchesCity(record, city: city) && matchesKeyword(record, keyword: normalizedKeyword)
        }
    }

    /// 以決定性的規則排序紀錄。
    ///
    /// 排序鍵依序為：郵遞區號（遞增）→ 縣市名 → 行政區名。
    /// 因為郵遞區號皆為 3 位數字，字串比較的結果等同數值比較。
    /// 第二、三層排序鍵確保相同區號的紀錄順序固定，
    /// 使同樣的查詢條件永遠得到相同的結果順序。
    ///
    /// - Parameter records: 要排序的紀錄。
    /// - Returns: 排序後的新陣列。
    static func sorted(_ records: [ZipCodeRecord]) -> [ZipCodeRecord] {
        records.sorted { lhs, rhs in
            if lhs.zipCode != rhs.zipCode { return lhs.zipCode < rhs.zipCode }
            if lhs.city != rhs.city { return lhs.city < rhs.city }
            return lhs.district < rhs.district
        }
    }

    /// 正規化關鍵字：去除前後空白並轉為小寫。
    ///
    /// - Parameter keyword: 使用者輸入的原始關鍵字。
    /// - Returns: 可直接用於比對的關鍵字。
    static func normalize(_ keyword: String) -> String {
        keyword
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// 判斷紀錄是否屬於指定縣市；未指定縣市時一律視為符合。
    private static func matchesCity(_ record: ZipCodeRecord, city: String?) -> Bool {
        guard let city else { return true }
        return record.city == city
    }

    /// 判斷紀錄是否包含關鍵字；關鍵字為空時一律視為符合。
    private static func matchesKeyword(_ record: ZipCodeRecord, keyword: String) -> Bool {
        guard !keyword.isEmpty else { return true }
        return record.searchIndex.contains(keyword)
    }
}
