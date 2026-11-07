import Foundation
import CoreGraphics
func check(_ value: @autoclosure () -> Bool, _ message:String) { if !value() { fatalError(message) } }
let suite = "CurtainMaterialsTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName:suite)!
defer { defaults.removePersistentDomain(forName:suite) }
let settings = AppearanceSettings(defaults:defaults)
check(settings.material == .velvet, "existing installations retain velvet")
settings.material = .tulle
check(AppearanceSettings(defaults:defaults).material == .tulle, "material survives relaunch")
defaults.set("unknown",forKey:"curtainMaterial")
check(AppearanceSettings(defaults:defaults).material == .velvet, "invalid preference falls back safely")
var releasePaths: [[CGFloat]] = []
for material in FabricMaterial.allCases {
    let cloth = Cloth(width:800,height:500,right:false)
    cloth.material = material
    cloth.grab(index:200,at:CGPoint(x:300,y:240))
    for _ in 0..<30 { cloth.step() }
    check(cloth.points[200] == CGPoint(x:300,y:240), "all materials follow the hand")
    cloth.release()
    var path: [CGFloat] = []
    for _ in 0..<40 { cloth.step(); path.append(cloth.points[200].y) }
    releasePaths.append(path)
    cloth.open = true; cloth.windStrength = 1
    for _ in 0..<900 { cloth.step() }
    check(cloth.points.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "all materials stay stable in strong wind")
    check(cloth.points[0].y == 4, "all materials keep rail rings pinned")
    cloth.windStrength = 0; cloth.open = false
    for _ in 0..<1200 { cloth.step() }
    check(abs(cloth.points.last!.x-409.6)<0.01, "all materials close and settle after wind")
}
let velvetCottonDifference = zip(releasePaths[0],releasePaths[1]).map { abs($0-$1) }.max()!
let cottonTulleDifference = zip(releasePaths[1],releasePaths[2]).map { abs($0-$1) }.max()!
check(velvetCottonDifference > 2, "cotton and velvet release differently over time")
check(cottonTulleDifference > 2, "tulle has its own release response")
print("PASS: material persistence, distinct release behavior, grabbing, strong wind, pinned rings and settling")
