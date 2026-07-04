# annai-term V1 足場 仕様書

対応 Issue: [susumutomita/annai.term#2](https://github.com/susumutomita/annai.term/issues/2)。設計正本は [docs/design/annai-term-v1.md](../design/annai-term-v1.md)。

## 概要

annai-term V1 の実装に先立ち、V1 全体の設計正本と ADR を確定し、`packages/annai-term` の最小の実行可能な足場（`--version` / `--help` が動く CLI）を用意する。

## ユーザーストーリー

- リポジトリメンテナとして、後続の実装 Issue が参照する設計正本と依存の向きを固定したい。
- 開発者として、`annai-term --version` が動く足場から TDD で各モジュールを積み上げたい。

## 受け入れ基準

- [ ] `docs/design/annai-term-v1.md` に代替案比較・選定理由・エッジケース（縮退動作）が記載されている。
- [ ] ADR に独立リポジトリ採用（[ADR-0006](../adr/0006-adopt-annai-term-standalone.md)）とローカル LLM 方針（[ADR-0007](../adr/0007-local-llm-first-no-cloud.md)）が記録され、README に採用が明記されている。
- [ ] `packages/annai-term` の `test` / `test:coverage`（100%）/ `typecheck` / `build` が Green。
- [ ] bin エントリ経由で `annai-term --version` がバージョンを表示する。

## 非機能要件

- パフォーマンス: 足場の起動は即時（実行時依存ゼロ）。
- セキュリティ: 実行時依存ゼロ。ネットワークアクセスなし。サプライチェーン harness を通す。
- アクセシビリティ: `--help` は plain text で、パイプ・非 TTY でも読める。

## 技術設計

- パッケージ: 単一 `packages/annai-term`。ロジックは純関数 `run(argv, io)` に置き、bin は薄いラッパにする（設計正本の依存方針に従う）。
- CLI 挙動: `--version` / `-v` でバージョン、引数なし・`--help` / `-h` でヘルプ、未対応引数は stderr にエラーとヘルプを出して exit code 2。
- バージョンの出所: `package.json` の `version` を単一の出所とし、実行時に読む。
- 依存: 実行時ゼロ。typecheck / build 用に TypeScript を開発依存として追加する。
- カバレッジ: 計測対象は `src/`（100%）。bin は別プロセス起動の subprocess テストで振る舞いを検証し、計測の分母には含まれない。bin の I/O 結線は subprocess の stdout / stderr アサーションで担保する。

## スコープ外

- adapters / catalog / engine / backends / tui の実装（後続 Issue）。
- `ask` / `doctor` サブコマンド本体（[Issue 8](https://github.com/susumutomita/annai.term/issues/8)）。
- 未実装コマンドのプレースホルダや「今後追加予定」の表示（`INVARIANT_NO_MVP_PLACEHOLDER`）。
