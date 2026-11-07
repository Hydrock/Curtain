import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    var displayName: String { self == .english ? "English" : "Русский" }
}

extension Notification.Name {
    static let curtainLanguageDidChange = Notification.Name("CurtainLanguageDidChange")
}

final class Localization: NSObject {
    static let shared = Localization()
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults; super.init() }
    // Explicit English fallback, independent of the macOS preferred language.
    var language: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "") ?? .english }
        set {
            guard newValue != language else { return }
            defaults.set(newValue.rawValue, forKey: "appLanguage")
            NotificationCenter.default.post(name: .curtainLanguageDidChange, object: self)
        }
    }
    func text(_ english: String, _ russian: String) -> String {
        language == .english ? english : russian
    }
}

func L(_ english: String, _ russian: String) -> String {
    Localization.shared.text(english, russian)
}
