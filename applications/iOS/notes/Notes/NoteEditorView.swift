
import SwiftUI

// MARK: - NOTE EDITOR

struct NoteEditorView: View {
    
    /// The note being edited
    @Binding var note: Note
    
    /// Called whenever the note needs to be persisted
    let onSave: (Note) -> Void
    
    @State private var showingSettings = false
    @State private var showingRenameAlert = false
    @State private var renameTitle = ""
    
    var body: some View {
        
        // MARK: EDITOR
        
        TextEditor(text: $note.text)
        
        // All note content is monospaced
            .font(
                .system(
                    size: note.fontSize,
                    design: .monospaced
                )
            )
        
        // The note's accent colour controls its text
            .foregroundStyle(note.color)
        
        // Use the system background in light and dark mode
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .background(
                Color(uiColor: .systemBackground)
            )
        
        // MARK: NAVIGATION BAR
        
            .navigationTitle(
                note.title.isEmpty
                ? "Untitled"
                : note.title
            )
            .navigationBarTitleDisplayMode(.inline)
        
            .toolbarBackground(
                note.color,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
        
            .toolbar {
                
                // Centred tappable note title
                ToolbarItem(placement: .principal) {
                    
                    Button {
                        renameTitle = note.title
                        showingRenameAlert = true
                    } label: {
                        
                        Text(
                            note.title.isEmpty
                            ? "Untitled"
                            : note.title
                        )
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.black)
                    }
                    .accessibilityLabel("Rename note")
                }
                
                // Open note settings
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Button {
                        showingSettings = true
                    } label: {
                        
                        Image(
                            systemName: "pencil.and.scribble"
                        )
                        .font(
                            .system(size: 19, weight: .medium)
                        )
                        .foregroundStyle(.black)
                    }
                    .accessibilityLabel("Note settings")
                }
            }
        
        // MARK: SETTINGS SHEET
        
            .sheet(isPresented: $showingSettings) {
                
                NoteSettingsView(
                    note: $note,
                    onSave: {
                        onSave(note)
                    },
                    onRename: { newTitle in
                        
                        // Update the actual bound note
                        note.title = newTitle.isEmpty
                        ? "Untitled"
                        : newTitle
                        
                        onSave(note)
                    }
                )
                .presentationDetents([
                    .medium,
                    .large
                ])
                .presentationDragIndicator(.visible)
            }
        
        // MARK: RENAME ALERT
        
            .alert(
                "Rename Note",
                isPresented: $showingRenameAlert
            ) {
                
                TextField(
                    "Note name",
                    text: $renameTitle
                )
                
                Button(
                    "Cancel",
                    role: .cancel
                ) {}
                
                Button("Save") {
                    
                    let cleanedTitle = renameTitle
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    
                    note.title = cleanedTitle.isEmpty
                    ? "Untitled"
                    : cleanedTitle
                    
                    onSave(note)
                }
                
            } message: {
                Text("Enter a new name for this note")
            }
        
        // MARK: AUTOMATIC PERSISTENCE
        
        // Save text and settings whenever the note changes
            .onChange(of: note) { _, updatedNote in
                onSave(updatedNote)
            }
        
            .tint(note.color)
    }
}
