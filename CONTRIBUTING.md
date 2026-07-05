# Contributing

`annai-term` is a personal, bespoke tool, but issues and pull requests are welcome.

## Requirements

- macOS 26 or later.
- A Swift toolchain (Command Line Tools or Xcode). Apple Foundation Models needs Apple Intelligence to be enabled; without it, the app falls back to deterministic retrieval.

## Local checks

```bash
make swift_check     # build, run the spec, enforce 100% line coverage, and swift-format lint
make before-commit   # the above plus repo governance (architecture-harness, skill audit, doc lint)
```

Tests live in `Sources/AnnaiTermSpec`, an Xcode-free spec runner (XCTest and Swift Testing ship only with full Xcode). Coverage is measured with `llvm-cov` over the pure library targets, which must stay at 100% line coverage.

## Conventions

- Conventional Commits.
- Pure logic lives in the `*Kit` library targets (100% covered). Real I/O and GUI live in the executable targets, which are excluded from coverage and verified by running them.
- Never fabricate a keybinding: unknown or missing selections return "not found".
- Design decisions go in `docs/adr/`. The V1 design of record is [`docs/design/annai-term-v1.md`](./docs/design/annai-term-v1.md).

## Repository governance

The repository keeps a Bun-based harness from its `typescript-template` origin (architecture-harness, skill audit, doc lint). It runs on Linux in CI; the Swift product gate runs on macOS in CI.

## License

By contributing, you agree that your contributions are licensed under the MIT License.
