import Foundation

// MARK: - Input method (determines keyboard layout + IME behaviour)

struct InputMethodProfile: Identifiable, Equatable {
    let id: String
    let label: String
    let keyboardVariant: KeyboardVariant
    let pinyinMode: PinyinMode?

    enum PinyinMode { case simplified, traditional }

    var isChineseIME: Bool  { pinyinMode != nil }
    var isTraditional: Bool { pinyinMode == .traditional }

    static let qwerty     = InputMethodProfile(id: "qwerty",      label: "QWERTY",               keyboardVariant: .qwerty,  pinyinMode: nil)
    static let azerty     = InputMethodProfile(id: "azerty",      label: "AZERTY",               keyboardVariant: .azerty,  pinyinMode: nil)
    static let qwertz     = InputMethodProfile(id: "qwertz",      label: "QWERTZ",               keyboardVariant: .qwertz,  pinyinMode: nil)
    static let russian    = InputMethodProfile(id: "russian",     label: "Russian (ЙЦУКЕН)",     keyboardVariant: .russian, pinyinMode: nil)
    static let pinyinSimp = InputMethodProfile(id: "pinyin-simp", label: "Pinyin (Simplified)",  keyboardVariant: .qwerty,  pinyinMode: .simplified)
    static let pinyinTrad = InputMethodProfile(id: "pinyin-trad", label: "Pinyin (Traditional)", keyboardVariant: .qwerty,  pinyinMode: .traditional)

    private static let all: [InputMethodProfile] = [
        .qwerty, .azerty, .qwertz, .russian, .pinyinSimp, .pinyinTrad
    ]

    static func profile(for id: String) -> InputMethodProfile {
        all.first { $0.id == id } ?? .qwerty
    }
}

// MARK: - Language (determines predictions + available input methods)

struct InputLanguageProfile: Identifiable {
    let id: String        // used as the prediction language code for UITextChecker
    let label: String
    let methods: [InputMethodProfile]

    var defaultMethod: InputMethodProfile { methods[0] }
}

extension InputLanguageProfile {
    static let all: [InputLanguageProfile] = [
        InputLanguageProfile(id: "en_US",  label: "English (US)",  methods: [.qwerty, .azerty, .qwertz]),
        InputLanguageProfile(id: "en_GB",  label: "English (UK)",  methods: [.qwerty, .azerty, .qwertz]),
        InputLanguageProfile(id: "zh_Hans",label: "Chinese (简体)", methods: [.pinyinSimp]),
        InputLanguageProfile(id: "zh_Hant",label: "Chinese (繁體)", methods: [.pinyinTrad]),
    ]

    static func profile(for id: String) -> InputLanguageProfile {
        all.first { $0.id == id } ?? all[0]
    }
}
