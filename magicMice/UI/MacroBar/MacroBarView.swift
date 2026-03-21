import SwiftUI
import SwiftData

struct MacroBarView: View {
    @Binding var showFKeys: Bool
    @Query(sort: \MacroSlot.sortOrder) var slots: [MacroSlot]
    @Environment(\.modelContext) private var context
    @State private var editingSlot: MacroSlot?

    // F1–F12 use Unicode private-use characters (same encoding as macOS NSEvent / UIKit)
    private let fKeyInputs: [String] = [
        "\u{F704}", "\u{F705}", "\u{F706}", "\u{F707}",
        "\u{F708}", "\u{F709}", "\u{F70A}", "\u{F70B}",
        "\u{F70C}", "\u{F70D}", "\u{F70E}", "\u{F70F}"
    ]

    var body: some View {
        Group {
            if showFKeys {
                fKeyRow
                    .transition(.opacity)
            } else {
                macroRow
                    .transition(.opacity)
            }
        }
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#16161E").opacity(0.9))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        )
        .sheet(item: $editingSlot) { slot in
            MacroEditSheet(slot: slot)
                .presentationDetents([.medium])
        }
        .onAppear {
            MacroStore.seedDefaultsIfNeeded(context: context)
        }
    }

    // MARK: - F1–F12 row

    private var fKeyRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(fKeyInputs.enumerated()), id: \.offset) { index, input in
                    Button("F\(index + 1)") {
                        HapticEngine.shared.keyTap()
                        KeyDispatcher.shared.sendKeyCommand(input: input, modifiers: [])
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#E8E8F0"))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#1C1C24"))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
                    )
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Macro row

    private var macroRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slots) { slot in
                    MacroSlotView(slot: slot) {
                        KeyDispatcher.shared.sendMacro(keyCode: slot.keyCode,
                                                       modifiers: slot.modifiers)
                    } onLongPress: {
                        editingSlot = slot
                    }
                    .frame(width: 64, height: 44)
                }

                addButton
            }
            .padding(.horizontal, 8)
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
        .frame(width: 44, height: 44)
    }
}
