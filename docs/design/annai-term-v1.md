# annai-term V1 設計（アーキテクチャ正本）

親 Issue: [susumutomita/annai.term#1](https://github.com/susumutomita/annai.term/issues/1)。本書は V1 全体の設計正本であり、実装 Issue はここを参照する。判断の背景は [ADR-0006](../adr/0006-adopt-annai-term-standalone.md)（独立リポジトリ採用）と [ADR-0007](../adr/0007-swift-native-mac-only-afm.md)（Mac 専用・Swift ネイティブ・AFM 前提）。

## 製品原則

- 本気の一人のためのオーダーメードソフト。対象ユーザーは開発者本人ただ 1 人。汎用性より Ghostty でのシームレスな体験を優先する。
- Mac 専用（macOS 26 以降）。Swift ネイティブ。AFM 前提でオンデバイス完結。
- 実在するキーだけを答える。Ghostty / Herdr / user config のどの層のキーかを必ず表示する。
- 該当なしは該当なしと返し、近そうなキーを捏造しない。
- 質問・設定・画面内容・shell history・コードを外部へ送らない。

## 起動モデル（シームレスの要）

Ghostty はプラグイン API を持たず、keybind も固定アクションにしか割り当てられない（任意コマンド実行アクションが無い）。そのため「Ghostty から起動する」経路ではシームレスにならない。V1 は次の 2 経路を持つ。

- **オーバーレイ（主）**: 常駐アプリがシステムのグローバルホットキーを登録し、どのアプリの上でも AppKit のボーダーレスパネルを即座に出す。質問を打ち、回答（層 / キー / 補足 / 競合注記）を見て、Esc で消す。Ghostty で作業中でもフォーカスを奪わずに聞ける。
- **CLI（従）**: `annai-term ask "<質問>"` と `annai-term doctor`。スクリプト・非対話用途と診断用。

## アーキテクチャ全体

データは一方向に流れる。依存の向きは矢印方向のみを許す。

```text
Adapters ──▶ Catalog ──▶ Engine ──▶ Overlay(App) / CLI
              (型)         ▲
                          │
             Backend ─────┘（Engine から呼ばれる。Catalog の型に依存）
```

| モジュール（Swift target） | 責務 |
| --- | --- |
| `AdapterKit` | Ghostty（`ghostty +list-keybinds`）/ Herdr（`config.toml`）の生設定を読み、raw keybind を取り出す。 |
| `CatalogKit` | raw keybind を正規化し、競合を検出して `[Keybinding]` を作る（default と user の merge は各 adapter が行う）。 |
| `EngineKit` | 質問から候補を絞り（retrieve）、Backend に制約付き選択をさせ（answer）、層情報付きの回答を組み立てる（explain）。 |
| `AFMBackend` | AFM（`FoundationModels`）による候補からの分類。Ollama を任意 fallback に持つ。 |
| `AnnaiTermApp` | グローバルホットキー + AppKit オーバーレイ。composition root。 |
| `AnnaiTermCLI` | `ask` / `doctor` の実行体。`AnnaiTermKit` を薄く包む。 |
| `AnnaiTermKit` | 純ロジック（引数解釈など）。副作用を持たず 100% カバーする。 |

各層の受け入れ条件は対応する実装 Issue に置く。本書はモジュール境界・型・依存の向き・縮退動作を固定する。

## ドメイン型（正本）

```swift
struct Chord: Equatable, Sendable {
    let modifiers: [String]  // canonical order: super → ctrl → alt → shift
    let key: String
    var canonical: String    // 例: "super+shift+j" / "super++"
    var display: String      // 例: "Cmd + Shift + J" / "Cmd + +"
}

struct Keybinding: Equatable, Sendable {
    enum Source: String, Sendable { case ghostty, herdr, user, generic }
    enum Scope: String, Sendable { case app, terminal, multiplexer, shell }
    let id: String
    let source: Source
    let scope: Scope
    let sequence: [Chord]    // 多段入力。例: [Ctrl+B, V]。正規化済み chord の列
    let action: String
    let description: String
    let configPath: String?
    let isCustom: Bool
    let precedence: Int       // 小さいほど先にキーを奪う
    var display: String       // sequence を " → " で連結
}

struct Answer: Equatable, Sendable {
    enum Confidence: String, Sendable { case high, low, none }
    let keybindingId: String?
    let confidence: Confidence
    let explanation: String
    let conflictNote: String?
    let followUp: String?
}
```

### precedence の割り当て

| 層 | source | precedence |
| --- | --- | --- |
| OS / IME（観測不能） | （カタログに載せない） | 50（予約） |
| ターミナルアプリ | `ghostty` | 100 |
| multiplexer | `herdr` | 200 |
| shell | （将来） | 300 |

OS / IME / アプリフォーカス層は完全には観測できないため、V1 ではカタログに載せず、競合説明では「推定」と明示する。

## LLM の役割と privacy

- Backend へ渡す payload の構築を EngineKit 内の単一関数に集約し、その入力型を「質問・正規化済み `[Keybinding]`・各 binding の source / scope / precedence」に閉じる。pane 内容・shell history・コードは構造上渡せない。
- AFM は `keybindingId` を選ぶ分類だけを行う。候補集合に無い ID は reject し、`confidence: .none` の該当なしとして扱う。
- 送信先はオンデバイス AFM のみ。Ollama を使う場合も `localhost` に限定する。

## 縮退動作（エッジケース正本）

| 状況 | 挙動 |
| --- | --- |
| Ghostty user config 無し | 既定 keybind のみでカタログ生成。doctor に「user config 無し」を表示。 |
| Ghostty バイナリ無し | config パースと同梱既定スナップショットに縮退。実効値は「推定」と明示。 |
| Herdr config.toml 無し | 既定カタログのみで動く（正常系）。 |
| AFM 利用不可 | 決定的 retrieval による候補一覧を提示。捏造しない。 |
| 該当キー無し | 該当なしを返す。近そうなキーを捏造しない。 |
| 解釈不能な設定行 | 補完せず「不明」として doctor に集約する。 |
| 同一 chord を複数層が取る | 競合として検出し、どの層が先に処理するかを説明する。観測不能要因は「推定」と明示。 |
| グローバルホットキーの権限が無い | オーバーレイを起動せず CLI の使い方を案内する。 |

## 品質ゲート（Swift）

XCTest / swift-testing は Xcode 同梱で Command Line Tools には無い。CI が Xcode 非依存で回せるよう、テストは Xcode 非依存のスペックランナー `AnnaiTermSpec`（`swift run AnnaiTermSpec`）で実行し、カバレッジは計装ビルド + `llvm-cov` で測る（`scripts/swift-coverage.sh`、100% 未満で fail）。lint は toolchain 同梱の `swift format`。まとめて `make swift_check`。リポジトリのガバナンス（architecture-harness / skill 監査 / doc lint）は bun 製のまま維持する。

## 実装の分割

依存順に、足場 → CatalogKit → AdapterKit（Ghostty / Herdr）・AFMBackend → EngineKit → CLI（`ask` / `doctor`）→ Overlay（グローバルホットキー + AppKit）→ privacy 保証と README。既存 Issue [#2](https://github.com/susumutomita/annai.term/issues/2) 〜 [#10](https://github.com/susumutomita/annai.term/issues/10) を Swift ベースに再設計する。

## 足場（Issue 2）のスコープ

- 本設計正本と ADR-0006 / ADR-0007。
- SwiftPM プロジェクト（`Package.swift` / `AnnaiTermKit` / `AnnaiTermCLI` / `AnnaiTermSpec`）。CLI は `--version` / `--help` のみ実装し、未実装コマンドへの言及やプレースホルダは置かない。
- Swift 品質ゲート（`make swift_check`）と README への採用明記。

V1 の他モジュール（AdapterKit / CatalogKit / EngineKit / AFMBackend / Overlay）は本 Issue のスコープ外であり、上記の依存順で各 Issue が実装する。
