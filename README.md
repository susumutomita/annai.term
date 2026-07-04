# annai-term

Ghostty・Herdr のキーバインドを日本語で聞ける Mac ネイティブツールです。「右に分割して次のタブ」のように尋ねると、どの層（Ghostty / Herdr）のどのキーかを案内します。

本気の一人のためのオーダーメードソフトで、汎用性より Ghostty でのシームレスな体験を優先します。Swift ネイティブ・Mac 専用・オンデバイスの Apple Foundation Models 前提です（[ADR-0007](./docs/adr/0007-swift-native-mac-only-afm.md)）。

## インストール

macOS 26 以降と Swift ツールチェイン（Command Line Tools か Xcode）が要ります。どちらの経路もソースからビルドします。

Homebrew から入れる場合は次を実行します。

```bash
brew tap susumutomita/annai-term https://github.com/susumutomita/annai.term
brew install annai-term
```

make で `~/.local/bin` へ入れる場合は次を実行します。

```bash
git clone https://github.com/susumutomita/annai.term
cd annai.term
make install-cli
annai-term --version
```

`~/.local/bin` が PATH に無い場合は通してください。別の場所へ入れるときは `make install-cli PREFIX=/usr/local` のように指定します（`/usr/local` は sudo が要ることがあります）。試すだけなら `swift run annai-term ask "..."` でも動きます。

## 使い方

```bash
annai-term ask "右に分割して次のタブ"   # 質問に合うキーバインドを 1 件案内します
annai-term doctor                        # 読み込んだ設定・件数・競合・モデル可否を表示します
```

回答にはどの層のどのキーかと補足を必ず添えます。該当が無いときは該当なしと返し、近そうなキーは捏造しません。

## 起動ショートカット（オーバーレイ）

オーバーレイ版 `annai-term-overlay` は常駐して Cmd + Option + Space で呼び出します。Ghostty はプラグイン API も任意コマンドの keybind 実行も持たないため、Ghostty 自身から直接起動する経路はありません。

- オーバーレイ版のグローバルホットキーで、どのアプリの上でも呼び出す。
- CLI 版はシェルの alias（例: `alias an='annai-term ask'`）で素早く呼ぶ。

オーバーレイの global hotkey は `.app` バンドル化とアクセシビリティ権限が前提です。

## 仕組み

質問はローカルだけで処理します。

- Adapters: `ghostty +list-keybinds` と `~/.config/herdr/config.toml` を読む。
- Catalog: chord を正規化し、default と user を merge し、層をまたぐ競合を検出する。
- Engine: 同義語辞書で候補を絞り、回答を組み立てる。
- Backend: Apple Foundation Models で候補から 1 件を選ぶ。棄権や利用不可のときは決定的な retrieval にフォールバックする。

設計正本は [docs/design/annai-term-v1.md](./docs/design/annai-term-v1.md) です。

## 設定の探索順

- Ghostty: `ghostty +list-keybinds --default` と `--plain` を一次ソースにし、実効値とデフォルトの差分で isCustom を導く。config は `$XDG_CONFIG_HOME/ghostty/config` と `~/.config/ghostty/config` を見る。
- Herdr: `~/.config/herdr/config.toml`（`$XDG_CONFIG_HOME` を優先）を読み、デフォルトカタログと merge する。無ければデフォルトカタログだけで動く。

## プライバシー

- 推論はオンデバイスの Apple Foundation Models で完結する。クラウド LLM・API キー・テレメトリーは持たない。
- モデルへ渡すのは「質問」と「正規化済みの候補（id・source・scope・display・action・description）」だけ。pane 内容・shell history・コードは payload の型に構造上含まれず、`PrivacySpec` でプロンプトを再構成できることを検証している。

## 既知の制限

- Apple Foundation Models は macOS 26 と Apple Intelligence を要求する。利用できない環境では決定的な retrieval にフォールバックする。
- オーバーレイ版の対話動作にはアクセシビリティ権限と `.app` バンドル化が要る。
- GitHub-hosted の CI に macOS 26 runner が無いため、CI は repo ガバナンスのみを検証する。Swift の製品ゲートと release ビルドはローカルか macOS 26 runner で回す。

## 開発

```bash
make swift_check     # build + spec + カバレッジ 100% + swift format lint
make before-commit   # 上記 + repo ガバナンス（architecture-harness / skill 監査 / doc lint）
```

リポジトリのガバナンスは typescript-template 由来の Bun 製ハーネスを使います。設計判断は [docs/adr/](./docs/adr/)、invariant は [docs/architecture/harness.md](./docs/architecture/harness.md) を参照します。

## ライセンス

MIT。
