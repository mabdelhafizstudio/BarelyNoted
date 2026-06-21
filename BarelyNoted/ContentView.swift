import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: NotesStore
    @State private var selectedForDeletion = Set<Note.ID>()
    @State private var isSelecting = false
    @State private var burningIDs = Set<Note.ID>()

    var body: some View {
        NavigationSplitView {
            SidebarView(isSelecting: $isSelecting, selectedForDeletion: $selectedForDeletion, burningIDs: $burningIDs)
                .navigationSplitViewColumnWidth(min: 260, ideal: 310)
        } detail: {
            NoteEditorView()
        }
        .background(LavenderBackground())
        .tint(.lavenderInk)
    }
}

struct SidebarView: View {
    @EnvironmentObject private var store: NotesStore
    @Binding var isSelecting: Bool
    @Binding var selectedForDeletion: Set<Note.ID>
    @Binding var burningIDs: Set<Note.ID>

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BarelyNoted").font(.gentiumBold(30))
                    Text("fun little markdowns").font(.gentium(14)).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: store.addNote) { Image(systemName: "plus") }
                    .buttonStyle(.glassCircle)
            }
            .padding(.horizontal)

            HStack {
                Button(isSelecting ? "Done" : "Select") { isSelecting.toggle(); selectedForDeletion.removeAll() }
                Spacer()
                Button("All") { selectedForDeletion = Set(store.notes.map(\.id)); isSelecting = true }
                Button(role: .destructive) { burnAndDelete(selectedForDeletion.isEmpty && !isSelecting ? Set(store.notes.map(\.id)) : selectedForDeletion) } label: { Text(selectedForDeletion.isEmpty && isSelecting ? "Delete" : "Delete") }
                    .disabled(isSelecting && selectedForDeletion.isEmpty)
            }
            .font(.gentiumBold(15))
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.notes) { note in
                        NoteRow(note: note, isSelecting: isSelecting, isChosen: selectedForDeletion.contains(note.id), isBurning: burningIDs.contains(note.id))
                            .onTapGesture {
                                if isSelecting { toggle(note.id) } else { store.selectedID = note.id }
                            }
                    }
                }.padding(.horizontal)
            }
        }
        .padding(.vertical, 22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding()
    }

    private func toggle(_ id: Note.ID) {
        if selectedForDeletion.contains(id) { selectedForDeletion.remove(id) } else { selectedForDeletion.insert(id) }
    }

    private func burnAndDelete(_ ids: Set<Note.ID>) {
        guard !ids.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.8)) { burningIDs.formUnion(ids) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
            store.delete(ids: ids)
            selectedForDeletion.removeAll()
            burningIDs.subtract(ids)
            isSelecting = false
        }
    }
}

struct NoteRow: View {
    let note: Note
    let isSelecting: Bool
    let isChosen: Bool
    let isBurning: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting { Image(systemName: isChosen ? "checkmark.circle.fill" : "circle") }
            VStack(alignment: .leading, spacing: 5) {
                Text(note.renderedTitle).font(.gentiumBold(18)).lineLimit(1)
                Text(note.body.replacingOccurrences(of: "#", with: "")).font(.gentium(14)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(isChosen ? Color.lavenderInk.opacity(0.8) : .white.opacity(0.18)))
        .modifier(BurnEffect(active: isBurning))
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: NotesStore
    @State private var title = ""
    @State private var bodyText = ""
    @State private var preview = true

    var body: some View {
        ZStack { LavenderBackground()
            if let note = store.selectedNote {
                VStack(spacing: 18) {
                    HStack {
                        TextField("A barely-there title", text: $title).font(.gentiumBold(34)).textFieldStyle(.plain)
                        ShareLink(item: shareText) { Label("Share", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent)
                        Button(preview ? "Edit" : "Preview") { preview.toggle() }.buttonStyle(.bordered)
                    }
                    .onChange(of: title) { _, _ in persist() }

                    Group {
                        if preview {
                            ScrollView { Text(markdown: bodyText).frame(maxWidth: .infinity, alignment: .leading).padding(28) }
                        } else {
                            TextEditor(text: $bodyText).scrollContentBackground(.hidden).padding(18).onChange(of: bodyText) { _, _ in persist() }
                        }
                    }
                    .font(.gentium(21))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                }
                .padding(28)
                .onAppear { load(note) }
                .onChange(of: note.id) { _, _ in if let selected = store.selectedNote { load(selected) } }
            } else {
                ContentUnavailableView("No notes yet", systemImage: "sparkles", description: Text("Make the first barely noted thought."))
            }
        }
    }

    private var shareText: String { "# \(title)\n\n\(bodyText)" }
    private func load(_ note: Note) { title = note.title; bodyText = note.body }
    private func persist() { store.updateSelected(title: title, body: bodyText) }
}

struct BurnEffect: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .opacity(active ? 0 : 1)
            .scaleEffect(active ? 0.88 : 1)
            .blur(radius: active ? 8 : 0)
            .overlay(alignment: .topTrailing) {
                if active { Image(systemName: "flame.fill").font(.system(size: 46)).foregroundStyle(.orange, .red).transition(.scale.combined(with: .opacity)) }
            }
    }
}

struct LavenderBackground: View {
    var body: some View {
        LinearGradient(colors: [.lavenderMist, .white, .lavenderBlush], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
}

extension Text {
    init(markdown: String) { self.init((try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)) }
}

extension Font {
    static func gentium(_ size: CGFloat) -> Font { .custom("Gentium Plus", size: size) }
    static func gentiumBold(_ size: CGFloat) -> Font { .custom("Gentium Plus Bold", size: size) }
}

extension Color {
    static let lavenderMist = Color(red: 0.91, green: 0.87, blue: 1.0)
    static let lavenderBlush = Color(red: 0.98, green: 0.91, blue: 0.98)
    static let lavenderInk = Color(red: 0.43, green: 0.31, blue: 0.67)
}

struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.padding(12).background(.ultraThinMaterial, in: Circle()).scaleEffect(configuration.isPressed ? 0.92 : 1)
    }
}

extension ButtonStyle where Self == GlassCircleButtonStyle { static var glassCircle: GlassCircleButtonStyle { GlassCircleButtonStyle() } }
