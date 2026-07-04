import CatalogKit
import Foundation

/// `ghostty +list-keybinds` 出力のパース結果。
public struct GhosttyParseResult: Equatable, Sendable {
    public let keybindings: [Keybinding]
    public let unbinds: [[Chord]]
    /// 解釈できなかった行。捏造せず doctor に集約する。
    public let unknownLines: [String]
    /// `keybind = clear`（既定の全破棄）が含まれていたか。
    public let clearsDefaults: Bool

    public init(
        keybindings: [Keybinding],
        unbinds: [[Chord]],
        unknownLines: [String],
        clearsDefaults: Bool
    ) {
        self.keybindings = keybindings
        self.unbinds = unbinds
        self.unknownLines = unknownLines
        self.clearsDefaults = clearsDefaults
    }
}

/// `ghostty +list-keybinds --plain` の出力（`keybind = <trigger>=<action>` の行）を
/// カタログに変換する。キー自体が `=` / `+` のケース（`super+=` / `super++`）は
/// action に `=` が現れないことを利用し、最後の `=` を区切りとして分解する。
public func parseGhosttyKeybinds(_ output: String) -> GhosttyParseResult {
    let prefix = "keybind = "
    var keybindings: [Keybinding] = []
    var unbinds: [[Chord]] = []
    var unknown: [String] = []
    var clears = false

    for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty { continue }
        guard line.hasPrefix(prefix) else {
            unknown.append(line)
            continue
        }
        let rest = String(line.dropFirst(prefix.count))
        if rest == "clear" {
            clears = true
            continue
        }
        guard let separator = rest.lastIndex(of: "=") else {
            unknown.append(line)
            continue
        }
        let trigger = String(rest[rest.startIndex..<separator])
        let action = String(rest[rest.index(after: separator)...])
        if trigger.isEmpty || action.isEmpty {
            unknown.append(line)
            continue
        }
        let sequence = normalizeSequence(trigger)
        if action == "unbind" {
            unbinds.append(sequence)
            continue
        }
        keybindings.append(
            Keybinding(
                id: "ghostty:" + sequence.map(\.canonical).joined(separator: ">"),
                source: .ghostty,
                scope: .app,
                sequence: sequence,
                action: action,
                description: action,
                precedence: 100
            )
        )
    }

    return GhosttyParseResult(
        keybindings: keybindings,
        unbinds: unbinds,
        unknownLines: unknown,
        clearsDefaults: clears
    )
}

/// 既定と実効の出力を突き合わせ、実効側の binding に isCustom を付ける。
/// 同一 sequence で action が既定と同じなら既定、違う・既定に無いなら custom。
public func ghosttyCatalog(
    defaultOutput: String,
    effectiveOutput: String
) -> GhosttyParseResult {
    let defaults = parseGhosttyKeybinds(defaultOutput)
    let effective = parseGhosttyKeybinds(effectiveOutput)

    var defaultActionByChord: [String: String] = [:]
    for binding in defaults.keybindings {
        defaultActionByChord[binding.sequenceCanonical] = binding.action
    }

    let marked = effective.keybindings.map { binding -> Keybinding in
        defaultActionByChord[binding.sequenceCanonical] == binding.action
            ? binding
            : binding.markingCustom()
    }

    return GhosttyParseResult(
        keybindings: marked,
        unbinds: effective.unbinds,
        unknownLines: effective.unknownLines,
        clearsDefaults: effective.clearsDefaults
    )
}
