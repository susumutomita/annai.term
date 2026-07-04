import BackendKit
import CatalogKit

@MainActor
private func sampleCandidates() -> [CandidateSummary] {
    let binding = Keybinding(
        id: "ghostty:super+c",
        source: .ghostty,
        scope: .app,
        sequence: [normalizeChord("super+c")],
        action: "copy_to_clipboard",
        description: "コピー",
        precedence: 100
    )
    return [CandidateSummary(from: binding)]
}

@MainActor
private func runPromptSpec() {
    let candidate = sampleCandidates()[0]
    expect(
        candidate.id == "ghostty:super+c" && candidate.source == "ghostty"
            && candidate.display == "Cmd + C",
        "CandidateSummary は Keybinding から安全なフィールドだけ写す"
    )

    let input = SelectionInput(question: "コピーしたい", candidates: sampleCandidates())
    let prompt = buildSelectionPrompt(input)
    expect(prompt.contains("コピーしたい"), "プロンプトに質問を含める")
    expect(prompt.contains("id=ghostty:super+c"), "プロンプトに候補 id を含める")
    expect(prompt.contains("keybindingId"), "候補から選ぶ JSON 指示を含める")
}

@MainActor
private func runParseSpec() {
    expect(
        parseSelectionResponse("{\"keybindingId\":\"ghostty:super+c\"}") == "ghostty:super+c",
        "素の JSON から id を取り出す"
    )
    expect(
        parseSelectionResponse("説明します: {\"keybindingId\":\"x\"} 以上") == "x",
        "前後にテキストがあっても最初の JSON を拾う"
    )
    expect(parseSelectionResponse("{\"keybindingId\":null}") == nil, "null は該当なし")
    expect(parseSelectionResponse("{\"foo\":1}") == nil, "keybindingId が無ければ nil")
    expect(parseSelectionResponse("これは JSON ではない") == nil, "波括弧が無ければ nil")
    expect(parseSelectionResponse("{壊れた}") == nil, "壊れた JSON は nil")
    expect(parseSelectionResponse("}{") == nil, "閉じが開きより前なら nil")
}

@MainActor
private func runValidateSpec() {
    let candidates = sampleCandidates()
    expect(validateSelection(nil, candidates: candidates) == nil, "nil はそのまま該当なし")
    expect(
        validateSelection("ghostty:not-real", candidates: candidates) == nil,
        "候補に無い id は reject する"
    )
    expect(
        validateSelection("ghostty:super+c", candidates: candidates) == "ghostty:super+c",
        "候補にある id は通す"
    )
    expect(BackendAvailability.available == .available, "availability を比較できる")
    expect(BackendAvailability.unavailable("x") != .available, "unavailable は available と異なる")
}

@MainActor
func runBackendSpec() {
    runPromptSpec()
    runParseSpec()
    runValidateSpec()
}
