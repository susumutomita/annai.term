import AnnaiTermKit

@MainActor
func runCLISpec() {
    expect(
        run(["--version"]) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
        "--version は version を 1 行返し exit 0 を返す"
    )
    expect(
        run(["-v"]) == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
        "短縮形 -v でも version を返す"
    )
    expect(
        run(["--version", "bogus"])
            == CLIResult(stdout: [annaiTermVersion], stderr: [], exitCode: 0),
        "後続トークンが続いても診断フラグを先勝ちで短絡する"
    )
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

    let unknown = run(["no-such-command"])
    expect(unknown.stdout.isEmpty, "未対応の引数では標準出力に何も出さない")
    expect(unknown.exitCode == 2, "未対応の引数は exit 2 を返す")
    expect(unknown.stderr.count == 2, "未対応の引数はエラーとヘルプの 2 行を stderr に返す")
    expect(unknown.stderr.first?.contains("no-such-command") == true, "エラー行に入力トークンを含める")
    expect(unknown.stderr.last == helpText, "エラーの後にヘルプを添える")

    expect(helpText.contains("annai-term"), "helpText はプロダクト名を案内する")
    expect(
        helpText.contains("--version") && helpText.contains("--help"),
        "helpText は実在する 2 つのフラグを案内する"
    )
    expect(!annaiTermVersion.isEmpty, "version は空でない")
}
