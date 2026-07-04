# ADR-0006: annai.term を独立リポジトリとして採用する

- **Status**: Accepted
- **Date**: 2026-07-04
- **Deciders**: Susumu Tomita (@susumutomita)

## Context

`annai.nvim` の [Issue 8](https://github.com/susumutomita/annai.nvim/issues/8) で「Ghostty・Herdr を自然言語で案内する」構想が生まれた。しかし操作の入口は macOS → Ghostty（ターミナルアプリ）→ Herdr（pane / tab / workspace / agent 操作）→ shell と多層に分かれ、Neovim プラグインに閉じると Ghostty が先に奪うキーバインドを案内できない。

本リポジトリは `typescript-template` 由来のハーネス（architecture-harness invariant・品質バー・skill 監査）を持つ。この統制の土台の上で、Ghostty / Herdr を案内する新規プロダクトを独立して開発する。移管元の課題は [親 Issue](https://github.com/susumutomita/annai.term/issues/1) に集約した。

## Decision

`annai.nvim` の当該構想を `annai.term` へ移管し、独立リポジトリとして開発する。

- 実行体は `annai-term` として単独で成立させる。Ghostty / Herdr の plugin API に依存しない（そもそも Ghostty にプラグイン機構は無い。詳細は [ADR-0007](./0007-swift-native-mac-only-afm.md)）。
- リポジトリのガバナンス層（architecture-harness / skill 監査 / doc lint）は継承する。製品コードの実装スタックは本 ADR では固定せず、[ADR-0007](./0007-swift-native-mac-only-afm.md) で決める。

代替として `annai.nvim` に内包したまま拡張する案があったが、Ghostty 層のキーを案内できない構造的な限界があるため退けた。

## Consequences

- **Good**: ターミナルのどの層から来たキーでも一貫して案内できる。ハーネスと品質バーを最初から継承した状態で開発を始められる。
- **Bad**: `annai.nvim` と発想が二重化する期間が生じる。
- **Tradeoff**: リポジトリのガバナンスは TS/Bun 製のまま残るため、製品を別スタックにすると一部ツールが製品コードに効かない。この扱いは [ADR-0007](./0007-swift-native-mac-only-afm.md) で明示する。

## References

- 関連 Issue: [親 Issue](https://github.com/susumutomita/annai.term/issues/1)、[移管元 annai.nvim#8](https://github.com/susumutomita/annai.nvim/issues/8)
- 関連 ADR: [ADR-0007](./0007-swift-native-mac-only-afm.md)
- 外部資料: [Ghostty config reference](https://ghostty.org/docs/config/reference)、[Herdr keyboard](https://herdr.dev/docs/keyboard/)
