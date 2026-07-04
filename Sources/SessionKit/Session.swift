import AdapterKit
import BackendKit
import BackendTransport
import CatalogKit
import EngineKit
import Foundation

// 実 I/O の結線（ghostty 起動・config 読み込み・AFM 推論）。CLI とオーバーレイで共有する。
// 純ロジックは各 Kit がカバレッジ 100% で担保するため、この層はカバレッジ対象外。

public struct SessionCatalog {
    public let bindings: [Keybinding]
    public let conflicts: [Conflict]
    public let ghosttyBinary: String?
    public let herdrConfigPath: String?
    public let unknownLines: [String]
}

private func runCommand(_ launch: String, _ arguments: [String]) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launch)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    do {
        try process.run()
    } catch {
        return nil
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    return String(data: data, encoding: .utf8)
}

private func ghosttyBinary() -> String? {
    let candidates = [
        "/Applications/Ghostty.app/Contents/MacOS/ghostty",
        "/opt/homebrew/bin/ghostty",
        "/usr/local/bin/ghostty",
    ]
    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
}

private func herdrConfigPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let base = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? (home + "/.config")
    return base + "/herdr/config.toml"
}

public func loadCatalog() -> SessionCatalog {
    var bindings: [Keybinding] = []
    var unknown: [String] = []
    let binary = ghosttyBinary()

    if let binary {
        let defaultOutput = runCommand(binary, ["+list-keybinds", "--default", "--plain"]) ?? ""
        let effective = runCommand(binary, ["+list-keybinds", "--plain"])
        let result =
            effective.map { ghosttyCatalog(defaultOutput: defaultOutput, effectiveOutput: $0) }
            ?? parseGhosttyKeybinds(defaultOutput)
        bindings += result.keybindings
        unknown += result.unknownLines
    }

    let herdrPath = herdrConfigPath()
    let herdrPresent = FileManager.default.fileExists(atPath: herdrPath)
    if herdrPresent, let toml = try? String(contentsOfFile: herdrPath, encoding: .utf8) {
        let catalog = herdrCatalog(configToml: toml)
        bindings += catalog.keybindings
        unknown += catalog.unknownLines
    } else {
        bindings += herdrDefaultCatalog()
    }

    return SessionCatalog(
        bindings: bindings,
        conflicts: detectConflicts(bindings),
        ghosttyBinary: binary,
        herdrConfigPath: herdrPresent ? herdrPath : nil,
        unknownLines: unknown
    )
}

private func selectId(_ input: SelectionInput) async -> String? {
    if #available(macOS 26.0, *) {
        let afm = AFMBackend()
        if case .available = await afm.availability() {
            // AFM が棄権したら retrieve 済みの最有力候補（実在 binding）を使う。候補空なら nil。
            let id = (try? await afm.selectKeybindingId(input)) ?? nil
            return id ?? retrievalFallbackId(for: input.candidates)
        }
    }
    return retrievalFallbackId(for: input.candidates)
}

/// 質問を解決して回答を返す。CLI とオーバーレイの共通入口。
public func resolveAnswer(question: String) async -> Answer {
    let catalog = loadCatalog()
    let candidates = retrieve(question, catalog: catalog.bindings)
    let input = SelectionInput(
        question: question,
        candidates: candidates.map(CandidateSummary.init(from:))
    )
    let selected = await selectId(input)
    return buildAnswer(
        question: question,
        selectedId: selected,
        catalog: catalog.bindings,
        conflicts: catalog.conflicts
    )
}

public func modelStatus() async -> String {
    if #available(macOS 26.0, *) {
        switch await AFMBackend().availability() {
        case .available: return "Apple Foundation Models (available)"
        case .unavailable(let reason): return "AFM 利用不可 (\(reason)) → retrieval fallback"
        }
    }
    return "retrieval fallback (macOS < 26)"
}

public func doctorReport() async -> [String] {
    let catalog = loadCatalog()
    let model = await modelStatus()
    var lines = [
        "annai-term doctor",
        "- Ghostty: \(catalog.ghosttyBinary ?? "バイナリ未検出（推定）")",
        "- Herdr config: \(catalog.herdrConfigPath ?? "無し（既定カタログ）")",
        "- カタログ件数: \(catalog.bindings.count)",
        "- 競合候補: \(catalog.conflicts.count)",
        "- 解析失敗（不明）: \(catalog.unknownLines.count)",
        "- モデル: \(model)",
    ]
    lines += catalog.conflicts.prefix(5).map { "  競合: \($0.note)" }
    return lines
}
