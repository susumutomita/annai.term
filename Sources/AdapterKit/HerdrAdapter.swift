import CatalogKit
import Foundation

// Herdr の既定 keybind。正本は https://herdr.dev/docs/keyboard/（prefix = Ctrl+B）。
// 対応バージョンが変わったら doc を再確認してここを更新する。捏造せず docs 由来だけを載せる。
private struct HerdrDefault {
    let suffix: String
    let action: String
    let description: String
}

private let herdrDefaults: [HerdrDefault] =
    [
        HerdrDefault(suffix: "c", action: "new_tab", description: "新しいタブを作る"),
        HerdrDefault(suffix: "v", action: "split_vertical", description: "右にペインを分割"),
        HerdrDefault(suffix: "-", action: "split_horizontal", description: "下にペインを分割"),
        HerdrDefault(suffix: "h", action: "focus_pane", description: "左のペインへ移動"),
        HerdrDefault(suffix: "j", action: "focus_pane", description: "下のペインへ移動"),
        HerdrDefault(suffix: "k", action: "focus_pane", description: "上のペインへ移動"),
        HerdrDefault(suffix: "l", action: "focus_pane", description: "右のペインへ移動"),
        HerdrDefault(suffix: "w", action: "workspace_navigation", description: "ワークスペースピッカー"),
        HerdrDefault(suffix: "q", action: "detach", description: "セッションを残して切断"),
        HerdrDefault(suffix: "z", action: "zoom", description: "ペインを拡大"),
        HerdrDefault(suffix: "x", action: "close_pane", description: "ペインを閉じる"),
        HerdrDefault(suffix: "shift+h", action: "swap_panes", description: "ペインを左と入れ替え"),
        HerdrDefault(suffix: "shift+j", action: "swap_panes", description: "ペインを下と入れ替え"),
        HerdrDefault(suffix: "shift+k", action: "swap_panes", description: "ペインを上と入れ替え"),
        HerdrDefault(suffix: "shift+l", action: "swap_panes", description: "ペインを右と入れ替え"),
        HerdrDefault(suffix: "r", action: "resize_mode", description: "リサイズモード"),
        HerdrDefault(suffix: "[", action: "copy_mode", description: "コピーモード"),
        HerdrDefault(suffix: "n", action: "next_tab", description: "次のタブ"),
        HerdrDefault(suffix: "p", action: "previous_tab", description: "前のタブ"),
        HerdrDefault(suffix: "shift+t", action: "rename_tab", description: "タブ名を変更"),
        HerdrDefault(suffix: "shift+x", action: "close_tab", description: "タブを閉じる"),
        HerdrDefault(suffix: "shift+n", action: "new_workspace", description: "ワークスペースを作る"),
        HerdrDefault(suffix: "shift+w", action: "rename_workspace", description: "ワークスペース名を変更"),
        HerdrDefault(suffix: "shift+d", action: "close_workspace", description: "ワークスペースを削除"),
        HerdrDefault(suffix: "g", action: "goto_picker", description: "goto ピッカー"),
        HerdrDefault(suffix: "b", action: "toggle_sidebar", description: "サイドバーの表示切替"),
    ]
    + (1...9).map {
        HerdrDefault(suffix: "\($0)", action: "jump_to_tab", description: "タブ \($0) へ移動")
    }

private func herdrBinding(
    prefix: Chord,
    suffix: String,
    action: String,
    description: String,
    isCustom: Bool
) -> Keybinding {
    let sequence = [prefix] + normalizeSequence(suffix)
    return Keybinding(
        id: "herdr:" + sequence.map(\.canonical).joined(separator: ">"),
        source: .herdr,
        scope: .multiplexer,
        sequence: sequence,
        action: action,
        description: description,
        isCustom: isCustom,
        precedence: 200
    )
}

/// Herdr の既定カタログを指定 prefix で組み立てる（prefix 変更を display / sequence に反映）。
public func herdrDefaultCatalog(prefix: Chord = normalizeChord("ctrl+b")) -> [Keybinding] {
    herdrDefaults.map {
        herdrBinding(
            prefix: prefix,
            suffix: $0.suffix,
            action: $0.action,
            description: $0.description,
            isCustom: false
        )
    }
}
