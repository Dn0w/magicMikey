import SwiftUI

/// Top-level layout.
/// Top 50%: Macro Bar + Keyboard
/// Bottom 50%: Gesture / Trackpad Zone  (MacBook style)
struct RootView: View {
    @StateObject private var modifierState = ModifierState()
    @StateObject private var displayMonitor = DisplayMonitor.shared

    @AppStorage("trackpadVisible")   private var trackpadVisible: Bool = true
    @AppStorage("keyboardVariant")   private var keyboardVariantRaw: String = KeyboardVariant.qwerty.rawValue
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 3.0
    @AppStorage("naturalScrolling")  private var naturalScrolling: Bool = true
    @State private var showSettings = false
    @State private var showFKeys = false

    private var keyboardVariant: KeyboardVariant {
        KeyboardVariant(rawValue: keyboardVariantRaw) ?? .qwerty
    }

    var body: some View {
        GeometryReader { geo in
            let kh = computeKeyHeight(totalHalf: keyboardHeight(geo.size.height))
            ZStack(alignment: .topTrailing) {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                VStack(spacing: 0) {
                    topHalf(geo: geo)
                    bottomHalf(geo: geo)
                }

                // Floating controls pinned top-right, same height as smart bar row
                floatingControls(keyHeight: kh)

                // External display warning banner
                if !displayMonitor.isExternalDisplayConnected {
                    noDisplayBanner
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().presentationDetents([.medium, .large])
        }
        .onChange(of: scrollSensitivity) { _, v in GestureTranslator.shared.scrollSensitivity = v }
        .onChange(of: naturalScrolling)  { _, v in GestureTranslator.shared.naturalScrolling = v }
    }

    // MARK: - Split: keyboard 50% / trackpad 50%

    private func keyboardHeight(_ total: CGFloat) -> CGFloat { total * 0.5 }
    private func trackpadHeight(_ total: CGFloat) -> CGFloat { total * 0.5 }

    // MARK: - Top section (keyboard + macro bar)

    @ViewBuilder
    private func topHalf(geo: GeometryProxy) -> some View {
        let halfH = keyboardHeight(geo.size.height)

        let kh = computeKeyHeight(totalHalf: halfH)

        VStack(spacing: 0) {
            MacroBarView(showFKeys: $showFKeys, rowHeight: kh)
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 2)

            KeyboardView(modifierState: modifierState,
                         keyboardVariant: keyboardVariant,
                         keyHeight: kh,
                         onSettings: { showSettings = true },
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

    /// Distributes the top half across 6 equal rows: smart bar + 5 keyboard rows.
    private func computeKeyHeight(totalHalf: CGFloat) -> CGFloat {
        let rowGaps: CGFloat = 4 * 5       // 4 gaps between 5 keyboard rows (gap = 5pt)
        let vertPadding: CGFloat = 6 + 2 + 8  // macro top pad + macro bottom pad + keyboard bottom pad

        let available = totalHalf - rowGaps - vertPadding
        return max(36, floor(available / 6))
    }

    // MARK: - Floating controls

    private func floatingControls(keyHeight: CGFloat) -> some View {
        let btnH = keyHeight - 12   // matches row's .padding(.vertical, 6) inside smart bar
        return HStack(spacing: 10) {
            trackpadToggle(keyHeight: btnH)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#888899"))
                    .frame(width: btnH, height: btnH)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#1C1C24"))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                    )
            }
        }
        .padding(.top, 12)   // 6pt outer (topHalf) + 6pt inner (row padding)
        .padding(.trailing, 8)
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

    private func trackpadToggle(keyHeight: CGFloat) -> some View {
        Button { trackpadVisible.toggle() } label: {
            Image(systemName: trackpadVisible ? "hand.point.up.left.fill" : "hand.point.up.left")
                .font(.system(size: 14))
                .foregroundColor(trackpadVisible ? Color(hex: "#4A9EFF") : Color(hex: "#555566"))
                .frame(width: keyHeight, height: keyHeight)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#1C1C24"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                )
        }
    }
}
