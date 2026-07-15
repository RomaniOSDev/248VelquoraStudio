import SwiftUI
import UIKit
import StoreKit

struct SettingsView: View {
    let bottomInset: CGFloat
    var embedsInHub: Bool = false
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        Group {
            if embedsInHub {
                settingsContent
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .appScreenChrome()
            } else {
                NavigationStack {
                    settingsContent
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.large)
                        .appScreenChrome()
                }
                .transparentScreenChrome()
            }
        }
    }

    private var settingsContent: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    statsCard
                    rowsCard
                    Text(versionText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {
                SensoryFeedback.lightTap()
            }
            Button("Reset", role: .destructive) {
                SensoryFeedback.warning()
                store.resetAllData()
            }
        } message: {
            Text("This permanently deletes all tasks, stats, and achievements on this device.")
        }
    }

    private var statsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderLabel(title: "Overview", subtitle: "Local activity on this device")
                HStack(spacing: 10) {
                    MetricTile(title: "Books", value: "\(store.books.count)", symbol: "books.vertical")
                    MetricTile(title: "Sessions", value: "\(store.readingSessions.count)", symbol: "text.book.closed")
                    MetricTile(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill")
                }
                HStack(spacing: 10) {
                    MetricTile(title: "Entries", value: "\(store.itemsCreated)", symbol: "plus.circle")
                    MetricTile(title: "Minutes", value: "\(store.totalMinutesUsed)", symbol: "clock")
                    MetricTile(title: "Pages/mo", value: "\(store.pagesReadThisMonth)", symbol: "doc.plaintext")
                }
            }
        }
    }

    private var rowsCard: some View {
        SurfaceCard(padding: 0) {
            VStack(spacing: 0) {
                SettingsRowCell(title: "Rate Us", symbol: "star.fill") {
                    SensoryFeedback.lightTap()
                    rateApp()
                }
                Divider().background(Color("AppTextSecondary").opacity(0.25))
                SettingsRowCell(title: "Privacy Policy", symbol: "hand.raised.fill") {
                    SensoryFeedback.lightTap()
                    openLink(.privacyPolicy)
                }
                Divider().background(Color("AppTextSecondary").opacity(0.25))
                SettingsRowCell(title: "Terms of Use", symbol: "doc.text.fill") {
                    SensoryFeedback.lightTap()
                    openLink(.termsOfUse)
                }
                Divider().background(Color("AppTextSecondary").opacity(0.25))
                SettingsRowCell(title: "Reset All Data", symbol: "trash.fill", destructive: true) {
                    SensoryFeedback.lightTap()
                    showResetAlert = true
                }
            }
        }
    }

    private func openLink(_ link: AppLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
