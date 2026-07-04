import Foundation

/// 正規化済みの単一 chord（修飾キー + キー）。
/// 修飾キーは canonical order（super → ctrl → alt → shift）で並ぶ。
public struct Chord: Equatable, Sendable {
    public let modifiers: [String]
    public let key: String

    public init(modifiers: [String], key: String) {
        self.modifiers = modifiers
        self.key = key
    }

    /// 比較・マージのキーに使う正準表現。例: "super+shift+j" / "ctrl+b" / "super++"。
    public var canonical: String {
        (modifiers + [key]).joined(separator: "+")
    }

    /// 表示用。例: "Cmd + Shift + J" / "Cmd + +" / "Ctrl + B"。
    /// キー自体が "+" のケースを空白で区切って曖昧さを避ける。
    public var display: String {
        let names = modifiers.map { Chord.displayNames[$0] ?? $0 }
        return (names + [Chord.displayKey(key)]).joined(separator: " + ")
    }

    static let modifierAliases: [String: String] = [
        "super": "super", "cmd": "super", "command": "super", "meta": "super",
        "ctrl": "ctrl", "control": "ctrl",
        "alt": "alt", "opt": "alt", "option": "alt",
        "shift": "shift",
    ]

    static let canonicalOrder = ["super", "ctrl", "alt", "shift"]

    static let displayNames: [String: String] = [
        "super": "Cmd", "ctrl": "Ctrl", "alt": "Option", "shift": "Shift",
    ]

    static func displayKey(_ key: String) -> String {
        key.count == 1 ? key.uppercased() : key
    }
}

/// chord 文字列を正準形にする。修飾別名の統一・並び順の固定・NFKC 正規化・小文字化を行う。
/// キー自体が "+" / "=" / "," のケース（例: Ghostty の `super++`）を取りこぼさない。
public func normalizeChord(_ raw: String) -> Chord {
    let normalized = raw.precomposedStringWithCompatibilityMapping.lowercased()
    var rest = Substring(normalized)
    var mods: Set<String> = []
    // 先頭から "<modifier>+" を貪欲に消費する。残りがキー（"+" 自体を含む）。
    while let plus = rest.firstIndex(of: "+") {
        let token = String(rest[rest.startIndex..<plus])
        guard let canon = Chord.modifierAliases[token] else { break }
        mods.insert(canon)
        rest = rest[rest.index(after: plus)...]
    }
    let ordered = Chord.canonicalOrder.filter { mods.contains($0) }
    return Chord(modifiers: ordered, key: String(rest))
}

/// 多段入力を正規化する。既定の区切りは Ghostty の ">"。Herdr の prefix + キーも同じ表現に載せる。
public func normalizeSequence(_ raw: String, separator: Character = ">") -> [Chord] {
    raw.split(separator: separator).map { normalizeChord(String($0)) }
}
