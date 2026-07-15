import SwiftUI

struct ReadingPlannerView: View {
    let bottomInset: CGFloat
    var embedsNavigation: Bool = true

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ReadingPlannerViewModel()

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack {
                    plannerContent
                        .navigationTitle("Reading Planner")
                        .navigationBarTitleDisplayMode(.large)
                        .appScreenChrome()
                        .toolbar { addToolbar }
                }
                .transparentScreenChrome()
            } else {
                plannerContent
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlannerAdd)) { _ in
            viewModel.openAdd()
        }
        .sheet(isPresented: $viewModel.showingEditor) {
            ReadingTaskEditorView(task: viewModel.editingTask)
                .environmentObject(store)
        }
    }

    private var addToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.openAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var plannerContent: some View {
        ZStack {
            if embedsNavigation {
                AppBackgroundView()
            }

            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 10) {
                        MetricTile(title: "Upcoming", value: "\(viewModel.activeTasks.count)", symbol: "calendar")
                        MetricTile(title: "Done", value: "\(viewModel.completedTasks.count)", symbol: "checkmark.circle")
                        MetricTile(
                            title: "Overdue",
                            value: "\(viewModel.activeTasks.filter { $0.dueDate < Date() }.count)",
                            symbol: "exclamationmark.circle"
                        )
                    }

                    if viewModel.activeTasks.isEmpty && viewModel.completedTasks.isEmpty {
                        emptyContent
                    } else {
                        if !viewModel.activeTasks.isEmpty {
                            SectionHeaderLabel(title: "Upcoming", trailing: "\(viewModel.activeTasks.count)")
                            ForEach(viewModel.activeTasks) { task in
                                PlannerTaskCell(
                                    task: task,
                                    bookTitle: store.book(id: task.bookId)?.title,
                                    isPulsing: viewModel.pulsingTaskId == task.id,
                                    onComplete: { viewModel.complete(task) },
                                    onEdit: { viewModel.openEdit(task) },
                                    onDelete: { viewModel.delete(task) }
                                )
                            }
                        }

                        if !viewModel.completedTasks.isEmpty {
                            SectionHeaderLabel(title: "Completed", trailing: "\(viewModel.completedTasks.count)")
                            ForEach(viewModel.completedTasks.prefix(20)) { task in
                                PlannerTaskCell(
                                    task: task,
                                    bookTitle: store.book(id: task.bookId)?.title,
                                    isPulsing: false
                                )
                            }
                        }

                        Button {
                            viewModel.openAdd()
                        } label: {
                            Text("Add Task")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, embedsNavigation ? 16 : 8)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()

            SuccessCheckmarkOverlay(isVisible: $viewModel.showSuccess)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var emptyContent: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                symbol: "calendar.badge.plus",
                title: "No planned sessions yet!",
                message: "Add one now."
            )
            Text("Plan your first reading session")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppTextPrimary"))
            Button {
                viewModel.openAdd()
            } label: {
                Text("Add Task")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
        }
    }
}

struct ReadingTaskEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let task: ReadingTask?

    @State private var title = ""
    @State private var chapter = ""
    @State private var notes = ""
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
                        TextField("Book title / label", text: $title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: CGFloat(shakeTitle)))
                        if titleError {
                            Text("Please enter a title.")
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                        TextField("Chapter / pages", text: $chapter)
                            .foregroundStyle(Color("AppTextPrimary"))
                        DatePicker("Schedule", selection: $dueDate)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppPrimary"))
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .listRowBackground(Color("AppSurface"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(task == nil ? "New Session" : "Edit Session")
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
                    chapter = task.chapter
                    notes = task.notes
                    dueDate = task.dueDate
                    selectedBookId = task.bookId?.uuidString ?? ""
                } else if let reading = store.books.first(where: { $0.status == .reading }) {
                    selectedBookId = reading.id.uuidString
                    title = reading.title
                }
            }
            .onChange(of: selectedBookId) { newValue in
                if title.isEmpty, let book = store.books.first(where: { $0.id.uuidString == newValue }) {
                    title = book.title
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
            existing.chapter = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.dueDate = dueDate
            existing.bookId = bookId
            store.updateReadingTask(existing)
        } else {
            store.addReadingTask(
                title: trimmed,
                chapter: chapter.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: dueDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                bookId: bookId
            )
        }
        dismiss()
    }
}
