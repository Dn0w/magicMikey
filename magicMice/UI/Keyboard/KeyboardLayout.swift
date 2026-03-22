import Foundation
import UIKit

enum KeyboardVariant: String, CaseIterable, Identifiable {
    case qwerty  = "QWERTY"
    case azerty  = "AZERTY"
    case qwertz  = "QWERTZ"
    case russian = "Russian"

    var id: String { rawValue }
}

struct KeyboardLayout {
    let variant: KeyboardVariant

    // MARK: - Accent map (Latin letters → long-press variants)

    private static let accentMap: [String: [String]] = [
        "a": ["à","á","â","ã","ä","å","æ"],
        "e": ["è","é","ê","ë"],
        "i": ["ì","í","î","ï"],
        "o": ["ò","ó","ô","õ","ö","ø","œ"],
        "u": ["ù","ú","û","ü"],
        "n": ["ñ"],
        "c": ["ç"],
        "s": ["ß"],
        "y": ["ý","ÿ"],
        "z": ["ž"],
    ]

    private func letter(_ label: String) -> Key {
        let accents = KeyboardLayout.accentMap[label.lowercased()] ?? []
        return Key(label, accents: accents)
    }

    // MARK: - Row definitions

    var numberRow: [Key] {
        let pairs: [(String, String)] = [
            ("`","~"),("1","!"),("2","@"),("3","#"),("4","$"),("5","%"),
            ("6","^"),("7","&"),("8","*"),("9","("),("0",")"),(("-","_")),(("=","+"))
        ]
        return pairs.map { Key($0.0, shifted: $0.1) }
    }

    var topRow: [Key] {
        switch variant {
        case .qwerty:
            let letters = ["Q","W","E","R","T","Y","U","I","O","P"]
            let punct: [(String, String)] = [("[","{"), ("]","}"), ("\\","|")]
            return letters.map { letter($0) } + punct.map { Key($0.0, shifted: $0.1) }
        case .azerty: return row(["A","Z","E","R","T","Y","U","I","O","P","^","$"])
        case .qwertz: return row(["Q","W","E","R","T","Z","U","I","O","P","Ü","+"])
        case .russian:
            // й ц у к е н г ш щ з х ъ ё  (13 keys)
            return ["й","ц","у","к","е","н","г","ш","щ","з","х","ъ","ё"].map { Key($0) }
        }
    }

    var homeRow: [Key] {
        switch variant {
        case .qwerty:
            let letters = ["A","S","D","F","G","H","J","K","L"]
            let punct: [(String, String)] = [(";",":"), ("'","\"")]
            return letters.map { letter($0) } + punct.map { Key($0.0, shifted: $0.1) }
        case .azerty: return row(["Q","S","D","F","G","H","J","K","L","M","ù"])
        case .qwertz: return row(["A","S","D","F","G","H","J","K","L","Ö","Ä"])
        case .russian:
            // ф ы в а п р о л д ж э  (11 keys)
            return ["ф","ы","в","а","п","р","о","л","д","ж","э"].map { Key($0) }
        }
    }

    var bottomRow: [Key] {
        switch variant {
        case .qwerty:
            let letters = ["Z","X","C","V","B","N","M"]
            let punct: [(String, String)] = [(",","<"), (".",">"),(("/","?"))]
            return letters.map { letter($0) } + punct.map { Key($0.0, shifted: $0.1) }
        case .azerty: return row(["W","X","C","V","B","N",",",";",":","!"])
        case .qwertz: return row(["Y","X","C","V","B","N","M",",",".","–"])
        case .russian:
            // я ч с м и т ь б ю .  (10 keys)
            return ["я","ч","с","м","и","т","ь","б","ю","."].map { Key($0) }
        }
    }

    var functionRow: [Key] {
        // F1–F12 use Unicode private-use code points U+F704–U+F70F (same as macOS/UIKit)
        let fKeys = (1...12).map { n -> Key in
            let char = String(Unicode.Scalar(0xF703 + n)!)
            return Key("F\(n)", character: char, type: .function)
        }
        return [Key("esc", character: UIKeyCommand.inputEscape, type: .action)] + fKeys
    }

    // MARK: - Helpers

    private func row(_ labels: [String]) -> [Key] {
        labels.map { letter($0) }
    }
}
