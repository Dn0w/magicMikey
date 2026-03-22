import SwiftUI
import SwiftData
import UIKit

struct MacroBarView: View {
    @EnvironmentObject var router: InputRouter
    @Binding var showFKeys: Bool
    var rowHeight: CGFloat = 60
    var leftIcon: String? = nil
    var leftIconActive: Bool = false
    var onLeftAction: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    @Query(sort: \MacroSlot.sortOrder) var slots: [MacroSlot]
    @Environment(\.modelContext) private var context
    @State private var editingSlot: MacroSlot?

    @AppStorage("inputMethod") private var inputMethodId = "qwerty"
    @AppStorage("inputLang")   private var inputLangId   = "en_US"
    @State private var chineseCandidates:  [String] = []
    @State private var assembledSentence:  String?  = nil
    @State private var wordPredictions:    [String] = []

    private var activeMethod: InputMethodProfile { .profile(for: inputMethodId) }
    private var isChineseCandidateMode: Bool {
        activeMethod.isChineseIME && !router.pinyinBuffer.isEmpty
    }
    private var isWordPredictionMode: Bool {
        !activeMethod.isChineseIME && !router.wordFragment.isEmpty && !showFKeys
    }

    // F1–F12 use Unicode private-use characters (same encoding as macOS NSEvent / UIKit)
    private let fKeyInputs: [String] = [
        "\u{F704}", "\u{F705}", "\u{F706}", "\u{F707}",
        "\u{F708}", "\u{F709}", "\u{F70A}", "\u{F70B}",
        "\u{F70C}", "\u{F70D}", "\u{F70E}", "\u{F70F}"
    ]

    private var btnH: CGFloat { rowHeight - 12 }

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isChineseCandidateMode {
                    chineseCandidateRow.transition(.opacity)
                } else if isWordPredictionMode {
                    wordPredictionRow.transition(.opacity)
                } else if showFKeys {
                    fKeyRow.transition(.opacity)
                } else {
                    macroRow.transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.12), value: isChineseCandidateMode)
            .animation(.easeInOut(duration: 0.12), value: isWordPredictionMode)
            .frame(maxWidth: .infinity)

            if let leftIcon, let onLeftAction {
                Button { onLeftAction() } label: {
                    Image(systemName: leftIcon)
                        .font(.system(size: 14))
                        .foregroundColor(leftIconActive ? Color(hex: "#4A9EFF") : Color(hex: "#888899"))
                        .frame(width: btnH, height: btnH)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#1C1C24"))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                        )
                }
            }

            if let onSettings {
                Button { onSettings() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#888899"))
                        .frame(width: btnH, height: btnH)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#1C1C24"))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                        )
                }
            }
        }
        .frame(height: rowHeight)
        .sheet(item: $editingSlot) { slot in
            MacroEditSheet(
                slot: slot,
                onSave: { label, keyCode, modifiers in
                    slot.label     = label
                    slot.keyCode   = keyCode
                    slot.modifiers = modifiers
                },
                onDelete: {
                    // Defer deletion to next run loop so sheet is fully gone first
                    DispatchQueue.main.async { context.delete(slot) }
                }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: router.pinyinBuffer) { _, buf in
            guard activeMethod.isChineseIME else { return }
            if buf.isEmpty {
                chineseCandidates = []
                assembledSentence = nil
            } else {
                let trad = activeMethod.isTraditional
                chineseCandidates = Array(PinyinEngine.candidates(for: buf, traditional: trad).prefix(40))
                assembledSentence = PinyinEngine.assembledSentence(for: buf, traditional: trad)
            }
        }
        .onChange(of: router.wordFragment) { _, fragment in
            guard !activeMethod.isChineseIME else { wordPredictions = []; return }
            wordPredictions = fragment.isEmpty ? [] : Self.completions(for: fragment, lang: inputLangId)
        }
        .onAppear {
            MacroStore.seedDefaultsIfNeeded(context: context)
        }
    }

    // MARK: - UITextChecker word completions

    private static func completions(for fragment: String, lang: String) -> [String] {
        let checker = UITextChecker()
        let nsStr = fragment as NSString
        let range = NSRange(location: 0, length: nsStr.length)
        let raw = checker.completions(forPartialWordRange: range, in: fragment, language: lang) ?? []
        // Filter out the fragment itself and limit to 6
        return Array(raw.filter { $0.lowercased() != fragment.lowercased() }.prefix(6))
    }

    // MARK: - Word prediction strip (Latin)

    private var wordPredictionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Typed fragment shown as a dim label
                Text(router.wordFragment)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "#555566"))
                    .padding(.horizontal, 6)
                    .lineLimit(1)
                    .fixedSize()

                Rectangle()
                    .fill(Color(hex: "#2E2E3E"))
                    .frame(width: 1, height: 20)

                ForEach(wordPredictions, id: \.self) { word in
                    Button {
                        HapticEngine.shared.keyTap()
                        // Delete the partial word already typed, then insert completion
                        let deleteCount = router.wordFragment.count
                        for _ in 0..<deleteCount { router.deleteBackward() }
                        router.insertText(word)
                    } label: {
                        Text(word)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#E8E8F0"))
                            .padding(.horizontal, 10)
                            .frame(height: btnH)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#1C1C24"))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Chinese candidate strip

    private var chineseCandidateRow: some View {
        HStack(spacing: 0) {
            // Pinyin buffer indicator
            Text(router.pinyinBuffer)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(hex: "#4A9EFF"))
                .padding(.horizontal, 10)
                .lineLimit(1)
                .fixedSize()

            Rectangle()
                .fill(Color(hex: "#2E2E3E"))
                .frame(width: 1, height: 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // ── Assembled sentence chip (shown when 2+ syllables) ──
                    if let sentence = assembledSentence {
                        Button {
                            HapticEngine.shared.keyTap()
                            router.insertText(sentence)
                            router.pinyinBuffer = ""
                        } label: {
                            Text(sentence)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "#E8E8F0"))
                                .padding(.horizontal, 12)
                                .frame(maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#1C2840"))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "#4A9EFF").opacity(0.5), lineWidth: 1))
                                )
                        }
                        .padding(.vertical, 6)

                        Rectangle()
                            .fill(Color(hex: "#2E2E3E"))
                            .frame(width: 1, height: 20)
                            .padding(.horizontal, 2)
                    }

                    // ── Individual character / phrase candidates ──
                    ForEach(Array(chineseCandidates.enumerated()), id: \.offset) { _, candidate in
                        Button {
                            HapticEngine.shared.keyTap()
                            router.insertText(candidate)
                            router.pinyinBuffer = ""
                        } label: {
                            Text(candidate)
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#E8E8F0"))
                                .frame(minWidth: btnH, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "#1C1C24"))
                                )
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - F1–F12 row

    private var fKeyRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(fKeyInputs.enumerated()), id: \.offset) { index, input in
                Button("F\(index + 1)") {
                    HapticEngine.shared.keyTap()
                    router.sendCommand(input, [])
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#E8E8F0"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#1C1C24"))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                )
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Macro row

    private var macroRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slots) { slot in
                    MacroSlotView(slot: slot) {
                        router.sendMacro(keyCode: slot.keyCode, modifiers: slot.modifiers)
                    } onLongPress: {
                        editingSlot = slot
                    }
                    .frame(width: 64).frame(maxHeight: .infinity)
                }

                addButton
            }
        .padding(.vertical, 6)
        }
    }

    // MARK: - Add button

    private var addButton: some View {
        Button {
            let newSlot = MacroSlot(label: "New", keyCode: 4,
                                   modifiers: 1 << 20, sortOrder: slots.count)
            context.insert(newSlot)
            editingSlot = newSlot
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#2E2E3E"), style: StrokeStyle(lineWidth: 1, dash: [4]))
                Image(systemName: "plus")
                    .foregroundColor(Color(hex: "#4A9EFF"))
            }
        }
        .frame(width: 44).frame(maxHeight: .infinity)
    }
}
