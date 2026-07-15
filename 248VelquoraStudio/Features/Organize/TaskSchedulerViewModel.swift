import Foundation
import Combine
import SwiftUI

final class TaskSchedulerViewModel: ObservableObject {
    @Published var showingEditor = false
    @Published var editingTask: SchedulerTask?
    @Published var showSuccess = false
    @Published var animatingCheckId: UUID?

    private let store: AppDataStore

    init(store: AppDataStore = .shared) {
        self.store = store
    }

    var tasks: [SchedulerTask] {
        store.schedulerTasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            return lhs.dueDate < rhs.dueDate
        }
    }

    func openAdd() {
        SensoryFeedback.lightTap()
        editingTask = nil
        showingEditor = true
    }

    func openEdit(_ task: SchedulerTask) {
        SensoryFeedback.lightTap()
        editingTask = task
        showingEditor = true
    }

    func delete(_ task: SchedulerTask) {
        SensoryFeedback.warning()
        store.deleteSchedulerTask(id: task.id)
    }

    func complete(_ task: SchedulerTask) {
        if task.isCompleted {
            store.toggleSchedulerTask(id: task.id)
            SensoryFeedback.tick()
            return
        }
        store.completeSchedulerTask(id: task.id)
        SensoryFeedback.completeWithVibrate()
        animatingCheckId = task.id
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.animatingCheckId = nil
        }
    }
}
