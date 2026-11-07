import AppKit
import ApplicationServices

func check(_ value: @autoclosure () -> Bool, _ message: String) {
    if !value() { fputs("FAIL: \(message)\n",stderr); exit(1) }
}
// Regression: one batched AX reply must preserve frame and minimization state.
var axPosition = CGPoint(x: 100, y: 200), axSize = CGSize(width: 800, height: 500)
let positionValue = AXValueCreate(.cgPoint, &axPosition)!
let sizeValue = AXValueCreate(.cgSize, &axSize)!
let snapshot = WindowSnapshot(values: [positionValue, sizeValue, kCFBooleanTrue!], primaryTop: 1080)
check(snapshot?.frame == CGRect(x: 100, y: 380, width: 800, height: 500), "batched AX geometry converts screen coordinates")
check(snapshot?.minimized == true, "batched AX reply preserves minimized state")
check(WindowSnapshot(values: [kCFNull!, sizeValue, kCFBooleanFalse!], primaryTop: 1080) == nil, "invalid AX position is rejected")
check(WindowSnapshot(values: [], primaryTop: 1080) == nil, "incomplete AX replies are rejected")
let unsupportedMinimize = WindowSnapshot(values: [positionValue, sizeValue, kCFNull!], primaryTop: 1080)
check(unsupportedMinimize?.frame == snapshot?.frame && unsupportedMinimize?.minimized == false, "unsupported minimize attribute does not discard geometry")
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let window = NSWindow(contentRect:NSRect(x:100,y:100,width:800,height:520),styleMask:[.titled,.resizable],backing:.buffered,defer:false)
window.isReleasedWhenClosed = false
window.orderFront(nil)
let firstFabric = FabricView(frame: CGRect(x:0, y:0, width:800, height:500))
let secondFabric = FabricView(frame: firstFabric.frame)
for view in [firstFabric, secondFabric] {
    view.left.grab(index: 200, at: CGPoint(x: 300, y: 250))
    for _ in 0..<20 { view.left.step() }
    view.left.release()
}
firstFabric.setFrameSize(firstFabric.frame.size)
firstFabric.left.step(); secondFabric.left.step()
check(firstFabric.left.points == secondFabric.left.points, "same-size layout preserves cloth momentum during a window move")
let attachment = CurtainAttachment(demo:window)
attachment.update()
check(attachment.panel.isVisible,"demo curtain stays visible even without application focus")
check(attachment.panel.level == .normal,"demo curtain shares normal window stacking")
check(abs(attachment.panel.frame.maxY - (window.frame.maxY - 30)) < 1,"curtain leaves title bar free")
check(attachment.fabric.fabric(at:CGPoint(x:200,y:200)) != nil,"closed fabric receives clicks")
attachment.fabric.setOpen(true)
for _ in 0..<400 { attachment.fabric.tick() }
check(attachment.fabric.fabric(at:CGPoint(x:400,y:200)) == nil,"open center lets clicks pass through")
check(attachment.fabric.fabric(at:CGPoint(x:15,y:200)) != nil,"gathered curtain remains grabbable")
window.setFrame(NSRect(x:200,y:200,width:600,height:400),display:false)
attachment.update()
check(attachment.panel.frame == NSRect(x:200,y:200,width:600,height:370),"curtain follows move and resize")
attachment.fabric.setOpen(false)
for _ in 0..<400 { attachment.fabric.tick() }
func mouse(_ type: NSEvent.EventType, x: CGFloat, clicks: Int = 1) -> NSEvent {
    NSEvent.mouseEvent(with:type,location:CGPoint(x:x,y:180),modifierFlags:[],timestamp:0,windowNumber:attachment.panel.windowNumber,context:nil,eventNumber:1,clickCount:clicks,pressure:1)!
}
attachment.fabric.mouseDown(with:mouse(.leftMouseDown,x:220))
check(attachment.fabric.dragging != nil,"mouse down grabs fabric")
attachment.fabric.mouseDragged(with:mouse(.leftMouseDragged,x:20))
attachment.fabric.mouseUp(with:mouse(.leftMouseUp,x:20))
check(attachment.fabric.left.open,"outward drag opens left curtain")
check(attachment.fabric.dragging == nil,"mouse up releases fabric")
attachment.fabric.mouseDown(with:mouse(.leftMouseDown,x:450,clicks:2))
check(attachment.fabric.right.open,"double click toggles right curtain")
var changedTransparency = -1
let control = TransparencyControl(value: 20) { changedTransparency = $0 }
control.slider.integerValue = 65
_ = control.slider.sendAction(control.slider.action!, to: control.slider.target)
check(changedTransparency == 65, "slider delivers selected transparency")
check(control.label.stringValue.contains("65%"), "slider displays updated percentage")
var changedVolume = -1
let volumeControl = VolumeControl(value: 35) { changedVolume = $0 }
check(volumeControl.slider.integerValue == 35, "volume slider loads current setting")
volumeControl.slider.integerValue = 80
_ = volumeControl.slider.sendAction(volumeControl.slider.action!, to: volumeControl.slider.target)
check(changedVolume == 80, "volume slider delivers selected level")
check(volumeControl.label.stringValue.contains("80%"), "volume label updates while adjusting")
volumeControl.slider.integerValue = 0
_ = volumeControl.slider.sendAction(volumeControl.slider.action!, to: volumeControl.slider.target)
check(changedVolume == 0, "volume slider can mute sound")
let previousLanguage = Localization.shared.language
for (language, expectedVolume, expectedTransparency) in [(AppLanguage.english, "Volume: 35%", "Transparency: 20%"), (.russian, "Громкость: 35%", "Прозрачность: 20%")] {
    Localization.shared.language = language
    let volume = VolumeControl(value: 35) { _ in }
    let transparency = TransparencyControl(value: 20) { _ in }
    check(volume.label.stringValue == expectedVolume, "volume control uses selected language")
    check(transparency.label.stringValue == expectedTransparency, "transparency control uses selected language")
}
Localization.shared.language = previousLanguage
attachment.remove()
check(!attachment.panel.isVisible && attachment.dead,"remove dismisses curtain")
window.orderOut(nil)
print("PASS: demo focus, stacking, title bar, fabric hit testing, click-through, move/resize, drag events, double click, removal")
