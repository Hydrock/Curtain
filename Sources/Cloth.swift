import Foundation
import CoreGraphics

/// A damped, elastic displacement field over a sliding pleated rest mesh.
/// Top-row rings are pinned to the rail; all other points can be pulled.
final class Cloth {
    let columns = 22
    let rows = 28
    private(set) var points: [CGPoint] = []
    private var velocity: [CGVector] = []
    private var width: CGFloat
    private var height: CGFloat
    let right: Bool
    var onOpenChanged: ((Bool) -> Void)?
    var open = false {
        didSet { if open != oldValue { onOpenChanged?(open) } }
    }
    private(set) var gathering: CGFloat = 0
    private var held: Int?
    private var hand = CGPoint.zero

    init(width: CGFloat, height: CGFloat, right: Bool) {
        self.width = max(80, width); self.height = max(60, height); self.right = right
        points = (0...rows).flatMap { r in (0...columns).map { c in rest(c, r) } }
        velocity = Array(repeating: .zero, count: points.count)
    }
    func rest(_ c: Int, _ r: Int) -> CGPoint {
        let u = CGFloat(c) / CGFloat(columns), v = CGFloat(r) / CGFloat(rows)
        let span = width * (0.512 * (1 - gathering) + 0.085 * gathering)
        let x = u * span
        let hem = sin(u * .pi * 8) * (2 + 3 * gathering) * pow(v, 5)
        return CGPoint(x: right ? width - x : x, y: v * (height - 8) + hem + 4)
    }
    func resize(width: CGFloat, height: CGFloat) {
        let w = max(80, width), h = max(60, height)
        for i in points.indices { points[i].x *= w / self.width; points[i].y *= h / self.height }
        self.width = w; self.height = h
        velocity = Array(repeating: .zero, count: points.count)
    }
    func nearest(to point: CGPoint) -> Int? {
        // The rail itself is fixed: choose the nearest movable point.
        ((columns + 1)..<points.count).min {
            hypot(points[$0].x - point.x, points[$0].y - point.y) < hypot(points[$1].x - point.x, points[$1].y - point.y)
        }
    }
    func grab(index: Int, at point: CGPoint) { held = index; moveHand(point) }
    func moveHand(_ point: CGPoint) {
        hand = CGPoint(x: min(width + 150, max(-150, point.x)), y: min(height + 150, max(4, point.y)))
    }
    func release() { held = nil }
    func step() {
        gathering += ((open ? 1 : 0) - gathering) * 0.075
        // Fixed 120 Hz substeps give a stable spring solver independent of UI size.
        for _ in 0..<2 {
            let old = points
            for r in 0...rows {
                for c in 0...columns {
                    let i = r * (columns + 1) + c, target = rest(c, r)
                    if r == 0 { points[i] = target; velocity[i] = .zero; continue }
                    var fx = (target.x - old[i].x) * 0.018
                    var fy = (target.y - old[i].y) * 0.018
                    for (nc, nr) in [(c-1,r),(c+1,r),(c,r-1),(c,r+1)] where nc >= 0 && nc <= columns && nr >= 0 && nr <= rows {
                        let j = nr * (columns + 1) + nc, neighbor = rest(nc, nr)
                        fx += ((old[j].x - neighbor.x) - (old[i].x - target.x)) * 0.12
                        fy += ((old[j].y - neighbor.y) - (old[i].y - target.y)) * 0.12
                    }
                    velocity[i].dx = (velocity[i].dx + fx) * 0.91
                    velocity[i].dy = (velocity[i].dy + fy) * 0.91
                    points[i].x += velocity[i].dx; points[i].y += velocity[i].dy
                }
            }
            if let i = held { points[i] = hand; velocity[i] = .zero }
        }
    }
}
