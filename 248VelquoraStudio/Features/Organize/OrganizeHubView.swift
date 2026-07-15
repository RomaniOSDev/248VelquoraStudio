import SwiftUI

struct OrganizeHubView: View {
    let bottomInset: CGFloat
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    CustomSegmentedControl(titles: ["Scheduler", "Insights"], selection: $segment)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    Group {
                        if segment == 0 {
                            TaskSchedulerView(bottomInset: bottomInset, embedsNavigation: false)
                        } else {
                            TaskInsightsView(bottomInset: bottomInset, embedsNavigation: false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(segment == 0 ? "Task Scheduler" : "Insights")
            .navigationBarTitleDisplayMode(.large)
            .appScreenChrome()
            .toolbar {
                if segment == 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            NotificationCenter.default.post(name: .openSchedulerAdd, object: nil)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color("AppPrimary"))
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
        .transparentScreenChrome()
    }
}
