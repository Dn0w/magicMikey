import SwiftUI

struct LayoutPickerView: View {
    @Binding var selectedMode: LayoutMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layout Mode")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#888899"))

            HStack(spacing: 8) {
                ForEach(LayoutMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode.systemImage)
                                .font(.system(size: 16))
                            Text(mode.rawValue)
                                .font(.system(size: 9, design: .monospaced))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedMode == mode
                                      ? Color(hex: "#4A9EFF").opacity(0.2)
                                      : Color(hex: "#1C1C24"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedMode == mode
                                                ? Color(hex: "#4A9EFF")
                                                : Color(hex: "#2E2E3E"), lineWidth: 1)
                                )
                        )
                        .foregroundColor(selectedMode == mode
                                         ? Color(hex: "#4A9EFF")
                                         : Color(hex: "#E8E8F0"))
                    }
                }
            }
        }
    }
}
