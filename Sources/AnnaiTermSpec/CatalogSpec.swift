import CatalogKit

@MainActor
private func runNormalizeSpec() {
    expect(
        normalizeChord("super+c") == Chord(modifiers: ["super"], key: "c"),
        "normalizeChord は修飾キーとキーに分解する"
    )
    expect(
        normalizeChord("cmd+shift+j") == Chord(modifiers: ["super", "shift"], key: "j"),
        "別名 cmd を super に統一する"
    )
    expect(
        normalizeChord("control+option+a")
            == Chord(modifiers: ["ctrl", "alt"], key: "a"),
        "別名 control / option を ctrl / alt に統一する"
    )
    expect(
        normalizeChord("shift+ctrl+super+a")
            == Chord(modifiers: ["super", "ctrl", "shift"], key: "a"),
        "修飾キーを canonical order（super → ctrl → alt → shift）に並べ替える"
    )
    expect(
        normalizeChord("super++") == Chord(modifiers: ["super"], key: "+"),
        "キー自体が + のケース（super++）を取りこぼさない"
    )
    expect(
        normalizeChord("super+=") == Chord(modifiers: ["super"], key: "="),
        "キーが = のケースを分解する"
    )
    expect(
        normalizeChord("copy") == Chord(modifiers: [], key: "copy"),
        "修飾キーの無いトリガーはキーだけにする"
    )
    expect(
        normalizeChord("ＳＵＰＥＲ+Ｃ") == Chord(modifiers: ["super"], key: "c"),
        "全角入力を NFKC 正規化 + 小文字化してから分解する"
    )
    expect(
        normalizeSequence("ctrl+b>v")
            == [Chord(modifiers: ["ctrl"], key: "b"), Chord(modifiers: [], key: "v")],
        "多段入力を > で分割して正規化する"
    )
}

@MainActor
private func runChordDisplaySpec() {
    expect(normalizeChord("super++").canonical == "super++", "canonical は + キーを保つ")
    expect(
        Chord(modifiers: ["super", "shift"], key: "j").display == "Cmd + Shift + J",
        "display は Mac 名 + 大文字キーで組み立てる"
    )
    expect(
        Chord(modifiers: ["super"], key: "+").display == "Cmd + +",
        "キーが + のときも空白区切りで曖昧さを避ける"
    )
    expect(
        Chord(modifiers: [], key: "arrow_left").display == "arrow_left",
        "名前付きキーはそのまま表示する"
    )
    expect(
        Chord(modifiers: ["hyper"], key: "x").display == "hyper + X",
        "未知の修飾キーは名前をそのまま表示する"
    )
}

@MainActor
private func binding(
    _ id: String,
    _ source: Keybinding.Source,
    _ trigger: String,
    precedence: Int,
    custom: Bool = false
) -> Keybinding {
    Keybinding(
        id: id,
        source: source,
        scope: source == .herdr ? .multiplexer : .app,
        sequence: normalizeSequence(trigger),
        action: id,
        description: id,
        isCustom: custom,
        precedence: precedence
    )
}

@MainActor
private func runKeybindingSpec() {
    let multi = Keybinding(
        id: "split",
        source: .herdr,
        scope: .multiplexer,
        sequence: normalizeSequence("ctrl+b>v"),
        action: "split_right",
        description: "右に分割",
        precedence: 200
    )
    expect(multi.display == "Ctrl + B → V", "多段の display は → で連結する")
    expect(multi.sequenceCanonical == "ctrl+b>v", "sequenceCanonical は全 chord を > で連結する")
    expect(multi.leadingCanonical == "ctrl+b", "leadingCanonical は先頭 chord を返す")
    expect(!multi.isCustom && multi.markingCustom().isCustom, "markingCustom は isCustom を立てる")

    let empty = Keybinding(
        id: "x",
        source: .generic,
        scope: .shell,
        sequence: [],
        action: "x",
        description: "x",
        precedence: 300
    )
    expect(empty.leadingCanonical == "", "空 sequence の leadingCanonical は空文字")
}

@MainActor
private func runConflictSpec() {
    let bindings = [
        binding("gk", .ghostty, "super+k", precedence: 100),
        binding("hk", .herdr, "super+k", precedence: 200),
        binding("gb1", .ghostty, "ctrl+b", precedence: 100),
        binding("gb2", .ghostty, "ctrl+b>v", precedence: 100),  // 先頭 chord は ctrl+b で gb1 と同層
        binding("hp1", .herdr, "ctrl+a", precedence: 200),
        binding("hp2", .herdr, "ctrl+a", precedence: 200),  // 同一層のみ（競合でない）
    ]
    let conflicts = detectConflicts(bindings)
    expect(conflicts.count == 1, "precedence の異なる層が同一先頭 chord を取る場合だけ競合にする")
    let conflict = conflicts[0]
    expect(conflict.winner.source == .ghostty, "precedence が小さい層が winner")
    expect(conflict.note.contains("herdr"), "note は届かない層を明示する")
    expect(conflict.note.contains("推定"), "観測しきれない要因を推定と明示する")

    let emptyWinner = Keybinding(
        id: "e",
        source: .ghostty,
        scope: .app,
        sequence: [],
        action: "e",
        description: "e",
        precedence: 100
    )
    let fallback = Conflict(chord: "raw", bindings: [emptyWinner], winner: emptyWinner)
    expect(fallback.note.contains("raw"), "先頭 chord が無いときは canonical を表示に使う")
}

@MainActor
func runCatalogSpec() {
    runNormalizeSpec()
    runChordDisplaySpec()
    runKeybindingSpec()
    runConflictSpec()
}
