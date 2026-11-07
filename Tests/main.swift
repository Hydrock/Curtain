import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
let cloth = Cloth(width: 800, height: 500, right: false)
for _ in 0..<300 { cloth.step() }
check(cloth.points.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "closed fabric stays finite")
check(cloth.points.last!.x > 350, "closed panel covers half the window")
cloth.open = true
for _ in 0..<400 { cloth.step() }
check(cloth.points.map(\.x).max()! < 130, "opening gathers cloth at left edge")
let index = cloth.nearest(to: cloth.points[200])!
let before = cloth.points[index]
cloth.grab(index: index, at: CGPoint(x: before.x + 190, y: before.y + 80))
for _ in 0..<30 { cloth.step() }
check(cloth.points[index].x > before.x + 130, "drag pulls the grabbed fabric point")
check(abs(cloth.points[index + 1].x - before.x) > 20, "pull propagates through the fabric")
cloth.release()
for _ in 0..<900 { cloth.step() }
check(cloth.points.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "fabric survives release")
check(cloth.points.map(\.x).max()! < 135, "released open curtain settles")
cloth.resize(width: 300, height: 180)
cloth.open = false
for _ in 0..<400 { cloth.step() }
check(cloth.points.map(\.x).max()! < 210, "resize adapts cloth geometry")
let right = Cloth(width: 800, height: 500, right: true)
right.open = true
for _ in 0..<400 { right.step() }
check(right.points.map(\.x).min()! > 670, "right curtain gathers at right edge")
right.grab(index: 200, at: CGPoint(x: -100000, y: 100000))
for _ in 0..<100 { right.step() }
right.release()
for _ in 0..<1000 { right.step() }
check(right.points.allSatisfy { $0.x.isFinite && $0.y.isFinite }, "extreme pull stays stable")
print("PASS: opening, drag propagation, release, settling, resizing, right panel, extreme pull")
