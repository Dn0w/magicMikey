import SwiftUI
import UIKit
import NaturalLanguage

struct PredictionBarView: View {
    @EnvironmentObject var router: InputRouter
    @AppStorage("inputLang")   private var inputLang   = "en_US"
    @AppStorage("inputMethod") private var inputMethodId = "qwerty"

    @State private var slots: [String] = ["", "", ""]
    @State private var partial: String = ""
    @State private var chineseCandidates: [String] = []

    private var activeMethod: InputMethodProfile { .profile(for: inputMethodId) }
    private var isChineseMode: Bool  { activeMethod.isChineseIME }
    private var isTraditional: Bool  { activeMethod.isTraditional }

    var body: some View {
        Group {
            if isChineseMode && !router.pinyinBuffer.isEmpty {
                chineseCandidateBar
            } else if isChineseMode {
                chineseReadyBar
            } else {
                latinPredictionBar
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#0D0D14"))
        .onChange(of: router.currentContext) { _, ctx in
            guard !isChineseMode else { return }
            refresh(context: ctx)
        }
        .onChange(of: router.pinyinBuffer) { _, buf in
            guard isChineseMode else { return }
            chineseCandidates = buf.isEmpty ? [] : Array(
                PinyinEngine.candidates(for: buf, traditional: isTraditional).prefix(30)
            )
        }
    }

    // MARK: - Chinese candidate bar

    private var chineseCandidateBar: some View {
        HStack(spacing: 0) {
            Text(router.pinyinBuffer)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(hex: "#4A9EFF"))
                .padding(.horizontal, 10)
                .lineLimit(1)
                .fixedSize()

            Rectangle()
                .fill(Color(hex: "#2E2E3E"))
                .frame(width: 1, height: 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(chineseCandidates.enumerated()), id: \.offset) { _, candidate in
                        Button {
                            router.insertText(candidate)
                            router.pinyinBuffer = ""
                        } label: {
                            Text(candidate)
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#E8E8F0"))
                                .frame(minWidth: 36, minHeight: 28)
                                .padding(.horizontal, 6)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chineseReadyBar: some View {
        HStack {
            Text(isTraditional ? "繁體 — 開始輸入拼音" : "简体 — 开始输入拼音")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#444458"))
                .padding(.horizontal, 12)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Latin 3-slot bar

    private var latinPredictionBar: some View {
        HStack(spacing: 0) {
            slotButton(slots[0], position: .left)
            divider
            slotButton(slots[1], position: .center)
            divider
            slotButton(slots[2], position: .right)
        }
        .frame(maxWidth: .infinity)
    }

    private enum Position { case left, center, right }

    @ViewBuilder
    private func slotButton(_ word: String, position: Position) -> some View {
        let isEmpty = word.isEmpty
        Button {
            guard !isEmpty else { return }
            apply(word)
        } label: {
            ZStack {
                if position == .center && !isEmpty {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "#1C1C24"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                }
                Text(isEmpty ? "" : word)
                    .font(.system(size: 15))
                    .foregroundColor(labelColor(position, empty: isEmpty))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .disabled(isEmpty)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: "#2E2E3E"))
            .frame(width: 1, height: 18)
    }

    private func labelColor(_ position: Position, empty: Bool) -> Color {
        if empty { return .clear }
        switch position {
        case .center: return Color(hex: "#E8E8F0")
        case .left, .right: return Color(hex: "#888899")
        }
    }

    // MARK: - Latin suggestion engine

    private func refresh(context: String) {
        let word = context.components(separatedBy: .whitespacesAndNewlines).last ?? ""
        partial = word
        guard word.count >= 2 else { slots = ["", "", ""]; return }

        let lang = effectiveLanguage(for: context)
        let checker = UITextChecker()
        let nsWord = word as NSString
        let range  = NSRange(location: 0, length: nsWord.length)

        if let completions = checker.completions(forPartialWordRange: range, in: word, language: lang),
           !completions.isEmpty {
            slots = padded(Array(completions.prefix(3))); return
        }
        let misspelled = checker.rangeOfMisspelledWord(in: word, range: range,
                                                       startingAt: 0, wrap: false, language: lang)
        if misspelled.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelled, in: word, language: lang),
           !guesses.isEmpty {
            slots = padded(Array(guesses.prefix(3))); return
        }
        slots = ["", word, ""]
    }

    // MARK: - Auto language detection (Phase 2)

    private func effectiveLanguage(for context: String) -> String {
        guard inputLang == "auto" else { return inputLang }
        guard context.count > 8 else { return "en_US" }
        let r = NLLanguageRecognizer()
        r.processString(context)
        guard let detected = r.dominantLanguage else { return "en_US" }
        return Self.nlToLocale[detected.rawValue] ?? "en_US"
    }

    private static let nlToLocale: [String: String] = [
        "en": "en_US", "fr": "fr_FR", "de": "de_DE", "es": "es_ES",
        "it": "it_IT", "pt": "pt_PT", "pt-BR": "pt_BR", "ru": "ru_RU",
        "nl": "nl_NL", "pl": "pl_PL", "sv": "sv_SE", "nb": "nb_NO",
        "da": "da_DK", "fi": "fi_FI", "tr": "tr_TR", "cs": "cs_CZ",
        "hu": "hu_HU", "ro": "ro_RO", "el": "el_GR",
    ]

    private func padded(_ words: [String]) -> [String] {
        var out = words; while out.count < 3 { out.append("") }; return out
    }

    private func apply(_ word: String) {
        for _ in partial { router.deleteBackward() }
        router.insertText(word + " ")
    }
}
