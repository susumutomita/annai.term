// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "annai-term",
    platforms: [
        // AFM (FoundationModels) と AppKit オーバーレイを使うため macOS 26 を要求する。
        // 足場のコア (AnnaiTermKit) 自体はまだ AFM を使わないが、製品の対象を正直に宣言する。
        .macOS("26.0")
    ],
    products: [
        .executable(name: "annai-term", targets: ["AnnaiTermCLI"]),
        .executable(name: "annai-term-overlay", targets: ["AnnaiTermApp"]),
        .library(name: "AnnaiTermKit", targets: ["AnnaiTermKit"]),
    ],
    targets: [
        // 純ロジック層。副作用を持たず単体テストで 100% カバーする。
        .target(name: "AnnaiTermKit"),
        // キーバインドのドメイン層。正規化・merge・競合検出。
        .target(name: "CatalogKit"),
        // 各ツールの設定を読み、raw keybind を Keybinding に変換する adapter 層。
        .target(name: "AdapterKit", dependencies: ["CatalogKit"]),
        // ローカル LLM バックエンドの純ロジック（プロンプト構築・応答解析・制約検証）。
        .target(name: "BackendKit", dependencies: ["CatalogKit"]),
        // 実バックエンド（AFM）への結線。macOS 26 + AFM 実機でのみ推論が走るためカバレッジ対象外。
        .target(name: "BackendTransport", dependencies: ["BackendKit"]),
        // 質問 → 候補絞り込み（retrieve）→ 回答組み立て（buildAnswer）。純ロジック。
        .target(name: "EngineKit", dependencies: ["CatalogKit", "BackendKit"]),
        // 実 I/O の結線（ghostty 起動・config 読み込み・AFM 推論）。CLI とオーバーレイで共有。
        // カバレッジ対象外。
        .target(
            name: "SessionKit",
            dependencies: [
                "AnnaiTermKit", "CatalogKit", "AdapterKit",
                "BackendKit", "BackendTransport", "EngineKit",
            ]
        ),
        // 薄い実行体。引数を Kit に渡し、出力と終了だけを担う。
        .executableTarget(
            name: "AnnaiTermCLI",
            dependencies: ["AnnaiTermKit", "EngineKit", "SessionKit"]
        ),
        // グローバルホットキー + AppKit オーバーレイ。GUI はカバレッジ対象外。
        .executableTarget(
            name: "AnnaiTermApp",
            dependencies: ["AnnaiTermKit", "EngineKit", "SessionKit"]
        ),
        // Xcode 非依存のスペックランナー。CLT だけ・CI (Xcode 無し) でも
        // `swift run AnnaiTermSpec` で実行でき、失敗時に exit 1 で落ちる。
        // XCTest / swift-testing は Xcode 同梱で CLT には無いため、検証可能性を優先する。
        .executableTarget(
            name: "AnnaiTermSpec",
            dependencies: ["AnnaiTermKit", "CatalogKit", "AdapterKit", "BackendKit", "EngineKit"]
        ),
    ]
)
