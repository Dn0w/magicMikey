import SwiftUI

struct MacroSlotView: View {
    let slot: MacroSlot
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: slot.colorHex ?? "#1C1C24"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#2E2E3E"), lineWidth: 1)
                )

            VStack(spacing: 3) {
                if let symbol = slot.systemImage {
                    Image(systemName: symbol)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4A9EFF"))
                }
                Text(slot.label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#E8E8F0"))
                    .lineLimit(1)
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.08, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5,
                            pressing: { pressing in isPressed = pressing },
                            perform: onLongPress)
        .onTapGesture {
            HapticEngine.shared.macroTap()
            onTap()
        }
    }
}
