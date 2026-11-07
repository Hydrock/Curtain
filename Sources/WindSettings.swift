import Foundation

final class WindSettings {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var enabled: Bool {
        get { defaults.bool(forKey: "curtainWindEnabled") }
        set { defaults.set(newValue, forKey: "curtainWindEnabled") }
    }
    var strengthPercent: Int {
        get {
            guard defaults.object(forKey: "curtainWindStrength") != nil else { return 35 }
            return min(100, max(0, defaults.integer(forKey: "curtainWindStrength")))
        }
        set { defaults.set(min(100, max(0, newValue)), forKey: "curtainWindStrength") }
    }
    var effectiveStrength: Double { enabled ? Double(strengthPercent) / 100 : 0 }
}
