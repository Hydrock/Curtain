import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var status: NSStatusItem!
    var welcome: NSWindow?
    var demo: NSWindow?
    var attachments: [CurtainAttachment] = []
    var targets: [WindowTarget] = []
    var timer: Timer?
    let appearance = AppearanceSettings()
    let sound = CurtainSound()
    var tintIndex = UserDefaults.standard.integer(forKey:"fabricColor")
    let colors: [(String, NSColor)] = [
        ("Бархат · винный",NSColor(calibratedRed:0.43,green:0.16,blue:0.23,alpha:1)),
        ("Бархат · хвойный",NSColor(calibratedRed:0.13,green:0.34,blue:0.29,alpha:1)),
        ("Лён · песочный",NSColor(calibratedRed:0.74,green:0.63,blue:0.46,alpha:1)),
        ("Бархат · ночной",NSColor(calibratedRed:0.18,green:0.25,blue:0.43,alpha:1))
    ]
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName:"curtains.closed", accessibilityDescription:"Curtain") ?? NSImage(systemSymbolName:"rectangle.split.2x1",accessibilityDescription:"Curtain")
        status.button?.toolTip = "Curtain — шторы для окон"
        let menu = NSMenu(); menu.delegate = self; status.menu = menu
        timer = Timer(timeInterval:1.0/60, repeats:true) { [weak self] _ in
            guard let self else { return }
            for attachment in self.attachments {
                attachment.update()
                if attachment.panel.isVisible { attachment.fabric.tick() }
            }
            self.attachments.filter { $0.dead }.forEach { $0.remove() }
            self.attachments.removeAll { $0.dead }
        }
        RunLoop.main.add(timer!,forMode:.common)
        showWelcome()
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        @discardableResult func add(_ title:String,_ action:Selector?,key:String = "") -> NSMenuItem {
            let item = menu.addItem(withTitle:title,action:action,keyEquivalent:key); item.target = self; return item
        }
        let heading = add("Curtain · шторы для окон",nil); heading.isEnabled = false
        add("О приложении и управление…",#selector(showWelcome))
        add("Попробовать на демо-окне",#selector(showDemo))
        menu.addItem(.separator())
        if AXIsProcessTrusted() {
            targets = availableWindows()
            let parent = add("Повесить шторы на окно",nil), submenu = NSMenu()
            if targets.isEmpty { submenu.addItem(withTitle:"Нет доступных окон",action:nil,keyEquivalent:"") }
            for (i,target) in targets.enumerated() {
                let title = "\(target.appName) — \(target.title.prefix(65))"
                let item = submenu.addItem(withTitle:title,action:#selector(attachWindow(_:)),keyEquivalent:"")
                item.target = self; item.tag = i
                if attachments.contains(where:{ $0.target.map { CFEqual($0.element,target.element) } ?? false }) { item.state = .on }
            }
            parent.submenu = submenu
        } else {
            add("Разрешить доступ к окнам…",#selector(requestAccess))
        }
        menu.addItem(.separator())
        add("Открыть все шторы",#selector(openAll))
        add("Закрыть все шторы",#selector(closeAll))
        let colorMenu = NSMenu(), colorItem = add("Ткань",nil)
        for (i,color) in colors.enumerated() {
            let item = colorMenu.addItem(withTitle:color.0,action:#selector(changeColor(_:)),keyEquivalent:"")
            item.target = self; item.tag = i; item.state = i == tintIndex ? .on : .off
        }
        colorItem.submenu = colorMenu
        let transparencyItem = NSMenuItem()
        transparencyItem.view = TransparencyControl(value: appearance.transparency) { [weak self] value in
            guard let self else { return }
            self.appearance.transparency = value
            self.attachments.forEach { $0.panel.alphaValue = self.appearance.opacity }
        }
        menu.addItem(transparencyItem)
        let soundItem = add("Звук штор", #selector(toggleSound))
        soundItem.state = sound.enabled ? .on : .off
        let volumeItem = NSMenuItem()
        volumeItem.view = VolumeControl(value: sound.volumePercent) { [weak self] value in
            self?.sound.volumePercent = value
        }
        menu.addItem(volumeItem)
        add("Снять все шторы",#selector(removeAll))
        menu.addItem(.separator())
        add("Завершить Curtain",#selector(quit),key:"q")
    }
    func applyTint(_ attachment: CurtainAttachment) {
        attachment.fabric.tint = colors[max(0,min(colors.count-1,tintIndex))].1
        attachment.panel.alphaValue = appearance.opacity
        attachment.fabric.left.onOpenChanged = { [weak self] in self?.sound.play(opening: $0) }
        attachment.fabric.right.onOpenChanged = { [weak self] in self?.sound.play(opening: $0) }
    }
    @objc func attachWindow(_ sender:NSMenuItem) {
        guard targets.indices.contains(sender.tag) else { return }
        let target = targets[sender.tag]
        if let existing = attachments.first(where:{ $0.target.map { CFEqual($0.element,target.element) } ?? false }) {
            existing.remove(); return
        }
        let attachment = CurtainAttachment(target:target); applyTint(attachment); attachments.append(attachment)
        NSRunningApplication(processIdentifier:target.pid)?.activate()
    }
    @objc func showWelcome() {
        if let welcome { NSApp.activate(ignoringOtherApps:true); welcome.makeKeyAndOrderFront(nil); return }
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:760,height:560),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        window.title = "Curtain"; window.isReleasedWhenClosed = false
        let view = WelcomeView(frame:NSRect(x:0,y:0,width:760,height:560)); window.contentView = view
        let demoButton = NSButton(title:"Попробовать шторы",target:self,action:#selector(showDemo))
        demoButton.bezelStyle = .rounded; demoButton.controlSize = .large
        demoButton.frame = NSRect(x:38,y:452,width:198,height:36); view.addSubview(demoButton)
        let attach = NSButton(title:"Выбрать окно…",target:self,action:#selector(chooseWindow))
        attach.bezelStyle = .rounded; attach.controlSize = .large
        attach.frame = NSRect(x:245,y:452,width:168,height:36); view.addSubview(attach)
        welcome = window; window.center(); NSApp.activate(ignoringOtherApps:true); window.makeKeyAndOrderFront(nil)
    }
    @objc func chooseWindow() {
        if !AXIsProcessTrusted() { requestAccess(); return }
        status.button?.performClick(nil)
    }
    @objc func showDemo() {
        NSApp.activate(ignoringOtherApps:true)
        if let demo {
            demo.makeKeyAndOrderFront(nil)
            if !attachments.contains(where:{ $0.demo === demo && !$0.dead }) {
                let attachment = CurtainAttachment(demo:demo); applyTint(attachment); attachments.append(attachment)
            }
            return
        }
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:800,height:520),styleMask:[.titled,.closable,.resizable,.miniaturizable],backing:.buffered,defer:false)
        window.title = "Curtain · потяните за ткань"; window.minSize = NSSize(width:400,height:330)
        window.isReleasedWhenClosed = false; window.contentView = DemoView(frame:NSRect(x:0,y:0,width:800,height:520))
        window.center(); window.makeKeyAndOrderFront(nil); demo = window
        let attachment = CurtainAttachment(demo:window); applyTint(attachment); attachments.append(attachment)
    }
    @objc func requestAccess() {
        let alert = NSAlert(); alert.messageText = "Разрешите Curtain следовать за окнами"
        alert.informativeText = "В настройках macOS откройте «Конфиденциальность и безопасность → Универсальный доступ» и включите Curtain. Если его нет в списке, добавьте собранное приложение кнопкой «+». Затем снова выберите окно через значок Curtain в строке меню.\n\nДемо-окно работает без этого разрешения."
        alert.addButton(withTitle:"Открыть настройки"); alert.addButton(withTitle:"Пока только демо")
        NSApp.activate(ignoringOtherApps:true)
        if alert.runModal() == .alertFirstButtonReturn {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String:true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else { showDemo() }
    }
    @objc func openAll() { attachments.forEach { $0.fabric.setOpen(true) } }
    @objc func closeAll() { attachments.forEach { $0.fabric.setOpen(false) } }
    @objc func removeAll() { attachments.forEach { $0.remove() }; attachments.removeAll() }
    @objc func changeColor(_ sender:NSMenuItem) {
        tintIndex = sender.tag; UserDefaults.standard.set(tintIndex,forKey:"fabricColor")
        attachments.forEach { applyTint($0) }
    }
    @objc func toggleSound() { sound.enabled.toggle() }
    @objc func quit() { removeAll(); NSApp.terminate(nil) }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool) -> Bool { showWelcome(); return true }
    func applicationWillTerminate(_ notification:Notification) { removeAll(); timer?.invalidate() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
