import AppKit

// メニューバー常駐（.accessory）のオーバーレイアプリ。Cmd+Option+Space で呼び出す。
let application = NSApplication.shared
let controller = OverlayController()
application.delegate = controller
application.setActivationPolicy(.accessory)
application.run()
