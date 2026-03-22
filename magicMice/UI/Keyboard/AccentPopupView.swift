import SwiftUI

struct AccentPopupView: View {
    let variants: [String]
    let onSelect: (String) -> Void

    @State private var highlighted: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(variants, id: \.self) { ch in
                Button {
                    onSelect(ch)
                } label: {
                    Text(ch)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(highlighted == ch ? Color(hex: "#4A9EFF") : Color(hex: "#E8E8F0"))
                        .frame(width: 36, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(highlighted == ch
                                      ? Color(hex: "#4A9EFF").opacity(0.2)
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { over in highlighted = over ? ch : nil }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#1C1C24"))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
        )
    }
}
