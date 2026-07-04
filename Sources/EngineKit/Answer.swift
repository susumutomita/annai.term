import BackendKit
import CatalogKit

/// 利用者へ返す回答。keybindingId を選ぶだけで、キーは catalog の実在 binding から取る。
public struct Answer: Equatable, Sendable {
    public enum Confidence: String, Sendable { case high, low, none }

    public let keybindingId: String?
    public let confidence: Confidence
    public let explanation: String
    public let conflictNote: String?
    public let followUp: String?

    public init(
        keybindingId: String?,
        confidence: Confidence,
        explanation: String,
        conflictNote: String? = nil,
        followUp: String? = nil
    ) {
        self.keybindingId = keybindingId
        self.confidence = confidence
        self.explanation = explanation
        self.conflictNote = conflictNote
        self.followUp = followUp
    }
}

/// 検証済みの id（候補外は事前に reject 済み）と catalog から回答を組み立てる。
/// 該当なし・不明 id は「該当なし」を有効な結果として返し、近そうなキーを捏造しない。
public func buildAnswer(
    question: String,
    selectedId: String?,
    catalog: [Keybinding],
    conflicts: [Conflict]
) -> Answer {
    guard let selectedId, let binding = catalog.first(where: { $0.id == selectedId }) else {
        return Answer(
            keybindingId: nil,
            confidence: .none,
            explanation: "該当するキーバインドは見つかりませんでした。"
        )
    }
    let layer = binding.source.rawValue
    let note = conflicts.first { $0.chord == binding.leadingCanonical }?.note
    return Answer(
        keybindingId: binding.id,
        confidence: .high,
        explanation: "\(layer): \(binding.display) — \(binding.description)",
        conflictNote: note
    )
}

/// バックエンド不在時の決定的フォールバック選択。候補は retrieve 済みで先頭が最有力。
public func retrievalFallbackId(for candidates: [CandidateSummary]) -> String? {
    candidates.first?.id
}
