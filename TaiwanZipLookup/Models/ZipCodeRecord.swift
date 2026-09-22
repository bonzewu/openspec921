//
//  ZipCodeRecord.swift
//  TaiwanZipLookup
//
//  郵遞區號紀錄的資料模型。
//

import Foundation

/// 單筆臺灣 3 碼郵遞區號紀錄。
///
/// 這是一個不可變（immutable）的值型別：所有屬性皆為 `let`，
/// 建立後不會再被修改，因此可安全地在多個執行緒之間傳遞。
///
/// 為了讓即時搜尋不必在每次按鍵時重複做字串小寫化，
/// 初始化時會一次性把所有可搜尋欄位合併成 `searchIndex`（全小寫），
/// 查詢階段只需對這個欄位做一次 `contains` 比對。
struct ZipCodeRecord: Codable, Identifiable, Hashable {

    /// 3 碼郵遞區號，例如 `"100"`。
    let zipCode: String

    /// 縣市中文名稱，例如 `"臺北市"`。
    let city: String

    /// 縣市英文名稱，例如 `"Taipei City"`。
    let cityEnglish: String

    /// 鄉鎮市區中文名稱，例如 `"中正區"`。
    let district: String

    /// 鄉鎮市區英文名稱，例如 `"Zhongzheng Dist."`。
    let districtEnglish: String

    /// 預先計算的小寫搜尋索引，包含全部可搜尋欄位。
    ///
    /// 不會被編碼進 JSON，也不參與相等性比較以外的邏輯。
    let searchIndex: String

    /// 穩定且唯一的識別值。
    ///
    /// 以「郵遞區號＋縣市＋行政區」組成；同一個郵遞區號可能對應多個
    /// 行政區（例如共用區號的情況），因此不能只用 `zipCode` 當識別值。
    var id: String { "\(zipCode)-\(city)-\(district)" }

    /// 「郵遞區號 + 完整地址前綴」格式的字串，例如 `"100 臺北市中正區"`。
    ///
    /// 提供給「複製完整地址」功能使用。
    var fullAddressPrefix: String { "\(zipCode) \(city)\(district)" }

    /// 中文顯示名稱，例如 `"臺北市中正區"`。
    var localizedName: String { "\(city)\(district)" }

    /// 英文顯示名稱，例如 `"Zhongzheng Dist., Taipei City"`。
    var englishName: String { "\(districtEnglish), \(cityEnglish)" }

    /// JSON 中實際存在的欄位；`searchIndex` 為衍生欄位，故不列入。
    private enum CodingKeys: String, CodingKey {
        case zipCode
        case city
        case cityEnglish
        case district
        case districtEnglish
    }

    /// 以各欄位建立紀錄，並同時計算搜尋索引。
    ///
    /// - Parameters:
    ///   - zipCode: 3 碼郵遞區號。
    ///   - city: 縣市中文名稱。
    ///   - cityEnglish: 縣市英文名稱。
    ///   - district: 鄉鎮市區中文名稱。
    ///   - districtEnglish: 鄉鎮市區英文名稱。
    init(
        zipCode: String,
        city: String,
        cityEnglish: String,
        district: String,
        districtEnglish: String
    ) {
        self.zipCode = zipCode
        self.city = city
        self.cityEnglish = cityEnglish
        self.district = district
        self.districtEnglish = districtEnglish
        self.searchIndex = Self.makeSearchIndex(
            zipCode: zipCode,
            city: city,
            cityEnglish: cityEnglish,
            district: district,
            districtEnglish: districtEnglish
        )
    }

    /// 由 JSON 解碼；解碼後同樣會補上衍生的搜尋索引。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            zipCode: try container.decode(String.self, forKey: .zipCode),
            city: try container.decode(String.self, forKey: .city),
            cityEnglish: try container.decode(String.self, forKey: .cityEnglish),
            district: try container.decode(String.self, forKey: .district),
            districtEnglish: try container.decode(String.self, forKey: .districtEnglish)
        )
    }

    /// 把所有可搜尋欄位串接成單一小寫字串。
    ///
    /// 中文字元不受 `lowercased()` 影響，英文則統一為小寫，
    /// 使後續查詢天然具備大小寫不敏感的特性。
    private static func makeSearchIndex(
        zipCode: String,
        city: String,
        cityEnglish: String,
        district: String,
        districtEnglish: String
    ) -> String {
        [zipCode, city, cityEnglish, district, districtEnglish]
            .joined(separator: " ")
            .lowercased()
    }
}
