import AdapterKit
import AnnaiTermKit
import BackendKit
import BackendTransport
import CatalogKit
import EngineKit
import Foundation

// composition root。実 I/O（ghostty 起動・config 読み込み・AFM 推論）をここで結線する。
// 純ロジックは各 Kit がカバレッジ 100% で担保するため、この層はカバレッジ対象外。

struct LoadedCatalog {
    let bindings: [Keybinding]
    let conflicts: [Conflict]
    let ghosttyBinary: String?
    let herdrConfigPath: String?
    let unknownLines: [String]
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

func loadCatalog() -> LoadedCatalog {
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

    return LoadedCatalog(
        bindings: bindings,
        conflicts: detectConflicts(bindings),
        ghosttyBinary: binary,
        herdrConfigPath: herdrPresent ? herdrPath : nil,
        unknownLines: unknown
    )
}

private func selectId(_ input: SelectionInput) async -> (id: String?, model: String) {
    if #available(macOS 26.0, *) {
        let afm = AFMBackend()
        switch await afm.availability() {
        case .available:
            // AFM が選べたらそれを、棄権したら retrieve 済みの最有力候補（実在 binding）を使う。
            // 候補が空なら nil のまま = 正真正銘の該当なし。
            let id = (try? await afm.selectKeybindingId(input)) ?? nil
            return (id ?? retrievalFallbackId(for: input.candidates), "Apple Foundation Models")
        case .unavailable(let reason):
            return (retrievalFallbackId(for: input.candidates), "AFM 利用不可 (\(reason)) → retrieval")
        }
    }
    return (retrievalFallbackId(for: input.candidates), "retrieval (macOS < 26)")
}

func runAsk(_ question: String) async -> Int32 {
    let catalog = loadCatalog()
    let candidates = retrieve(question, catalog: catalog.bindings)
    let input = SelectionInput(
        question: question,
        candidates: candidates.map(CandidateSummary.init(from:))
    )
    let selected = await selectId(input)
    let answer = buildAnswer(
        question: question,
        selectedId: selected.id,
        catalog: catalog.bindings,
        conflicts: catalog.conflicts
    )

    print(answer.explanation)
    if let note = answer.conflictNote { print("競合: \(note)") }
    return answer.keybindingId == nil ? 1 : 0
}

func runDoctor() async -> Int32 {
    let catalog = loadCatalog()
    var model = "retrieval fallback"
    if #available(macOS 26.0, *) {
        switch await AFMBackend().availability() {
        case .available: model = "Apple Foundation Models (available)"
        case .unavailable(let reason): model = "AFM 利用不可 (\(reason)) → retrieval fallback"
        }
    }
    print("annai-term doctor")
    print("- Ghostty: \(catalog.ghosttyBinary ?? "バイナリ未検出（推定）")")
    print("- Herdr config: \(catalog.herdrConfigPath ?? "無し（既定カタログ）")")
    print("- カタログ件数: \(catalog.bindings.count)")
    print("- 競合候補: \(catalog.conflicts.count)")
    print("- 解析失敗（不明）: \(catalog.unknownLines.count)")
    print("- モデル: \(model)")
    for conflict in catalog.conflicts.prefix(5) { print("  競合: \(conflict.note)") }
    return 0
}
