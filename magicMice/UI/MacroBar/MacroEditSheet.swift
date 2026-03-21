import SwiftUI
import SwiftData

struct MacroEditSheet: View {
    @Bindable var slot: MacroSlot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("Label", text: $slot.label)
                        .font(.system(.body, design: .monospaced))
                }

                Section("SF Symbol") {
                    TextField("SF Symbol name (optional)", text: Binding(
                        get: { slot.systemImage ?? "" },
                        set: { slot.systemImage = $0.isEmpty ? nil : $0 }
                    ))
                    if let sym = slot.systemImage, !sym.isEmpty {
                        Label("Preview", systemImage: sym)
                    }
                }

                Section("Key Code (HID Usage)") {
                    Stepper("Code: \(slot.keyCode)", value: $slot.keyCode, in: 4...231)
                }

                Section("Modifiers (raw flags)") {
                    Toggle("⌘ Command", isOn: modifierBinding(.command))
                    Toggle("⇧ Shift",   isOn: modifierBinding(.shift))
                    Toggle("⌥ Option",  isOn: modifierBinding(.alternate))
                    Toggle("⌃ Control", isOn: modifierBinding(.control))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#0A0A0F"))
            .navigationTitle("Edit Macro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func modifierBinding(_ flag: UIKeyModifierFlags) -> Binding<Bool> {
        Binding(
            get: { (slot.modifiers & flag.rawValue) != 0 },
            set: { isOn in
                if isOn { slot.modifiers |= flag.rawValue }
                else     { slot.modifiers &= ~flag.rawValue }
            }
        )
    }
}
