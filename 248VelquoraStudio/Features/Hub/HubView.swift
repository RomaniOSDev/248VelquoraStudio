import SwiftUI

struct HubView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        HStack(spacing: 10) {
                            MetricTile(title: "Books", value: "\(store.books.count)", symbol: "books.vertical")
                            MetricTile(title: "Quotes", value: "\(store.quotes.count)", symbol: "quote.bubble")
                            MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill")
                        }

                        SectionHeaderLabel(title: "Workspace", subtitle: "Tools and account settings")

                        NavigationLink {
                            ZStack {
                                AppBackgroundView()
                                TaskSchedulerView(bottomInset: 24, embedsNavigation: false)
                            }
                            .navigationTitle("Task Scheduler")
                            .navigationBarTitleDisplayMode(.inline)
                            .appScreenChrome()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        SensoryFeedback.lightTap()
                                        NotificationCenter.default.post(name: .openSchedulerAdd, object: nil)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color("AppPrimary"))
                                            .frame(width: 44, height: 44)
                                    }
                                }
                            }
                        } label: {
                            HubRowCell(
                                title: "Task Scheduler",
                                subtitle: "Book-related to-dos and deadlines",
                                symbol: "checklist"
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { SensoryFeedback.lightTap() })

                        NavigationLink {
                            ZStack {
                                AppBackgroundView()
                                TaskInsightsView(bottomInset: 24, embedsNavigation: false)
                            }
                            .navigationTitle("Insights")
                            .navigationBarTitleDisplayMode(.inline)
                            .appScreenChrome()
                        } label: {
                            HubRowCell(
                                title: "Insights",
                                subtitle: "Completion trends over time",
                                symbol: "chart.xyaxis.line"
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { SensoryFeedback.lightTap() })

                        NavigationLink {
                            AchievementsView(bottomInset: 24, embedsInHub: true)
                        } label: {
                            HubRowCell(
                                title: "Stats & Achievements",
                                subtitle: "Badges and reading milestones",
                                symbol: "chart.bar.fill"
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { SensoryFeedback.lightTap() })

                        NavigationLink {
                            SettingsView(bottomInset: 24, embedsInHub: true)
                        } label: {
                            HubRowCell(
                                title: "Settings",
                                subtitle: "Privacy, support, and data reset",
                                symbol: "gearshape.fill"
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { SensoryFeedback.lightTap() })
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
        }
        .transparentScreenChrome()
    }
}
