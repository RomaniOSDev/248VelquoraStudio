import SwiftUI

struct TaskSchedulerView: View {
    let bottomInset: CGFloat
    var embedsNavigation: Bool = true

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = TaskSchedulerViewModel()

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack { content }
            } else {
                content
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSchedulerAdd)) { _ in
            viewModel.openAdd()
        }
        .sheet(isPresented: $viewModel.showingEditor) {
            SchedulerTaskEditorView(task: viewModel.editingTask)
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
                    HStack(spacing: 10) {
                        MetricTile(
                            title: "Open",
                            value: "\(viewModel.tasks.filter { !$0.isCompleted }.count)",
                            symbol: "circle"
                        )
                        MetricTile(
                            title: "Done",
                            value: "\(viewModel.tasks.filter(\.isCompleted).count)",
                            symbol: "checkmark.circle"
                        )
                        MetricTile(title: "Total", value: "\(viewModel.tasks.count)", symbol: "checklist")
                    }

                    if viewModel.tasks.isEmpty {
                        EmptyStateView(
                            symbol: "calendar",
                            title: "Start organizing your reading tasks",
                            message: "Create your first book-related to-do."
                        )
                        Button {
                            viewModel.openAdd()
                        } label: {
                            Text("Add Task")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                    } else {
                        SectionHeaderLabel(title: "Tasks", trailing: "\(viewModel.tasks.count)")
                        ForEach(viewModel.tasks) { task in
                            SchedulerTaskCell(
                                task: task,
                                bookTitle: store.book(id: task.bookId)?.title,
                                isAnimating: viewModel.animatingCheckId == task.id,
                                onToggle: { viewModel.complete(task) },
                                onEdit: { viewModel.openEdit(task) },
                                onDelete: { viewModel.delete(task) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()

            SuccessCheckmarkOverlay(isVisible: $viewModel.showSuccess)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

struct SchedulerTaskEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let task: SchedulerTask?

    @State private var title = ""
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var selectedBookId = ""
    @State private var shakeTitle = 0
    @State private var titleError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        if !store.books.isEmpty {
                            Picker("Book", selection: $selectedBookId) {
                                Text("None").tag("")
                                ForEach(store.books) { book in
                                    Text(book.title).tag(book.id.uuidString)
                                }
                            }
                            .tint(Color("AppPrimary"))
                        }
                        TextField("Task title", text: $title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: CGFloat(shakeTitle)))
                        if titleError {
                            Text("Please enter a task title.")
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                        DatePicker("Due date", selection: $dueDate)
                            .tint(Color("AppPrimary"))
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        SensoryFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppPrimary"))
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let task {
                    title = task.title
                    dueDate = task.dueDate
                    selectedBookId = task.bookId?.uuidString ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            titleError = true
            SensoryFeedback.warning()
            withAnimation(.default) { shakeTitle += 1 }
            return
        }
        SensoryFeedback.mediumTap()
        SensoryFeedback.success()
        let bookId = UUID(uuidString: selectedBookId)
        if var existing = task {
            existing.title = trimmed
            existing.dueDate = dueDate
            existing.bookId = bookId
            store.updateSchedulerTask(existing)
        } else {
            store.addSchedulerTask(title: trimmed, dueDate: dueDate, bookId: bookId)
        }
        dismiss()
    }
}
