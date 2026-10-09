
import Foundation

// MARK: - NOTE FILE STORAGE

/// Handles all reading and writing of note files
final class NotesFileStore {
    
    private let fileManager = FileManager.default
    
    /// The directory where every note is stored
    private var directory: URL {
        
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        
        return applicationSupport
            .appendingPathComponent(
                "NeoNotes",
                isDirectory: true
            )
            .appendingPathComponent(
                "Notes",
                isDirectory: true
            )
    }
    
    // MARK: DIRECTORY MANAGEMENT
    
    /// Creates the storage directory if it does not exist
    private func prepareDirectory() {
        
        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }
    
    /// Generates a stable filename using the note's UUID
    private func url(for id: UUID) -> URL {
        
        directory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("txt")
    }
    
    // MARK: SAVE NOTE
    
    /// Saves the title, contents, font size and accent colour
    func save(_ note: Note) {
        
        prepareDirectory()
        
        // Base64 encoding prevents unusual titles from
        // interfering with the metadata format
        let encodedTitle = Data(
            note.title.utf8
        ).base64EncodedString()
        
        let contents = """
        NEONOTES
        VERSION: 2
        ID: \(note.id.uuidString)
        TITLE64: \(encodedTitle)
        FONT_SIZE: \(note.fontSize)
        ACCENT: \(note.accentHex)
        ---TEXT---
        \(note.text)
        """
        
        do {
            try contents.write(
                to: url(for: note.id),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            print(
                "NeoNotes: failed to save note: \(error)"
            )
        }
    }
    
    // MARK: DELETE NOTE
    
    /// Deletes the text file belonging to a note
    func delete(_ note: Note) {
        
        try? fileManager.removeItem(
            at: url(for: note.id)
        )
    }
    
    // MARK: LOAD ALL NOTES
    
    /// Reads every valid text file and sorts newest first
    func loadAll() -> [Note] {
        
        prepareDirectory()
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [
                .contentModificationDateKey
            ]
        ) else {
            return []
        }
        
        return files
            .filter {
                $0.pathExtension.lowercased() == "txt"
            }
            .compactMap {
                load(from: $0)
            }
            .sorted { first, second in
                
                modificationDate(for: first.id) >
                modificationDate(for: second.id)
            }
    }
    
    /// Retrieves a file's last modification date
    private func modificationDate(for id: UUID) -> Date {
        
        let values = try? url(for: id).resourceValues(
            forKeys: [.contentModificationDateKey]
        )
        
        return values?.contentModificationDate ?? .distantPast
    }
    
    // MARK: LOAD ONE NOTE
    
    /// Parses a saved note from its text representation
    private func load(from file: URL) -> Note? {
        
        guard let contents = try? String(
            contentsOf: file,
            encoding: .utf8
        ) else {
            return nil
        }
        
        let lines = contents.components(separatedBy: "\n")
        
        var id = UUID(
            uuidString: file.deletingPathExtension().lastPathComponent
        ) ?? UUID()
        
        var title = "Note"
        var fontSize = 16.0
        var accentHex = "#61BB46"
        
        // Metadata from the previous version
        var red = 0.380
        var green = 0.733
        var blue = 0.275
        
        var textStart: Int?
        
        // Read metadata until the text separator
        for index in lines.indices {
            
            let line = lines[index]
            
            if line == "---TEXT---" {
                textStart = index + 1
                break
            }
            
            if line.hasPrefix("ID: ") {
                
                if let parsed = UUID(
                    uuidString: String(line.dropFirst(4))
                ) {
                    id = parsed
                }
                
            } else if line.hasPrefix("TITLE64: ") {
                
                let encoded = String(line.dropFirst(9))
                
                if let data = Data(base64Encoded: encoded),
                   let decoded = String(
                    data: data,
                    encoding: .utf8
                   ) {
                    title = decoded
                }
                
            } else if line.hasPrefix("TITLE: ") {
                
                // Backwards compatibility with older notes
                title = String(line.dropFirst(7))
                
            } else if line.hasPrefix("FONT_SIZE: ") {
                
                fontSize = Double(
                    line.dropFirst(11)
                ) ?? 16
                
            } else if line.hasPrefix("ACCENT: ") {
                
                accentHex = String(line.dropFirst(8))
                
            } else if line.hasPrefix("RED: ") {
                
                red = Double(line.dropFirst(5)) ?? red
                
            } else if line.hasPrefix("GREEN: ") {
                
                green = Double(line.dropFirst(7)) ?? green
                
            } else if line.hasPrefix("BLUE: ") {
                
                blue = Double(line.dropFirst(6)) ?? blue
            }
        }
        
        // Convert the legacy RGB colour if no hexadecimal
        // accent colour was saved
        if !lines.contains(where: {
            $0.hasPrefix("ACCENT: ")
        }) {
            
            accentHex = String(
                format: "#%02X%02X%02X",
                Int((red * 255).rounded()),
                Int((green * 255).rounded()),
                Int((blue * 255).rounded())
            )
        }
        
        // Reconstruct the note body without discarding
        // additional lines or newlines inside the content
        let noteText: String
        
        if let start = textStart,
           start < lines.count {
            noteText = lines[start...].joined(separator: "\n")
        } else {
            noteText = ""
        }
        
        return Note(
            id: id,
            title: title,
            text: noteText,
            fontSize: min(max(fontSize, 10), 32),
            accentHex: accentHex
        )
    }
}
