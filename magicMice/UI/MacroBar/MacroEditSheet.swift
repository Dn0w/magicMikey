import SwiftUI
import SwiftData

struct MacroEditSheet: View {
    // Local copies — no @Bindable, no SwiftData reference held in this view
    @State private var label: String
    @State private var keyCode: Int
    @State private var modifiers: Int

    var onSave: (String, Int, Int) -> Void = { _, _, _ in }
    var onDelete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    init(slot: MacroSlot,
         onSave: @escaping (String, Int, Int) -> Void = { _, _, _ in },
         onDelete: @escaping () -> Void = {}) {
        _label     = State(initialValue: slot.label)
        _keyCode   = State(initialValue: slot.keyCode)
        _modifiers = State(initialValue: slot.modifiers)
        self.onSave   = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    labelSection
                    shortcutSection
                    deleteSection
                }
                .padding(16)
            }
            .background(Color(hex: "#0A0A0F"))
            .navigationTitle("Edit Macro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(label, keyCode, modifiers)
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#4A9EFF"))
                }
            }
        }
    }

    // MARK: - Label

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("LABEL")
            TextField("Label", text: $label)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(hex: "#E8E8F0"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
        }
    }

    // MARK: - Shortcut

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SHORTCUT")

            HStack {
                Text(currentComboLabel)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#4A9EFF"))
                Spacer()
                Text("tap modifiers + key below")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "#555566"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(fieldBackground)

            HStack(spacing: 8) {
                modifierButton("⌘", label: "Cmd",   flag: .command)
                modifierButton("⇧", label: "Shift", flag: .shift)
                modifierButton("⌥", label: "Opt",   flag: .alternate)
                modifierButton("⌃", label: "Ctrl",  flag: .control)
            }

            keyGrid
        }
    }

    private var currentComboLabel: String {
        var parts: [String] = []
        if modifiers & UIKeyModifierFlags.control.rawValue   != 0 { parts.append("⌃") }
        if modifiers & UIKeyModifierFlags.alternate.rawValue != 0 { parts.append("⌥") }
        if modifiers & UIKeyModifierFlags.shift.rawValue     != 0 { parts.append("⇧") }
        if modifiers & UIKeyModifierFlags.command.rawValue   != 0 { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private func modifierButton(_ symbol: String, label: String, flag: UIKeyModifierFlags) -> some View {
        let active = (modifiers & flag.rawValue) != 0
        return Button {
            if active { modifiers &= ~flag.rawValue }
            else      { modifiers |=  flag.rawValue }
        } label: {
            VStack(spacing: 2) {
                Text(symbol).font(.system(size: 18, weight: .semibold, design: .monospaced))
                Text(label) .font(.system(size: 9,  design: .monospaced))
            }
            .foregroundColor(active ? Color(hex: "#0A0A0F") : Color(hex: "#E8E8F0"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(active ? Color(hex: "#F5A623") : Color(hex: "#1C1C24"))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(active ? Color(hex: "#F5A623") : Color(hex: "#2E2E3E"), lineWidth: 1))
            )
        }
    }

    // MARK: - Key grid

    private struct KeyEntry { let label: String; let code: Int; var isWide: Bool = false }

    private static let keyRows: [[KeyEntry]] = [
        [ .init(label:"Q",code:20), .init(label:"W",code:26), .init(label:"E",code:8),
          .init(label:"R",code:21), .init(label:"T",code:23), .init(label:"Y",code:28),
          .init(label:"U",code:24), .init(label:"I",code:12), .init(label:"O",code:18),
          .init(label:"P",code:19) ],
        [ .init(label:"A",code:4),  .init(label:"S",code:22), .init(label:"D",code:7),
          .init(label:"F",code:9),  .init(label:"G",code:10), .init(label:"H",code:11),
          .init(label:"J",code:13), .init(label:"K",code:14), .init(label:"L",code:15) ],
        [ .init(label:"Z",code:29), .init(label:"X",code:27), .init(label:"C",code:6),
          .init(label:"V",code:25), .init(label:"B",code:5),  .init(label:"N",code:17),
          .init(label:"M",code:16) ],
        [ .init(label:"1",code:30), .init(label:"2",code:31), .init(label:"3",code:32),
          .init(label:"4",code:33), .init(label:"5",code:34), .init(label:"6",code:35),
          .init(label:"7",code:36), .init(label:"8",code:37), .init(label:"9",code:38),
          .init(label:"0",code:39) ],
        [ .init(label:"Space",  code:44, isWide:true),
          .init(label:"Return", code:40, isWide:true),
          .init(label:"Tab",    code:43),
          .init(label:"Esc",    code:41),
          .init(label:"⌫",     code:42) ],
    ]

    private var keyGrid: some View {
        VStack(spacing: 6) {
            ForEach(Self.keyRows.indices, id: \.self) { rowIdx in
                HStack(spacing: 6) {
                    ForEach(Self.keyRows[rowIdx].indices, id: \.self) { colIdx in
                        keyPickerButton(Self.keyRows[rowIdx][colIdx])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyPickerButton(_ entry: KeyEntry) -> some View {
        let selected = keyCode == entry.code
        Button { keyCode = entry.code } label: {
            Text(entry.label)
                .font(.system(size: entry.isWide ? 11 : 13, weight: .medium, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.7)
                .foregroundColor(selected ? Color(hex: "#0A0A0F") : Color(hex: "#E8E8F0"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color(hex: "#4A9EFF") : Color(hex: "#1C1C24"))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(selected ? Color(hex: "#4A9EFF") : Color(hex: "#2E2E3E"), lineWidth: 1))
                )
        }
    }

    private func keyName(for code: Int) -> String {
        for row in Self.keyRows {
            if let e = row.first(where: { $0.code == code }) { return e.label }
        }
        return "(\(code))"
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Button(role: .destructive) {
            onDelete()
            dismiss()
        } label: {
            Text("Delete Macro")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#FF4444"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#1C1C24"))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#FF4444").opacity(0.5), lineWidth: 1))
                )
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(Color(hex: "#888899"))
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(hex: "#1C1C24"))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#2E2E3E"), lineWidth: 1))
    }
}
