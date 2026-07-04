/// ローカル LLM バックエンドの抽象。probe で可否を、select で候補からの分類だけを行う。
/// 実装（AFM / Ollama）は BackendTransport に置く。ここは契約だけを定義する。
public protocol LocalBackend: Sendable {
    var name: String { get }
    func availability() async -> BackendAvailability
    /// 質問 + 候補から keybindingId を選ぶ。候補外・該当なしは nil。
    func selectKeybindingId(_ input: SelectionInput) async throws -> String?
}
