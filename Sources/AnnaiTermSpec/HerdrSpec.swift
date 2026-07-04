import AdapterKit
import CatalogKit

private let sampleConfig = """
    # my herdr config
    orphan = "before table"
    garbage line here
    [keys]
    prefix = "ctrl+a"  # override prefix
    new_tab = "prefix+t"
    navigate_workspace_down = "j"
    switch_tab = "prefix+1..9"
    solo = "prefix"
    bare = bareword
    single = 'squote'

    [[keys.command]]
    key = "prefix+alt+g"
    type = "pane"
    command = "lazygit"
    description = "run lazygit"

    [[keys.command]]
    key = "prefix+a..b"
    type = "pane"
    command = "ranged_cmd"

    [[keys.command]]
    type = "pane"
    command = "no_key"

    [[keys.command]]
    key = "prefix+m"
    type = "shell"
    command = "make"

    [server]
    foo = "bar"
    """

@MainActor
private func runHerdrDefaultSpec() {
    let catalog = herdrDefaultCatalog()
    expect(catalog.count == 35, "docs 由来の既定 keybind を 35 件載せる")
    let newTab = catalog.first { $0.action == "new_tab" }
    expect(
        newTab?.sequence == [normalizeChord("ctrl+b"), normalizeChord("c")],
        "既定 prefix は Ctrl+B、new_tab は Ctrl+B → C"
    )
    expect(newTab?.display == "Ctrl + B → C", "多段 display は prefix → キー")
    expect(
        newTab?.isCustom == false && newTab?.precedence == 200,
        "既定は isCustom=false / precedence=200"
    )

    let custom = herdrDefaultCatalog(prefix: normalizeChord("ctrl+a"))
    expect(
        custom.first { $0.action == "detach" }?.sequence.first == normalizeChord("ctrl+a"),
        "prefix を変えると全 binding の先頭 chord に反映される"
    )
}

@MainActor
private func runHerdrParseSpec() {
    let config = parseHerdrConfig(sampleConfig)
    expect(config.prefix == "ctrl+a", "prefix 上書きを行末コメントを剥がして読む")
    expect(config.actionOverrides.count == 6, "[keys] の action 上書きを集める")
    expect(config.actionOverrides["single"] == "squote", "シングルクオートの値も剥がす")
    expect(
        config.commands == [
            HerdrCommand(
                key: "prefix+alt+g",
                type: "pane",
                command: "lazygit",
                description: "run lazygit"
            ),
            HerdrCommand(key: "prefix+a..b", type: "pane", command: "ranged_cmd", description: ""),
            HerdrCommand(key: "prefix+m", type: "shell", command: "make", description: ""),
        ],
        "[[keys.command]] を読む。key 欠落のブロックは捨てる"
    )
    expect(
        config.unknownLines.count == 3,
        "テーブル外の代入・= 無し行・別テーブルの行を unknown に集約する"
    )
}

@MainActor
private func runHerdrCatalogSpec() {
    let catalog = herdrCatalog(configToml: sampleConfig)
    let byAction = { (action: String) in catalog.keybindings.first { $0.action == action } }

    expect(
        byAction("new_tab")?.sequence == [normalizeChord("ctrl+a"), normalizeChord("t")],
        "action 上書き（new_tab=prefix+t）を既定に反映し prefix も差し替える"
    )
    expect(byAction("new_tab")?.isCustom == true, "上書きした binding は isCustom")
    expect(
        byAction("solo")?.sequence == [normalizeChord("ctrl+a")],
        "値 prefix 単体は prefix だけの sequence"
    )
    expect(byAction("bare")?.sequence == [normalizeChord("bareword")], "prefix 無しの値はそのまま chord にする")
    expect(byAction("lazygit") != nil, "カスタムコマンドを binding として追加する")
    expect(
        byAction("make")?.description == "make",
        "description 省略のコマンドは command 名を説明に使う"
    )
    expect(
        catalog.unknownLines.count == 5,
        "範囲記法（..）の上書き・コマンドは未対応として unknown に集約する"
    )

    let noPrefix = herdrCatalog(configToml: "")
    expect(
        noPrefix.keybindings.first { $0.action == "new_tab" }?.sequence.first
            == normalizeChord("ctrl+b"),
        "prefix 未指定なら既定 Ctrl+B にフォールバックする"
    )
}

@MainActor
func runHerdrSpec() {
    runHerdrDefaultSpec()
    runHerdrParseSpec()
    runHerdrCatalogSpec()
}
