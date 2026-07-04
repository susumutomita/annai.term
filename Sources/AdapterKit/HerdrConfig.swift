import CatalogKit
import Foundation

/// `[[keys.command]]` のカスタムコマンド。
public struct HerdrCommand: Equatable, Sendable {
    public let key: String
    public let type: String
    public let command: String
    public let description: String

    public init(key: String, type: String, command: String, description: String) {
        self.key = key
        self.type = type
        self.command = command
        self.description = description
    }
}

/// config.toml の keybind 関連セクションの解析結果。
public struct HerdrConfig: Equatable, Sendable {
    public let prefix: String?
    public let actionOverrides: [String: String]
    public let commands: [HerdrCommand]
    public let unknownLines: [String]

    public init(
        prefix: String?,
        actionOverrides: [String: String],
        commands: [HerdrCommand],
        unknownLines: [String]
    ) {
        self.prefix = prefix
        self.actionOverrides = actionOverrides
        self.commands = commands
        self.unknownLines = unknownLines
    }
}

public struct HerdrCatalog: Equatable, Sendable {
    public let keybindings: [Keybinding]
    public let unknownLines: [String]

    public init(keybindings: [Keybinding], unknownLines: [String]) {
        self.keybindings = keybindings
        self.unknownLines = unknownLines
    }
}

private func unquote(_ value: String) -> String {
    guard value.count >= 2, let first = value.first, let last = value.last,
        first == last, first == "\"" || first == "'"
    else { return value }
    return String(value.dropFirst().dropLast())
}

/// `~/.config/herdr/config.toml` の keybind スキーマ（[keys] / [[keys.command]]）を解析する。
/// 正本は https://herdr.dev/docs/configuration/。keybind 部分の subset に絞った解析で、
/// 解釈できない行・テーブルは捏造せず unknown に集約する。
public func parseHerdrConfig(_ toml: String) -> HerdrConfig {
    enum Section { case none, keys, command }
    var section: Section = .none
    var prefix: String?
    var actionOverrides: [String: String] = [:]
    var commandBlocks: [[String: String]] = []
    var unknown: [String] = []

    for rawLine in toml.split(separator: "\n", omittingEmptySubsequences: false) {
        var line = String(rawLine)
        if let hash = line.firstIndex(of: "#") { line = String(line[..<hash]) }
        line = line.trimmingCharacters(in: .whitespaces)
        if line.isEmpty { continue }
        if line == "[keys]" {
            section = .keys
            continue
        }
        if line == "[[keys.command]]" {
            section = .command
            commandBlocks.append([:])
            continue
        }
        if line.hasPrefix("[") {
            section = .none
            continue
        }
        guard let equal = line.firstIndex(of: "=") else {
            unknown.append(line)
            continue
        }
        let key = String(line[..<equal]).trimmingCharacters(in: .whitespaces)
        let value = unquote(
            String(line[line.index(after: equal)...]).trimmingCharacters(in: .whitespaces)
        )
        switch section {
        case .keys:
            if key == "prefix" { prefix = value } else { actionOverrides[key] = value }
        case .command:
            commandBlocks[commandBlocks.count - 1][key] = value
        case .none:
            unknown.append(line)
        }
    }

    let commands = commandBlocks.compactMap { block -> HerdrCommand? in
        guard let key = block["key"], let type = block["type"], let command = block["command"]
        else { return nil }
        return HerdrCommand(
            key: key,
            type: type,
            command: command,
            description: block["description"] ?? ""
        )
    }
    return HerdrConfig(
        prefix: prefix,
        actionOverrides: actionOverrides,
        commands: commands,
        unknownLines: unknown
    )
}

/// `prefix+…` 記法を chord 列に変換する。範囲記法（1..9）は未対応として nil を返す。
private func herdrSequence(_ value: String, prefix: Chord) -> [Chord]? {
    if value.contains("..") { return nil }
    if value == "prefix" { return [prefix] }
    if value.hasPrefix("prefix+") {
        return [prefix] + normalizeSequence(String(value.dropFirst("prefix+".count)))
    }
    return normalizeSequence(value)
}

private func herdrBinding(
    id: String,
    sequence: [Chord],
    action: String,
    description: String
) -> Keybinding {
    Keybinding(
        id: id,
        source: .herdr,
        scope: .multiplexer,
        sequence: sequence,
        action: action,
        description: description,
        isCustom: true,
        precedence: 200
    )
}

/// 既定カタログに config.toml の prefix 変更・action 上書き・カスタムコマンドを適用する。
public func herdrCatalog(configToml: String) -> HerdrCatalog {
    let config = parseHerdrConfig(configToml)
    let prefix = config.prefix.map(normalizeChord) ?? normalizeChord("ctrl+b")
    var bindings = herdrDefaultCatalog(prefix: prefix)
    var unknown = config.unknownLines

    for (action, value) in config.actionOverrides.sorted(by: { $0.key < $1.key }) {
        guard let sequence = herdrSequence(value, prefix: prefix) else {
            unknown.append("\(action) = \(value)")
            continue
        }
        let rebound = herdrBinding(
            id: "herdr:" + sequence.map(\.canonical).joined(separator: ">"),
            sequence: sequence,
            action: action,
            description: action
        )
        if let index = bindings.firstIndex(where: { $0.action == action }) {
            bindings[index] = rebound
        } else {
            bindings.append(rebound)
        }
    }

    for command in config.commands {
        guard let sequence = herdrSequence(command.key, prefix: prefix) else {
            unknown.append(command.key)
            continue
        }
        bindings.append(
            herdrBinding(
                id: "herdr:cmd:" + sequence.map(\.canonical).joined(separator: ">"),
                sequence: sequence,
                action: command.command,
                description: command.description.isEmpty ? command.command : command.description
            )
        )
    }

    return HerdrCatalog(keybindings: bindings, unknownLines: unknown)
}
