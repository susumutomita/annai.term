# annai-term

> Ask about your Ghostty and Herdr keybindings in plain language — answered on-device, on your Mac.

[![CI](https://github.com/susumutomita/annai.term/actions/workflows/ci.yml/badge.svg)](https://github.com/susumutomita/annai.term/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/susumutomita/annai.term)](https://github.com/susumutomita/annai.term/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-black)

`annai-term` answers questions like "split right and go to the next tab" by telling you which key does it and which layer — Ghostty or Herdr — owns it. It runs entirely on your Mac with Apple's on-device Foundation Models: no cloud, no API keys, no telemetry.

It is a bespoke tool built for a single user. It favors a seamless "ask from anywhere" experience over broad portability, so it is macOS only, Swift-native, and Apple Foundation Models first ([ADR-0007](./docs/adr/0007-swift-native-mac-only-afm.md)).

## Why

Ghostty has no plugin API and cannot bind a key to run an arbitrary command, so nothing can launch a helper from Ghostty itself. `annai-term` instead runs as a CLI and as a global-hotkey overlay, reading your real keybindings from `ghostty +list-keybinds` and `~/.config/herdr/config.toml`.

## Install

Requires macOS 26 or later and a Swift toolchain (Command Line Tools or Xcode). Both paths build from source.

Homebrew:

```bash
brew tap susumutomita/annai-term https://github.com/susumutomita/annai.term
brew install annai-term
```

Make, which installs to `~/.local/bin`:

```bash
git clone https://github.com/susumutomita/annai.term
cd annai.term
make install-cli
annai-term --version
```

Add `~/.local/bin` to your `PATH` if it is not already there. Install elsewhere with `make install-cli PREFIX=/usr/local` (`/usr/local` may need `sudo`). To try it without installing, run `swift run annai-term ask "..."`.

## Usage

```bash
annai-term ask "split right and go to the next tab"   # answers one keybinding
annai-term doctor                                      # shows config, counts, conflicts, model status
```

Every answer names the layer (Ghostty / Herdr), the key, and a short note. If nothing matches, it says so — it never invents a key that does not exist.

## Overlay (global hotkey)

`annai-term-overlay` runs in the background and is summoned with Cmd + Option + Space over any app. This is the seamless launch path, since Ghostty exposes neither a plugin API nor an arbitrary-command keybind. The global hotkey requires bundling as a `.app` and Accessibility permission.

## How it works

Everything runs locally.

- Adapters read `ghostty +list-keybinds` and `~/.config/herdr/config.toml`.
- Catalog normalizes chords, merges defaults with your config, and detects cross-layer conflicts.
- Engine narrows candidates with a synonym dictionary and builds the answer.
- Backend asks Apple Foundation Models to pick one candidate. If it abstains or is unavailable, a deterministic retrieval fallback answers instead.

The design of record is [docs/design/annai-term-v1.md](./docs/design/annai-term-v1.md).

## Privacy

- Inference runs on-device via Apple Foundation Models. There is no cloud LLM, API key, or telemetry.
- The model receives only your question plus normalized candidates (id, source, scope, display, action, description). Pane contents, shell history, and code cannot enter the payload by construction, which is verified in `PrivacySpec`.

## Limitations

- Apple Foundation Models requires macOS 26 and Apple Intelligence. Without it, `annai-term` falls back to deterministic retrieval.
- The overlay's interaction needs Accessibility permission and `.app` bundling.
- OS, IME, and app-focus layers cannot be fully observed, so conflict explanations are marked as estimates.

## Development

```bash
make swift_check     # build + spec + 100% line coverage + swift-format lint
make before-commit   # the above + repo governance (harness / skill audit / doc lint)
```

CI verifies repo governance on Linux and the Swift product gate on macOS, and a tagged release attaches a built binary. Tests live in `Sources/AnnaiTermSpec`, an Xcode-free spec runner, because XCTest and Swift Testing ship only with full Xcode. See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT — see [LICENSE](./LICENSE).
