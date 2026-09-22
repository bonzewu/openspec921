//
//  TaiwanZipLookupApp.swift
//  TaiwanZipLookup
//
//  App 進入點。
//

import SwiftUI

/// 臺灣郵遞區號查詢 App。
///
/// 單一視窗的桌面工具：啟動後即載入內建資料集，
/// 全程不需網路連線。
@main
struct TaiwanZipLookupApp: App {

    /// 全 App 共用的查詢狀態。
    @StateObject private var viewModel = ZipCodeViewModel()

    var body: some Scene {
        WindowGroup("臺灣郵遞區號查詢") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 620, minHeight: 420)
        }
        .defaultSize(width: 760, height: 620)
        .windowToolbarStyle(.unified)
        .commands {
            // 移除預設的「新增視窗」指令：本 App 只需要單一視窗。
            CommandGroup(replacing: .newItem) {}
        }
    }
}
