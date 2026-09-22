//
//  ContentView.swift
//  TaiwanZipLookup
//
//  主畫面：搜尋列、縣市篩選、結果清單。
//

import SwiftUI

/// 郵遞區號查詢主畫面。
struct ContentView: View {

    /// 查詢狀態。
    @ObservedObject var viewModel: ZipCodeViewModel

    /// 搜尋列是否取得鍵盤焦點。
    ///
    /// 啟動後主動把焦點交給搜尋列，使用者開窗即可直接打字查詢，
    /// 不必先用滑鼠點一下輸入框。
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            content
            Divider()
            statusBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { isSearchFieldFocused = true }
    }

    // MARK: - 搜尋列

    /// 關鍵字輸入框與縣市篩選器。
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("輸入郵遞區號、縣市或鄉鎮市區（可用英文）", text: $viewModel.keyword)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                if !viewModel.keyword.isEmpty {
                    Button {
                        viewModel.keyword = ""
                        isSearchFieldFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("清除關鍵字")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(nsColor: .separatorColor))
            )

            Picker("縣市", selection: $viewModel.selectedCityTag) {
                Text("全部縣市").tag(ZipCodeViewModel.allCitiesTag)
                Divider()
                ForEach(viewModel.cities, id: \.self) { city in
                    Text(city).tag(city)
                }
            }
            .labelsHidden()
            .frame(width: 140)
            .help("依縣市篩選")

            if viewModel.hasActiveFilter {
                Button("清除條件") {
                    viewModel.clearFilters()
                    isSearchFieldFocused = true
                }
                .help("清除關鍵字與縣市篩選")
            }
        }
        .padding(12)
    }

    // MARK: - 主要內容

    /// 依載入狀態與查詢結果顯示對應畫面。
    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.loadErrorMessage {
            errorState(message: errorMessage)
        } else if viewModel.results.isEmpty {
            emptyState
        } else {
            resultList
        }
    }

    /// 查詢結果清單。
    private var resultList: some View {
        List(viewModel.results) { record in
            ZipCodeRow(
                record: record,
                onCopyZipCode: { viewModel.copyZipCode(of: record) },
                onCopyFullAddress: { viewModel.copyFullAddress(of: record) }
            )
                .contextMenu {
                    Button("複製郵遞區號 \(record.zipCode)") {
                        viewModel.copyZipCode(of: record)
                    }
                    Button("複製完整地址「\(record.fullAddressPrefix)」") {
                        viewModel.copyFullAddress(of: record)
                    }
                }
        }
        // 刻意不使用 alternatesRowBackgrounds：結果筆數少時，
        // 交替底色會延伸到清單下方的空白區域，形成多餘的灰色長條。
        .listStyle(.inset)
    }

    /// 查無結果的空狀態。
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "mail.and.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("找不到符合的郵遞區號")
                .font(.headline)
            Text("請確認關鍵字，或把縣市篩選改回「全部縣市」。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if viewModel.hasActiveFilter {
                Button("清除查詢條件") {
                    viewModel.clearFilters()
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 資料載入失敗的錯誤畫面。
    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("郵遞區號資料載入失敗")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重新載入") {
                viewModel.loadData()
            }
            .padding(.top, 4)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 狀態列

    /// 顯示結果筆數與複製提示。
    private var statusBar: some View {
        HStack {
            Text("共 \(viewModel.results.count) 筆結果")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()

            // 提示採「常駐 view + 切換透明度」而非用 if 條件插入／移除：
            // 版面高度因此固定，提示出現與消失時狀態列不會跳動。
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(viewModel.copiedNotice ?? "")
            }
            .font(.callout)
            .opacity(viewModel.copiedNotice == nil ? 0 : 1)
            .accessibilityHidden(viewModel.copiedNotice == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: viewModel.copiedNotice)
    }
}

/// Xcode 畫布預覽。
///
/// 同時提供淺色與深色兩種外觀，方便在畫布上一次檢查兩種模式的可讀性。
/// 畫面本身只使用語意色（`windowBackgroundColor`、`.secondary`、
/// `Color.accentColor` 等），因此兩種外觀皆會自動套用正確配色。
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(viewModel: ZipCodeViewModel())
                .frame(width: 760, height: 620)
                .preferredColorScheme(.light)
                .previewDisplayName("淺色")

            ContentView(viewModel: ZipCodeViewModel())
                .frame(width: 760, height: 620)
                .preferredColorScheme(.dark)
                .previewDisplayName("深色")
        }
    }
}
