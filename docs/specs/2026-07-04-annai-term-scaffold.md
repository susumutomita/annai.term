# annai-term V1 足場 仕様書

対応 Issue: [susumutomita/annai.term#2](https://github.com/susumutomita/annai.term/issues/2)。設計正本は [docs/design/annai-term-v1.md](../design/annai-term-v1.md)。スタック判断は [ADR-0007](../adr/0007-swift-native-mac-only-afm.md)。

## 概要

annai-term V1 の実装に先立ち、V1 全体の設計正本と ADR を確定し、Swift / SwiftPM の最小の実行可能な足場（`--version` / `--help` が動く `annai-term` CLI）を用意する。

## ユーザーストーリー

- リポジトリメンテナとして、後続の実装 Issue が参照する Swift ベースの設計正本と依存の向きを固定したい。
- 開発者として、`annai-term --version` が動く足場から TDD で各モジュールを積み上げたい。

## 受け入れ基準

- [ ] `docs/design/annai-term-v1.md` に Swift ネイティブのアーキテクチャ・起動モデル・縮退動作が記載されている。
- [ ] ADR に独立リポジトリ採用（[ADR-0006](../adr/0006-adopt-annai-term-standalone.md)）と Mac 専用・Swift ネイティブ・AFM 前提（[ADR-0007](../adr/0007-swift-native-mac-only-afm.md)）が記録され、README に採用が明記されている。
- [ ] `make swift_check`（build + spec + coverage 100% + swift format lint）が Green。
- [ ] `annai-term --version` がバージョンを表示する。

## 非機能要件

- パフォーマンス: 足場の起動は即時（外部依存ゼロ）。
- セキュリティ: 外部依存ゼロ。ネットワークアクセスなし。
- テスト容易性: XCTest / swift-testing（Xcode 同梱）に依存せず、CLT だけ・CI（Xcode 無し）でも `swift run AnnaiTermSpec` で検証できる。

## 技術設計

- パッケージ: SwiftPM。純ロジックは `AnnaiTermKit` の `run(_:) -> CLIResult`（副作用なし）に置き、`AnnaiTermCLI` の `main.swift` は結果を実 I/O に流すだけの薄いラッパにする。
- CLI 挙動: `--version` / `-v` でバージョン、引数なし・`--help` / `-h` でヘルプ、未対応引数は stderr にエラーとヘルプを出して exit code 2。`--version` / `--help` は診断フラグとして先勝ちで短絡する。
- バージョンの出所: `AnnaiTermKit` の `annaiTermVersion` 定数を単一の出所とする。
- カバレッジ: 計測対象は `AnnaiTermKit`（100%）。`main.swift`（実行体の薄いラッパ）は計測対象外とし、実バイナリの起動で検証する。
- テスト: `AnnaiTermSpec` が `run` の全分岐（version / help / 未対応）と境界を日本語の記述付きで検証する。

## スコープ外

- AdapterKit / CatalogKit / EngineKit / AFMBackend / Overlay の実装（後続 Issue）。
- `ask` / `doctor` サブコマンド本体（[Issue 8](https://github.com/susumutomita/annai.term/issues/8)）。
- 未実装コマンドのプレースホルダや「今後追加予定」の表示。
