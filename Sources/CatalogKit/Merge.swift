/// マージ中に見つけた事実。doctor が表示する。
public struct MergeDiagnostic: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case overridden  // user 設定が既定を上書きした
        case unbound  // user 設定で解除された
        case duplicate  // 同一 chord の重複定義（後勝ち）
    }

    public let kind: Kind
    public let chord: String
    public let detail: String

    public init(kind: Kind, chord: String, detail: String) {
        self.kind = kind
        self.chord = chord
        self.detail = detail
    }
}

public struct MergeResult: Equatable, Sendable {
    public let keybindings: [Keybinding]
    public let diagnostics: [MergeDiagnostic]

    public init(keybindings: [Keybinding], diagnostics: [MergeDiagnostic]) {
        self.keybindings = keybindings
        self.diagnostics = diagnostics
    }
}

/// 既定カタログと user 設定を統合する。
/// 同一 sequence は user が優先し isCustom を立てる。unbinds は除去する。
/// いずれの分岐も doctor 向けに diagnostic を残す。
public func mergeCatalog(
    defaults: [Keybinding],
    user: [Keybinding],
    unbinds: [[Chord]] = []
) -> MergeResult {
    var order: [String] = []
    var byKey: [String: Keybinding] = [:]
    var diagnostics: [MergeDiagnostic] = []

    for binding in defaults {
        let key = binding.sequenceCanonical
        if byKey[key] == nil { order.append(key) }
        byKey[key] = binding
    }

    for binding in user {
        let key = binding.sequenceCanonical
        if let existing = byKey[key] {
            let kind: MergeDiagnostic.Kind = existing.isCustom ? .duplicate : .overridden
            diagnostics.append(
                MergeDiagnostic(kind: kind, chord: key, detail: existing.action)
            )
        } else {
            order.append(key)
        }
        byKey[key] = binding.markingCustom()
    }

    for sequence in unbinds {
        let key = sequence.map(\.canonical).joined(separator: ">")
        guard let removed = byKey[key] else { continue }
        byKey[key] = nil
        order.removeAll { $0 == key }
        diagnostics.append(
            MergeDiagnostic(kind: .unbound, chord: key, detail: removed.action)
        )
    }

    return MergeResult(
        keybindings: order.compactMap { byKey[$0] },
        diagnostics: diagnostics
    )
}
