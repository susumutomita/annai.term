/// 正規化済みの keybind 1 件。カタログの要素であり、実在するキーだけを表す。
public struct Keybinding: Equatable, Sendable {
    public enum Source: String, Sendable {
        case ghostty, herdr, user, generic
    }

    public enum Scope: String, Sendable {
        case app, terminal, multiplexer, shell
    }

    public let id: String
    public let source: Source
    public let scope: Scope
    /// 多段入力。例: [Ctrl+B, V]。単段は 1 要素。
    public let sequence: [Chord]
    public let action: String
    public let description: String
    public let configPath: String?
    public let isCustom: Bool
    /// 小さいほど先にキーを奪う。ghostty=100 / herdr=200 / shell=300。
    public let precedence: Int

    public init(
        id: String,
        source: Source,
        scope: Scope,
        sequence: [Chord],
        action: String,
        description: String,
        configPath: String? = nil,
        isCustom: Bool = false,
        precedence: Int
    ) {
        self.id = id
        self.source = source
        self.scope = scope
        self.sequence = sequence
        self.action = action
        self.description = description
        self.configPath = configPath
        self.isCustom = isCustom
        self.precedence = precedence
    }

    /// 表示用。多段は " → " で連結する。例: "Ctrl + B → V"。
    public var display: String {
        sequence.map(\.display).joined(separator: " → ")
    }

    /// マージのキーに使う、全 chord をつないだ正準表現。
    public var sequenceCanonical: String {
        sequence.map(\.canonical).joined(separator: ">")
    }

    /// 競合判定に使う、先頭 chord の正準表現。空 sequence では空文字。
    public var leadingCanonical: String {
        sequence.first?.canonical ?? ""
    }

    /// isCustom を true にした複製を返す。user 上書きをマージ時に印付けるのに使う。
    public func markingCustom() -> Keybinding {
        Keybinding(
            id: id,
            source: source,
            scope: scope,
            sequence: sequence,
            action: action,
            description: description,
            configPath: configPath,
            isCustom: true,
            precedence: precedence
        )
    }
}
