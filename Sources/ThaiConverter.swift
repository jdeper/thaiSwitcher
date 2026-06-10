import Foundation

struct ThaiConverter {

    // English QWERTY → Thai Kedmanee (no shift)
    static let engToThai: [Character: Character] = [
        "`": "็",
        "1": "ๅ", "2": "/", "3": "-", "4": "ภ", "5": "ถ",
        "6": "ุ", "7": "ึ", "8": "ค", "9": "ต", "0": "จ",
        "-": "ข", "=": "ช",
        "q": "ๆ", "w": "ไ", "e": "ำ", "r": "พ", "t": "ะ",
        "y": "ั", "u": "ี", "i": "ร", "o": "น", "p": "ย",
        "[": "บ", "]": "ล", "\\": "ฃ",
        "a": "ฟ", "s": "ห", "d": "ก", "f": "ด", "g": "เ",
        "h": "้", "j": "่", "k": "า", "l": "ส",
        ";": "ว", "'": "ง",
        "z": "ผ", "x": "ป", "c": "แ", "v": "อ", "b": "ิ",
        "n": "ื", "m": "ท", ",": "ม", ".": "ใ", "/": "ฝ",
        // Shift variants
        "~": "๊",
        "!": "+", "@": "๑", "#": "๒", "$": "๓", "%": "๔",
        "^": "ู", "&": "ๅ", "*": "๖", "(": "๗", ")": "๘",
        "_": "๙", "+": "๐",
        "Q": "๐", "W": "\u{201C}", "E": "ฎ", "R": "ฑ", "T": "ธ",
        "Y": "ํ", "U": "๊", "I": "ณ", "O": "ฯ", "P": "ญ",
        "{": "ฐ", "}": ",", "|": "ฅ",
        "A": "ฤ", "S": "ฆ", "D": "ฏ", "F": "โ", "G": "ฌ",
        "H": "็", "J": "๋", "K": "ษ", "L": "ศ",
        ":": "ซ", "\"": ".",
        "Z": "(", "X": ")", "C": "ฉ", "V": "ฮ", "B": "ฺ",
        "N": "์", "M": "?", "<": "ฒ", ">": "ฬ", "?": "ฦ",
    ]

    // Thai Kedmanee → English QWERTY (reverse of above)
    static let thaiToEng: [Character: Character] = {
        var rev: [Character: Character] = [:]
        for (k, v) in engToThai {
            // Only map if not already mapped (some Thai chars share a key)
            if rev[v] == nil { rev[v] = k }
        }
        return rev
    }()

    static func isMostlyThai(_ text: String) -> Bool {
        let scalars = text.unicodeScalars
        guard !scalars.isEmpty else { return false }
        let thaiCount = scalars.filter { $0.value >= 0x0E00 && $0.value <= 0x0E7F }.count
        return thaiCount * 2 >= scalars.count
    }

    // Iterate unicodeScalars so Thai combining marks (ื ิ ี ้ ่ etc.)
    // are treated as individual characters, not merged into grapheme clusters.
    static func convert(_ text: String) -> String {
        let map = isMostlyThai(text) ? thaiToEng : engToThai
        return text.unicodeScalars.map { scalar in
            let ch = Character(scalar)
            return map[ch].map { String($0) } ?? String(ch)
        }.joined()
    }
}
