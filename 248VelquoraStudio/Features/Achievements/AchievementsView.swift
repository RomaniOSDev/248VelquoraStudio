import SwiftUI

struct AchievementsView: View {
    let bottomInset: CGFloat
    var embedsInHub: Bool = false
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        Group {
            if embedsInHub {
                achievementsContent
                    .navigationTitle("Stats")
                    .navigationBarTitleDisplayMode(.inline)
                    .appScreenChrome()
            } else {
                NavigationStack {
                    achievementsContent
                        .navigationTitle("Stats")
                        .navigationBarTitleDisplayMode(.large)
                        .appScreenChrome()
                }
                .transparentScreenChrome()
            }
        }
    }

    private var achievementsContent: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeaderLabel(title: "Your Progress", subtitle: "Milestones from real reading activity")
                            HStack(spacing: 10) {
                                MetricTile(title: "Entries", value: "\(store.itemsCreated)", symbol: "plus.circle")
                                MetricTile(title: "Sessions", value: "\(store.totalSessionsCompleted)", symbol: "text.book.closed")
                                MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill")
                            }
                            ProgressBar(
                                value: Double(store.achievementsUnlocked.count) / Double(max(1, AchievementCatalog.all.count)),
                                height: 10
                            )
                            Text("\(store.achievementsUnlocked.count) of \(AchievementCatalog.all.count) achievements")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AchievementCatalog.all) { item in
                            AchievementCell(
                                definition: item,
                                unlocked: store.isAchievementUnlocked(item.id),
                                unlockedAt: store.achievementsUnlocked[item.id]
                            )
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
    }
}
