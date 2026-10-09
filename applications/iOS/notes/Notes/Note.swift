
import SwiftUI

// MARK: - NOTE MODEL

/// Represents one saved note
struct Note: Identifiable, Hashable {
    
    /// A unique identifier used for navigation and storage
    var id: UUID
    
    /// The title displayed in the navigation bar and notes list
    var title: String
    
    /// The editable contents of the note
    var text: String
    
    /// The font size in points
    var fontSize: Double
    
    /// The accent colour stored as a hexadecimal string
    var accentHex: String
    
    init(
        id: UUID = UUID(),
        title: String = "Note",
        text: String = "",
        fontSize: Double = 16,
        accentHex: String = "#61BB46"
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.fontSize = fontSize
        self.accentHex = accentHex
    }
    
    /// Converts the stored hexadecimal colour into SwiftUI Color
    var color: Color {
        Color(hex: accentHex)
    }
}

// MARK: - PRESET ACCENT COLOURS

/// The six preset colours available in the settings screen
struct PresetColor: Identifiable {
    
    let name: String
    let hex: String
    
    var id: String { hex }
    
    var color: Color {
        Color(hex: hex)
    }
}

/// Preset colours inspired by the original design
let presetColors: [PresetColor] = [
    PresetColor(
        name: "Heavenly Green",
        hex: "#61BB46"
    ),
    PresetColor(
        name: "My Sin",
        hex: "#FDB827"
    ),
    PresetColor(
        name: "Orange Passion",
        hex: "#F5821F"
    ),
    PresetColor(
        name: "Basic Red",
        hex: "#E03A3E"
    ),
    PresetColor(
        name: "Dark Fuchsia",
        hex: "#963D97"
    ),
    PresetColor(
        name: "German Blue",
        hex: "#009DDC"
    )
]
