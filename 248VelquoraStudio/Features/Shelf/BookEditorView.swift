import SwiftUI

struct BookEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let book: Book?

    @State private var title = ""
    @State private var author = ""
    @State private var status: BookStatus = .want
    @State private var totalPages = ""
    @State private var currentPage = ""
    @State private var totalChapters = ""
    @State private var currentChapter = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(14 * 86400)
    @State private var shakeTitle = 0
    @State private var titleError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        TextField("Title", text: $title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: CGFloat(shakeTitle)))
                        if titleError {
                            Text("Please enter a title.")
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                        TextField("Author", text: $author)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Picker("Status", selection: $status) {
                            ForEach(BookStatus.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .tint(Color("AppPrimary"))
                    }
                    .listRowBackground(Color("AppSurface"))

                    Section("Progress") {
                        TextField("Total pages", text: $totalPages)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Current page", text: $currentPage)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Total chapters", text: $totalChapters)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Current chapter", text: $currentChapter)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .listRowBackground(Color("AppSurface"))

                    Section("Deadline") {
                        Toggle("Set finish date", isOn: $hasDeadline)
                            .tint(Color("AppPrimary"))
                            .foregroundStyle(Color("AppTextPrimary"))
                        if hasDeadline {
                            DatePicker("Target date", selection: $deadline, displayedComponents: .date)
                                .tint(Color("AppPrimary"))
                        }
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(book == nil ? "New Book" : "Edit Book")
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
            .onAppear { load() }
        }
    }

    private func load() {
        guard let book else { return }
        title = book.title
        author = book.author
        status = book.status
        totalPages = book.totalPages > 0 ? "\(book.totalPages)" : ""
        currentPage = book.currentPage > 0 ? "\(book.currentPage)" : ""
        totalChapters = book.totalChapters > 0 ? "\(book.totalChapters)" : ""
        currentChapter = book.currentChapter > 0 ? "\(book.currentChapter)" : ""
        if let date = book.targetFinishDate {
            hasDeadline = true
            deadline = date
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleError = true
            SensoryFeedback.warning()
            withAnimation(.default) { shakeTitle += 1 }
            return
        }
        SensoryFeedback.mediumTap()
        SensoryFeedback.success()
        let model = Book(
            id: book?.id ?? UUID(),
            title: trimmed,
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            totalPages: Int(totalPages) ?? 0,
            currentPage: Int(currentPage) ?? 0,
            totalChapters: Int(totalChapters) ?? 0,
            currentChapter: Int(currentChapter) ?? 0,
            targetFinishDate: hasDeadline ? deadline : nil,
            createdAt: book?.createdAt ?? Date()
        )
        if book == nil {
            store.addBook(model)
        } else {
            store.updateBook(model)
        }
        dismiss()
    }
}
