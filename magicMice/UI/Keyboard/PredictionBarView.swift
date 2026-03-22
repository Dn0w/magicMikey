import SwiftUI
import UIKit

struct PredictionBarView: View {
    @EnvironmentObject var router: InputRouter
    let language: String

    @State private var slots: [String] = ["", "", ""]
    @State private var partial: String = ""

    var body: some View {
        HStack(spacing: 0) {
            slotButton(slots[0], position: .left)
            divider
            slotButton(slots[1], position: .center)
            divider
            slotButton(slots[2], position: .right)
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#0D0D14"))
        .onChange(of: router.currentContext) { _, ctx in
            refresh(context: ctx)
        }
    }

    // MARK: - Slot button

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

    // MARK: - Suggestion engine

    private func refresh(context: String) {
        let word = context
            .components(separatedBy: .whitespacesAndNewlines)
            .last ?? ""
        partial = word

        guard word.count >= 2 else {
            slots = ["", "", ""]
            return
        }

        let checker = UITextChecker()
        let nsWord  = word as NSString
        let range   = NSRange(location: 0, length: nsWord.length)

        // Try completions first
        if let completions = checker.completions(
            forPartialWordRange: range, in: word, language: language),
           !completions.isEmpty {
            slots = padded(Array(completions.prefix(3)))
            return
        }

        // Fall back to spell-correction guesses
        let misspelled = checker.rangeOfMisspelledWord(
            in: word, range: range, startingAt: 0, wrap: false, language: language)
        if misspelled.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelled, in: word, language: language),
           !guesses.isEmpty {
            slots = padded(Array(guesses.prefix(3)))
            return
        }

        // No suggestions — show typed word in center as commit option
        slots = ["", word, ""]
    }

    private func padded(_ words: [String]) -> [String] {
        var out = words
        while out.count < 3 { out.append("") }
        return out
    }

    // MARK: - Apply suggestion

    private func apply(_ word: String) {
        // Delete the partial word character by character
        for _ in partial { router.deleteBackward() }
        router.insertText(word + " ")
    }
}
