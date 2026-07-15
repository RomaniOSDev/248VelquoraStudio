import SwiftUI

struct SessionEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    var presetBookId: UUID?
    var onSaved: (() -> Void)?

    @State private var selectedBookId = ""
    @State private var pageFrom = ""
    @State private var pageTo = ""
    @State private var duration = "25"
    @State private var note = ""
    @State private var shake = 0
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        if store.books.isEmpty {
                            Text("Add a book on the Shelf tab first.")
                                .foregroundStyle(Color("AppTextSecondary"))
                        } else {
                            Picker("Book", selection: $selectedBookId) {
                                Text("Select a book").tag("")
                                ForEach(store.books) { book in
                                    Text(book.title).tag(book.id.uuidString)
                                }
                            }
                            .tint(Color("AppPrimary"))
                        }
                        TextField("Page from", text: $pageFrom)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Page to", text: $pageTo)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Duration (minutes)", text: $duration)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Chapter note", text: $note, axis: .vertical)
                            .lineLimit(3...5)
                            .foregroundStyle(Color("AppTextPrimary"))
                        if let errorText {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.9))
                                .modifier(ShakeEffect(animatableData: CGFloat(shake)))
                        }
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        SensoryFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppPrimary"))
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let presetBookId {
                    selectedBookId = presetBookId.uuidString
                } else if let reading = store.books.first(where: { $0.status == .reading }) {
                    selectedBookId = reading.id.uuidString
                } else if let first = store.books.first {
                    selectedBookId = first.id.uuidString
                }
                if let book = store.book(id: UUID(uuidString: selectedBookId)), pageFrom.isEmpty {
                    pageFrom = "\(book.currentPage)"
                    let next = book.currentPage + 10
                    pageTo = "\(book.totalPages == 0 ? next : min(book.totalPages, next))"
                }
            }
        }
    }

    private func save() {
        guard let bookId = UUID(uuidString: selectedBookId) else {
            fail("Select a book.")
            return
        }
        guard let from = Int(pageFrom), let to = Int(pageTo), to >= from else {
            fail("Enter a valid page range.")
            return
        }
        let minutes = Int(duration) ?? 0
        guard minutes > 0 else {
            fail("Enter session duration in minutes.")
            return
        }
        SensoryFeedback.mediumTap()
        SensoryFeedback.success()
        store.addSession(
            bookId: bookId,
            pageFrom: from,
            pageTo: to,
            durationMinutes: minutes,
            chapterNote: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSaved?()
        dismiss()
    }

    private func fail(_ message: String) {
        errorText = message
        SensoryFeedback.warning()
        withAnimation(.default) { shake += 1 }
    }
}
