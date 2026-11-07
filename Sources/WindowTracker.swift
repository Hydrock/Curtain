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

struct WindowSnapshot {
    let frame: CGRect
    let minimized: Bool

    init?(values: [AnyObject], primaryTop: CGFloat) {
        guard values.count >= 2,
              CFGetTypeID(values[0]) == AXValueGetTypeID(),
              CFGetTypeID(values[1]) == AXValueGetTypeID() else { return nil }
        let p = unsafeBitCast(values[0], to: AXValue.self)
        let s = unsafeBitCast(values[1], to: AXValue.self)
        guard AXValueGetType(p) == .cgPoint, AXValueGetType(s) == .cgSize else { return nil }
        var point = CGPoint.zero, size = CGSize.zero
        guard AXValueGetValue(p, .cgPoint, &point), AXValueGetValue(s, .cgSize, &size),
              point.x.isFinite, point.y.isFinite, size.width.isFinite, size.height.isFinite,
              size.width > 40, size.height > 60 else { return nil }
        frame = CGRect(x: point.x, y: primaryTop-point.y-size.height, width: size.width, height: size.height)
        minimized = values.count > 2 ? (values[2] as? Bool ?? false) : false
    }
}

func windowSnapshot(_ element: AXUIElement) -> WindowSnapshot? {
    var values: CFArray?
    // One IPC round trip instead of separate position, size and minimized queries.
    let names = [kAXPositionAttribute, kAXSizeAttribute, kAXMinimizedAttribute] as CFArray
    guard AXUIElementCopyMultipleAttributeValues(element, names, [], &values) == .success,
          let values = values as? [AnyObject] else { return nil }
    return WindowSnapshot(values: values, primaryTop: NSScreen.screens.first?.frame.maxY ?? 0)
}

func windowRect(_ element: AXUIElement) -> CGRect? { windowSnapshot(element)?.frame }

/// Notification delivery runs on the main loop, including menu/mouse tracking modes.
private final class WindowObservation {
    private var observer: AXObserver?
    private var registrations: [(AXUIElement, String)] = []
    private let changed: (String) -> Void

    init(target: WindowTarget, owner: AXUIElement, changed: @escaping (String) -> Void) {
        self.changed = changed
        var created: AXObserver?
        guard AXObserverCreate(target.pid, { _, _, notification, context in
            guard let context else { return }
            Unmanaged<WindowObservation>.fromOpaque(context).takeUnretainedValue().changed(notification as String)
        }, &created) == .success, let created else { return }
        observer = created
        let context = Unmanaged.passUnretained(self).toOpaque()
        let notifications = [kAXMovedNotification, kAXResizedNotification, kAXWindowMiniaturizedNotification,
                             kAXWindowDeminiaturizedNotification, kAXUIElementDestroyedNotification]
        for name in notifications {
            if AXObserverAddNotification(created, target.element, name as CFString, context) == .success {
                registrations.append((target.element, name))
            }
        }
        if AXObserverAddNotification(created, owner, kAXFocusedWindowChangedNotification as CFString, context) == .success {
            registrations.append((owner, kAXFocusedWindowChangedNotification))
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .commonModes)
    }
    func invalidate() {
        guard let observer else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        for (element, name) in registrations { AXObserverRemoveNotification(observer, element, name as CFString) }
        registrations.removeAll()
        self.observer = nil
    }
    deinit { invalidate() }
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
    private let owner: AXUIElement?
    private var observation: WindowObservation?
    private var nextFocusCheck = 0.0
    private var isFocused = true
    private var lastFrame = CGRect.zero

    init(target: WindowTarget? = nil, demo: NSWindow? = nil) {
        self.target = target; self.demo = demo
        owner = target.map { AXUIElementCreateApplication($0.pid) }
        if let owner { AXUIElementSetMessagingTimeout(owner, 0.05) }
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
        if let target, let owner {
            observation = WindowObservation(target: target, owner: owner) { [weak self] notification in
                guard let self else { return }
                if notification == kAXUIElementDestroyedNotification {
                    self.dead = true; self.panel.orderOut(nil); return
                }
                self.update(forceFocusCheck: notification != kAXMovedNotification && notification != kAXResizedNotification)
            }
        }
    }
    static func body(_ rect: CGRect) -> CGRect {
        CGRect(x:rect.minX, y:rect.minY, width:rect.width, height:max(30, rect.height-30))
    }
    func update(forceFocusCheck: Bool = false) {
        guard !dead else { panel.orderOut(nil); return }
        var rect: CGRect?
        if let demo {
            guard demo.isVisible && !demo.isMiniaturized else { panel.orderOut(nil); return }
            rect = demo.frame
        } else if let target {
            guard let app = NSRunningApplication(processIdentifier:target.pid), !app.isTerminated else { dead = true; panel.orderOut(nil); return }
            guard !app.isHidden, NSWorkspace.shared.frontmostApplication?.processIdentifier == target.pid else {
                nextFocusCheck = 0
                panel.orderOut(nil); return
            }
            // Focus changes are notified immediately, with a 100ms fallback for apps
            // that don't publish notifications. Don't ask for focus on every frame.
            let now = ProcessInfo.processInfo.systemUptime
            if forceFocusCheck || now >= nextFocusCheck {
                nextFocusCheck = now + 0.1
                if let owner, let focused = attribute(owner, kAXFocusedWindowAttribute) {
                    isFocused = CFEqual(focused, target.element)
                }
            }
            guard isFocused else { panel.orderOut(nil); return }
            guard let snapshot = windowSnapshot(target.element) else {
                failures += 1
                if failures > 60 { dead = true }
                panel.orderOut(nil); return
            }
            failures = 0
            guard !snapshot.minimized else { panel.orderOut(nil); return }
            rect = snapshot.frame
        }
        guard let rect else { return }
        let body = Self.body(rect)
        if body != lastFrame {
            if body.size == lastFrame.size {
                // Moving does not invalidate the cloth layout or force a redraw.
                panel.setFrameOrigin(body.origin)
            } else {
                panel.setFrame(body, display: false)
            }
            lastFrame = body
        }
        if !panel.isVisible { panel.orderFrontRegardless() }
        let local = fabric.convert(panel.convertPoint(fromScreen:NSEvent.mouseLocation), from:nil)
        panel.ignoresMouseEvents = fabric.dragging == nil && fabric.fabric(at:local) == nil
    }
    func remove() {
        observation?.invalidate(); observation = nil
        demo?.removeChildWindow(panel)
        panel.orderOut(nil); panel.close(); dead = true
    }
}
