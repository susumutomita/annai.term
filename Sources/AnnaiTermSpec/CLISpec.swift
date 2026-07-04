import AnnaiTermKit

@MainActor
private func runParseCommandSpec() {
    expect(parseCommand(["--version"]) == .version, "--version は version コマンド")
    expect(parseCommand(["-v"]) == .version, "短縮形 -v も version")
    expect(parseCommand([]) == .help, "引数なしは help")
    expect(parseCommand(["--help"]) == .help, "--help は help")
    expect(parseCommand(["-h"]) == .help, "短縮形 -h も help")
    expect(parseCommand(["--version", "ask"]) == .version, "診断フラグは先勝ちで短絡する")
    expect(
        parseCommand(["ask", "文字を", "大きく"]) == .ask("文字を 大きく"),
        "ask は残りのトークンを質問に連結する"
    )
    expect(parseCommand(["ask"]) == .askMissingQuestion, "ask だけなら質問欠落")
    expect(parseCommand(["ask", "--json"]) == .askMissingQuestion, "フラグだけの ask も質問欠落")
    expect(parseCommand(["doctor"]) == .doctor, "doctor コマンド")
    expect(parseCommand(["bogus"]) == .unknown(["bogus"]), "未知のサブコマンドは unknown")
}

@MainActor
private func runRenderSpec() {
    expect(
        render(.version) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
        "version は version 文字列を stdout に"
    )
    expect(
        render(.help) == CLIResult(stdout: [helpText], stderr: [], exitCode: 0),
        "help は helpText を stdout に"
    )
    let missing = render(.askMissingQuestion)
    expect(missing?.exitCode == 2 && missing?.stdout.isEmpty == true, "質問欠落は exit 2 / stderr")
    let unknown = render(.unknown(["x", "y"]))
    expect(
        unknown?.exitCode == 2 && unknown?.stderr.first?.contains("x y") == true,
        "unknown は入力を含むエラーと exit 2"
    )
    expect(render(.ask("q")) == nil, "ask は同期描画できない（nil）")
    expect(render(.doctor) == nil, "doctor は同期描画できない（nil）")

    expect(helpText.contains("annai-term") && helpText.contains("ask"), "helpText は使い方を案内する")
    expect(!annaiTermVersion.isEmpty, "version は空でない")
}

@MainActor
func runCLISpec() {
    runParseCommandSpec()
    runRenderSpec()
}
