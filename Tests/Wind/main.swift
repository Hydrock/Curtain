import Foundation
import CoreGraphics
func check(_ value: @autoclosure () -> Bool, _ message:String) { if !value() { fatalError(message) } }
let suite = "CurtainWindTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName:suite)!
defer { defaults.removePersistentDomain(forName:suite) }
let settings = WindSettings(defaults:defaults)
check(!settings.enabled && settings.effectiveStrength == 0, "wind defaults to off")
settings.strengthPercent = 40; settings.enabled = true
check(abs(settings.effectiveStrength-0.4)<0.001, "wind strength maps to simulation amplitude")
check(WindSettings(defaults:defaults).enabled && WindSettings(defaults:defaults).strengthPercent == 40, "wind preferences survive relaunch")
settings.strengthPercent = 200
check(settings.strengthPercent == 100, "strength has upper bound")
settings.strengthPercent = -1
check(settings.strengthPercent == 0, "strength has lower bound")
settings.enabled = false
check(settings.effectiveStrength == 0, "disabled wind applies no force")
let still = Cloth(width:800,height:500,right:false)
let weak = Cloth(width:800,height:500,right:false)
let strong = Cloth(width:800,height:500,right:false)
weak.windStrength = 0.2; strong.windStrength = 0.8
var weakMin = CGFloat.infinity, weakMax = -CGFloat.infinity
var strongMin = CGFloat.infinity, strongMax = -CGFloat.infinity
var soundEvents = 0
strong.onOpenChanged = { _ in soundEvents += 1 }
for _ in 0..<900 {
    still.step(); weak.step(); strong.step()
    weakMin = min(weakMin,weak.points.last!.x); weakMax = max(weakMax,weak.points.last!.x)
    strongMin = min(strongMin,strong.points.last!.x); strongMax = max(strongMax,strong.points.last!.x)
}
check(abs(still.points.last!.x-409.6)<0.001, "disabled wind keeps a settled curtain still")
check(weakMax-weakMin>0.5, "light wind moves the hem")
check(strongMax-strongMin>(weakMax-weakMin)*2, "increasing strength visibly increases motion")
check(strongMax-strongMin<25, "even strong breeze remains subtle")
for c in 0...strong.columns { check(strong.points[c] == still.points[c], "wind never moves pinned rail rings") }
check(soundEvents == 0, "wind does not trigger opening and closing sounds")
strong.grab(index:200,at:CGPoint(x:200,y:260))
for _ in 0..<60 { strong.step() }
check(strong.points[200] == CGPoint(x:200,y:260), "hand remains in control while wind is blowing")
strong.release(); strong.open = true
for _ in 0..<300 { strong.step() }
check(strong.points.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "wind stays stable while opening and releasing")
strong.open = false; strong.windStrength = 0
for _ in 0..<1200 { strong.step() }
check(abs(strong.points.last!.x-still.points.last!.x)<0.01, "switching off lets fabric settle naturally")
strong.windStrength = .nan
check(strong.windStrength == 0, "invalid force is rejected")
print("PASS: wind preferences, strength, subtle motion, fixed rings, dragging, sound isolation, stability and settling")
