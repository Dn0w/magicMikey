import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var router: InputRouter
    @ObservedObject var modifierState: ModifierState
    var keyboardVariant: KeyboardVariant = .qwerty
    var keyHeight: CGFloat = 64
    var onKey: (Key) -> Void = { _ in }
    @Binding var showFKeys: Bool

    @State private var isFunctionRowExpanded = false
    @State private var isUpperCase = false
    @State private var accentPopup: (variants: [String], frame: CGRect)? = nil

    private let hPad: CGFloat = 8
    private let gap:  CGFloat = 5

    private var layout: KeyboardLayout { KeyboardLayout(variant: keyboardVariant) }

    var body: some View {
        GeometryReader { geo in
            // Stagger reference: QWERTY row = Tab(1.25kw) + 13 letters + 13 gaps
            // → 14.25·kw + 13·gap = avail  →  kw = (avail − 13·gap) / 14.25
            let avail = geo.size.width - hPad * 2
            let kw    = floor((avail - 13 * gap) / 14.25)

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    FunctionRowView(layout: layout, onKey: handleKey,
                                    isExpanded: $isFunctionRowExpanded)

                    VStack(spacing: gap) {
                        numberRow(kw: kw, avail: avail)
                        topRow(kw: kw, avail: avail)
                        homeRow(kw: kw, avail: avail)
                        bottomRow(kw: kw)
                        spaceRow(kw: kw)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 8)
                }

                // Accent popup overlay
                if let popup = accentPopup {
                    // Dismiss backdrop
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { accentPopup = nil }

                    // Position popup above the key that triggered it
                    let keyOrigin = popup.frame.origin
                    let kbOrigin  = geo.frame(in: .global).origin
                    let localX    = keyOrigin.x - kbOrigin.x
                    let localY    = keyOrigin.y - kbOrigin.y

                    // Rough popup width estimate (36+4 per char + 16 padding)
                    let popupW    = CGFloat(popup.variants.count) * 40 + 16
                    let clampedX  = min(max(localX, 4), geo.size.width - popupW - 4)

                    AccentPopupView(variants: popup.variants) { accent in
                        router.deleteBackward()
                        router.insertText(accent)
                        accentPopup = nil
                        modifierState.consumeAfterKeypress()
                    }
                    .offset(x: clampedX, y: max(0, localY - 56))
                    .zIndex(10)
                }
            }
        }
        .background(Color(hex: "#0A0A0F"))
    }

    // MARK: - Rows

    /// Number row: all keys at kw (shifted symbols shown when Shift armed), delete fills remainder.
    @ViewBuilder
    private func numberRow(kw: CGFloat, avail: CGFloat) -> some View {
        let deleteW = avail - CGFloat(layout.numberRow.count) * kw
                            - CGFloat(layout.numberRow.count) * gap
        HStack(spacing: gap) {
            ForEach(layout.numberRow) { key in
                KeyView(key: displayKey(key), isArmed: false, keyHeight: keyHeight,
                        onPress: { handleKey(key) })
                    .frame(width: kw, height: keyHeight)
            }
            KeyView(key: Key("⌫", type: .action), isArmed: false, keyHeight: keyHeight,
                    onPress: {
                HapticEngine.shared.keyTap()
                router.deleteBackward()
            })
            .frame(width: max(kw, deleteW), height: keyHeight)
        }
    }

    /// QWERTY row: Tab(fills remainder≈1.5kw) + 13 fixed-width keys. Stagger offset = 1.50kw.
    @ViewBuilder
    private func topRow(kw: CGFloat, avail: CGFloat) -> some View {
        let tabW = avail - CGFloat(layout.topRow.count) * kw
                         - CGFloat(layout.topRow.count) * gap
        HStack(spacing: gap) {
            KeyView(key: Key("⇥", character: "\t", type: .action),
                    isArmed: false, keyHeight: keyHeight,
                    onPress: { handleKey(Key("⇥", character: "\t")) })
            .frame(width: max(kw, tabW), height: keyHeight)

            ForEach(layout.topRow) { key in
                KeyView(key: displayKey(key), isArmed: false, keyHeight: keyHeight,
                        onPress: { handleKey(key) },
                        onLongPress: key.accentVariants.isEmpty ? nil : showAccentPopup)
                    .frame(width: kw, height: keyHeight)
            }
        }
    }

    /// Home row: Caps(1.75kw) + 11 fixed-width keys + Return(fills ≈ 1.75kw).
    @ViewBuilder
    private func homeRow(kw: CGFloat, avail: CGFloat) -> some View {
        HStack(spacing: gap) {
            KeyView(key: Key("⇪", type: .modifier),
                    isArmed: modifierState.isCapsLockOn, keyHeight: keyHeight,
                    onPress: {
                HapticEngine.shared.modifierArmed()
                modifierState.toggle(.alphaShift)
                isUpperCase = modifierState.isCapsLockOn
            })
            .frame(width: floor(kw * 1.75), height: keyHeight)

            ForEach(layout.homeRow) { key in
                KeyView(key: displayKey(key), isArmed: false, keyHeight: keyHeight,
                        onPress: { handleKey(key) },
                        onLongPress: key.accentVariants.isEmpty ? nil : showAccentPopup)
                    .frame(width: kw, height: keyHeight)
            }

            KeyView(key: Key("⏎", character: "\n", type: .action),
                    isArmed: false, keyHeight: keyHeight,
                    onPress: { handleKey(Key("⏎", character: "\n")) })
            .frame(maxWidth: .infinity, minHeight: keyHeight, maxHeight: keyHeight)
        }
    }

    /// Bottom row: LeftShift(fills ≈ 2kw) + 10 fixed-width keys + RightShift(2.5kw).
    @ViewBuilder
    private func bottomRow(kw: CGFloat) -> some View {
        HStack(spacing: gap) {
            KeyView(key: Key("⇧", type: .modifier),
                    isArmed: modifierState.isShiftArmed, keyHeight: keyHeight,
                    onPress: {
                HapticEngine.shared.modifierArmed()
                modifierState.toggle(.shift)
                isUpperCase = modifierState.isShiftArmed || modifierState.isCapsLockOn
            })
            .frame(maxWidth: .infinity, minHeight: keyHeight, maxHeight: keyHeight)

            ForEach(layout.bottomRow) { key in
                KeyView(key: displayKey(key), isArmed: false, keyHeight: keyHeight,
                        onPress: { handleKey(key) },
                        onLongPress: key.accentVariants.isEmpty ? nil : showAccentPopup)
                    .frame(width: kw, height: keyHeight)
            }

            KeyView(key: Key("⇧", type: .modifier),
                    isArmed: modifierState.isShiftArmed, keyHeight: keyHeight,
                    onPress: {
                HapticEngine.shared.modifierArmed()
                modifierState.toggle(.shift)
                isUpperCase = modifierState.isShiftArmed || modifierState.isCapsLockOn
            })
            .frame(width: floor(kw * 2.5), height: keyHeight)
        }
    }

    /// Space row: ⌃ ⌥ ⌘ + space + ⌘ ⌥ (narrower) + ← [↑↓] →
    @ViewBuilder
    private func spaceRow(kw: CGFloat) -> some View {
        let halfH = floor(keyHeight / 2)

        HStack(spacing: gap) {
            fnKey(kw: kw)
            mod("⌃", .control,   w: kw,              h: keyHeight, word: "control")
            mod("⌥", .alternate, w: kw,              h: keyHeight, word: "option")
            mod("⌘", .command,   w: floor(kw * 1.2), h: keyHeight, word: "command")

            KeyView(key: Key("space", character: " ", type: .space),
                    isArmed: false, keyHeight: keyHeight,
                    onPress: { handleKey(Key("space", character: " ")) })
            .frame(maxWidth: .infinity, minHeight: keyHeight, maxHeight: keyHeight)

            mod("⌘", .command,   w: floor(kw * 0.85), h: keyHeight, word: "command")
            mod("⌥", .alternate, w: floor(kw * 0.85), h: keyHeight, word: "option")

            arrow("←", UIKeyCommand.inputLeftArrow,  kw: kw, h: keyHeight)

            VStack(spacing: 2) {
                arrow("↑", UIKeyCommand.inputUpArrow,   kw: kw, h: halfH)
                arrow("↓", UIKeyCommand.inputDownArrow, kw: kw, h: halfH)
            }
            .frame(width: kw, height: keyHeight)

            arrow("→", UIKeyCommand.inputRightArrow, kw: kw, h: keyHeight)
        }
    }

    // MARK: - Reusable builders

    @ViewBuilder
    private func fnKey(kw: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.2)) { showFKeys.toggle() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(showFKeys ? Color(hex: "#4A9EFF").opacity(0.2) : Color(hex: "#1C1C24"))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                Text("fn")
                    .font(.system(size: floor(keyHeight * 0.28), weight: .medium, design: .monospaced))
                    .foregroundColor(showFKeys ? Color(hex: "#4A9EFF") : Color(hex: "#888899"))
            }
        }
        .frame(width: kw, height: keyHeight)
    }

    @ViewBuilder
    private func arrow(_ label: String, _ input: String, kw: CGFloat, h: CGFloat) -> some View {
        KeyView(key: Key(label, type: .action), isArmed: false, keyHeight: h,
                onPress: {
            HapticEngine.shared.keyTap()
            router.sendCommand(input, modifierState.activeModifiers)
            modifierState.consumeAfterKeypress()
        })
        .frame(width: kw, height: h)
    }

    @ViewBuilder
    private func mod(_ label: String, _ flag: UIKeyModifierFlags,
                     w: CGFloat, h: CGFloat, word: String? = nil) -> some View {
        KeyView(key: Key(label, secondary: word, type: .modifier),
                isArmed: modifierState.activeModifiers.contains(flag),
                keyHeight: h,
                onPress: {
            HapticEngine.shared.modifierArmed()
            modifierState.toggle(flag)
        })
        .frame(width: w, height: h)
    }

    // MARK: - Long-press accent popup

    private func showAccentPopup(_ variants: [String], _ frame: CGRect) {
        accentPopup = (variants: variants, frame: frame)
    }

    // MARK: - Input dispatch

    private func handleKey(_ key: Key) {
        HapticEngine.shared.keyTap()
        guard let char = key.character else { return }

        // Function keys (F1–F12) and ESC always dispatch as key commands.
        if key.type == .function ||
           (key.type == .action && char == UIKeyCommand.inputEscape) {
            router.sendCommand(char, modifierState.activeModifiers)
            modifierState.consumeAfterKeypress()
            onKey(key)
            return
        }

        // Shifted symbols only when Shift is armed; CapsLock only uppercases letters.
        let text: String
        if modifierState.isShiftArmed, let shifted = key.shiftedCharacter {
            text = shifted
        } else if isUpperCase {
            text = char.uppercased()
        } else {
            text = char
        }

        if modifierState.activeModifiers.isEmpty ||
           modifierState.activeModifiers == .alphaShift {
            router.insertText(text)
        } else {
            router.sendCommand(text, modifierState.activeModifiers)
        }
        modifierState.consumeAfterKeypress()
        if modifierState.isShiftArmed { isUpperCase = false }
        onKey(key)
    }

    private func displayKey(_ key: Key) -> Key {
        guard key.type == .character, let char = key.character else { return key }
        // Shifted symbols only when Shift is armed; CapsLock only uppercases letters.
        if modifierState.isShiftArmed, let shifted = key.shiftedCharacter {
            return Key(shifted, secondary: key.secondaryLabel, character: char,
                       shifted: shifted, width: key.width, type: key.type,
                       accents: key.accentVariants)
        }
        let display = isUpperCase ? char.uppercased() : char.lowercased()
        return Key(display, secondary: key.secondaryLabel, character: char,
                   shifted: key.shiftedCharacter, width: key.width, type: key.type,
                   accents: key.accentVariants)
    }
}
