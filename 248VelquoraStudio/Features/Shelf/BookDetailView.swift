import SwiftUI

struct BookDetailView: View {
    let bookId: UUID
    let bottomInset: CGFloat

    @EnvironmentObject private var store: AppDataStore
    @State private var showEdit = false
    @State private var showSession = false
    @State private var showPlan = false
    @State private var pendingPlan: [SmartPlanDay] = []
    @State private var showDeleteAlert = false

    private var book: Book? { store.book(id: bookId) }

    var body: some View {
        ZStack {
            AppBackgroundView()

            if let book {
                ScrollView {
                    VStack(spacing: 18) {
                        BookShelfCell(book: book, sessionCount: store.sessions(for: bookId).count)
                        progressCard(book)
                        paceCard(book)
                        actions
                        sessionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, max(24, bottomInset - 40))
                }
                .clearScrollBackground()
            } else {
                EmptyStateView(
                    symbol: "book.closed",
                    title: "Book not found",
                    message: "This book may have been removed."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(book?.title ?? "Book")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenChrome()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") {
                        SensoryFeedback.lightTap()
                        showEdit = true
                    }
                    Button("Delete", role: .destructive) {
                        SensoryFeedback.lightTap()
                        showDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let book {
                BookEditorView(book: book).environmentObject(store)
            }
        }
        .sheet(isPresented: $showSession) {
            SessionEditorView(presetBookId: bookId)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPlan) {
            if let book {
                SmartPlanSheet(book: book, plan: pendingPlan) {
                    store.acceptSmartPlan(pendingPlan, for: book)
                    SensoryFeedback.success()
                    showPlan = false
                }
                .environmentObject(store)
            }
        }
        .alert("Delete this book?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteBook(id: bookId)
            }
        } message: {
            Text("Sessions and quotes linked to this book will also be removed.")
        }
    }

    private func progressCard(_ book: Book) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderLabel(title: "Progress", subtitle: "Pages and chapters")
                if book.totalPages > 0 {
                    ProgressBar(value: book.pageProgress, height: 10)
                    Text("Page \(book.currentPage) / \(book.totalPages)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                if book.totalChapters > 0 {
                    ProgressBar(value: book.chapterProgress, height: 10)
                    Text("Chapter \(book.currentChapter) / \(book.totalChapters)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                if book.totalPages == 0 && book.totalChapters == 0 {
                    Text("Add page or chapter totals to track progress.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private func paceCard(_ book: Book) -> some View {
        SurfaceCard(accentBorder: book.pagesPerDayNeeded() != nil) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeaderLabel(title: "Pace to deadline")
                if let perDay = book.pagesPerDayNeeded() {
                    Text(perDay == 0 ? "You have finished the remaining pages." : "\(perDay) pages per day needed")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppPrimary"))
                    if let date = book.targetFinishDate {
                        Text("Target: \(date, style: .date)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                } else {
                    Text("Set a finish date and total pages to calculate daily pace.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                SensoryFeedback.lightTap()
                showSession = true
            } label: {
                Text("Log Reading Session")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                SensoryFeedback.lightTap()
                if let book {
                    pendingPlan = store.buildSmartPlan(for: book)
                    showPlan = true
                }
            } label: {
                Text("Build Smart Week Plan")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLabel(
                title: "Session history",
                trailing: "\(store.sessions(for: bookId).count)"
            )
            let sessions = store.sessions(for: bookId)
            if sessions.isEmpty {
                SurfaceCard {
                    Text("No sessions logged yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            } else {
                ForEach(sessions) { session in
                    SessionCell(
                        session: session,
                        bookTitle: book?.title ?? "Book",
                        onDelete: {
                            SensoryFeedback.warning()
                            store.deleteSession(id: session.id)
                        }
                    )
                }
            }
        }
    }
}

struct SmartPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let plan: [SmartPlanDay]
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        if plan.isEmpty {
                            EmptyStateView(
                                symbol: "calendar.badge.exclamationmark",
                                title: "No plan available",
                                message: "Add total pages and remaining progress to generate a week plan."
                            )
                        } else {
                            SoftReminderCell(
                                title: "Local smart schedule",
                                message: "Suggested reading for the next \(plan.count) days based on remaining pages and your deadline."
                            )

                            ForEach(plan) { day in
                                SurfaceCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.date, style: .date)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color("AppTextPrimary"))
                                            Text(day.note)
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color("AppTextSecondary"))
                                        }
                                        Spacer()
                                        MetaPill(text: "\(day.suggestedPages)p", emphasized: true)
                                    }
                                }
                            }

                            Button {
                                SensoryFeedback.mediumTap()
                                onAccept()
                            } label: {
                                Text("Accept Plan into Planner")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Smart Plan")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        SensoryFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}
