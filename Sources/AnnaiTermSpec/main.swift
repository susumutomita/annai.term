import AnnaiTermKit
import Foundation

// 日本語 BDD スタイルの最小スペックランナー。振る舞いを文で表現し、失敗時に exit 1。
// XCTest / swift-testing は Xcode 同梱で CLT には無いため、検証可能性を優先してこの形にする。

private var total = 0
private var failed = 0

@MainActor
private func expect(
    _ condition: Bool,
    _ description: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    total += 1
    if condition {
        print("  ok   \(description)")
    } else {
        failed += 1
        print("  FAIL \(description)  (\(file):\(line))")
    }
}

// run: --version / -v は version を 1 行返し exit 0
expect(
    run(["--version"]) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
    "--version は version を 1 行返し exit 0 を返す"
)
expect(
    run(["-v"]) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
    "短縮形 -v でも version を返す"
)
expect(
    run(["--version", "bogus"]) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
    "後続トークンが続いても診断フラグを先勝ちで短絡する"
)

// run: 引数なし / --help / -h はヘルプを返し exit 0
expect(
    run([]) == CLIResult(stdout: [helpText], stderr: [], exitCode: 0),
    "引数が無いときはヘルプを返し exit 0 を返す"
)
for flag in ["--help", "-h"] {
    expect(
        run([flag]) == CLIResult(stdout: [helpText], stderr: [], exitCode: 0),
        "\(flag) はヘルプを返し exit 0 を返す"
    )
}

// run: 未対応の引数はエラーとヘルプを stderr に返し exit 2
let unknown = run(["no-such-command"])
expect(unknown.stdout.isEmpty, "未対応の引数では標準出力に何も出さない")
expect(unknown.exitCode == 2, "未対応の引数は exit 2 を返す")
expect(unknown.stderr.count == 2, "未対応の引数はエラーとヘルプの 2 行を stderr に返す")
expect(unknown.stderr.first?.contains("no-such-command") == true, "エラー行に入力トークンを含める")
expect(unknown.stderr.last == helpText, "エラーの後にヘルプを添える")

// メタ情報
expect(helpText.contains("annai-term"), "helpText はプロダクト名を案内する")
expect(
    helpText.contains("--version") && helpText.contains("--help"),
    "helpText は実在する 2 つのフラグを案内する"
)
expect(!annaiTermVersion.isEmpty, "version は空でない")

print("\(total - failed)/\(total) passed")
exit(failed == 0 ? 0 : 1)
