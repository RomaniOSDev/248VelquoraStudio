import SwiftUI

struct HomeView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore
    @State private var showBookEditor = false
    @State private var showSessionEditor = false
    @State private var filter: BookStatus? = .reading
    @State private var heroAppeared = false

    private var readingBooks: [Book] {
        store.books.filter { $0.status == .reading }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var featuredBook: Book? {
        readingBooks.first ?? store.books.sorted { $0.updatedAt > $1.updatedAt }.first
    }

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
                    VStack(spacing: 20) {
                        heroSection
                        quickActions
                        if store.sessionsBehindPace || store.pagesBehindPace {
                            SoftReminderCell(
                                title: "Keep your pace",
                                message: paceMessage
                            )
                        }
                        metricsStrip
                        if let featuredBook {
                            continueReading(featuredBook)
                        }
                        shelfSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        SensoryFeedback.lightTap()
                        showBookEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $showBookEditor) {
                BookEditorView(book: nil).environmentObject(store)
            }
            .sheet(isPresented: $showSessionEditor) {
                SessionEditorView(presetBookId: featuredBook?.id)
                    .environmentObject(store)
            }
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    heroAppeared = true
                }
            }
        }
        .transparentScreenChrome()
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image("home_hero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
                .drawingGroup() // rasterize static hero once — smoother scroll
                .overlay {
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.1),
                            Color("AppBackground").opacity(0.45),
                            Color("AppBackground").opacity(0.92)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(heroEyebrow)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(heroTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(heroSubtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Button {
                        SensoryFeedback.lightTap()
                        if featuredBook != nil {
                            showSessionEditor = true
                        } else {
                            showBookEditor = true
                        }
                    } label: {
                        Text(featuredBook == nil ? "Add First Book" : "Log Session")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppBackground"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(AppDepth.primaryFill))
                    }
                    .buttonStyle(.plain)

                    if featuredBook != nil {
                        Button {
                            SensoryFeedback.lightTap()
                            NotificationCenter.default.post(name: .switchAppTab, object: AppTab.journal.rawValue)
                        } label: {
                            Text("Open Journal")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color("AppPrimary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(minHeight: 44)
                                .background(
                                    Capsule()
                                        .fill(AppDepth.primarySoftFill)
                                        .overlay(
                                            Capsule().stroke(AppDepth.accentEdge, lineWidth: 1.4)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .volumeStroke(accent: true, corner: 24)
        .cardElevation(true)
        .scaleEffect(heroAppeared ? 1 : 0.96)
        .opacity(heroAppeared ? 1 : 0)
    }

    private var heroEyebrow: String {
        if featuredBook != nil { return "CONTINUE READING" }
        if store.books.isEmpty { return "START YOUR SHELF" }
        return "YOUR LIBRARY"
    }

    private var heroTitle: String {
        if let book = featuredBook {
            return book.title
        }
        return "Build your reading shelf"
    }

    private var heroSubtitle: String {
        if let book = featuredBook, book.totalPages > 0 {
            return "Page \(book.currentPage) of \(book.totalPages) · \(Int(book.pageProgress * 100))% complete"
        }
        if featuredBook != nil {
            return "Log a session to update progress"
        }
        return "Track books, sessions, quotes, and weekly goals in one place."
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLabel(title: "Quick actions", subtitle: "Jump into what matters")
            HStack(spacing: 12) {
                HomeActionCard(
                    imageName: "home_shelf",
                    title: "Add Book",
                    subtitle: "Shelf"
                ) {
                    SensoryFeedback.lightTap()
                    showBookEditor = true
                }
                HomeActionCard(
                    imageName: "home_journal",
                    title: "Session",
                    subtitle: "Journal"
                ) {
                    SensoryFeedback.lightTap()
                    if store.books.isEmpty {
                        showBookEditor = true
                    } else {
                        showSessionEditor = true
                    }
                }
                HomeActionCard(
                    imageName: "home_quotes",
                    title: "Quotes",
                    subtitle: "Vault"
                ) {
                    SensoryFeedback.lightTap()
                    NotificationCenter.default.post(name: .switchAppTab, object: AppTab.vault.rawValue)
                }
            }
        }
    }

    // MARK: - Metrics / continue / shelf

    private var metricsStrip: some View {
        HStack(spacing: 10) {
            MetricTile(title: "Books", value: "\(store.books.count)", symbol: "books.vertical")
            MetricTile(title: "Sessions", value: "\(store.readingSessions.count)", symbol: "text.book.closed")
            MetricTile(title: "Pages/mo", value: "\(store.pagesReadThisMonth)", symbol: "doc.plaintext")
        }
    }

    private func continueReading(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLabel(title: "Continue reading", trailing: book.status.title)
            NavigationLink {
                BookDetailView(bookId: book.id, bottomInset: bottomInset)
            } label: {
                BookShelfCell(book: book, sessionCount: store.sessions(for: book.id).count)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    SensoryFeedback.lightTap()
                    showSessionEditor = true
                } label: {
                    Text("Log Session")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    SensoryFeedback.lightTap()
                    let plan = store.buildSmartPlan(for: book)
                    store.acceptSmartPlan(plan, for: book)
                    SensoryFeedback.success()
                    NotificationCenter.default.post(name: .switchAppTab, object: AppTab.journal.rawValue)
                } label: {
                    Text("Smart Plan")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var shelfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLabel(
                title: "Your shelf",
                subtitle: "Filter and open any work",
                trailing: "\(filteredBooks.count)"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", selected: filter == nil) { filter = nil }
                    ForEach(BookStatus.allCases) { status in
                        FilterChip(title: status.title, selected: filter == status) { filter = status }
                    }
                }
            }

            if filteredBooks.isEmpty {
                EmptyStateView(
                    symbol: "books.vertical",
                    title: filter == nil ? "Your shelf is empty" : "Nothing here yet",
                    message: filter == nil
                        ? "Add a book to track progress, sessions, and plans."
                        : "Try another filter or add a book with this status."
                )
                Button {
                    SensoryFeedback.lightTap()
                    showBookEditor = true
                } label: {
                    Text("Add Book")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
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
    }

    private var paceMessage: String {
        var parts: [String] = []
        if store.sessionsBehindPace {
            parts.append("\(store.sessionsThisWeek)/\(store.readingGoals.sessionsPerWeek) sessions this week.")
        }
        if store.pagesBehindPace {
            parts.append("\(store.pagesReadThisMonth)/\(store.readingGoals.pagesPerMonth) pages this month.")
        }
        return parts.joined(separator: " ")
    }
}

struct HomeActionCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 78)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .drawingGroup()
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppPrimary").opacity(0.18), lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppDepth.cardFill)
                    .volumeStroke(corner: 18)
                    .cardElevation()
            )
        }
        .buttonStyle(ScalePressStyle())
    }
}

private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension Notification.Name {
    static let switchAppTab = Notification.Name("switchAppTab")
}
