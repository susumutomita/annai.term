/// run の結果。副作用を持たせず、標準出力・標準エラー・終了コードを値として返す。
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
      annai-term ask "<質問>"   質問に合うキーバインドを 1 件案内する
      annai-term doctor          読み込んだ設定・競合・モデル・件数を表示する
      annai-term --version       バージョンを表示する
      annai-term --help          このヘルプを表示する

    Docs: https://github.com/susumutomita/annai.term
    """

/// 引数から解決したコマンド。実行（I/O・async）は呼び出し側が担う。
public enum Command: Equatable, Sendable {
    case version
    case help
    case ask(String)
    case askMissingQuestion
    case doctor
    case unknown([String])
}

/// 引数をコマンドに解決する純関数。--version / --help は診断フラグとして先勝ちで短絡する。
public func parseCommand(_ arguments: [String]) -> Command {
    if arguments.contains("--version") || arguments.contains("-v") { return .version }
    if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
        return .help
    }
    switch arguments[0] {
    case "ask":
        let question = arguments.dropFirst().filter { !$0.hasPrefix("-") }
            .joined(separator: " ")
        return question.isEmpty ? .askMissingQuestion : .ask(question)
    case "doctor":
        return .doctor
    default:
        return .unknown(arguments)
    }
}

/// 同期で描画できるコマンド（version / help / エラー）を CLIResult にする。
/// ask / doctor は I/O と async を要するため nil を返し、呼び出し側が実行する。
public func render(_ command: Command) -> CLIResult? {
    switch command {
    case .version:
        return CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0)
    case .help:
        return CLIResult(stdout: [helpText], stderr: [], exitCode: 0)
    case .askMissingQuestion:
        return CLIResult(
            stdout: [],
            stderr: ["annai-term: ask には質問が必要です。", helpText],
            exitCode: 2
        )
    case .unknown(let arguments):
        return CLIResult(
            stdout: [],
            stderr: ["annai-term: 未対応の引数です: \(arguments.joined(separator: " "))", helpText],
            exitCode: 2
        )
    case .ask, .doctor:
        return nil
    }
}
