import AppKit

final class CurtainSound {
    private var clips: [String: NSSound] = [:]
    private var activeSound: NSSound?
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private var lastPlay = -Double.infinity
    var enabled: Bool {
        get { defaults.object(forKey: "curtainSound") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "curtainSound") }
    }
    var volumePercent: Int {
        get {
            guard defaults.object(forKey: "curtainVolume") != nil else { return 35 }
            return min(100, max(0, defaults.integer(forKey: "curtainVolume")))
        }
        set {
            let value = min(100, max(0, newValue))
            defaults.set(value, forKey: "curtainVolume")
            clips.values.forEach { $0.volume = Float(value) / 100 }
        }
    }
    func play(opening: Bool, material: FabricMaterial = .velvet) {
        let now = ProcessInfo.processInfo.systemUptime
        // Both fabric panels and multi-window commands share one quiet sound.
        guard enabled, volumePercent > 0, now - lastPlay > 0.09 else { return }
        lastPlay = now
        activeSound?.stop()
        let key = material.soundPrefix + (opening ? "Open" : "Close")
        if clips[key] == nil { clips[key] = Self.sound(opening: opening, material: material) }
        let sound = clips[key]
        activeSound = sound
        sound?.volume = Float(volumePercent) / 100
        sound?.play()
    }
    func stop() { activeSound?.stop(); activeSound = nil; lastPlay = -Double.infinity }
    private static func sound(opening: Bool, material: FabricMaterial) -> NSSound? {
        let name = material.soundPrefix + (opening ? "Open" : "Close")
        if let url = Bundle.main.url(forResource: name, withExtension: "wav"),
           let sound = NSSound(contentsOf: url, byReference: false) { return sound }
        return NSSound(data: wave(opening: opening, material: material))
    }
    /// Fallback for command-line builds without bundled recordings.
    /// Deterministic filtered noise: a soft fabric swish with subtle rail texture.
    static func wave(opening: Bool, material: FabricMaterial = .velvet) -> Data {
        let duration = material == .velvet ? 1.0 : (material == .cotton ? 0.8 : 0.92)
        let rate = 44100, count = Int(Double(rate) * (opening ? 0.68 : 0.78) * duration)
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(36 + count * 2)); ascii("WAVEfmt ")
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        ascii("data"); u32(UInt32(count * 2))
        var seed: UInt32 = opening ? 38291 : 72819
        var low = 0.0, smooth = 0.0
        for i in 0..<count {
            seed = seed &* 1664525 &+ 1013904223
            let noise = Double(seed) / Double(UInt32.max) * 2 - 1
            low += 0.009 * (noise - low)
            let filter = material == .velvet ? 0.065 : (material == .cotton ? 0.11 : 0.04)
            smooth += filter * (noise - smooth)
            let t = Double(i) / Double(count - 1)
            let envelope = pow(sin(.pi * t), 1.4)
            let ripple = 0.78 + 0.22 * sin(Double(i) / Double(rate) * 2 * .pi * (opening ? 3 : 2.5))
            let sample = (smooth - low) * envelope * ripple * 0.4
            u16(UInt16(bitPattern: Int16(max(-32767, min(32767, sample * 32767)))))
        }
        return data
    }
}
