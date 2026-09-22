#if OWNER_MODE
import SwiftUI

/// Owner-only free-text note card, shown below the coach card on every
/// session detail page. Lets the owner jot personal suggestions or
/// reminders tied to that specific session; persisted via
/// `OwnerNoteStore`, one note per session.
struct OwnerNoteCard: View {
    let sessionId: UUID

    @State private var isEditing = false
    @State private var draft: String
    @State private var savedNote: String

    init(sessionId: UUID) {
        self.sessionId = sessionId
        let existing = OwnerNoteStore.note(for: sessionId)
        _savedNote = State(initialValue: existing)
        _draft = State(initialValue: existing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            if isEditing {
                editor
            } else if !savedNote.isEmpty {
                Text(savedNote)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Button {
                    draft = ""
                    isEditing = true
                } label: {
                    Text("Tap to add a note for yourself")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.info)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.Colors.info))
            Text("My Notes")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.info)
            Spacer()
            if !isEditing {
                Button {
                    draft = savedNote
                    isEditing = true
                } label: {
                    Image(systemName: savedNote.isEmpty ? "plus.circle" : "pencil.circle")
                        .font(.title3)
                }
                .foregroundStyle(Theme.Colors.info)
                .accessibilityIdentifier("trainingPlan.session.ownerNote.edit")
            }
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            TextEditor(text: $draft)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.info.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Button("Cancel") {
                    isEditing = false
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Button("Save") {
                    savedNote = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    OwnerNoteStore.setNote(savedNote, for: sessionId)
                    isEditing = false
                }
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.info)
                .accessibilityIdentifier("trainingPlan.session.ownerNote.save")
            }
        }
    }
}
#endif
