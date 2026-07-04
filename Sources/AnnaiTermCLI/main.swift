import AnnaiTermKit
import Foundation

// 薄い composition root。version / help / エラーは同期描画、ask / doctor は async 実行。
let arguments = Array(CommandLine.arguments.dropFirst())
let command = parseCommand(arguments)

if let result = render(command) {
    for line in result.stdout {
        print(line)
    }
    if !result.stderr.isEmpty {
        let text = result.stderr.map { $0 + "\n" }.joined()
        FileHandle.standardError.write(Data(text.utf8))
    }
    exit(result.exitCode)
}

switch command {
case .ask(let question):
    exit(await runAsk(question))
case .doctor:
    exit(await runDoctor())
default:
    exit(0)
}
