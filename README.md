# typescript-template

TypeScript + Bun + Biome を使った Claude Code 向けモノレポテンプレート。

## このリポジトリについて

このリポジトリは annai-term を開発する独立リポジトリです。annai-term は Ghostty・Herdr のキーバインドを日本語で案内する Mac ネイティブアプリで、本気の一人のためのオーダーメードソフトです。汎用性より Ghostty でのシームレスな体験を優先し、Swift ネイティブ・Mac 専用・AFM 前提で作ります。リポジトリのガバナンス（architecture-harness・skill 監査・doc lint）はテンプレート由来の Bun 製ハーネスを引き続き使います。

- 採用の判断: [ADR-0006](./docs/adr/0006-adopt-annai-term-standalone.md)
- Mac 専用・Swift ネイティブ・AFM 前提: [ADR-0007](./docs/adr/0007-swift-native-mac-only-afm.md)
- V1 設計正本: [docs/design/annai-term-v1.md](./docs/design/annai-term-v1.md)
- 実装: `Package.swift` / `Sources/`、品質ゲートは `make swift_check`

## annai-term の使い方

ビルドは Swift ツールチェイン（macOS 26 以降）で行います。

```bash
swift build -c release          # .build/release/annai-term ができます
annai-term ask "右に分割して次のタブ"   # 質問に合うキーバインドを 1 件案内します
annai-term doctor               # 読み込んだ設定・件数・競合・モデル可否を表示します
```

回答には、どの層（Ghostty / Herdr）のどのキーかと補足を必ず添えます。該当が無いときは該当なしと返し、近そうなキーは捏造しません。

オーバーレイ版（`annai-term-overlay`）は常駐して Cmd + Option + Space で呼び出します。global hotkey を使うため、`.app` バンドル化とアクセシビリティ権限が必要です。

## 起動ショートカット

Ghostty はプラグイン API も任意コマンドの keybind 実行も持たないため、Ghostty 自身から直接起動する経路はありません。次のどちらかで起動します。

- オーバーレイ版のグローバルホットキー（Cmd + Option + Space）で、どのアプリの上でも呼び出す。
- CLI 版はシェルの alias（例: `alias an='annai-term ask'`）で素早く呼ぶ。

## 設定の探索順

- Ghostty: `ghostty +list-keybinds --default` と `--plain` を一次ソースにし、実効値とデフォルトの差分で isCustom を導く。config は `$XDG_CONFIG_HOME/ghostty/config` と `~/.config/ghostty/config` を見る。
- Herdr: `~/.config/herdr/config.toml`（`$XDG_CONFIG_HOME` を優先）を読み、デフォルトカタログと merge する。無ければデフォルトカタログだけで動く。

## プライバシー

- 推論はオンデバイスの Apple Foundation Models で完結する。クラウド LLM・API キー・テレメトリーは持たない。
- モデルへ渡すのは「質問」と「正規化済みの候補（id・source・scope・display・action・description）」だけ。pane 内容・shell history・コードは payload の型に構造上含まれず、`PrivacySpec` でプロンプトを再構成できることを検証している。

## 既知の制限

- Apple Foundation Models は macOS 26 と Apple Intelligence を要求する。利用できない環境では決定的な retrieval にフォールバックする。
- オーバーレイ版の対話動作にはアクセシビリティ権限と `.app` バンドル化が要る。CI は macOS 26 runner が無いため repo ガバナンスのみを検証し、Swift の製品ゲートはローカルで回す。
- OS・IME・アプリフォーカス層はすべては観測しきれないため、競合の説明では「推定」と明示する。

## ツールスタック

| 用途 | ツール |
|------|--------|
| ランタイム | Bun |
| バックエンド | Hono |
| フロントエンド | Vite + React |
| リンター/フォーマッター | Biome |
| テスト | bun test |
| Git フック | Husky + lint-staged |

## セットアップ

```bash
# 依存をインストール（lifecycle scripts 無効）
make install

# Git hooks を有効化（必要時のみ）
make setup-hooks

# プロジェクトをスキャフォールド（初回のみ）
# Claude Code で以下を実行
/init-project
```

## コマンド

```bash
make install        # 依存をインストール（ignore-scripts）
make setup-hooks    # Husky hooks をセットアップ
make dev            # 全パッケージを開発モードで起動
make lint           # biome check
make format         # biome format
make typecheck      # tsc --noEmit（全ワークスペース）
make test           # bun test（全ワークスペース）
make harness_test   # architecture-harness の検出ロジックをテスト
make build          # ビルド（全ワークスペース）
make before-commit  # コミット前チェック（harness + harness_test + lint_text + lint）
```

## スキル

| スキル | 説明 |
|--------|------|
| `/init-project` | packages/backend（Hono）と packages/frontend（Vite + React）をスキャフォールド |
| `/feature` | 新機能開発のオーケストレーション（ヒアリング → 仕様化 → Issue → 並列実装） |
| `/architecture-harness` | invariant の機械検証。`why <RULE_ID>` で意図を表示 |
| `/skill-audit` | スキル・フック・設定の監査。サードパーティスキルの導入前検査 |
| `/follow-up` | scope 外の発見をフォローアップとして記録・解消管理 |
| `/frontend-design` | 高品質なフロントエンド実装 |

## ディレクトリ構成

```
.
├── .claude/
│   ├── settings.json       # Claude Code フック設定
│   ├── rules/              # path-scoped ルール（対象パス作業時に自動ロード）
│   ├── scripts/            # フック実行スクリプト
│   └── skills/             # カスタムスキル
├── packages/
│   ├── backend/            # /init-project で Hono サーバーを生成
│   └── frontend/           # /init-project で Vite + React を生成
├── biome.json              # リンター/フォーマッター設定
├── CLAUDE.md               # AI エージェント向け開発ガイドライン
└── Makefile
```

## サプライチェイン防御

このテンプレートは Shai-Hulud 系（[Flatt Security の解説](https://blog.flatt.tech/entry/mini_shai_hulud_2nd)）のサプライチェイン攻撃を多層で防ぐデフォルト値を持つ。

- `make install` / `make install_ci` は常に `--ignore-scripts` を付ける。**Bun は `.npmrc` の `ignore-scripts` も `npm_config_ignore_scripts` 環境変数も読まない**（公式 docs では `bunfig.toml` のみが設定経路）ため、Bun を叩くコマンド側で毎回明示する必要がある。husky の `prepare` も巻き添えで止まるので `make setup-hooks` で明示的に opt-in する。
- `bunfig.toml` の `trustedDependencies = []` で、Bun がデフォルトで信頼する「top 500 npm パッケージ」の lifecycle script もゼロにする。
- `make before-commit` が走らせる `architecture-harness` が、Git URL 依存・lifecycle hook の濫用・IOC ファイル名・ロックファイル内の Git 解決を機械的に検出する（`INVARIANT_NO_GIT_DEPENDENCY` / `INVARIANT_LIFECYCLE_HOOK_SCOPED` / `INVARIANT_NO_KNOWN_IOC` / `INVARIANT_LOCKFILE_NO_GIT_RESOLUTION`）。
- CI は `safe-chain` + 上記設定で重ねる。
- `.npmrc` は **意図的に置かない**。Bun は読まないので Bun の防御には寄与せず、「効いていそうで効いていない」security theater になるため。本テンプレートは Bun 専用。pnpm/npm/yarn を併用する派生プロジェクトは自分で `.npmrc` を足す。

設計判断の正本は [ADR-0001](./docs/adr/0001-supply-chain-hardening.md)、invariant 一覧は [docs/architecture/harness.md](./docs/architecture/harness.md) を参照。

## スキル・フックの監査

スキル（`.claude/skills/`）とフック（`.claude/scripts/`、`.claude/settings.json`）はモデルのコンテキストに注入される実行可能な指示であり、npm 依存と同じくサプライチェインの一部として扱う。[NVIDIA SkillSpector](https://github.com/nvidia/skillspector) の知見を `architecture-harness` に移植し、以下を機械検出する。

- `INVARIANT_SKILL_FRONTMATTER_VALID` — SKILL.md の frontmatter 検証（name とディレクトリ名の一致、description の品質）。
- `INVARIANT_SKILL_NO_HIDDEN_INSTRUCTIONS` — 不可視 Unicode・base64 ブロック・HTML コメントによる隠し指示の検出。
- `INVARIANT_SKILL_NO_EXFIL_EXEC` — リモート取得のシェルパイプ実行・base64 デコード実行の検出。

サードパーティスキルの導入前検査と目視レビューのチェックリストは `/skill-audit` スキルに集約している。設計判断は [ADR-0002](./docs/adr/0002-skill-audit-invariants.md) を参照。

## 開発ガイドライン

[CLAUDE.md](./CLAUDE.md) を参照。完了の品質基準は [docs/architecture/quality-bar.md](./docs/architecture/quality-bar.md)、その根拠は [ADR-0003](./docs/adr/0003-quality-first-no-mvp.md) にある。MVP は完了条件ではない。プロがそのまま使える品質で初回から出すことをデフォルトとする。
