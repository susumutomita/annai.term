import Foundation

// 日本語 BDD スタイルの最小スペックランナーの共有部。
// XCTest / swift-testing は Xcode 同梱で CLT には無いため、検証可能性を優先してこの形にする。

@MainActor private var specTotal = 0
@MainActor private var specFailed = 0

@MainActor
func expect(
    _ condition: Bool,
    _ description: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    specTotal += 1
    if condition {
        print("  ok   \(description)")
    } else {
        specFailed += 1
        print("  FAIL \(description)  (\(file):\(line))")
    }
}

@MainActor
func specSummaryAndExit() -> Never {
    print("\(specTotal - specFailed)/\(specTotal) passed")
    exit(specFailed == 0 ? 0 : 1)
}
