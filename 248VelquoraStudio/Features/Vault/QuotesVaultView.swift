import SwiftUI

struct QuotesVaultView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore
    @State private var query = ""
    @State private var selectedTag: String?
    @State private var showEditor = false
    @State private var shareText = ""
    @State private var showShare = false

    private var allTags: [String] {
        Array(Set(store.quotes.flatMap(\.tags))).sorted()
    }

    private var filtered: [QuoteNote] {
        store.filteredQuotes(query: query, tag: selectedTag)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SurfaceCard(padding: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("AppTextSecondary"))
                        TextField("Search quotes, tags, books", text: $query)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .padding(.horizontal, 4)
                    .frame(minHeight: 36)
                }

                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", selected: selectedTag == nil) { selectedTag = nil }
                            ForEach(allTags, id: \.self) { tag in
                                FilterChip(title: tag, selected: selectedTag == tag) { selectedTag = tag }
                            }
                        }
                    }
                }

                if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "quote.bubble",
                        title: "No quotes yet",
                        message: "Save lines with a page number and tags. Export anytime."
                    )
                } else {
                    SectionHeaderLabel(title: "Vault", trailing: "\(filtered.count)")
                    ForEach(filtered) { quote in
                        QuoteCell(
                            quote: quote,
                            bookTitle: store.book(id: quote.bookId)?.title ?? "Book",
                            onDelete: {
                                SensoryFeedback.warning()
                                store.deleteQuote(id: quote.id)
                            }
                        )
                    }

                    Button {
                        SensoryFeedback.lightTap()
                        shareText = store.exportQuotesText(query: query, tag: selectedTag)
                        showShare = true
                    } label: {
                        Text("Export Quotes")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, bottomInset)
        }
        .clearScrollBackground()
        .onReceive(NotificationCenter.default.publisher(for: .openQuoteAdd)) { _ in
            showEditor = true
        }
        .sheet(isPresented: $showEditor) {
            QuoteEditorView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: [shareText])
        }
    }
}

struct QuoteEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBookId = ""
    @State private var text = ""
    @State private var page = ""
    @State private var tagsText = ""
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
                        TextField("Quote", text: $text, axis: .vertical)
                            .lineLimit(4...8)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Page", text: $page)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Tags (comma-separated)", text: $tagsText)
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
            .navigationTitle("New Quote")
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
                if let reading = store.books.first(where: { $0.status == .reading }) {
                    selectedBookId = reading.id.uuidString
                } else if let first = store.books.first {
                    selectedBookId = first.id.uuidString
                }
            }
        }
    }

    private func save() {
        guard let bookId = UUID(uuidString: selectedBookId) else {
            fail("Select a book.")
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fail("Enter quote text.")
            return
        }
        let pageNumber = Int(page) ?? 0
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        SensoryFeedback.mediumTap()
        SensoryFeedback.success()
        store.addQuote(bookId: bookId, text: trimmed, page: pageNumber, tags: tags)
        dismiss()
    }

    private func fail(_ message: String) {
        errorText = message
        SensoryFeedback.warning()
        withAnimation(.default) { shake += 1 }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
