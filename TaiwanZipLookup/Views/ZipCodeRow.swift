//
//  ZipCodeRow.swift
//  TaiwanZipLookup
//
//  結果清單中的單列呈現。
//

import SwiftUI

/// 單筆郵遞區號紀錄的清單列。
///
/// 郵遞區號以等寬粗體加底色強調，讓使用者一眼就能掃到數字；
/// 右側提供兩個常駐的複製按鈕，避免使用者必須先知道有右鍵選單。
struct ZipCodeRow: View {

    /// 要顯示的紀錄。
    let record: ZipCodeRecord

    /// 點擊「複製郵遞區號」時呼叫。
    let onCopyZipCode: () -> Void

    /// 點擊「複製完整地址」時呼叫。
    let onCopyFullAddress: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(record.zipCode)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(minWidth: 56, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.12))
                )
                .accessibilityLabel("郵遞區號 \(record.zipCode)")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(record.city)
                        .foregroundStyle(.secondary)
                    Text(record.district)
                        .fontWeight(.medium)
                }
                .font(.body)

                Text(record.englishName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Button {
                    onCopyZipCode()
                } label: {
                    Image(systemName: "number.square")
                }
                .help("複製郵遞區號 \(record.zipCode)")

                Button {
                    onCopyFullAddress()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .help("複製完整地址「\(record.fullAddressPrefix)」")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .imageScale(.large)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Xcode 畫布預覽。
struct ZipCodeRow_Previews: PreviewProvider {
    static var previews: some View {
        ZipCodeRow(
            record: ZipCodeRecord(
                zipCode: "100",
                city: "臺北市",
                cityEnglish: "Taipei City",
                district: "中正區",
                districtEnglish: "Zhongzheng Dist."
            ),
            onCopyZipCode: {},
            onCopyFullAddress: {}
        )
        .padding()
        .frame(width: 420)
    }
}
