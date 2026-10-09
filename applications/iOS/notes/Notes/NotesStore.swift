
import SwiftUI

// MARK: - NOTES STORE

/// Owns the notes collection while the app is running
@MainActor
final class NotesStore: ObservableObject {
    
    /// Notes currently loaded into the app
    @Published var notes: [Note] = []
    
    /// Handles persistent storage
    private let fileStore = NotesFileStore()
    
    // MARK: INITIALISATION
    
    init() {
        notes = fileStore.loadAll()
    }
    
    // MARK: CREATE
    
    /// Creates and saves a new note
    @discardableResult
    func addNote() -> Note {
        
        let note = Note(
            title: "Note \(notes.count + 1)"
        )
        
        notes.insert(note, at: 0)
        fileStore.save(note)
        
        return note
    }
    
    // MARK: SAVE
    
    /// Persists an existing note
    ///
    /// The editor already updates the bound note in the
    /// published collection so this method only writes it
    func save(_ note: Note) {
        
        guard notes.contains(where: {
            $0.id == note.id
        }) else {
            return
        }
        
        fileStore.save(note)
    }
    
    // MARK: DELETE
    
    /// Removes a note from memory and persistent storage
    func delete(_ note: Note) {
        
        notes.removeAll {
            $0.id == note.id
        }
        
        fileStore.delete(note)
    }
    
    // MARK: RENAME
    
    /// Changes a note's title and saves the new metadata
    func rename(_ note: Note, to newTitle: String) {
        
        guard let index = notes.firstIndex(where: {
            $0.id == note.id
        }) else {
            return
        }
        
        let cleanedTitle = newTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        notes[index].title = cleanedTitle.isEmpty
        ? "Untitled"
        : cleanedTitle
        
        fileStore.save(notes[index])
    }
}
