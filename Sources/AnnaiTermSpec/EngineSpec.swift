import AdapterKit
import BackendKit
import CatalogKit
import EngineKit

@MainActor
private func sampleCatalog() -> [Keybinding] {
    let ghostty = parseGhosttyKeybinds(
        """
        keybind = super+==increase_font_size:1
        keybind = super+c=copy_to_clipboard:mixed
        """
    ).keybindings
    return ghostty + herdrDefaultCatalog()
}

@MainActor
private func runRetrieveSpec() {
    let catalog = sampleCatalog()

    expect(
        retrieve("文字を大きくしたい", catalog: catalog).first?.action == "increase_font_size:1",
        "「文字を大きく」は increase_font_size を最上位にする"
    )
    expect(
        retrieve("右に分割したい", catalog: catalog).first?.action == "split_vertical",
        "「分割」は split を引く"
    )
    expect(
        retrieve("作業を残して抜けたい", catalog: catalog).first?.action == "detach",
        "「残して抜けたい」は detach を引く"
    )
    expect(
        retrieve("copy", catalog: catalog).contains { $0.action == "copy_to_clipboard:mixed" },
        "質問中のラテン語もそのまま検索語にする"
    )
    expect(retrieve("あああ", catalog: catalog).isEmpty, "同義語もラテン語も無ければ空を返す")
    expect(retrieve("a タブ", catalog: catalog, limit: 2).count == 2, "1 文字語は無視し limit で件数を絞る")
    expect(
        retrieve("次のタブに移動", catalog: catalog).first?.action == "next_tab",
        "スコアが高い候補（next+tab の 2 語一致）を上位に並べる"
    )
}

@MainActor
private func runAnswerSpec() {
    let catalog = sampleCatalog()
    let font = catalog.first { $0.action == "increase_font_size:1" }
    let fontId = font?.id ?? ""

    let high = buildAnswer(question: "x", selectedId: fontId, catalog: catalog, conflicts: [])
    expect(high.confidence == .high && high.keybindingId == fontId, "検証済み id は high で返す")
    expect(high.explanation.contains(font?.display ?? "?"), "説明にキー表示を含める")

    let none = buildAnswer(question: "x", selectedId: nil, catalog: catalog, conflicts: [])
    expect(none.confidence == .none && none.keybindingId == nil, "選択が無ければ該当なし")

    let bogus = buildAnswer(question: "x", selectedId: "no-such", catalog: catalog, conflicts: [])
    expect(bogus.confidence == .none, "catalog に無い id も該当なしにする（捏造しない）")

    let gk = Keybinding(
        id: "ghostty:super+k",
        source: .ghostty,
        scope: .app,
        sequence: [normalizeChord("super+k")],
        action: "clear",
        description: "クリア",
        precedence: 100
    )
    let hk = Keybinding(
        id: "herdr:super+k",
        source: .herdr,
        scope: .multiplexer,
        sequence: [normalizeChord("super+k")],
        action: "x",
        description: "y",
        precedence: 200
    )
    let conflict = Conflict(chord: "super+k", bindings: [gk, hk], winner: gk)
    let withNote = buildAnswer(
        question: "x",
        selectedId: gk.id,
        catalog: [gk],
        conflicts: [conflict]
    )
    expect(withNote.conflictNote != nil, "先頭 chord が競合していれば conflictNote を付ける")
}

@MainActor
private func runFallbackSpec() {
    let font = sampleCatalog().first { $0.action == "increase_font_size:1" }
    let candidates = font.map { [CandidateSummary(from: $0)] } ?? []
    expect(retrievalFallbackId(for: candidates) == font?.id, "フォールバックは先頭候補の id")
    expect(retrievalFallbackId(for: []) == nil, "候補が無ければ nil")
}

@MainActor
private func runAnswerLinesSpec() {
    let none = Answer(keybindingId: nil, confidence: .none, explanation: "なし")
    expect(answerLines(none) == ["なし"], "該当なしは説明 1 行")

    let plain = Answer(keybindingId: "x", confidence: .high, explanation: "説明")
    expect(answerLines(plain) == ["説明"], "note / followUp 無しは説明のみ")

    let full = Answer(
        keybindingId: "x",
        confidence: .high,
        explanation: "説明",
        conflictNote: "衝突",
        followUp: "次の手順"
    )
    expect(
        answerLines(full) == ["説明", "競合: 衝突", "次に: 次の手順"],
        "conflictNote と followUp を続ける"
    )
}

@MainActor
func runEngineSpec() {
    runRetrieveSpec()
    runAnswerSpec()
    runFallbackSpec()
    runAnswerLinesSpec()
}
