import CatalogKit
import Foundation

/// バックエンドの利用可否。doctor が表示する。
public enum BackendAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

/// LLM に渡してよい候補の要約。privacy 境界: ここに含められる情報だけがモデルへ渡る。
/// pane 内容・shell history・コードを表すフィールドは構造上存在しない。
public struct CandidateSummary: Equatable, Sendable {
    public let id: String
    public let source: String
    public let scope: String
    public let precedence: Int
    public let action: String
    public let description: String
    public let display: String

    public init(from binding: Keybinding) {
        self.id = binding.id
        self.source = binding.source.rawValue
        self.scope = binding.scope.rawValue
        self.precedence = binding.precedence
        self.action = binding.action
        self.description = binding.description
        self.display = binding.display
    }
}

/// LLM への入力。質問 + 候補要約だけ。これ以外の文脈は渡らない。
public struct SelectionInput: Equatable, Sendable {
    public let question: String
    public let candidates: [CandidateSummary]

    public init(question: String, candidates: [CandidateSummary]) {
        self.question = question
        self.candidates = candidates
    }
}

/// LLM が候補から 1 件選ぶための制約付きプロンプト。自由にキーを生成させず id を選ばせる。
public func buildSelectionPrompt(_ input: SelectionInput) -> String {
    var lines: [String] = [
        "あなたはキーバインド案内アシスタントです。",
        "次の質問に最も合う候補を 1 つだけ選び、JSON で {\"keybindingId\":\"<id>\"} のみを返してください。",
        "該当が無ければ {\"keybindingId\":null} を返してください。候補に無い id を作ってはいけません。",
        "",
        "質問: \(input.question)",
        "",
        "候補:",
    ]
    for candidate in input.candidates {
        lines.append(
            "- id=\(candidate.id) | \(candidate.source)/\(candidate.scope)"
                + " | \(candidate.display) | \(candidate.action) | \(candidate.description)"
        )
    }
    return lines.joined(separator: "\n")
}

/// モデル出力から keybindingId を取り出す。前後に余計なテキストがあっても最初の JSON を拾う。
public func parseSelectionResponse(_ raw: String) -> String? {
    let candidate = extractJSONObject(raw) ?? raw
    guard let data = candidate.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let id = object["keybindingId"] as? String
    else { return nil }
    return id
}

/// 返された id が候補集合に無ければ reject（該当なし扱い）。捏造を構造で止める最後の関門。
public func validateSelection(_ id: String?, candidates: [CandidateSummary]) -> String? {
    guard let id, candidates.contains(where: { $0.id == id }) else { return nil }
    return id
}

private func extractJSONObject(_ raw: String) -> String? {
    guard let open = raw.firstIndex(of: "{"), let close = raw.lastIndex(of: "}"),
        open < close
    else { return nil }
    return String(raw[open...close])
}
