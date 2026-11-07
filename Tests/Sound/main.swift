import Foundation
import AppKit
func check(_ value: @autoclosure () -> Bool, _ message:String) { if !value() { fatalError(message) } }
let open = CurtainSound.wave(opening:true), close = CurtainSound.wave(opening:false)
check(String(data:open.prefix(4),encoding:.ascii) == "RIFF", "valid WAV header")
check(open.count > 40000 && open != close, "distinct opening and closing fabric sounds")
let cloth = Cloth(width:800,height:500,right:false)
var changes:[Bool] = []
cloth.onOpenChanged = { changes.append($0) }
cloth.open = false; cloth.open = true; cloth.open = true; cloth.open = false
check(changes == [true,false], "sound fires once per actual state change")
let suite = "CurtainSoundTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let sound = CurtainSound(defaults: defaults)
check(sound.volumePercent == 35, "existing playback level is preserved by default")
sound.volumePercent = 70
check(CurtainSound(defaults: defaults).volumePercent == 70, "volume survives relaunch")
sound.volumePercent = 150
check(sound.volumePercent == 100, "volume is clamped to 100 percent")
sound.volumePercent = -5
check(sound.volumePercent == 0, "volume is clamped to zero")
check(sound.enabled, "sound defaults to enabled")
sound.enabled = false
check(!CurtainSound(defaults: defaults).enabled, "mute survives relaunch")
check(open.dropFirst(44).contains { $0 != 0 }, "sound contains audible waveform data")
for name in ["CurtainOpen", "CurtainClose"] {
    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/\(name).wav")
    let data = try! Data(contentsOf: url)
    check(data.count > 40000, "recording is present")
    check(NSSound(contentsOf: url, byReference: false) != nil, "recording decodes in AppKit")
}
var materialRecordings = Set<Data>()
for material in FabricMaterial.allCases {
    for direction in ["Open", "Close"] {
        let path = "Resources/\(material.soundPrefix)\(direction).wav"
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        check(NSSound(data: data) != nil, "material audio decodes")
        materialRecordings.insert(data)
    }
}
check(materialRecordings.count == 6, "materials and directions have distinct audio recordings")
check(CurtainSound.wave(opening:true, material:.cotton) != CurtainSound.wave(opening:true, material:.tulle), "fallback sounds also follow the material")
print("PASS: audio format, distinct sound assets, transition notifications, mute persistence, bundled recordings decode")
