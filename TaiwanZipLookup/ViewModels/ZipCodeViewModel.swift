//
//  ZipCodeViewModel.swift
//  TaiwanZipLookup
//
//  介面狀態管理：持有查詢條件，把查詢工作委派給 ZipCodeQuery。
//

import Foundation
import SwiftUI
import os

/// 郵遞區號查詢畫面的狀態容器。
///
/// 本型別只負責「保存使用者輸入的條件」與「對外揭露查詢結果」，
/// 真正的過濾與排序邏輯一律委派給無狀態的 ``ZipCodeQuery``，
/// 讓查詢行為可以獨立於 UI 被測試。
@MainActor
final class ZipCodeViewModel: ObservableObject {

    /// 代表「全部縣市」的選項值。
    ///
    /// `Picker` 需要一個非 `nil` 的可雜湊 tag，因此以空字串代表不限縣市。
    static let allCitiesTag = ""

    /// 使用者輸入的搜尋關鍵字。
    @Published var keyword: String = ""

    /// 使用者選擇的縣市；空字串代表不限縣市。
    @Published var selectedCityTag: String = ZipCodeViewModel.allCitiesTag

    /// 複製成功後短暫顯示的提示文字；`nil` 代表不顯示。
    @Published private(set) var copiedNotice: String?

    /// 完整的郵遞區號資料集。
    @Published private(set) var allRecords: [ZipCodeRecord] = []

    /// 資料集中出現的縣市清單（保留原始順序）。
    @Published private(set) var cities: [String] = []

    /// 資料載入失敗時的錯誤描述；`nil` 代表載入正常。
    @Published private(set) var loadErrorMessage: String?

    /// 複製服務。
    private let pasteboardService: PasteboardService

    /// 讀取內建資料集的來源 bundle。
    private let bundle: Bundle

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.bonzewu.TaiwanZipLookup",
        category: "ZipCodeViewModel"
    )

    /// 提示文字自動消失前停留的秒數。
    private let noticeDuration: Duration = .seconds(2)

    /// 目前正在等待清除提示的任務；有新的複製動作時會被取消。
    private var noticeDismissTask: Task<Void, Never>?

    /// 建立 ViewModel。
    ///
    /// - Parameters:
    ///   - pasteboardService: 複製服務，測試時可注入假的剪貼簿。
    ///   - bundle: 資料集來源 bundle，預設為主 bundle。
    ///   - loadsImmediately: 是否在初始化時立即載入資料，預設為 `true`。
    init(
        pasteboardService: PasteboardService = PasteboardService(),
        bundle: Bundle = .main,
        loadsImmediately: Bool = true
    ) {
        self.pasteboardService = pasteboardService
        self.bundle = bundle
        if loadsImmediately {
            loadData()
        }
    }

    /// 目前選擇的縣市；空字串（全部縣市）會轉換為 `nil`。
    var selectedCity: String? {
        selectedCityTag == Self.allCitiesTag ? nil : selectedCityTag
    }

    /// 套用目前查詢條件後的結果。
    ///
    /// 資料量僅數百筆，每次重算的成本遠低於維護快取的複雜度，
    /// 因此刻意以計算屬性呈現，保證畫面永遠與條件一致。
    var results: [ZipCodeRecord] {
        ZipCodeQuery.search(records: allRecords, keyword: keyword, city: selectedCity)
    }

    /// 是否處於「有查詢條件卻查無結果」的狀態。
    var isShowingEmptyResult: Bool {
        loadErrorMessage == nil && results.isEmpty
    }

    /// 是否已套用任何查詢條件。
    var hasActiveFilter: Bool {
        !ZipCodeQuery.normalize(keyword).isEmpty || selectedCity != nil
    }

    /// 載入內建郵遞區號資料集。
    ///
    /// 失敗時不會讓程式崩潰，而是把錯誤描述寫入 ``loadErrorMessage``
    /// 供畫面顯示，同時寫入日誌。
    func loadData() {
        do {
            let records = try ZipCodeRepository.loadRecords(from: bundle)
            allRecords = records
            cities = ZipCodeRepository.cities(from: records)
            loadErrorMessage = nil
        } catch {
            allRecords = []
            cities = []
            loadErrorMessage = error.localizedDescription
            logger.error("郵遞區號資料載入失敗：\(error.localizedDescription, privacy: .public)")
        }
    }

    /// 清除所有查詢條件。
    func clearFilters() {
        keyword = ""
        selectedCityTag = Self.allCitiesTag
    }

    /// 複製指定紀錄的郵遞區號。
    ///
    /// - Parameter record: 目標紀錄。
    func copyZipCode(of record: ZipCodeRecord) {
        guard pasteboardService.copyZipCode(of: record) else {
            showNotice("複製失敗，請再試一次")
            return
        }
        showNotice("已複製郵遞區號 \(record.zipCode)")
    }

    /// 複製指定紀錄的完整地址前綴。
    ///
    /// - Parameter record: 目標紀錄。
    func copyFullAddress(of record: ZipCodeRecord) {
        guard pasteboardService.copyFullAddress(of: record) else {
            showNotice("複製失敗，請再試一次")
            return
        }
        showNotice("已複製「\(record.fullAddressPrefix)」")
    }

    /// 顯示提示文字，並在停留時間後自動清除。
    ///
    /// - Parameter message: 要顯示的文字。
    func showNotice(_ message: String) {
        copiedNotice = message
        noticeDismissTask?.cancel()
        noticeDismissTask = Task { [weak self, duration = noticeDuration] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.copiedNotice = nil }
        }
    }
}
