import Foundation
import Combine

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, body: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var renderedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled whisper" : title }
}

final class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] { didSet { save() } }
    @Published var selectedID: Note.ID?
    private let storageURL: URL

    init() {
        storageURL = URL.documentsDirectory.appending(path: "barely-noted.json")
        load()
        if notes.isEmpty {
            notes = [Note(title: "Welcome to BarelyNoted", body: "# BarelyNoted\n\nA lavender little place for markdown thoughts.\n\n- Write softly\n- Preview instantly\n- Share when ready\n\n> Delete with finality.")]
        }
        selectedID = notes.first?.id
    }

    var selectedNote: Note? { notes.first { $0.id == selectedID } }

    func addNote() {
        let note = Note(title: "New note", body: "# New note\n\nStart with a spark.")
        notes.insert(note, at: 0)
        selectedID = note.id
    }

    func updateSelected(title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == selectedID }) else { return }
        notes[index].title = title
        notes[index].body = body
        notes[index].updatedAt = .now
    }

    func delete(ids: Set<Note.ID>) {
        notes.removeAll { ids.contains($0.id) }
        selectedID = notes.first?.id
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL), let decoded = try? JSONDecoder().decode([Note].self, from: data) else { return }
        notes = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
