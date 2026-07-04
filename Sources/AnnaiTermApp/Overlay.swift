import AppKit
import EngineKit
import SessionKit

// グローバルホットキー（Cmd+Option+Space）で、どのアプリの上でも呼べるオーバーレイ。
// 実行には .app バンドル化とアクセシビリティ権限が要る（global monitor の前提）。
// GUI はヘッドレス検証できないためカバレッジ対象外。純ロジックは各 Kit が 100% で担保する。
@MainActor
final class OverlayController: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    private var panel: NSPanel?
    private var input: NSTextField?
    private var answerField: NSTextField?
    private var monitors: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildPanel()
        installHotkey()
    }

    private func buildPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 170),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hidesOnDeactivate = false

        let field = NSTextField(frame: NSRect(x: 16, y: 122, width: 528, height: 28))
        field.placeholderString = "やりたいこと（例: 右に分割して次のタブ）"
        field.delegate = self

        let answer = NSTextField(wrappingLabelWithString: "")
        answer.frame = NSRect(x: 16, y: 12, width: 528, height: 100)
        answer.isEditable = false

        panel.contentView?.addSubview(field)
        panel.contentView?.addSubview(answer)
        self.panel = panel
        self.input = field
        self.answerField = answer
    }

    private func installHotkey() {
        let toggleOnHotkey: (NSEvent) -> Void = { event in
            MainActor.assumeIsolated {
                if event.modifierFlags.contains([.command, .option]), event.keyCode == 49 {
                    self.toggle()
                }
            }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown,
            handler: toggleOnHotkey
        ) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: {
                toggleOnHotkey($0)
                return $0
            }
        ) {
            monitors.append(local)
        }
    }

    private func toggle() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        input?.becomeFirstResponder()
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy selector: Selector
    ) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            submit()
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            panel?.orderOut(nil)
            return true
        }
        return false
    }

    private func submit() {
        guard let question = input?.stringValue, !question.isEmpty else { return }
        answerField?.stringValue = "…"
        Task { @MainActor in
            let answer = await resolveAnswer(question: question)
            answerField?.stringValue = answerLines(answer).joined(separator: "\n")
        }
    }
}
