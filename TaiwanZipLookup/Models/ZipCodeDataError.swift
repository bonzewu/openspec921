//
//  ZipCodeDataError.swift
//  TaiwanZipLookup
//
//  郵遞區號資料載入過程可能發生的錯誤。
//

import Foundation

/// 郵遞區號資料載入失敗的原因。
///
/// 刻意採用列舉而非泛用的 `NSError`，讓呼叫端能以 `switch`
/// 完整處理每一種失敗情境，並且在測試中可精確斷言錯誤類型。
enum ZipCodeDataError: Error, Equatable {

    /// 在 bundle 中找不到指定的資料檔。
    ///
    /// - Parameter name: 所查找的檔名（含副檔名）。
    case resourceNotFound(name: String)

    /// 資料檔存在但內容無法解析成預期結構。
    ///
    /// - Parameter description: 底層解碼錯誤的描述，保留以便寫入日誌。
    case decodingFailed(description: String)
}

extension ZipCodeDataError: LocalizedError {

    /// 可直接顯示給使用者的繁體中文錯誤描述。
    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "找不到郵遞區號資料檔「\(name)」，請確認資料檔已加入 App 資源。"
        case .decodingFailed(let description):
            return "郵遞區號資料檔解碼失敗：\(description)"
        }
    }

    /// 建議的處理方式。
    var recoverySuggestion: String? {
        switch self {
        case .resourceNotFound:
            return "請重新安裝 App，或確認 zipcodes.json 已包含在 Resources 中。"
        case .decodingFailed:
            return "請確認資料檔為合法 JSON，且每筆紀錄包含 zipCode、city、cityEnglish、district、districtEnglish 欄位。"
        }
    }
}
