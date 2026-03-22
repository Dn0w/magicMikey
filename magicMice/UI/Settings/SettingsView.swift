import SwiftUI

struct SettingsView: View {
    @AppStorage("inputLang")         private var inputLang: String = "en_US"
    @AppStorage("inputMethod")       private var inputMethod: String = "qwerty"
    @AppStorage("hapticIntensity")   private var hapticIntensity: String = "medium"
    @AppStorage("hapticEnabled")     private var hapticEnabled: Bool = true
    @AppStorage("keySoundEnabled")   private var keySoundEnabled: Bool = false
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 3.0
    @AppStorage("naturalScrolling")  private var naturalScrolling: Bool = true

    @Environment(\.dismiss) private var dismiss

    private var currentLang: InputLanguageProfile {
        InputLanguageProfile.profile(for: inputLang)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Language & Input") {
                    // Step 1 — language
                    Picker("Language", selection: $inputLang) {
                        ForEach(InputLanguageProfile.all) { lang in
                            Text(lang.label).tag(lang.id)
                        }
                    }
                    .onChange(of: inputLang) { _, newLang in
                        // Auto-reset input method when switching language
                        let profile = InputLanguageProfile.profile(for: newLang)
                        if !profile.methods.contains(where: { $0.id == inputMethod }) {
                            inputMethod = profile.defaultMethod.id
                        }
                    }

                    // Step 2 — input method (only shown if >1 choice)
                    if currentLang.methods.count > 1 {
                        Picker("Input Method", selection: $inputMethod) {
                            ForEach(currentLang.methods) { method in
                                Text(method.label).tag(method.id)
                            }
                        }
                    } else if let only = currentLang.methods.first {
                        HStack {
                            Text("Input Method")
                            Spacer()
                            Text(only.label)
                                .foregroundStyle(.secondary)
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
            .onChange(of: hapticEnabled) { _, v in HapticEngine.shared.isEnabled = v }
        }
    }
}
