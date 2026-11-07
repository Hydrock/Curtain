import AppKit
import ApplicationServices

struct WindowTarget {
    let element: AXUIElement
    let pid: pid_t
    let title: String
    let appName: String
}

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func windowRect(_ element: AXUIElement) -> CGRect? {
    guard let p = attribute(element, kAXPositionAttribute), let s = attribute(element, kAXSizeAttribute),
          CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID() else { return nil }
    var point = CGPoint.zero, size = CGSize.zero
    guard AXValueGetValue(unsafeBitCast(p, to: AXValue.self), .cgPoint, &point),
          AXValueGetValue(unsafeBitCast(s, to: AXValue.self), .cgSize, &size),
          size.width > 40, size.height > 60 else { return nil }
    // AX uses a top-left origin on the primary display. AppKit uses bottom-left.
    let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0
    return CGRect(x: point.x, y: primaryTop-point.y-size.height, width:size.width, height:size.height)
}

func availableWindows() -> [WindowTarget] {
    guard AXIsProcessTrusted() else { return [] }
    var result: [WindowTarget] = []
    for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular && app.processIdentifier != getpid() {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 0.15)
        guard let windows = attribute(element, kAXWindowsAttribute) as? [AXUIElement] else { continue }
        for window in windows {
            AXUIElementSetMessagingTimeout(window, 0.15)
            guard windowRect(window) != nil else { continue }
            let title = attribute(window, kAXTitleAttribute) as? String ?? "Окно"
            result.append(WindowTarget(element:window, pid:app.processIdentifier, title:title.isEmpty ? "Без названия" : title, appName:app.localizedName ?? "Приложение"))
        }
    }
    return result.sorted { ($0.appName, $0.title) < ($1.appName, $1.title) }
}

final class CurtainAttachment {
    let target: WindowTarget?
    weak var demo: NSWindow?
    let panel: CurtainPanel
    let fabric: FabricView
    var dead = false
    private var failures = 0
    private var lastFrame = CGRect.zero

    init(target: WindowTarget? = nil, demo: NSWindow? = nil) {
        self.target = target; self.demo = demo
        let rect = demo?.frame ?? target.flatMap { windowRect($0.element) } ?? CGRect(x:100,y:100,width:800,height:500)
        let body = Self.body(rect)
        fabric = FabricView(frame: CGRect(origin:.zero, size:body.size))
        panel = CurtainPanel(contentRect:body, styleMask:[.borderless,.nonactivatingPanel], backing:.buffered, defer:false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.isReleasedWhenClosed = false; panel.hidesOnDeactivate = false
        panel.level = demo == nil ? .floating : .normal
        panel.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .canJoinAllApplications]
        panel.contentView = fabric
        panel.ignoresMouseEvents = true
        fabric.onDismiss = { [weak self] in self?.dead = true; self?.panel.orderOut(nil) }
        if let demo { demo.addChildWindow(panel, ordered:.above) }
        lastFrame = body
    }
    static func body(_ rect: CGRect) -> CGRect {
        CGRect(x:rect.minX, y:rect.minY, width:rect.width, height:max(30, rect.height-30))
    }
    func update() {
        guard !dead else { panel.orderOut(nil); return }
        var rect: CGRect?
        if let demo {
            guard demo.isVisible && !demo.isMiniaturized else { panel.orderOut(nil); return }
            rect = demo.frame
        } else if let target {
            guard let app = NSRunningApplication(processIdentifier:target.pid), !app.isTerminated else { dead = true; panel.orderOut(nil); return }
            guard !app.isHidden, NSWorkspace.shared.frontmostApplication?.processIdentifier == target.pid else { panel.orderOut(nil); return }
            if (attribute(target.element, kAXMinimizedAttribute) as? Bool) == true { panel.orderOut(nil); return }
            rect = windowRect(target.element)
            if rect == nil {
                failures += 1
                if failures > 30 { dead = true }
                panel.orderOut(nil); return
            }
            failures = 0
            // Don't float a background sibling's curtain over the owner's front window.
            let axApp = AXUIElementCreateApplication(target.pid)
            AXUIElementSetMessagingTimeout(axApp, 0.1)
            if let focused = attribute(axApp, kAXFocusedWindowAttribute), !CFEqual(focused, target.element) {
                panel.orderOut(nil); return
            }
        }
        guard let rect else { return }
        let body = Self.body(rect)
        if body != lastFrame { panel.setFrame(body, display:true); lastFrame = body }
        if !panel.isVisible { panel.orderFrontRegardless() }
        let local = fabric.convert(panel.convertPoint(fromScreen:NSEvent.mouseLocation), from:nil)
        panel.ignoresMouseEvents = fabric.dragging == nil && fabric.fabric(at:local) == nil
    }
    func remove() {
        demo?.removeChildWindow(panel)
        panel.orderOut(nil); panel.close(); dead = true
    }
}
