import SwiftUI

struct SettingsView: View {
    @AppStorage("keyboardVariant")     private var keyboardVariant: String = KeyboardVariant.qwerty.rawValue
    @AppStorage("hapticIntensity")     private var hapticIntensity: String = "medium"
    @AppStorage("hapticEnabled")       private var hapticEnabled: Bool = true
    @AppStorage("keySoundEnabled")     private var keySoundEnabled: Bool = false
    @AppStorage("scrollSensitivity")   private var scrollSensitivity: Double = 3.0
    @AppStorage("naturalScrolling")    private var naturalScrolling: Bool = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Keyboard") {
                    Picker("Layout", selection: $keyboardVariant) {
                        ForEach(KeyboardVariant.allCases) { v in
                            Text(v.rawValue).tag(v.rawValue)
                        }
                    }
                    Toggle("Key Click Sound", isOn: $keySoundEnabled)
                }

                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: $hapticEnabled)
                    if hapticEnabled {
                        Picker("Intensity", selection: $hapticIntensity) {
                            Text("Light").tag("light")
                            Text("Medium").tag("medium")
                            Text("Heavy").tag("heavy")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Trackpad") {
                    VStack(alignment: .leading) {
                        Text("Sensitivity: \(Int(scrollSensitivity))")
                            .font(.system(.caption, design: .monospaced))
                        Slider(value: $scrollSensitivity, in: 1...5, step: 1)
                    }
                    Toggle("Natural Scrolling", isOn: $naturalScrolling)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#0A0A0F"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: hapticEnabled)      { _, v in HapticEngine.shared.isEnabled = v }
            .onChange(of: scrollSensitivity)  { _, v in GestureTranslator.shared.scrollSensitivity = v }
            .onChange(of: naturalScrolling)   { _, v in GestureTranslator.shared.naturalScrolling = v }
        }
    }
}
