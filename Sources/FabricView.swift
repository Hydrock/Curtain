import AppKit

final class CurtainPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class FabricView: NSView {
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    var left: Cloth
    var right: Cloth
    var tint = NSColor(calibratedRed: 0.32, green: 0.12, blue: 0.19, alpha: 1)
    var dragging: Cloth?
    var onDismiss: (() -> Void)?
    private var down = CGPoint.zero
    private var dragged = false

    override init(frame: NSRect) {
        left = Cloth(width: frame.width, height: frame.height, right: false)
        right = Cloth(width: frame.width, height: frame.height, right: true)
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func setFrameSize(_ newSize: NSSize) {
        guard newSize != frame.size else { return }
        super.setFrameSize(newSize)
        left.resize(width: newSize.width, height: newSize.height)
        right.resize(width: newSize.width, height: newSize.height)
    }
    func outline(_ cloth: Cloth) -> NSBezierPath {
        let path = NSBezierPath(), stride = cloth.columns + 1
        path.move(to: cloth.points[0])
        for c in 1...cloth.columns { path.line(to: cloth.points[c]) }
        for r in 1...cloth.rows { path.line(to: cloth.points[r * stride + cloth.columns]) }
        for c in (0..<cloth.columns).reversed() { path.line(to: cloth.points[cloth.rows * stride + c]) }
        for r in (0..<cloth.rows).reversed() { path.line(to: cloth.points[r * stride]) }
        path.close()
        return path
    }
    func fabric(at point: CGPoint) -> Cloth? {
        if outline(right).contains(point) { return right }
        if outline(left).contains(point) { return left }
        return nil
    }
    func tick() { left.step(); right.step(); needsDisplay = true }
    func setOpen(_ value: Bool) { left.open = value; right.open = value }
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        for cloth in [left, right] { drawFabric(cloth, context: ctx) }
        let rail = NSBezierPath(roundedRect: NSRect(x: 0, y: 1, width: bounds.width, height: 4), xRadius: 2, yRadius: 2)
        NSColor(calibratedRed: 0.64, green: 0.52, blue: 0.33, alpha: 1).setFill(); rail.fill()
        for cloth in [left, right] {
            for c in stride(from: 0, through: cloth.columns, by: 2) {
                let p = cloth.points[c]
                let ring = NSBezierPath(ovalIn: NSRect(x: p.x - 2, y: 0, width: 4, height: 8))
                NSColor(calibratedWhite: 0.82, alpha: 1).setStroke(); ring.lineWidth = 1; ring.stroke()
            }
        }
    }
    private func drawFabric(_ cloth: Cloth, context ctx: CGContext) {
        let path = outline(cloth)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = .black.withAlphaComponent(0.32)
        shadow.shadowBlurRadius = 10; shadow.shadowOffset = NSSize(width: cloth.right ? -4 : 4, height: -4)
        shadow.set(); tint.setFill(); path.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let base = tint.usingColorSpace(.deviceRGB)!
        let stride = cloth.columns + 1
        // Subdivide each mesh strip for smooth, continuous velvet highlights.
        for c in 0..<cloth.columns {
            for s in 0..<4 {
                let a = CGFloat(s) / 4, b = CGFloat(s + 1) / 4
                func point(_ row: Int, _ fraction: CGFloat) -> CGPoint {
                    let p = cloth.points[row * stride + c], q = cloth.points[row * stride + c + 1]
                    return CGPoint(x: p.x + (q.x-p.x)*fraction, y: p.y + (q.y-p.y)*fraction)
                }
                let strip = NSBezierPath(); strip.move(to: point(0, a))
                for r in 1...cloth.rows { strip.line(to: point(r,a)) }
                for r in (0...cloth.rows).reversed() { strip.line(to: point(r,b)) }
                strip.close()
                let phase = (CGFloat(c) + (a+b)/2) / CGFloat(cloth.columns) * .pi * 16
                let light = 0.68 + 0.32 * cos(phase) + 0.12 * sin(phase)
                NSColor(calibratedRed: min(1,base.redComponent*light*1.25), green: min(1,base.greenComponent*light*1.25), blue: min(1,base.blueComponent*light*1.25), alpha: 1).setFill()
                strip.fill()
            }
        }
        // Fine horizontal threads and a stitched, weighted hem.
        NSColor.white.withAlphaComponent(0.035).setStroke()
        let threads = NSBezierPath(); threads.lineWidth = 0.5
        for y in strideThrough(height: bounds.height) {
            threads.move(to: CGPoint(x: 0, y: y)); threads.line(to: CGPoint(x: bounds.width, y: y))
        }
        threads.stroke()
        let hem = NSBezierPath()
        for c in 0...cloth.columns {
            var p = cloth.points[cloth.rows*stride+c]; p.y -= 7
            if c == 0 { hem.move(to:p) } else { hem.line(to:p) }
        }
        NSColor.black.withAlphaComponent(0.2).setStroke(); hem.lineWidth = 1; hem.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
    private func strideThrough(height: CGFloat) -> [CGFloat] {
        Array(Swift.stride(from: CGFloat(10), to: height, by: CGFloat(4)))
    }
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let cloth = fabric(at:p) else { return }
        if event.clickCount == 2 { cloth.open.toggle(); return }
        down = p; dragged = false; dragging = cloth
        if let i = cloth.nearest(to:p) { cloth.grab(index:i, at:p) }
        NSCursor.closedHand.push()
    }
    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from:nil)
        if hypot(p.x-down.x,p.y-down.y)>5 { dragged = true }
        dragging?.moveHand(p)
    }
    override func mouseUp(with event: NSEvent) {
        guard let cloth = dragging else { return }
        let p = convert(event.locationInWindow, from:nil)
        cloth.release()
        if dragged {
            let dx = p.x-down.x
            if abs(dx) > 50 { cloth.open = cloth.right ? dx > 0 : dx < 0 }
        }
        dragging = nil; NSCursor.pop()
    }
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        for (title, action) in [(L("Open curtains", "Открыть шторы"), #selector(openCurtains)), (L("Close curtains", "Закрыть шторы"), #selector(closeCurtains)), (L("Remove curtains", "Снять шторы"), #selector(removeCurtains))] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: ""); item.target = self
        }
        NSMenu.popUpContextMenu(menu, with:event, for:self)
    }
    @objc func openCurtains() { setOpen(true) }
    @objc func closeCurtains() { setOpen(false) }
    @objc func removeCurtains() { onDismiss?() }
}
