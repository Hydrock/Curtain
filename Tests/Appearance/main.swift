import Foundation
func check(_ value: @autoclosure () -> Bool, _ message:String) {
    if !value() { fputs("FAIL: \(message)\n",stderr); exit(1) }
}
let suite = "CurtainTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName:suite)!
defer { defaults.removePersistentDomain(forName:suite) }
let settings = AppearanceSettings(defaults:defaults)
check(settings.transparency == 0 && settings.opacity == 1,"new curtains are opaque")
settings.transparency = 65
check(abs(settings.opacity - 0.35) < 0.0001,"transparency converts to opacity")
check(AppearanceSettings(defaults:defaults).transparency == 65,"transparency survives relaunch")
settings.transparency = 100
check(settings.transparency == 90 && abs(settings.opacity - 0.1) < 0.0001,"curtains remain visible and grabbable")
settings.transparency = -10
check(settings.opacity == 1,"negative transparency is clamped")
print("PASS: default opacity, conversion, persistence, upper and lower limits")
