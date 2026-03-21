import SwiftUI

/// Top-level layout.
/// Top 50%: Macro Bar + Keyboard
/// Bottom 50%: Gesture / Trackpad Zone  (MacBook style)
struct RootView: View {
    @StateObject private var modifierState = ModifierState()
    @StateObject private var displayMonitor = DisplayMonitor.shared

    @AppStorage("trackpadVisible") private var trackpadVisible: Bool = true
    @AppStorage("keyboardVariant") private var keyboardVariantRaw: String = KeyboardVariant.qwerty.rawValue
    @State private var showSettings = false
    @State private var showFKeys = false

    private var keyboardVariant: KeyboardVariant {
        KeyboardVariant(rawValue: keyboardVariantRaw) ?? .qwerty
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                VStack(spacing: 0) {
                    topHalf(geo: geo)
                    bottomHalf(geo: geo)
                }

                // Floating controls pinned top-right
                floatingControls

                // External display warning banner
                if !displayMonitor.isExternalDisplayConnected {
                    noDisplayBanner
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().presentationDetents([.medium, .large])
        }
    }

    // MARK: - Split: keyboard 50% / trackpad 50%

    private func keyboardHeight(_ total: CGFloat) -> CGFloat { total * 0.5 }
    private func trackpadHeight(_ total: CGFloat) -> CGFloat { total * 0.5 }

    // MARK: - Top section (keyboard + macro bar)

    @ViewBuilder
    private func topHalf(geo: GeometryProxy) -> some View {
        let halfH = keyboardHeight(geo.size.height)

        VStack(spacing: 0) {
            MacroBarView(showFKeys: $showFKeys)
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 2)

            KeyboardView(modifierState: modifierState,
                         keyboardVariant: keyboardVariant,
                         keyHeight: computeKeyHeight(totalHalf: halfH),
                         showFKeys: $showFKeys)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: halfH)
    }

    // MARK: - Bottom section (trackpad)

    @ViewBuilder
    private func bottomHalf(geo: GeometryProxy) -> some View {
        let halfH = trackpadHeight(geo.size.height)

        Group {
            if trackpadVisible {
                GestureZoneView()
                    .frame(width: geo.size.width * 0.5)
                    .padding(.vertical, 10)
            } else {
                Color.clear
            }
        }
        .frame(width: geo.size.width, height: halfH)
    }

    // MARK: - Key height calculation

    /// Distributes the top half's height across 5 equal-height key rows.
    private func computeKeyHeight(totalHalf: CGFloat) -> CGFloat {
        let macroBarHeight: CGFloat = 62
        let rowGaps: CGFloat = 5 * 4       // 4 gaps between 5 rows
        let vertPadding: CGFloat = 16

        let available = totalHalf - macroBarHeight - rowGaps - vertPadding
        return max(40, floor(available / 5))
    }

    // MARK: - Floating controls

    private var floatingControls: some View {
        HStack(spacing: 10) {
            trackpadToggle

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#888899"))
                    .padding(9)
                    .background(Circle().fill(Color(hex: "#1C1C24")))
            }
        }
        .padding(.top, 10)
        .padding(.trailing, 14)
    }

    // MARK: - No display banner

    private var noDisplayBanner: some View {
        VStack(spacing: 6) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#F5A623"))
            Text("Setup required")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#E8E8F0"))
            VStack(alignment: .leading, spacing: 4) {
                Label("Connect iPad to an external display", systemImage: "1.circle.fill")
                Label("Enable Stage Manager in Control Center", systemImage: "2.circle.fill")
                Label("Move other apps to the external display", systemImage: "3.circle.fill")
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(Color(hex: "#888899"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#1C1C24"))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#F5A623").opacity(0.4), lineWidth: 1))
        )
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var trackpadToggle: some View {
        Button { trackpadVisible.toggle() } label: {
            Image(systemName: trackpadVisible ? "hand.point.up.left.fill" : "hand.point.up.left")
                .font(.system(size: 12))
                .foregroundColor(trackpadVisible ? Color(hex: "#4A9EFF") : Color(hex: "#555566"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .background(
            Capsule().fill(Color(hex: "#1C1C24"))
                .overlay(Capsule().stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
        )
    }
}
