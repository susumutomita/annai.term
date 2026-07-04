import BackendKit
import FoundationModels

/// Apple Foundation Models（オンデバイス）バックエンド。primary。
/// FoundationModels は Swift 専用・macOS 26 + Apple Intelligence 前提のため、
/// 実推論は AFM が有効な実機でのみ走る。ここは実 API への結線であり、
/// ユニットカバレッジ対象外（BackendKit の純ロジックがカバレッジ 100%）。
@available(macOS 26.0, *)
public struct AFMBackend: LocalBackend {
    public let name = "apple-foundation-models"

    public init() {}

    public func availability() async -> BackendAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable("\(reason)")
        }
    }

    public func selectKeybindingId(_ input: SelectionInput) async throws -> String? {
        let session = LanguageModelSession()
        let response = try await session.respond(to: buildSelectionPrompt(input))
        return validateSelection(
            parseSelectionResponse(response.content),
            candidates: input.candidates
        )
    }
}
