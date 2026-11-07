import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var status: NSStatusItem!
    var welcome: NSWindow?
    var demo: NSWindow?
    var attachments: [CurtainAttachment] = []
    var targets: [WindowTarget] = []
    var timer: Timer?
    var languageObserver: NSObjectProtocol?
    let appearance = AppearanceSettings()
    let sound = CurtainSound()
    let wind = WindSettings()
    var tintIndex = UserDefaults.standard.integer(forKey:"fabricColor")
    var colors: [(String, NSColor)] { [
        (L("Velvet · Burgundy", "Бархат · винный"),NSColor(calibratedRed:0.43,green:0.16,blue:0.23,alpha:1)),
        (L("Velvet · Forest", "Бархат · хвойный"),NSColor(calibratedRed:0.13,green:0.34,blue:0.29,alpha:1)),
        (L("Linen · Sand", "Лён · песочный"),NSColor(calibratedRed:0.74,green:0.63,blue:0.46,alpha:1)),
        (L("Velvet · Midnight", "Бархат · ночной"),NSColor(calibratedRed:0.18,green:0.25,blue:0.43,alpha:1))
    ] }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName:"curtains.closed", accessibilityDescription:"Curtain") ?? NSImage(systemSymbolName:"rectangle.split.2x1",accessibilityDescription:"Curtain")
        status.button?.toolTip = L("Curtain — curtains for your windows", "Curtain — шторы для окон")
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
        languageObserver = NotificationCenter.default.addObserver(forName: .curtainLanguageDidChange, object: Localization.shared, queue: .main) { [weak self] _ in
            self?.refreshLanguage()
        }
        showWelcome()
    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        @discardableResult func add(_ title:String,_ action:Selector?,key:String = "") -> NSMenuItem {
            let item = menu.addItem(withTitle:title,action:action,keyEquivalent:key); item.target = self; return item
        }
        let heading = add(L("Curtain · curtains for your windows", "Curtain · шторы для окон"),nil); heading.isEnabled = false
        add(L("About and controls…", "О приложении и управление…"),#selector(showWelcome))
        add(L("Try the demo", "Попробовать на демо-окне"),#selector(showDemo))
        menu.addItem(.separator())
        if AXIsProcessTrusted() {
            targets = availableWindows()
            let parent = add(L("Attach curtains to a window", "Повесить шторы на окно"),nil), submenu = NSMenu()
            if targets.isEmpty { submenu.addItem(withTitle:L("No windows available", "Нет доступных окон"),action:nil,keyEquivalent:"") }
            for (i,target) in targets.enumerated() {
                let title = "\(target.appName) — \(target.title.prefix(65))"
                let item = submenu.addItem(withTitle:title,action:#selector(attachWindow(_:)),keyEquivalent:"")
                item.target = self; item.tag = i
                if attachments.contains(where:{ $0.target.map { CFEqual($0.element,target.element) } ?? false }) { item.state = .on }
            }
            parent.submenu = submenu
        } else {
            add(L("Allow window access…", "Разрешить доступ к окнам…"),#selector(requestAccess))
        }
        menu.addItem(.separator())
        add(L("Open all curtains", "Открыть все шторы"),#selector(openAll))
        add(L("Close all curtains", "Закрыть все шторы"),#selector(closeAll))
        let colorMenu = NSMenu(), colorItem = add(L("Fabric", "Ткань"),nil)
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
        let windItem = add(L("Wind", "Ветер"), #selector(toggleWind))
        windItem.state = wind.enabled ? .on : .off
        let windStrengthItem = NSMenuItem()
        windStrengthItem.view = WindControl(value: wind.strengthPercent) { [weak self] value in
            guard let self else { return }
            self.wind.strengthPercent = value
            self.attachments.forEach { self.applyWind($0) }
        }
        menu.addItem(windStrengthItem)
        let soundItem = add(L("Curtain sound", "Звук штор"), #selector(toggleSound))
        soundItem.state = sound.enabled ? .on : .off
        let volumeItem = NSMenuItem()
        volumeItem.view = VolumeControl(value: sound.volumePercent) { [weak self] value in
            self?.sound.volumePercent = value
        }
        menu.addItem(volumeItem)
        let languageItem = add(L("Language", "Язык"), nil)
        let languageMenu = NSMenu()
        for (index, language) in AppLanguage.allCases.enumerated() {
            let item = languageMenu.addItem(withTitle: language.displayName, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self; item.tag = index
            item.state = Localization.shared.language == language ? .on : .off
        }
        languageItem.submenu = languageMenu
        add(L("Remove all curtains", "Снять все шторы"),#selector(removeAll))
        menu.addItem(.separator())
        add(L("Quit Curtain", "Завершить Curtain"),#selector(quit),key:"q")
    }
    func applyTint(_ attachment: CurtainAttachment) {
        attachment.fabric.tint = colors[max(0,min(colors.count-1,tintIndex))].1
        attachment.panel.alphaValue = appearance.opacity
        applyWind(attachment)
        attachment.fabric.left.onOpenChanged = { [weak self] in self?.sound.play(opening: $0) }
        attachment.fabric.right.onOpenChanged = { [weak self] in self?.sound.play(opening: $0) }
    }
    func applyWind(_ attachment: CurtainAttachment) {
        attachment.fabric.left.windStrength = CGFloat(wind.effectiveStrength)
        attachment.fabric.right.windStrength = CGFloat(wind.effectiveStrength)
    }
    @objc func toggleWind() {
        wind.enabled.toggle()
        attachments.forEach { applyWind($0) }
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
        let demoButton = NSButton(title:L("Try the curtains", "Попробовать шторы"),target:self,action:#selector(showDemo))
        demoButton.tag = 1001; demoButton.bezelStyle = .rounded; demoButton.controlSize = .large
        demoButton.frame = NSRect(x:38,y:452,width:198,height:36); view.addSubview(demoButton)
        let attach = NSButton(title:L("Choose a window…", "Выбрать окно…"),target:self,action:#selector(chooseWindow))
        attach.tag = 1002; attach.bezelStyle = .rounded; attach.controlSize = .large
        attach.frame = NSRect(x:245,y:452,width:168,height:36); view.addSubview(attach)
        let languagePicker = NSPopUpButton(frame: NSRect(x:570,y:25,width:150,height:30), pullsDown:false)
        languagePicker.addItems(withTitles: AppLanguage.allCases.map(\.displayName))
        languagePicker.selectItem(at: AppLanguage.allCases.firstIndex(of: Localization.shared.language) ?? 0)
        languagePicker.tag = 1003; languagePicker.target = self; languagePicker.action = #selector(chooseWelcomeLanguage(_:))
        languagePicker.setAccessibilityLabel(L("Language", "Язык"))
        view.addSubview(languagePicker)
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
        window.title = L("Curtain · pull the fabric", "Curtain · потяните за ткань"); window.minSize = NSSize(width:400,height:330)
        window.isReleasedWhenClosed = false; window.contentView = DemoView(frame:NSRect(x:0,y:0,width:800,height:520))
        window.center(); window.makeKeyAndOrderFront(nil); demo = window
        let attachment = CurtainAttachment(demo:window); applyTint(attachment); attachments.append(attachment)
    }
    @objc func requestAccess() {
        let alert = NSAlert(); alert.messageText = L("Let Curtain follow your windows", "Разрешите Curtain следовать за окнами")
        alert.informativeText = L(
            "In System Settings, open Privacy & Security → Device Control and Data Access (Accessibility on earlier macOS versions) and enable Curtain. If it is missing, add the app using +. Then choose a window from the Curtain menu.\n\nThe demo works without this permission.",
            "В System Settings откройте Privacy & Security → Device Control and Data Access (Accessibility в более ранних версиях macOS) и включите Curtain. Если его нет в списке, добавьте приложение кнопкой +. Затем выберите окно через меню Curtain.\n\nДемо работает без этого разрешения.")
        alert.addButton(withTitle:L("Open Settings", "Открыть настройки")); alert.addButton(withTitle:L("Try the demo first", "Пока только демо"))
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
    @objc func chooseWelcomeLanguage(_ sender: NSPopUpButton) {
        guard AppLanguage.allCases.indices.contains(sender.indexOfSelectedItem) else { return }
        Localization.shared.language = AppLanguage.allCases[sender.indexOfSelectedItem]
    }
    @objc func changeLanguage(_ sender: NSMenuItem) {
        guard AppLanguage.allCases.indices.contains(sender.tag) else { return }
        Localization.shared.language = AppLanguage.allCases[sender.tag]
    }
    func refreshLanguage() {
        status.button?.toolTip = L("Curtain — curtains for your windows", "Curtain — шторы для окон")
        (welcome?.contentView?.viewWithTag(1001) as? NSButton)?.title = L("Try the curtains", "Попробовать шторы")
        (welcome?.contentView?.viewWithTag(1002) as? NSButton)?.title = L("Choose a window…", "Выбрать окно…")
        if let picker = welcome?.contentView?.viewWithTag(1003) as? NSPopUpButton {
            picker.selectItem(at: AppLanguage.allCases.firstIndex(of: Localization.shared.language) ?? 0)
            picker.setAccessibilityLabel(L("Language", "Язык"))
        }
        welcome?.contentView?.needsDisplay = true
        demo?.title = L("Curtain · pull the fabric", "Curtain · потяните за ткань")
        demo?.contentView?.needsDisplay = true
    }
    @objc func toggleSound() { sound.enabled.toggle() }
    @objc func quit() { removeAll(); NSApp.terminate(nil) }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool) -> Bool { showWelcome(); return true }
    func applicationWillTerminate(_ notification:Notification) {
        removeAll(); timer?.invalidate()
        if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
