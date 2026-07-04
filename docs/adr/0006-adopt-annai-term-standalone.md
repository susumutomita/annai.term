# ADR-0006: annai.term を独立リポジトリとして採用する

- **Status**: Accepted
- **Date**: 2026-07-04
- **Deciders**: Susumu Tomita (@susumutomita)

## Context

`annai.nvim` の [Issue 8](https://github.com/susumutomita/annai.nvim/issues/8) で「Ghostty・Herdr を自然言語で案内する」構想が生まれた。しかし操作の入口は macOS → Ghostty（ターミナルアプリ）→ Herdr（pane / tab / workspace / agent 操作）→ shell と多層に分かれ、Neovim プラグインに閉じると Ghostty が先に奪うキーバインドを案内できない。Herdr 専用プラグインでも同じ制約がある。

本リポジトリは `typescript-template` 由来のハーネス（サプライチェーン防御・architecture-harness invariant・品質バー）を持つ。この土台の上で「ターミナル内で完結する独立 CLI / TUI」を新規プロダクトとして開発する必要がある。移管元の課題は [親 Issue](https://github.com/susumutomita/annai.term/issues/1) に集約した。

## Decision

`annai.nvim` の当該構想を `annai.term` へ移管し、独立リポジトリとして開発する。

- 実行体は `annai-term` 単体の CLI / TUI とする。stdin / stdout だけで動き、Ghostty / Herdr の plugin API に依存しない。
- どのターミナルからでも起動でき、Ghostty / Herdr へ任意のショートカットを割り当てる設定例は案内するが、実行体は常に `annai-term` 単独で成立する。
- 将来 `annai.nvim` と共通の catalog / constrained-selection / local-backend core を抽出する余地を残す。ただし共通利用者が実在するまでは分離せず、単一パッケージ内のモジュール境界で責務を分ける（パッケージ構成の詳細は [docs/design/annai-term-v1.md](../design/annai-term-v1.md)）。

代替として `annai.nvim` に内包したまま拡張する案があったが、Ghostty 層のキーを案内できない構造的な限界があるため退けた。

## Consequences

- **Good**: ターミナルのどの層から来たキーでも一貫して案内できる。ハーネスと品質バーを最初から継承した状態で V1 を始められる。
- **Bad**: `annai.nvim` と実装が二重化する期間が生じる。将来の core 抽出まで重複を許容する。
- **Tradeoff**: 早すぎる共通化（最初から core / cli を別パッケージに割る）は捨てた。再検討のトリガーは「`annai.nvim` が同じ catalog / selection ロジックを実際に必要としたとき」とし、その時点で core を別パッケージへ切り出す（ADR で追記する）。

## References

- 関連 Issue: [親 Issue](https://github.com/susumutomita/annai.term/issues/1)、[移管元 annai.nvim#8](https://github.com/susumutomita/annai.nvim/issues/8)
- 関連設計: [docs/design/annai-term-v1.md](../design/annai-term-v1.md)
- 関連 ADR: [ADR-0007](./0007-local-llm-first-no-cloud.md)
- 外部資料: [Ghostty config reference](https://ghostty.org/docs/config/reference)、[Herdr keyboard](https://herdr.dev/docs/keyboard/)
