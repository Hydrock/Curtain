import Foundation
import CoreGraphics

/// Shared physical, visual and audio identity. Independent of AppKit and locale.
enum FabricMaterial: String, CaseIterable {
    case velvet, cotton, tulle
    var englishName: String {
        switch self { case .velvet: return "Heavy velvet"; case .cotton: return "Springy cotton"; case .tulle: return "Light tulle" }
    }
    var russianName: String {
        switch self { case .velvet: return "Тяжёлый бархат"; case .cotton: return "Упругий хлопок"; case .tulle: return "Лёгкий тюль" }
    }
    var soundPrefix: String {
        switch self { case .velvet: return "Velvet"; case .cotton: return "Cotton"; case .tulle: return "Tulle" }
    }
    var opacity: CGFloat { switch self { case .velvet: return 1; case .cotton: return 0.94; case .tulle: return 0.32 } }
    var foldCount: CGFloat { switch self { case .velvet: return 8; case .cotton: return 6; case .tulle: return 12 } }
    var foldDepth: CGFloat { switch self { case .velvet: return 1; case .cotton: return 0.55; case .tulle: return 0.35 } }
    var inverseMass: CGFloat { switch self { case .velvet: return 0.72; case .cotton: return 1; case .tulle: return 1.28 } }
    var damping: CGFloat { switch self { case .velvet: return 0.89; case .cotton: return 0.94; case .tulle: return 0.95 } }
    var restoring: CGFloat { switch self { case .velvet: return 0.018; case .cotton: return 0.028; case .tulle: return 0.014 } }
    var coupling: CGFloat { switch self { case .velvet: return 0.12; case .cotton: return 0.16; case .tulle: return 0.08 } }
    var gatheringSpeed: CGFloat { switch self { case .velvet: return 0.055; case .cotton: return 0.075; case .tulle: return 0.095 } }
    var gatheredWidth: CGFloat { switch self { case .velvet: return 0.085; case .cotton: return 0.075; case .tulle: return 0.055 } }
    var windResponse: CGFloat { switch self { case .velvet: return 1; case .cotton: return 1.5; case .tulle: return 1.65 } }
    var whiteness: CGFloat { switch self { case .velvet: return 0; case .cotton: return 0.18; case .tulle: return 0.78 } }
    var foldContrast: CGFloat { switch self { case .velvet: return 0.32; case .cotton: return 0.14; case .tulle: return 0.09 } }
}
