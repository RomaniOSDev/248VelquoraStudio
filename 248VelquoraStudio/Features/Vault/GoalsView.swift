import SwiftUI

struct GoalsView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore
    @State private var sessionsTarget: Double = 3
    @State private var pagesTarget: Double = 150
    @State private var savedFlash = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SoftReminderCell(
                    title: "In-app reminders",
                    message: reminderCopy
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeaderLabel(
                            title: "Weekly sessions",
                            trailing: "\(store.sessionsThisWeek)/\(store.readingGoals.sessionsPerWeek)"
                        )
                        ProgressBar(value: store.goalSessionProgress, height: 10)
                        Stepper(value: $sessionsTarget, in: 1...21, step: 1) {
                            Text("Target: \(Int(sessionsTarget)) sessions")
                                .foregroundStyle(Color("AppTextPrimary"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .tint(Color("AppPrimary"))
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeaderLabel(
                            title: "Monthly pages",
                            trailing: "\(store.pagesReadThisMonth)/\(store.readingGoals.pagesPerMonth)"
                        )
                        ProgressBar(value: store.goalPageProgress, height: 10)
                        Stepper(value: $pagesTarget, in: 20...2000, step: 10) {
                            Text("Target: \(Int(pagesTarget)) pages")
                                .foregroundStyle(Color("AppTextPrimary"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .tint(Color("AppPrimary"))
                    }
                }

                HStack(spacing: 10) {
                    MetricTile(title: "Sessions", value: "\(store.sessionsThisWeek)", symbol: "calendar")
                    MetricTile(title: "Pages", value: "\(store.pagesReadThisMonth)", symbol: "doc.plaintext")
                    MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill")
                }

                Button {
                    SensoryFeedback.mediumTap()
                    SensoryFeedback.success()
                    store.updateGoals(
                        ReadingGoals(
                            sessionsPerWeek: Int(sessionsTarget),
                            pagesPerMonth: Int(pagesTarget)
                        )
                    )
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        savedFlash = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { savedFlash = false }
                    }
                } label: {
                    Text(savedFlash ? "Saved" : "Save Goals")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, bottomInset)
        }
        .clearScrollBackground()
        .onAppear {
            sessionsTarget = Double(store.readingGoals.sessionsPerWeek)
            pagesTarget = Double(store.readingGoals.pagesPerMonth)
        }
    }

    private var reminderCopy: String {
        if !store.sessionsBehindPace && !store.pagesBehindPace {
            return "You’re on pace this period. Keep logging sessions to stay consistent."
        }
        var parts: [String] = []
        if store.sessionsBehindPace {
            parts.append("A single session today helps your weekly target.")
        }
        if store.pagesBehindPace {
            parts.append("A short reading block can restore your monthly page pace.")
        }
        return parts.joined(separator: " ")
    }
}
