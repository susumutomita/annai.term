/// run の結果。副作用を持たせず、標準出力・標準エラー・終了コードを値として返す。
/// 実際の出力と終了は呼び出し側 (AnnaiTermCLI/main.swift) が担い、run 自体はテスト可能に保つ。
public struct CLIResult: Equatable, Sendable {
    public let stdout: [String]
    public let stderr: [String]
    public let exitCode: Int32

    public init(stdout: [String], stderr: [String], exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public let helpText = """
    annai-term — Ghostty・Herdr のキーバインドを日本語で案内する Mac ネイティブアプリ

    Usage:
      annai-term --version   バージョンを表示する
      annai-term --help      このヘルプを表示する

    Docs: https://github.com/susumutomita/annai.term
    """

/// V1 足場の入口。実在するフラグ (--version / --help) だけを扱い、未実装コマンドは持たない。
/// adapters / catalog / engine / overlay は後続 Issue で結線する。
/// --version / --help は診断フラグとして先勝ちで短絡させ、後続トークンは検査しない。
public func run(_ arguments: [String]) -> CLIResult {
    if arguments.contains("--version") || arguments.contains("-v") {
        return CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0)
    }
    if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
        return CLIResult(stdout: [helpText], stderr: [], exitCode: 0)
    }
    let joined = arguments.joined(separator: " ")
    return CLIResult(
        stdout: [],
        stderr: ["annai-term: 未対応の引数です: \(joined)", helpText],
        exitCode: 2
    )
}
