# ADR-0007: annai-term を Mac 専用・Swift ネイティブ・AFM 前提で作る

- **Status**: Accepted
- **Date**: 2026-07-04
- **Deciders**: Susumu Tomita (@susumutomita)

## Context

annai-term は「本気の一人のためのオーダーメードソフト」であり、対象ユーザーは開発者本人ただ 1 人である。したがって汎用性（クロスプラットフォーム対応、複数 multiplexer 対応）は目標ではなく、Ghostty でシームレスに聞ける体験を最優先する。

検討の結果、次の事実が判明した。

- Ghostty には **プラグイン API もスクリプト機構も無い**。設定は config ファイルと固定アクション（実機の `ghostty +list-actions` で 85 個）だけで、keybind は固定アクションにしか割り当てられない。「任意コマンドを実行する」アクションが無いため、keybind から `annai-term` を直接起動することすらネイティブにはできない。
- したがって「Ghostty のプラグイン」や「Ghostty の keybind から起動する純 CLI」では真のシームレスさに届かない。
- Apple Foundation Models（AFM）は `FoundationModels` フレームワーク（Swift 専用）からしか呼べず、オンデバイスで動く。対象環境は macOS 26 + Apple Intelligence。

当初の草案（[PR #11](https://github.com/susumutomita/annai.term/pull/11)、未マージ）は Bun / TypeScript のクロスプラットフォーム CLI + Ollama fallback だった。これは上記の優先順位（単一ユーザー・Mac・シームレス・AFM）と噛み合わない。

## Decision

annai-term を Mac 専用・Swift ネイティブ・AFM 前提で作る。[親 Issue](https://github.com/susumutomita/annai.term/issues/1) の「ターミナル内で完結・macOS GUI アプリは対象外」の制約は、本 ADR で緩和して supersede する（Ghostty にシームレスな起動経路が無いため）。

- **実装**: Swift / SwiftPM。対象は macOS 26 以降。クロスプラットフォーム（Linux 等）は捨てる。
- **起動**: 常駐アプリがシステムのグローバルホットキーを登録し、どのアプリの上でも即座に AppKit のボーダーレスオーバーレイパネルを出して聞ける。加えて one-shot / 診断用に `annai-term` CLI（`ask` / `doctor`）を持つ。
- **バックエンド**: AFM（`FoundationModels`）を primary とする。クラウド LLM・API キー・テレメトリー・クラッシュレポート送信は持たない。プライバシー原則（質問・設定・画面内容・shell history・コードを外部へ送らない）はオンデバイス AFM でむしろ強くなる。Ollama はローカル開発時の任意 fallback として残すが必須ではない。
- **制約付き選択は維持**: LLM は候補の `keybindingId` を選ぶ分類だけを行い、候補外の ID は reject する。捏造しない。
- **品質ゲートを Swift 用に作り直す**: `swift build` + Xcode 非依存スペックランナー（`AnnaiTermSpec`）+ `llvm-cov` によるカバレッジ 100% + `swift format` lint。リポジトリのガバナンス（architecture-harness / skill 監査 / doc lint）は bun 製のまま維持する。

### 代替案の比較

| 案 | 内容 | 判定 |
| --- | --- | --- |
| TS コア + AFM だけ Swift ブリッジ | Bun/TS で全層を書き、AFM 呼び出しだけ Swift サブプロセス。ハーネスを活かせクロスプラットフォーム。 | 却下。グローバルホットキーのオーバーレイをネイティブに持てず、シームレス度が一段下がる。単一ユーザー・Mac 専用なのでクロスプラットフォームの利点は不要。 |
| Swift ネイティブ（採用） | 全層 Swift。AFM とグローバルホットキーオーバーレイをネイティブに扱う。 | 採用。最もシームレスで、AFM を直接呼べ、単一の自己完結アプリになる。 |

## Consequences

- **Good**: グローバルホットキーで真のシームレス起動。AFM をプロセス内で直接呼べる。Bun ランタイム非依存の単一アプリ。オンデバイスでプライバシーが強い。
- **Bad**: Linux の Ghostty / Herdr 利用者を捨てる（単一ユーザー専用なので許容）。macOS 26 + Apple Intelligence を要求する。この repo の TS/Bun ハーネスは製品コード（Swift）には効かず、Swift 側のゲートを別途持つ。未マージの TS 足場（PR #11）は破棄。
- **Tradeoff**: `annai.nvim` とのコア共有（JS 寄り）から遠ざかる。再検討トリガーは「対象ユーザーが増える / 他 OS が必要になる」場合で、そのときは本 ADR を supersede する。CLAUDE.md / AGENTS.md のスタック記述（Bun / Hono / Vite）と `/feature` フローの Swift 対応、未使用 TS ツールの撤去はフォローアップで扱う。

## References

- 関連 Issue: [親 Issue](https://github.com/susumutomita/annai.term/issues/1)
- 関連 PR: [PR #11（未マージ・破棄）](https://github.com/susumutomita/annai.term/pull/11)
- 関連設計: [docs/design/annai-term-v1.md](../design/annai-term-v1.md)
- 関連 ADR: [ADR-0006](./0006-adopt-annai-term-standalone.md)
- 外部資料: [Ghostty config reference](https://ghostty.org/docs/config/reference)、[Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels)
