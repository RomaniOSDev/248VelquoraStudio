import SwiftUI

struct SessionsLogView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore
    @State private var showEditor = false
    @State private var showSuccess = false

    private var sessions: [ReadingSession] {
        store.readingSessions.sorted { $0.loggedAt > $1.loggedAt }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        MetricTile(title: "This week", value: "\(store.sessionsThisWeek)", symbol: "calendar")
                        MetricTile(title: "Pages/mo", value: "\(store.pagesReadThisMonth)", symbol: "doc.plaintext")
                        MetricTile(title: "Minutes", value: "\(store.readingSessions.reduce(0) { $0 + $1.durationMinutes })", symbol: "clock")
                    }

                    if store.sessionsBehindPace || store.pagesBehindPace {
                        SoftReminderCell(
                            title: "Gentle pace check",
                            message: reminderMessage
                        )
                    }

                    if sessions.isEmpty {
                        EmptyStateView(
                            symbol: "text.book.closed",
                            title: "No sessions yet",
                            message: "Log pages read, time spent, and a short chapter note."
                        )
                        Button {
                            SensoryFeedback.lightTap()
                            showEditor = true
                        } label: {
                            Text("Log Session")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                    } else {
                        SectionHeaderLabel(title: "History", trailing: "\(sessions.count)")
                        ForEach(sessions) { session in
                            SessionCell(
                                session: session,
                                bookTitle: store.book(id: session.bookId)?.title ?? "Book",
                                onDelete: {
                                    SensoryFeedback.warning()
                                    store.deleteSession(id: session.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()

            SuccessCheckmarkOverlay(isVisible: $showSuccess)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onReceive(NotificationCenter.default.publisher(for: .openSessionAdd)) { _ in
            showEditor = true
        }
        .sheet(isPresented: $showEditor) {
            SessionEditorView(presetBookId: nil) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccess = true
                }
            }
            .environmentObject(store)
        }
    }

    private var reminderMessage: String {
        var parts: [String] = []
        if store.sessionsBehindPace {
            parts.append("You’ve logged \(store.sessionsThisWeek) of \(store.readingGoals.sessionsPerWeek) sessions this week.")
        }
        if store.pagesBehindPace {
            parts.append("Pages this month: \(store.pagesReadThisMonth)/\(store.readingGoals.pagesPerMonth).")
        }
        return parts.joined(separator: " ")
    }
}
