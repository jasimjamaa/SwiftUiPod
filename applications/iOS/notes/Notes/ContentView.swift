
import SwiftUI

// MARK: - NOTES HOME SCREEN

struct ContentView: View {
    
    @StateObject private var store = NotesStore()
    
    /// Navigation path ensures only one screen is visible
    @State private var navigationPath: [UUID] = []
    
    /// Search query for filtering titles and note contents
    @State private var searchText = ""
    
    /// State for the rename alert
    @State private var noteToRename: Note?
    @State private var renameTitle = ""
    
    /// My Sin yellow used for the home navigation bar
    private let homeColor = Color(hex: "#FDB827")
    
    // MARK: FILTERED NOTES
    
    private var filteredNotes: [Note] {
        
        guard !searchText.isEmpty else {
            return store.notes
        }
        
        return store.notes.filter { note in
            
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: VIEW
    
    var body: some View {
        
        NavigationStack(path: $navigationPath) {
            
            List {
                
                ForEach(filteredNotes) { note in
                    
                    // Tapping a row opens its individual editor
                    NavigationLink(value: note.id) {
                        NoteRow(note: note)
                    }
                    
                    // Swipe left to delete
                    .swipeActions(edge: .trailing) {
                        
                        Button(role: .destructive) {
                            store.delete(note)
                        } label: {
                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                        }
                    }
                    
                    // Swipe right to rename
                    .swipeActions(edge: .leading) {
                        
                        Button {
                            noteToRename = note
                            renameTitle = note.title
                        } label: {
                            Label(
                                "Rename",
                                systemImage: "pencil"
                            )
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.plain)
            
            // MARK: NAVIGATION BAR
            
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbarBackground(
                homeColor,
                for: .navigationBar
            )
            
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
            
            .toolbar {
                
                // Centred Notes title
                ToolbarItem(placement: .principal) {
                    
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.black)
                }
                
                // Create a note on the right
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button {
                        createNote()
                    } label: {
                        
                        Image(
                            systemName: "square.and.pencil"
                        )
                        .font(
                            .system(size: 19, weight: .medium)
                        )
                        .foregroundStyle(.black)
                    }
                    .accessibilityLabel("New note")
                }
            }
            
            // MARK: SEARCH
            
            .searchable(
                text: $searchText,
                prompt: "Search notes"
            )
            
            // MARK: NOTE DESTINATION
            
            .navigationDestination(for: UUID.self) { id in
                
                if let index = store.notes.firstIndex(where: {
                    $0.id == id
                }) {
                    
                    NoteEditorView(
                        note: $store.notes[index],
                        onSave: { updatedNote in
                            store.save(updatedNote)
                        }
                    )
                    
                } else {
                    
                    ContentUnavailableView(
                        "Note Not Found",
                        systemImage: "note.text"
                    )
                }
            }
            
            // MARK: RENAME ALERT
            
            .alert(
                "Rename Note",
                isPresented: Binding(
                    get: {
                        noteToRename != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            noteToRename = nil
                        }
                    }
                )
            ) {
                
                TextField(
                    "Note name",
                    text: $renameTitle
                )
                
                Button(
                    "Cancel",
                    role: .cancel
                ) {
                    noteToRename = nil
                }
                
                Button("Save") {
                    
                    if let note = noteToRename {
                        store.rename(
                            note,
                            to: renameTitle
                        )
                    }
                    
                    noteToRename = nil
                }
                
            }
            .tint(homeColor)
        }
    }
    
    // MARK: CREATE NOTE
    
    /// Saves a new note and immediately navigates to it
    private func createNote() {
        
        let note = store.addNote()
        
        navigationPath.append(note.id)
    }
}
