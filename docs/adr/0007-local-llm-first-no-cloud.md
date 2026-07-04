# ADR-0007: ローカル LLM 優先・クラウド LLM 不使用・テレメトリー無し

- **Status**: Accepted
- **Date**: 2026-07-04
- **Deciders**: Susumu Tomita (@susumutomita)

## Context

`annai-term` は利用者の質問・設定ファイル・画面内容・shell history・コードといった機微な文脈の近くで動く。[親 Issue](https://github.com/susumutomita/annai.term/issues/1) の最重要原則は「これらを外部へ送らない」ことである。一方で「実在するキーだけを答える」「該当なしは該当なしと返し、近そうなキーを捏造しない」ためには、自然言語の質問を解釈する仕組みが要る。クラウド LLM に丸投げすると privacy 原則と衝突し、キーを自由生成させると捏造を招く。

## Decision

LLM はローカルで動かし、役割を「候補からの制約付き選択」に限定する。

- バックエンド優先順位は Apple Foundation Models（オンデバイス、利用可能なら）→ ローカル Ollama（`localhost` のみ）。クラウド LLM・API キー・テレメトリー・クラッシュレポート送信は持たない。
- LLM へ渡す入力は「日本語の質問」と「正規化済みの `Keybinding[]`（各 binding の source / scope / precedence を含む）」に限定する。pane 内容・shell history・コードは構造上渡らないよう、payload 構築を単一関数に閉じる。
- LLM は `keybindingId` を選ぶ分類だけを行う。返された ID が catalog に存在しなければ reject し、該当なしを有効な結果として扱う。
- どのローカルバックエンドも利用できない場合は、決定的な retrieval（語彙検索）による候補一覧の提示に縮退する。LLM が無くても捏造せず候補は返す。

Apple Foundation Models は Swift API 経由のため Bun から直接呼べない。V1 では「Swift 製ヘルパーバイナリを同梱して子プロセスで呼ぶ」か「V1 は Ollama のみとし AFM をフォローアップにする」かを短い spike で判断し、結果を本 ADR を supersede する形で追記する。親 Issue の表現「利用可能なら」に沿い、後者を許容する。

## Consequences

- **Good**: 機微な文脈が端末外へ出ない。ネットワーク接続先が `localhost` に限定され、監査しやすい。捏造を構造的に防ぐ（候補外 ID は reject）。
- **Bad**: ローカルモデルの導入・性能・可用性に品質が左右される。AFM 対応はプラットフォーム制約でブリッジ実装が要る。
- **Tradeoff**: クラウド LLM の高い言語理解性能は捨てる。再検討のトリガーは「ローカルバックエンドだけでは実運用の解釈精度が不足すると計測で示されたとき」。その場合も原則（外部送信しない）は動かさず、オンデバイスモデルの強化で対応し、方針変更は ADR で supersede する。

## References

- 関連 Issue: [親 Issue](https://github.com/susumutomita/annai.term/issues/1)
- 関連設計: [docs/design/annai-term-v1.md](../design/annai-term-v1.md)
- 関連 ADR: [ADR-0006](./0006-adopt-annai-term-standalone.md)
