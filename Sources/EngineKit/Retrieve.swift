import CatalogKit
import Foundation

// 日本語の言い回しを action / description の英語語彙へ橋渡しする辞書。決定的で説明可能。
// マッチ時は日本語キー自体も検索語に足す（Herdr の日本語 description に直接当てる）。
private let synonyms: [String: [String]] = [
    "分割": ["split"],
    "ペイン": ["pane"],
    "タブ": ["tab"],
    "文字": ["font"],
    "大きく": ["increase", "font"],
    "拡大": ["increase", "zoom"],
    "小さく": ["decrease"],
    "閉じ": ["close", "detach", "quit"],
    "残し": ["detach"],
    "抜け": ["detach"],
    "移動": ["focus"],
    "左": ["left"],
    "右": ["right"],
    "上": ["up"],
    "下": ["down"],
    "作り": ["new"],
    "作成": ["new"],
    "新し": ["new"],
    "新規": ["new"],
    "次": ["next"],
    "前": ["previous", "prev"],
    "コピー": ["copy"],
    "貼り付け": ["paste"],
    "検索": ["search", "find"],
    "リロード": ["reload"],
    "再読み込み": ["reload"],
    "ワークスペース": ["workspace"],
    "サイドバー": ["sidebar"],
]

/// 質問から候補を決定的に絞り込む。同義語辞書 + 質問中のラテン語を検索語にして
/// action / description / display をスコアリングし、スコア降順・precedence 昇順で top-N。
public func retrieve(_ question: String, catalog: [Keybinding], limit: Int = 8) -> [Keybinding] {
    let normalized = question.precomposedStringWithCompatibilityMapping.lowercased()
    var terms: Set<String> = []
    for (japanese, english) in synonyms where normalized.contains(japanese) {
        terms.insert(japanese)
        for word in english { terms.insert(word) }
    }
    for token in normalized.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
        let word = String(token)
        if word.count >= 2, word.allSatisfy(\.isASCII) { terms.insert(word) }
    }
    if terms.isEmpty { return [] }

    let scored = catalog.compactMap { binding -> (binding: Keybinding, score: Int)? in
        let haystack = "\(binding.action) \(binding.description) \(binding.display)".lowercased()
        let score = terms.reduce(0) { $0 + (haystack.contains($1) ? 1 : 0) }
        return score > 0 ? (binding, score) : nil
    }
    let ranked = scored.sorted {
        $0.score != $1.score ? $0.score > $1.score : $0.binding.precedence < $1.binding.precedence
    }
    return ranked.prefix(limit).map(\.binding)
}
