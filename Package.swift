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
        .library(name: "AnnaiTermKit", targets: ["AnnaiTermKit"]),
    ],
    targets: [
        // 純ロジック層。副作用を持たず単体テストで 100% カバーする。
        .target(name: "AnnaiTermKit"),
        // キーバインドのドメイン層。正規化・merge・競合検出。
        .target(name: "CatalogKit"),
        // 薄い実行体。引数を Kit に渡し、出力と終了だけを担う。
        .executableTarget(
            name: "AnnaiTermCLI",
            dependencies: ["AnnaiTermKit"]
        ),
        // Xcode 非依存のスペックランナー。CLT だけ・CI (Xcode 無し) でも
        // `swift run AnnaiTermSpec` で実行でき、失敗時に exit 1 で落ちる。
        // XCTest / swift-testing は Xcode 同梱で CLT には無いため、検証可能性を優先する。
        .executableTarget(
            name: "AnnaiTermSpec",
            dependencies: ["AnnaiTermKit", "CatalogKit"]
        ),
    ]
)
