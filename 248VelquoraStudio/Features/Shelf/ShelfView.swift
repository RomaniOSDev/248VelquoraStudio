import SwiftUI

struct ShelfView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore
    @State private var showEditor = false
    @State private var filter: BookStatus? = nil

    private var filteredBooks: [Book] {
        let list = store.books.sorted { $0.updatedAt > $1.updatedAt }
        guard let filter else { return list }
        return list.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        overviewStrip
                        filterRow

                        if filteredBooks.isEmpty {
                            EmptyStateView(
                                symbol: "books.vertical",
                                title: "Your shelf is empty",
                                message: "Add a book to track progress, sessions, and plans."
                            )
                            Button {
                                SensoryFeedback.lightTap()
                                showEditor = true
                            } label: {
                                Text("Add Book")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 24)
                        } else {
                            SectionHeaderLabel(
                                title: "Your works",
                                subtitle: "Tap a book for sessions and smart plans",
                                trailing: "\(filteredBooks.count)"
                            )
                            ForEach(filteredBooks) { book in
                                NavigationLink {
                                    BookDetailView(bookId: book.id, bottomInset: bottomInset)
                                } label: {
                                    BookShelfCell(
                                        book: book,
                                        sessionCount: store.sessions(for: book.id).count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Shelf")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        SensoryFeedback.lightTap()
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                BookEditorView(book: nil)
                    .environmentObject(store)
            }
        }
        .transparentScreenChrome()
    }

    private var overviewStrip: some View {
        HStack(spacing: 10) {
            MetricTile(title: "Books", value: "\(store.books.count)", symbol: "books.vertical")
            MetricTile(title: "Reading", value: "\(store.books.filter { $0.status == .reading }.count)", symbol: "book.fill")
            MetricTile(title: "Sessions", value: "\(store.readingSessions.count)", symbol: "text.book.closed")
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: filter == nil) { filter = nil }
                ForEach(BookStatus.allCases) { status in
                    FilterChip(title: status.title, selected: filter == status) { filter = status }
                }
            }
        }
    }
}
