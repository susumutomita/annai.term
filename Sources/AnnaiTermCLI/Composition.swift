import EngineKit
import Foundation
import SessionKit

// CLI から SessionKit の共通パイプラインを呼ぶ薄いラッパ。
func runAsk(_ question: String) async -> Int32 {
    let answer = await resolveAnswer(question: question)
    for line in answerLines(answer) {
        print(line)
    }
    return answer.keybindingId == nil ? 1 : 0
}

func runDoctor() async -> Int32 {
    for line in await doctorReport() {
        print(line)
    }
    return 0
}
