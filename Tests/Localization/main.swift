import Foundation
func check(_ value: @autoclosure () -> Bool, _ message:String) { if !value() { fatalError(message) } }
let suite = "CurtainLanguageTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName:suite)!
defer { defaults.removePersistentDomain(forName:suite) }
defaults.set(["ru-RU"],forKey:"AppleLanguages")
let localization = Localization(defaults:defaults)
check(localization.language == .english, "English is default even on a Russian system")
check(localization.text("Open", "Открыть") == "Open", "default renders English")
var changes = 0
let observer = NotificationCenter.default.addObserver(forName:.curtainLanguageDidChange,object:localization,queue:nil) { _ in changes += 1 }
localization.language = .russian
check(localization.text("Open", "Открыть") == "Открыть", "Russian selection updates text")
check(Localization(defaults:defaults).language == .russian, "language survives relaunch")
localization.language = .russian
check(changes == 1, "language change notifies once and ignores unchanged selections")
localization.language = .english
check(changes == 2, "switching back notifies existing views")
defaults.set("de",forKey:"appLanguage")
check(Localization(defaults:defaults).language == .english, "unsupported stored language falls back to English")
NotificationCenter.default.removeObserver(observer)
print("PASS: English default, Russian text, persistence, live notifications, invalid preference fallback")
