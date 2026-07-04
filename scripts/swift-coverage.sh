#!/usr/bin/env bash
# AnnaiTermKit の行カバレッジを llvm-cov で測り、100% 未満なら fail する。
# XCTest / swift-testing は Xcode 同梱で CLT には無いため、それらに依存せず
# 計装付きビルド + スペックランナー実行 + llvm-cov で計測する。
# カバレッジ 100% は Definition of Done（docs/architecture/quality-bar.md / ADR-0003）。
set -euo pipefail
cd "$(dirname "$0")/.."

BIN=.build/debug/AnnaiTermSpec
PROFRAW=.build/annai-term.profraw
PROFDATA=.build/annai-term.profdata
TARGET=Sources/AnnaiTermKit

swift build --product AnnaiTermSpec \
    -Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping >/dev/null

LLVM_PROFILE_FILE="$PROFRAW" "$BIN" >/dev/null
xcrun llvm-profdata merge -sparse "$PROFRAW" -o "$PROFDATA"

xcrun llvm-cov report "$BIN" -instr-profile "$PROFDATA" "$TARGET"

PERCENT=$(
    xcrun llvm-cov export "$BIN" -instr-profile "$PROFDATA" "$TARGET" --summary-only |
        jq '.data[0].totals.lines.percent'
)

if awk "BEGIN { exit !($PERCENT >= 100) }"; then
    echo "coverage: ${PERCENT}% (AnnaiTermKit) — OK"
else
    echo "coverage: ${PERCENT}% (AnnaiTermKit) — FAIL: 100% 未満" >&2
    exit 1
fi
