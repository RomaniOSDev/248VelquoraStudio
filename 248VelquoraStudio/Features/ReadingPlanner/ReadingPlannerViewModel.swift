import Foundation
import Combine
import SwiftUI

final class ReadingPlannerViewModel: ObservableObject {
    @Published var showingEditor = false
    @Published var editingTask: ReadingTask?
    @Published var showSuccess = false
    @Published var pulsingTaskId: UUID?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var activeTasks: [ReadingTask] {
        store.readingTasks
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var completedTasks: [ReadingTask] {
        store.readingTasks
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func openAdd() {
        SensoryFeedback.lightTap()
        editingTask = nil
        showingEditor = true
    }

    func openEdit(_ task: ReadingTask) {
        SensoryFeedback.lightTap()
        editingTask = task
        showingEditor = true
    }

    func delete(_ task: ReadingTask) {
        SensoryFeedback.warning()
        store.deleteReadingTask(id: task.id)
    }

    func complete(_ task: ReadingTask) {
        store.completeReadingTask(id: task.id)
        SensoryFeedback.success()
        withPulse(task.id)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }
    }

    private func withPulse(_ id: UUID) {
        pulsingTaskId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.pulsingTaskId = nil
        }
    }
}
