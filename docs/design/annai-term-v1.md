# annai-term V1 設計（アーキテクチャ正本）

親 Issue: [susumutomita/annai.term#1](https://github.com/susumutomita/annai.term/issues/1)。本書は V1 全体の設計正本であり、実装 Issue（[#2](https://github.com/susumutomita/annai.term/issues/2) 〜 [#10](https://github.com/susumutomita/annai.term/issues/10)）はここを参照する。判断の背景は [ADR-0006](../adr/0006-adopt-annai-term-standalone.md)（独立リポジトリ採用）と [ADR-0007](../adr/0007-local-llm-first-no-cloud.md)（ローカル LLM 方針）。

## 目的とプロダクト像

Ghostty（ターミナルアプリ）と Herdr（ターミナル workspace マネージャ）のキーバインドを、日本語の質問から案内するターミナル完結の CLI / TUI。

- 実在するキーだけを答える。
- Ghostty / Herdr / user config のどの層のキーかを必ず表示する。
- 該当なしは該当なしと返し、近そうなキーを捏造しない。
- 質問・設定・画面内容・shell history・コードを外部へ送らない。

## アーキテクチャ全体

データは一方向に流れる。依存の向きは下記の矢印方向のみを許し、逆流させない。

```text
adapters ──▶ catalog ──▶ engine ──▶ cli / tui
              (型)         ▲
                          │
             backends ────┘（engine から呼ばれる。catalog の型に依存）
```

| モジュール | 責務 |
| --- | --- |
| `adapters/` | Ghostty / Herdr / generic の生設定を読み、raw な keybind を取り出す。 |
| `catalog/` | raw keybind を正規化・merge し、競合を検出して `Keybinding[]` を作る。 |
| `engine/` | 質問から候補を絞り（retrieve）、backend に制約付き選択をさせ（answer）、層情報付きの回答を組み立てる（explain）。 |
| `backends/` | ローカル LLM（Apple Foundation Models / Ollama）による候補からの分類。 |
| `cli/`・`tui/` | one-shot `ask` / `doctor`（cli）と対話画面（tui）。composition root はここに置く。 |

各層の詳細な受け入れ条件は対応する実装 Issue に置く。本書はモジュール境界・型・依存の向き・縮退動作を固定する。

## パッケージ構成の決定

採用: 単一パッケージ `packages/annai-term`（bin 名 `annai-term`）。モジュール境界はディレクトリで表現し、依存の一方向性は import の向きで保つ。

### 代替案の比較

| 案 | 内容 | 利点 | 欠点 |
| --- | --- | --- | --- |
| A（採用） | 単一パッケージ。`src/` 配下を adapters / catalog / engine / backends / cli / tui に分割。 | 版管理・ビルド配線が 1 つ。責務境界はディレクトリで明確。共通利用者が現れた時点で core を切り出せる。 | パッケージ境界による依存強制はないため、逆流はレビューと lint で防ぐ。 |
| B | 最初から `annai-core` と `annai-cli` の 2 パッケージに割る。 | core の再利用境界が物理的に固定される。 | 共通利用者（`annai.nvim`）がまだ実在せず、版管理・ビルド・型の配線コストを前払いする。YAGNI。 |
| C | workspace を使わずリポジトリ直下 `src/` に置く。 | 構成が最小。 | リポジトリは `packages/*` workspace とサプライチェーン harness を前提にしており、将来の core 分離もやりにくい。 |

### 選定理由

core 抽出（`annai.nvim` との共有）は [ADR-0006](../adr/0006-adopt-annai-term-standalone.md) の将来拡張であり、共有利用者が実在するまで前払いしない。案 A は責務をディレクトリ境界で分けつつ、抽出が必要になった時点で core を別パッケージへ移せる。最初に動いた構造ではなく、拡張点を残した最小構成を選ぶ。

## 依存方針

- `packages/annai-term` の実行時依存はゼロにする。引数パースは `node:util` の `parseArgs`、TOML / JSON / YAML の読み取りは Bun 標準（`Bun.TOML` / `Bun.YAML` / `import ... with { type: 'json' }`）を第一候補にする。
- TUI ライブラリの採否は [Issue 9](https://github.com/susumutomita/annai.term/issues/9) で比較して決める。React のような重い依存は避ける方針で評価する。
- TypeScript は typecheck / build のための開発依存であり、実行時依存には含めない。
- 依存を足す場合はレジストリ公開版の semver のみ（`INVARIANT_NO_GIT_DEPENDENCY`）。判断は ADR に残す。

## ドメイン型（正本）

```ts
type Keybinding = {
  id: string;
  source: 'ghostty' | 'herdr' | 'user' | 'generic';
  scope: 'app' | 'terminal' | 'multiplexer' | 'shell';
  sequence: string[]; // 多段入力。例: ['ctrl+b', 'v']
  display: string; // 表示用。例: 'Ctrl+B → V' / 'Cmd + +'
  action: string;
  description: string;
  configPath?: string;
  isCustom: boolean;
  precedence: number; // 小さいほど先にキーを奪う
};

type Answer = {
  keybindingId: string | null;
  confidence: 'high' | 'low' | 'none';
  explanation: string;
  conflictNote?: string;
  followUp?: string;
};
```

### precedence の割り当て

小さいほど先にキーを奪う。V1 は次の値を用いる。

| 層 | source | precedence |
| --- | --- | --- |
| OS / IME（観測不能） | （カタログに載せない） | 50（予約） |
| ターミナルアプリ | `ghostty` | 100 |
| multiplexer | `herdr` | 200 |
| shell | （将来） | 300 |

OS / IME / アプリフォーカス層は完全には観測できないため、V1 ではカタログに載せず、競合説明では「推定」と明示する。

## LLM の役割と privacy

- backend へ渡す payload の構築を engine 内の単一関数に集約し、その入力型を「質問・正規化済み `Keybinding[]`・各 binding の source / scope / precedence」に閉じる。pane 内容・shell history・コードは構造上渡せない（[Issue 10](https://github.com/susumutomita/annai.term/issues/10) で型とテストにより保証）。
- LLM は `keybindingId` を選ぶ分類だけを行う。返された ID が候補集合に無ければ reject し、`confidence: 'none'` の該当なしとして扱う。
- ネットワーク接続先は `localhost`（Ollama）のみ。それ以外は明示的に拒否する。

## 縮退動作（エッジケース正本）

「捏造しない・不明は不明と言う」を縮退仕様として固定する。

| 状況 | 挙動 |
| --- | --- |
| Ghostty user config 無し | 既定 keybind のみでカタログ生成。doctor に「user config 無し」を表示。 |
| Ghostty バイナリ無し | config パースと同梱既定スナップショット（取得元バージョン明記）に縮退。実効値は「推定」と明示。 |
| Herdr config.toml 無し | 既定カタログのみで動く（正常系）。 |
| ローカル LLM 無し | 決定的 retrieval による候補一覧を提示。捏造しない。 |
| 該当キー無し | 該当なしを返す。近そうなキーを捏造しない。 |
| 解釈不能な設定行 | 補完せず「不明」として doctor に集約する。 |
| 同一 chord を複数層が取る | 競合として検出し、どの層が先に処理するかを説明する。観測不能要因は「推定」と明示。 |
| 非 TTY で引数なし起動 | TUI を開始せず `ask` の使い方を案内して終了する。 |

## 実装の分割

依存順に [Issue 2](https://github.com/susumutomita/annai.term/issues/2)（足場・本設計・ADR）→ [Issue 3](https://github.com/susumutomita/annai.term/issues/3)（catalog）→ [Issue 4](https://github.com/susumutomita/annai.term/issues/4)・[Issue 5](https://github.com/susumutomita/annai.term/issues/5)（adapters）・[Issue 6](https://github.com/susumutomita/annai.term/issues/6)（backends）→ [Issue 7](https://github.com/susumutomita/annai.term/issues/7)（engine）→ [Issue 8](https://github.com/susumutomita/annai.term/issues/8)（cli）→ [Issue 9](https://github.com/susumutomita/annai.term/issues/9)（tui）→ [Issue 10](https://github.com/susumutomita/annai.term/issues/10)（privacy 保証と README）。

`adapters/generic.ts`（手動登録・将来の tmux / zellij）は V1 完了条件に含まれないため、着手時にフォローアップ Issue として起票する。

## Issue 2（本足場）のスコープ

- 本設計正本と ADR-0006 / ADR-0007。
- `packages/annai-term` の足場: `package.json`（bin `annai-term`）・`tsconfig.json`・エントリポイント（`--version` / `--help` のみ実装。未実装コマンドへの言及やプレースホルダは置かない）・テスト。
- 既存ゲート（`make before-commit` / typecheck / coverage 100% test / build）が回ること。README に独立リポジトリ採用を明記する。

V1 の他モジュール（adapters / catalog / engine / backends / tui）は本 Issue のスコープ外であり、上記の依存順で各 Issue が実装する。
