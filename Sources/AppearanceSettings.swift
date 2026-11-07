import Foundation

final class AppearanceSettings {
    private let defaults: UserDefaults
    private var storedTransparency: Int
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        storedTransparency = min(90, max(0, defaults.integer(forKey: "curtainTransparency")))
    }
    var transparency: Int {
        get { storedTransparency }
        set {
            storedTransparency = min(90, max(0, newValue))
            defaults.set(storedTransparency, forKey: "curtainTransparency")
        }
    }
    var opacity: Double { 1 - Double(storedTransparency) / 100 }
}
