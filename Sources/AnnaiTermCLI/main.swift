import AnnaiTermKit
import Foundation

// 薄いラッパ。純関数 run の結果を実 I/O に流し、終了コードで抜ける。
// Swift の exit() は C stdio を flush してから抜けるため、print した stdout は切り捨てられない。
let result = run(Array(CommandLine.arguments.dropFirst()))

for line in result.stdout {
    print(line)
}
if !result.stderr.isEmpty {
    let text = result.stderr.map { $0 + "\n" }.joined()
    FileHandle.standardError.write(Data(text.utf8))
}
exit(result.exitCode)
