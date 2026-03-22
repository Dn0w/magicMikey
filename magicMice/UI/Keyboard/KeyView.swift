import SwiftUI

struct KeyView: View {
    let key: Key
    let isArmed: Bool
    let keyHeight: CGFloat   // drives font scaling
    let onPress: () -> Void

    /// Called with accent variants + global frame when long-press fires.
    var onLongPress: (([String], CGRect) -> Void)? = nil

    @State private var isPressed = false
    @State private var globalFrame: CGRect = .zero

    var body: some View {
        Button(action: {}) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(keyBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "#2E2E3E"), lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    Text(key.label)
                        .font(.system(size: labelFontSize, weight: .medium, design: .monospaced))
                        .foregroundColor(labelColor)
                    if let secondary = key.secondaryLabel {
                        Text(secondary)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(hex: "#888899"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .buttonStyle(KeyButtonStyle(isPressed: $isPressed, onPress: onPress))
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .shadow(color: .black.opacity(0.4), radius: isPressed ? 1 : 4, x: 0, y: isPressed ? 0 : 2)
        .animation(.spring(response: 0.08, dampingFraction: 0.7), value: isPressed)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { globalFrame = geo.frame(in: .global) }
                    .onChange(of: geo.size) { _, _ in globalFrame = geo.frame(in: .global) }
            }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    guard !key.accentVariants.isEmpty else { return }
                    HapticEngine.shared.modifierArmed()
                    onLongPress?(key.accentVariants, globalFrame)
                }
        )
    }

    // MARK: - Computed appearance

    private var keyBackground: Color {
        if isArmed { return Color(hex: "#F5A623").opacity(0.25) }
        if isPressed { return Color(hex: "#4A9EFF").opacity(0.3) }
        return Color(hex: "#1C1C24")
    }

    private var labelColor: Color {
        if isArmed { return Color(hex: "#F5A623") }
        return Color(hex: "#E8E8F0")
    }

    private var labelFontSize: CGFloat {
        switch key.type {
        case .action, .modifier: return floor(keyHeight * 0.30)
        case .function:          return floor(keyHeight * 0.24)
        default:                 return floor(keyHeight * 0.40)
        }
    }
}

// MARK: - Custom button style that exposes press state

struct KeyButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let onPress: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed { onPress() }
            }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let int = UInt64(hex, radix: 16) ?? 0
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
