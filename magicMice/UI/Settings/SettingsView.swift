import SwiftUI

struct SettingsView: View {
    @AppStorage("keyboardVariant")     private var keyboardVariant: String = KeyboardVariant.qwerty.rawValue
    @AppStorage("predictionLanguage")  private var predictionLanguage: String = "en_US"
    @AppStorage("hapticIntensity")     private var hapticIntensity: String = "medium"
    @AppStorage("hapticEnabled")       private var hapticEnabled: Bool = true
    @AppStorage("keySoundEnabled")     private var keySoundEnabled: Bool = false
    @AppStorage("scrollSensitivity")   private var scrollSensitivity: Double = 3.0
    @AppStorage("naturalScrolling")    private var naturalScrolling: Bool = true

    private static let predictionLanguages: [(label: String, code: String)] = [
        ("English (US)",       "en_US"),
        ("English (UK)",       "en_GB"),
        ("French",             "fr_FR"),
        ("German",             "de_DE"),
        ("Spanish",            "es_ES"),
        ("Italian",            "it_IT"),
        ("Portuguese (BR)",    "pt_BR"),
        ("Portuguese (PT)",    "pt_PT"),
        ("Russian",            "ru_RU"),
        ("Dutch",              "nl_NL"),
        ("Polish",             "pl_PL"),
        ("Swedish",            "sv_SE"),
        ("Norwegian",          "nb_NO"),
        ("Danish",             "da_DK"),
        ("Finnish",            "fi_FI"),
        ("Turkish",            "tr_TR"),
        ("Czech",              "cs_CZ"),
        ("Hungarian",          "hu_HU"),
        ("Romanian",           "ro_RO"),
        ("Greek",              "el_GR"),
    ]

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
                    Picker("Prediction Language", selection: $predictionLanguage) {
                        ForEach(Self.predictionLanguages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
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
        }
    }
}
