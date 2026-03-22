import SwiftUI

/// Root SwiftUI view for the keyboard extension.
/// Mirrors the top half of RootView (macro bar + keyboard), no trackpad.
struct ExtensionKeyboardView: View {
    @EnvironmentObject var router: InputRouter
    @StateObject private var modifierState = ModifierState()
    @AppStorage("inputMethod") private var inputMethodId = "qwerty"
    @State private var showFKeys    = false
    @State private var showSettings = false

    private var keyboardVariant: KeyboardVariant {
        InputMethodProfile.profile(for: inputMethodId).keyboardVariant
    }

    var body: some View {
        GeometryReader { geo in
            let kh = computeKeyHeight(totalHeight: geo.size.height)
            VStack(spacing: 0) {
                MacroBarView(showFKeys: $showFKeys, rowHeight: kh,
                             leftIcon: "keyboard.chevron.compact.down",
                             leftIconActive: false,
                             onLeftAction: { router.dismissKeyboard() },
                             onSettings: { showSettings = true })
                    .padding(.horizontal, 8)
                    .padding(.top, 6)

                KeyboardView(modifierState: modifierState,
                             keyboardVariant: keyboardVariant,
                             keyHeight: kh,
                             showFKeys: $showFKeys)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(hex: "#0A0A0F"))
        .sheet(isPresented: $showSettings) {
            SettingsView().presentationDetents([.medium, .large])
        }
    }

    private func computeKeyHeight(totalHeight: CGFloat) -> CGFloat {
        let rowGaps: CGFloat     = 4 * 5
        let vertPadding: CGFloat = 6 + 8   // top 6 + keyboard bottom 8
        let available = totalHeight - rowGaps - vertPadding
        return max(32, floor(available / 6))
    }
}
