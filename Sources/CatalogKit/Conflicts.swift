/// 同一の先頭 chord を、precedence の異なる複数層が取っている状態。
public struct Conflict: Equatable, Sendable {
    public let chord: String
    /// precedence 昇順。先頭が winner。
    public let bindings: [Keybinding]
    public let winner: Keybinding

    public init(chord: String, bindings: [Keybinding], winner: Keybinding) {
        self.chord = chord
        self.bindings = bindings
        self.winner = winner
    }

    /// 「Cmd+K は Ghostty が先に処理するため、herdr には届きません（推定）。」形式の説明。
    /// OS 予約・IME・アプリフォーカスは観測しきれないため「推定」と明示する。
    public var note: String {
        let losers =
            bindings
            .filter { $0.source != winner.source }
            .map { $0.source.rawValue }
        let chordDisplay = winner.sequence.first?.display ?? chord
        return
            "\(chordDisplay) は \(winner.source.rawValue) が先に処理するため、"
            + "\(losers.joined(separator: " / ")) には届きません（推定）。"
    }
}

/// 同一の先頭 chord を複数の precedence 層が取っている競合を検出する。
/// 同一層だけで先頭 chord を共有する（Herdr の prefix 配下など）ものは競合ではない。
public func detectConflicts(_ keybindings: [Keybinding]) -> [Conflict] {
    // グループを出現順の配列で持ち、辞書は位置引きだけに使う（不到達な nil 分岐を作らない）。
    var groups: [[Keybinding]] = []
    var indexByChord: [String: Int] = [:]

    for binding in keybindings {
        let key = binding.leadingCanonical
        if let index = indexByChord[key] {
            groups[index].append(binding)
        } else {
            indexByChord[key] = groups.count
            groups.append([binding])
        }
    }

    return groups.compactMap { group -> Conflict? in
        guard Set(group.map(\.precedence)).count >= 2 else { return nil }
        let sorted = group.sorted { $0.precedence < $1.precedence }
        return Conflict(chord: sorted[0].leadingCanonical, bindings: sorted, winner: sorted[0])
    }
}
