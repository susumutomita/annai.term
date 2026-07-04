import BackendKit
import CatalogKit

// privacy 保証: LLM へ渡す payload は「質問 + 候補の安全フィールド」だけで決定的に作られる。
// pane 内容・shell history・コードは SelectionInput / CandidateSummary に構造上入らないため、
// プロンプトを完全再構成できることで「余計な文脈が混ざらない」ことをテストで固定する。
@MainActor
func runPrivacySpec() {
    let binding = Keybinding(
        id: "ghostty:super+c",
        source: .ghostty,
        scope: .app,
        sequence: [normalizeChord("super+c")],
        action: "copy",
        description: "コピー",
        precedence: 100
    )
    let input = SelectionInput(
        question: "コピーしたい",
        candidates: [CandidateSummary(from: binding)]
    )
    let prompt = buildSelectionPrompt(input)

    let candidateLines = prompt.split(separator: "\n").filter { $0.hasPrefix("- id=") }
    expect(candidateLines.count == 1, "候補行は候補数と一致し、余計な文脈が混ざらない")
    expect(
        candidateLines.first.map(String.init)
            == "- id=ghostty:super+c | ghostty/app | Cmd + C | copy | コピー",
        "候補行は id/source/scope/display/action/description の安全フィールドだけ"
    )
    expect(prompt.contains("コピーしたい"), "質問は含まれる")
    expect(!prompt.contains("precedence"), "precedence など内部値の生ラベルは漏らさない")
}
