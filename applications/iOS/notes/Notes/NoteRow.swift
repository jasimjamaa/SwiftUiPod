
import SwiftUI

// MARK: - NOTE LIST ROW

struct NoteRow: View {
    
    let note: Note
    
    var body: some View {
        
        HStack(spacing: 12) {
            
            // Small accent-coloured indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(note.color)
                .frame(
                    width: 4,
                    height: 38
                )
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                // Note title
                Text(
                    note.title.isEmpty
                    ? "Untitled"
                    : note.title
                )
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                
                // A short preview of the note contents
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
    
    // MARK: PREVIEW TEXT
    
    private var preview: String {
        
        let cleaned = note.text
            .replacingOccurrences(
                of: "\n",
                with: " "
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        return cleaned.isEmpty
        ? "No additional text"
        : cleaned
    }
}
