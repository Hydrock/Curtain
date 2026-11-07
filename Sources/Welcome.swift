import AppKit

final class WelcomeView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed:0.955,green:0.94,blue:0.90,alpha:1).setFill(); bounds.fill()
        text("C U R T A I N", at:CGPoint(x:40,y:36), size:12, color:ink, weight:.semibold)
        text("У каждого окна\nесть своя штора.", at:CGPoint(x:40,y:98), size:38, color:ink, weight:.regular)
        text("Маленький театр на вашем Mac.", at:CGPoint(x:42,y:208), size:16, color:ink)
        text("Потяните за ткань — она последует за рукой.\nОтпустите — складки мягко успокоятся.", at:CGPoint(x:42,y:249), size:13, color:ink.withAlphaComponent(0.65))
        text("01   Хватайте за любой участок", at:CGPoint(x:42,y:333), size:12, color:ink)
        text("02   Тяните к краю, чтобы открыть", at:CGPoint(x:42,y:361), size:12, color:ink)
        text("03   Двойной щелчок — открыть / закрыть", at:CGPoint(x:42,y:389), size:12, color:ink)
        text("Выбор окон и управление — в строке меню ↗", at:CGPoint(x:42,y:518), size:11, color:ink.withAlphaComponent(0.55))
        let card = NSRect(x:472,y:88,width:240,height:330)
        NSColor(calibratedRed:0.89,green:0.86,blue:0.80,alpha:1).setFill()
        NSBezierPath(roundedRect:card,xRadius:110,yRadius:110).fill()
        let opening = NSRect(x:502,y:118,width:180,height:275)
        NSColor(calibratedRed:0.21,green:0.30,blue:0.30,alpha:1).setFill()
        NSBezierPath(roundedRect:opening,xRadius:88,yRadius:88).fill()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect:opening,xRadius:88,yRadius:88).addClip()
        NSColor(calibratedRed:0.77,green:0.69,blue:0.50,alpha:1).setFill()
        NSBezierPath(ovalIn:NSRect(x:565,y:164,width:48,height:48)).fill()
        for side in 0..<2 {
            for i in 0..<45 {
                let x = side == 0 ? CGFloat(502+i) : CGFloat(682-i)
                let light = 0.64 + 0.3*cos(CGFloat(i)*0.45)
                NSColor(calibratedRed:0.42*light,green:0.18*light,blue:0.23*light,alpha:1).setFill()
                NSRect(x:x,y:118,width:1.2,height:275).fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        text("ПРИДУМАНО ВО СНЕ",at:CGPoint(x:515,y:450),size:10,color:ink.withAlphaComponent(0.5),weight:.medium)
    }
    private var ink: NSColor { NSColor(calibratedRed:0.20,green:0.25,blue:0.23,alpha:1) }
    private func text(_ string:String, at point:CGPoint, size:CGFloat, color:NSColor, weight:NSFont.Weight = .regular) {
        (string as NSString).draw(at:point, withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:weight), .foregroundColor:color])
    }
}

final class DemoView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed:0.94,green:0.92,blue:0.86,alpha:1).setFill(); bounds.fill()
        let center = bounds.width/2
        NSColor(calibratedRed:0.72,green:0.50,blue:0.30,alpha:1).setFill()
        NSBezierPath(ovalIn:NSRect(x:center-45,y:80,width:90,height:90)).fill()
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        func label(_ text:String, y:CGFloat, size:CGFloat, alpha:CGFloat = 1) {
            (text as NSString).draw(in:NSRect(x:35,y:y,width:bounds.width-70,height:120),withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:.regular),.foregroundColor:NSColor(calibratedRed:0.21,green:0.29,blue:0.27,alpha:alpha),.paragraphStyle:paragraph])
        }
        label("Немного тишины.",y:205,size:36)
        label("За этой шторой — ваше окно.",y:266,size:16,alpha:0.65)
        label("Тяните ткань к краям, чтобы открыть.\nДвойной щелчок по шторе — закрыть.\nПравый щелчок — меню управления.",y:330,size:13,alpha:0.6)
    }
}
