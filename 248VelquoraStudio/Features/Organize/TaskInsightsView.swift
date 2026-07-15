import SwiftUI

struct TaskInsightsView: View {
    let bottomInset: CGFloat
    var embedsNavigation: Bool = true

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = TaskInsightsViewModel()

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack { content }
            } else {
                content
            }
        }
        .sheet(isPresented: $viewModel.showAllTasks) {
            AllTasksListView()
                .environmentObject(store)
        }
    }

    private var content: some View {
        ZStack {
            if embedsNavigation {
                AppBackgroundView()
            }

            ScrollView {
                VStack(spacing: 18) {
                    if viewModel.hasData {
                        summaryCard
                        chartCard
                        Button {
                            SensoryFeedback.lightTap()
                            viewModel.showAllTasks = true
                        } label: {
                            Text("View All Tasks")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            EmptyStateView(
                symbol: "doc.text.magnifyingglass",
                title: "Complete tasks to see trends!",
                message: "Finish a reading session or scheduler task to populate this chart."
            )
            Text("Track your first reading task to unlock insights")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
        }
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderLabel(title: "Summary")
                HStack(spacing: 10) {
                    MetricTile(title: "Completed", value: "\(store.tasksCompletedCount)", symbol: "checkmark.circle")
                    MetricTile(title: "Avg Time", value: viewModel.averageCompletionLabel(), symbol: "timer")
                    MetricTile(title: "Best Streak", value: "\(store.longestStreakDays)d", symbol: "flame.fill")
                }
            }
        }
    }

    private var chartCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        viewModel.previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color("AppPrimary"))
                    }
                    Spacer()
                    Text(viewModel.monthTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button {
                        viewModel.nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }

                InsightsLineChart(
                    points: viewModel.dailyCounts,
                    selectedDay: viewModel.selectedDay
                ) { date, count in
                    viewModel.selectDay(date, count: count)
                }
                .frame(height: 180)

                if let tooltip = viewModel.tooltipText {
                    Text(tooltip)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }

                ForEach(Array(viewModel.dailyCounts.filter { $0.count > 0 }.suffix(7).reversed()), id: \.date) { item in
                    HStack {
                        Text(shortDate(item.date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        MetaPill(text: "\(item.count)", emphasized: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color("AppBackground").opacity(0.4))
                    )
                    .contextMenu {
                        Button("Previous Month") { viewModel.previousMonth() }
                        Button("Next Month") { viewModel.nextMonth() }
                    }
                }
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct InsightsLineChart: View {
    let points: [(date: Date, count: Int)]
    let selectedDay: Date?
    let onSelect: (Date, Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let maxCount = max(points.map(\.count).max() ?? 1, 1)
            let width = geo.size.width
            let height = geo.size.height
            let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : width

            ZStack {
                Canvas { context, size in
                    var path = Path()
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = size.height - (CGFloat(point.count) / CGFloat(maxCount)) * (size.height - 16) - 8
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    context.stroke(
                        path,
                        with: .color(Color("AppAccent")),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    for (index, point) in points.enumerated() where point.count > 0 {
                        let x = CGFloat(index) * stepX
                        let y = size.height - (CGFloat(point.count) / CGFloat(maxCount)) * (size.height - 16) - 8
                        let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                        context.fill(Path(ellipseIn: rect), with: .color(Color("AppPrimary")))
                    }
                }
                .allowsHitTesting(false)

                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    let x = CGFloat(index) * stepX
                    Button {
                        onSelect(point.date, point.count)
                    } label: {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                    }
                    .position(x: x, y: height / 2)
                }
            }
        }
    }
}

struct AllTasksListView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                List {
                    Section("Reading Sessions") {
                        ForEach(store.readingTasks.sorted { $0.dueDate > $1.dueDate }) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(task.isCompleted ? "Completed" : "Planned")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .listRowBackground(Color("AppSurface"))
                        }
                    }
                    Section("Scheduler Tasks") {
                        ForEach(store.schedulerTasks.sorted { $0.dueDate > $1.dueDate }) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(task.isCompleted ? "Completed" : "Open")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .listRowBackground(Color("AppSurface"))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("All Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        SensoryFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}
