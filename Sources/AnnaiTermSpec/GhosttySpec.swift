import AdapterKit
import CatalogKit

@MainActor
private func runGhosttyParseSpec() {
    // 実際の `ghostty +list-keybinds --default` の行 + 各分岐を突く行。
    let output = """
        keybind = super+shift+,=reload_config
        keybind = super+c=copy_to_clipboard:mixed
        keybind = super+==increase_font_size:1
        keybind = super++=increase_font_size:1
        keybind = super+q=unbind
        keybind = clear

        not a keybind line
        keybind = super+bad
        keybind = =noleader
        keybind = super+z=
        """
    let result = parseGhosttyKeybinds(output)

    expect(result.keybindings.count == 4, "keybind 行 4 件を binding にする")
    expect(result.unbinds == [normalizeSequence("super+q")], "unbind をトリガーとして取り出す")
    expect(result.clearsDefaults, "keybind = clear を検出する")
    expect(
        result.unknownLines.count == 4,
        "非 keybind 行・=無し・trigger 空・action 空を unknown に集約する"
    )

    expect(
        result.keybindings.first { $0.action == "copy_to_clipboard:mixed" }?.description
            == "クリップボードにコピー",
        "既知 action には日本語 description を付ける"
    )

    let plus = result.keybindings.first { $0.action == "increase_font_size:1" }
    expect(
        plus?.sequence == [Chord(modifiers: ["super"], key: "=")],
        "super+= のキー = を取りこぼさない"
    )
    let plusKey = result.keybindings.first { $0.sequence.first?.key == "+" }
    expect(
        plusKey?.source == .ghostty && plusKey?.precedence == 100,
        "super++ を ghostty / precedence 100 で載せる"
    )
}

@MainActor
private func runGhosttyCustomSpec() {
    let defaults = """
        keybind = super+c=copy_to_clipboard:mixed
        keybind = super+f=open_config
        """
    let effective = """
        keybind = super+c=copy_to_clipboard:mixed
        keybind = super+f=my_custom_action
        keybind = super+g=new_binding
        """
    let catalog = ghosttyCatalog(defaultOutput: defaults, effectiveOutput: effective)

    let byAction = { (action: String) in catalog.keybindings.first { $0.action == action } }
    expect(byAction("copy_to_clipboard:mixed")?.isCustom == false, "既定と同じ binding は isCustom にしない")
    expect(byAction("my_custom_action")?.isCustom == true, "action が既定と違う binding は isCustom にする")
    expect(byAction("new_binding")?.isCustom == true, "既定に無い binding は isCustom にする")
    expect(
        byAction("new_binding")?.description == "new_binding",
        "未知 action は action 名を description にする"
    )
}

@MainActor
func runGhosttySpec() {
    runGhosttyParseSpec()
    runGhosttyCustomSpec()
}
