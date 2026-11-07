import AppKit

/// A continuous slider inside the status menu; keeps the menu open while adjusting.
final class TransparencyControl: NSView {
    let label = NSTextField(labelWithString: "")
    let slider: NSSlider
    private let onChange: (Int) -> Void

    init(value: Int, onChange: @escaping (Int) -> Void) {
        self.onChange = onChange
        slider = NSSlider(value: Double(value), minValue: 0, maxValue: 90, target: nil, action: nil)
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 66))
        label.frame = NSRect(x: 18, y: 40, width: 225, height: 18)
        label.font = .menuFont(ofSize: 13)
        slider.frame = NSRect(x: 18, y: 11, width: 224, height: 22)
        slider.isContinuous = true
        slider.target = self; slider.action = #selector(changed)
        slider.setAccessibilityLabel(L("Curtain transparency", "Прозрачность штор"))
        slider.toolTip = L("0% — opaque curtains, 90% — almost transparent", "0% — плотные шторы, 90% — почти прозрачные")
        addSubview(label); addSubview(slider)
        updateLabel(value)
    }
    required init?(coder: NSCoder) { fatalError() }
    private func updateLabel(_ value: Int) { label.stringValue = L("Transparency", "Прозрачность") + ": \(value)%" }
    @objc private func changed() {
        let value = slider.integerValue
        updateLabel(value)
        onChange(value)
    }
}
