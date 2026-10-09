
import SwiftUI
import UIKit

// MARK: - HEX COLOUR SUPPORT

extension Color {
    
    /// Creates a SwiftUI colour from a hexadecimal value
    ///
    /// Supported format: #RRGGBB
    init(hex: String) {
        
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet(charactersIn: "#")
        )
        
        let value = UInt64(cleaned, radix: 16) ?? 0xFDB827
        
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
    
    /// Converts a SwiftUI colour into #RRGGBB format
    ///
    /// Used to persist custom colours selected by the user
    func hexadecimal() -> String {
        
        let uiColor = UIColor(self)
        
        guard let components = uiColor.cgColor.components else {
            return "#FDB827"
        }
        
        let rgb: [CGFloat]
        
        if components.count >= 3 {
            rgb = Array(components.prefix(3))
        } else {
            rgb = [
                components[0],
                components[0],
                components[0]
            ]
        }
        
        let red = Int((rgb[0] * 255).rounded())
        let green = Int((rgb[1] * 255).rounded())
        let blue = Int((rgb[2] * 255).rounded())
        
        return String(
            format: "#%02X%02X%02X",
            red,
            green,
            blue
        )
    }
}
