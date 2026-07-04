.PHONY: install
# --ignore-scripts: Mini Shai-Hulud 2nd (Flatt Security, 2026-05-12) を含む
# lifecycle script 系サプライチェイン攻撃を一段目で封じるフラグ。
# Bun は npm_config_ignore_scripts 環境変数も .npmrc の ignore-scripts も読まないため
# (公式 docs では bunfig.toml のみが設定経路)、Bun を叩く側で毎回明示する必要がある。
# Bun はデフォルトで「top 500 npm パッケージ」の lifecycle script を暗黙信頼する
# 仕様もあるため、ここで全停止させる方が事故が少ない。Husky の prepare も巻き添えで
# 止まるので、フックを使う場合は make setup-hooks で明示的に再有効化する。
install:
	bun install --ignore-scripts

.PHONY: install_ci
install_ci:
	bun install --frozen-lockfile --ignore-scripts

.PHONY: setup-hooks
# install 時に --ignore-scripts で止めた husky の prepare をここで明示的に走らせる。
# `bun run prepare` は package.json の "prepare": "husky" を叩くため、Husky 一発で済む。
setup-hooks:
	bun run prepare

.PHONY: build
build:
	bun run build

.PHONY: clean
clean:
	bun run clean

.PHONY: test
test:
	bun run test

.PHONY: test_coverage
test_coverage:
	bun run test:coverage

.PHONY: test_watch
test_watch:
	bun run --filter '*' test --watch

.PHONY: lint
lint:
	bun run lint

.PHONY: lint_fix
lint_fix:
	bun run lint:fix

.PHONY: lint_text
lint_text:
	bun run lint:text

.PHONY: typecheck
typecheck:
	bun run typecheck

.PHONY: format
format:
	bun run format

.PHONY: format_check
format_check:
	bun run format:check

.PHONY: architecture_harness
architecture_harness:
	bun scripts/architecture-harness.ts --staged --fail-on=error

.PHONY: harness_test
# harness 自体の invariant 検出ロジックを検証する。workspace 構成に依存しないため
# 既定ゲートに含める (workspace 側のテストは利用プロジェクトで before-commit に足す)。
harness_test:
	bun test scripts/

# --- Swift (annai-term 製品コード) ---
# 製品は Swift ネイティブ (ADR-0007)。XCTest / swift-testing は Xcode 同梱で CLT に無いため、
# テストは Xcode 非依存のスペックランナー (AnnaiTermSpec) で実行し、カバレッジは llvm-cov で測る。

.PHONY: swift_build
swift_build:
	swift build

.PHONY: swift_test
swift_test:
	swift run AnnaiTermSpec

.PHONY: swift_coverage
swift_coverage:
	bash scripts/swift-coverage.sh

.PHONY: swift_lint
swift_lint:
	swift format lint --strict --configuration .swift-format --recursive Sources Package.swift

.PHONY: swift_format
swift_format:
	swift format --in-place --configuration .swift-format --recursive Sources Package.swift

.PHONY: swift_check
swift_check: swift_build swift_test swift_coverage swift_lint

.PHONY: ci
# GitHub の runner は macOS 26 / Apple Intelligence を持たないため、CI では repo ガバナンス
# (architecture-harness / skill 監査 / doc lint) のみ検証する。製品コード (Swift) のゲート
# swift_check は macOS 26 のローカルで before-commit が回す (ADR-0007)。
ci: architecture_harness harness_test lint_text lint

.PHONY: before-commit
# ローカル (macOS 26) の完全ゲート。repo ガバナンス + 製品コードの swift_check。
# 両方通って初めて完了。
before-commit: ci swift_check

.PHONY: dev
dev:
	bun run dev
