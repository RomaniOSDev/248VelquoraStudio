import Foundation
import Combine

final class TaskInsightsViewModel: ObservableObject {
    @Published var monthOffset = 0
    @Published var selectedDay: Date?
    @Published var showAllTasks = false
    @Published var tooltipText: String?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var referenceDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: referenceDate)
    }

    var hasData: Bool {
        store.tasksCompletedCount > 0 || !store.taskCompletionHistory.isEmpty
    }

    var dailyCounts: [(date: Date, count: Int)] {
        store.dailyCounts(forMonthContaining: referenceDate)
    }

    func previousMonth() {
        SensoryFeedback.lightTap()
        monthOffset -= 1
        selectedDay = nil
        tooltipText = nil
    }

    func nextMonth() {
        SensoryFeedback.lightTap()
        monthOffset += 1
        selectedDay = nil
        tooltipText = nil
    }

    func selectDay(_ date: Date, count: Int) {
        SensoryFeedback.chartTap()
        selectedDay = date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        tooltipText = "\(formatter.string(from: date)): \(count) completed"
    }

    func averageCompletionLabel() -> String {
        let seconds = store.averageCompletionTimeSec
        if seconds <= 0 { return "—" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let rem = minutes % 60
        return "\(hours)h \(rem)m"
    }
}
