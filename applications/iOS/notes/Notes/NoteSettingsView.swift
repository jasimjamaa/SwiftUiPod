
import SwiftUI

// MARK: - NOTE SETTINGS

struct NoteSettingsView: View {
    
    /// The note whose settings are being changed
    @Binding var note: Note
    
    /// Saves metadata and content to persistent storage
    let onSave: () -> Void
    
    /// Updates the note title in the parent editor
    let onRename: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var customColor: Color
    @State private var showingRenameAlert = false
    @State private var renameTitle = ""
    
    // MARK: INITIALISATION
    
    init(
        note: Binding<Note>,
        onSave: @escaping () -> Void,
        onRename: @escaping (String) -> Void
    ) {
        self._note = note
        self.onSave = onSave
        self.onRename = onRename
        
        // Start with the note's currently selected colour
        self._customColor = State(
            initialValue: note.wrappedValue.color
        )
    }
    
    // MARK: VIEW
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                // MARK: RENAME
                
                Section("Note") {
                    
                    Button {
                        
                        renameTitle = note.title
                        showingRenameAlert = true
                        
                    } label: {
                        
                        Label(
                            "Rename Note",
                            systemImage: "pencil"
                        )
                    }
                    .foregroundStyle(.primary)
                }
                
                // MARK: FONT SIZE
                
                Section {
                    
                    HStack {
                        
                        Text("Font size")
                        
                        Spacer()
                        
                        Text(
                            "\(Int(note.fontSize)) pt"
                        )
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                    
                    Slider(
                        value: $note.fontSize,
                        in: 10...32,
                        step: 1
                    )
                    .tint(note.color)
                    .accessibilityLabel("Font size")
                    
                } header: {
                    
                    Text("Typography")
                    
                } footer: {
                    
                    Text(
                        "Your note uses a monospaced font"
                    )
                }
                
                // MARK: ACCENT COLOUR
                
                Section("Accent colour") {
                    
                    // All six preset colours appear horizontally
                    HStack(spacing: 0) {
                        
                        ForEach(presetColors) { preset in
                            
                            Spacer(minLength: 0)
                            
                            Button {
                                
                                note.accentHex = preset.hex
                                customColor = preset.color
                                onSave()
                                
                            } label: {
                                
                                Circle()
                                    .fill(preset.color)
                                    .frame(
                                        width: 32,
                                        height: 32
                                    )
                                    .overlay {
                                        
                                        // Outline the active colour
                                        if note.accentHex.uppercased()
                                            == preset.hex {
                                            
                                            Circle()
                                                .strokeBorder(
                                                    Color.primary,
                                                    lineWidth: 2
                                                )
                                                .padding(-4)
                                        }
                                    }
                                    .overlay {
                                        
                                        // Checkmark for the selected preset
                                        if note.accentHex.uppercased()
                                            == preset.hex {
                                            
                                            Image(
                                                systemName: "checkmark"
                                            )
                                            .font(
                                                .system(
                                                    size: 11,
                                                    weight: .bold
                                                )
                                            )
                                            .foregroundStyle(.black)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(preset.name)
                            
                            Spacer(minLength: 0)
                        }
                        
                        // MARK: CUSTOM COLOUR PICKER
                        
                        // The rainbow wheel opens the native iOS
                        // colour picker for arbitrary accent colours
                        ColorPicker(
                            "Custom colour",
                            selection: $customColor,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .frame(width: 34)
                        .accessibilityLabel(
                            "Choose custom accent colour"
                        )
                        .onChange(
                            of: customColor
                        ) { _, newColor in
                            
                            // Convert the chosen colour to a
                            // persistent hexadecimal RGB value
                            note.accentHex = newColor.hexadecimal()
                            
                            onSave()
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Display the selected colour's name
                    Text(selectedColorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: SETTINGS NAVIGATION BAR
            
            .navigationTitle("Note Settings")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
            
            // MARK: SAVE CHANGES
            
            .onChange(of: note.fontSize) { _, _ in
                onSave()
            }
            
            .onChange(of: note.accentHex) { _, _ in
                onSave()
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
                    
                    onRename(cleanedTitle)
                }
                
            } message: {
                
                Text("Enter a new name for this note")
            }
        }
    }
    
    // MARK: SELECTED COLOUR NAME
    
    private var selectedColorName: String {
        
        presetColors.first {
            $0.hex == note.accentHex.uppercased()
        }?.name ?? "Custom colour"
    }
}
