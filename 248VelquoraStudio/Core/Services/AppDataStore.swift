import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private var cancellables = Set<AnyCancellable>()

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet { defaults.set(lastActivityDate, forKey: Keys.lastActivityDate) }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) }
    }

    @Published var itemsCreated: Int {
        didSet { defaults.set(itemsCreated, forKey: Keys.itemsCreated) }
    }

    @Published var books: [Book] {
        didSet { saveCodable(books, key: Keys.books) }
    }

    @Published var readingSessions: [ReadingSession] {
        didSet { saveCodable(readingSessions, key: Keys.readingSessions) }
    }

    @Published var quotes: [QuoteNote] {
        didSet { saveCodable(quotes, key: Keys.quotes) }
    }

    @Published var readingGoals: ReadingGoals {
        didSet { saveCodable(readingGoals, key: Keys.readingGoals) }
    }

    @Published var readingTasks: [ReadingTask] {
        didSet { saveCodable(readingTasks, key: Keys.readingTasks) }
    }

    @Published var completedReadingTasks: Int {
        didSet { defaults.set(completedReadingTasks, forKey: Keys.completedReadingTasks) }
    }

    @Published var schedulerTasks: [SchedulerTask] {
        didSet { saveCodable(schedulerTasks, key: Keys.schedulerTasks) }
    }

    @Published var completedSchedulerEntries: [CompletedTaskEntry] {
        didSet { saveCodable(completedSchedulerEntries, key: Keys.completedSchedulerEntries) }
    }

    @Published var tasksCompletedCount: Int {
        didSet { defaults.set(tasksCompletedCount, forKey: Keys.tasksCompletedCount) }
    }

    @Published var averageCompletionTimeSec: Int {
        didSet { defaults.set(averageCompletionTimeSec, forKey: Keys.averageCompletionTimeSec) }
    }

    @Published var longestStreakDays: Int {
        didSet { defaults.set(longestStreakDays, forKey: Keys.longestStreakDays) }
    }

    @Published var taskCompletionHistory: [String: Int] {
        didSet { saveCodable(taskCompletionHistory, key: Keys.taskCompletionHistory) }
    }

    @Published var pendingAchievementIds: [String] = []

    private var completionDurations: [Int] {
        didSet { defaults.set(completionDurations, forKey: Keys.completionDurations) }
    }

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let itemsCreated = "itemsCreated"
        static let books = "books"
        static let readingSessions = "readingSessions"
        static let quotes = "quotes"
        static let readingGoals = "readingGoals"
        static let readingTasks = "readingTasks"
        static let completedReadingTasks = "completedTasks"
        static let schedulerTasks = "tasks"
        static let completedSchedulerEntries = "completedTasksEntries"
        static let tasksCompletedCount = "tasksCompletedCount"
        static let averageCompletionTimeSec = "averageCompletionTimeSec"
        static let longestStreakDays = "longestStreakDays"
        static let taskCompletionHistory = "taskCompletionHistory"
        static let completionDurations = "completionDurations"
    }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked, defaults: defaults) ?? [:]
        itemsCreated = defaults.integer(forKey: Keys.itemsCreated)
        books = Self.loadCodable([Book].self, key: Keys.books, defaults: defaults) ?? []
        readingSessions = Self.loadCodable([ReadingSession].self, key: Keys.readingSessions, defaults: defaults) ?? []
        quotes = Self.loadCodable([QuoteNote].self, key: Keys.quotes, defaults: defaults) ?? []
        readingGoals = Self.loadCodable(ReadingGoals.self, key: Keys.readingGoals, defaults: defaults) ?? .default
        readingTasks = Self.loadCodable([ReadingTask].self, key: Keys.readingTasks, defaults: defaults) ?? []
        completedReadingTasks = defaults.integer(forKey: Keys.completedReadingTasks)
        schedulerTasks = Self.loadCodable([SchedulerTask].self, key: Keys.schedulerTasks, defaults: defaults) ?? []
        completedSchedulerEntries = Self.loadCodable([CompletedTaskEntry].self, key: Keys.completedSchedulerEntries, defaults: defaults) ?? []
        tasksCompletedCount = defaults.integer(forKey: Keys.tasksCompletedCount)
        averageCompletionTimeSec = defaults.integer(forKey: Keys.averageCompletionTimeSec)
        longestStreakDays = defaults.integer(forKey: Keys.longestStreakDays)
        taskCompletionHistory = Self.loadCodable([String: Int].self, key: Keys.taskCompletionHistory, defaults: defaults) ?? [:]
        completionDurations = defaults.array(forKey: Keys.completionDurations) as? [Int] ?? []

        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    // MARK: - Books

    func book(id: UUID?) -> Book? {
        guard let id else { return nil }
        return books.first { $0.id == id }
    }

    func addBook(_ book: Book) {
        books.append(book)
        itemsCreated += 1
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func updateBook(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        var updated = book
        updated.updatedAt = Date()
        books[index] = updated
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func deleteBook(id: UUID) {
        books.removeAll { $0.id == id }
        readingSessions.removeAll { $0.bookId == id }
        quotes.removeAll { $0.bookId == id }
        for index in readingTasks.indices where readingTasks[index].bookId == id {
            readingTasks[index].bookId = nil
        }
        for index in schedulerTasks.indices where schedulerTasks[index].bookId == id {
            schedulerTasks[index].bookId = nil
        }
    }

    // MARK: - Sessions

    func sessions(for bookId: UUID) -> [ReadingSession] {
        readingSessions
            .filter { $0.bookId == bookId }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func addSession(
        bookId: UUID,
        pageFrom: Int,
        pageTo: Int,
        durationMinutes: Int,
        chapterNote: String
    ) {
        let session = ReadingSession(
            bookId: bookId,
            pageFrom: pageFrom,
            pageTo: pageTo,
            durationMinutes: durationMinutes,
            chapterNote: chapterNote
        )
        readingSessions.append(session)
        totalSessionsCompleted += 1
        recordActivity(minutes: max(1, durationMinutes))

        if let index = books.firstIndex(where: { $0.id == bookId }) {
            var book = books[index]
            book.currentPage = max(book.currentPage, pageTo)
            if book.totalPages > 0, book.currentPage >= book.totalPages {
                book.currentPage = book.totalPages
                book.status = .finished
            } else if book.status == .want {
                book.status = .reading
            }
            book.updatedAt = Date()
            books[index] = book
        }

        let key = Self.dayKey(session.loggedAt)
        taskCompletionHistory[key, default: 0] += 1
        tasksCompletedCount += 1
        evaluateAchievements()
    }

    func deleteSession(id: UUID) {
        readingSessions.removeAll { $0.id == id }
    }

    var pagesReadThisMonth: Int {
        let calendar = Calendar.current
        return readingSessions
            .filter { calendar.isDate($0.loggedAt, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.pagesRead }
    }

    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return readingSessions.filter { interval.contains($0.loggedAt) }.count
    }

    var goalSessionProgress: Double {
        min(1, Double(sessionsThisWeek) / Double(max(1, readingGoals.sessionsPerWeek)))
    }

    var goalPageProgress: Double {
        min(1, Double(pagesReadThisMonth) / Double(max(1, readingGoals.pagesPerMonth)))
    }

    var sessionsBehindPace: Bool {
        sessionsThisWeek < readingGoals.sessionsPerWeek
    }

    var pagesBehindPace: Bool {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let expected = Double(readingGoals.pagesPerMonth) * (Double(day) / Double(daysInMonth))
        return Double(pagesReadThisMonth) < expected * 0.85
    }

    // MARK: - Quotes

    func addQuote(bookId: UUID, text: String, page: Int, tags: [String]) {
        let quote = QuoteNote(bookId: bookId, text: text, page: page, tags: tags)
        quotes.append(quote)
        itemsCreated += 1
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func updateQuote(_ quote: QuoteNote) {
        guard let index = quotes.firstIndex(where: { $0.id == quote.id }) else { return }
        quotes[index] = quote
        recordActivity(minutes: 1)
    }

    func deleteQuote(id: UUID) {
        quotes.removeAll { $0.id == id }
    }

    func filteredQuotes(query: String, tag: String?) -> [QuoteNote] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return quotes
            .filter { quote in
                let tagOK = tag == nil || tag == "" || quote.tags.contains { $0.caseInsensitiveCompare(tag ?? "") == .orderedSame }
                let queryOK = q.isEmpty
                    || quote.text.lowercased().contains(q)
                    || quote.tags.contains { $0.lowercased().contains(q) }
                    || (book(id: quote.bookId)?.title.lowercased().contains(q) ?? false)
                return tagOK && queryOK
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func exportQuotesText(query: String = "", tag: String? = nil) -> String {
        let list = filteredQuotes(query: query, tag: tag)
        return list.map { quote in
            let bookTitle = book(id: quote.bookId)?.title ?? "Unknown"
            let tags = quote.tags.isEmpty ? "" : " [\(quote.tags.joined(separator: ", "))]"
            return "“\(quote.text)” — \(bookTitle), p.\(quote.page)\(tags)"
        }
        .joined(separator: "\n\n")
    }

    // MARK: - Goals

    func updateGoals(_ goals: ReadingGoals) {
        readingGoals = goals
        recordActivity(minutes: 1)
    }

    // MARK: - Smart schedule

    func buildSmartPlan(for book: Book, days: Int = 7) -> [SmartPlanDay] {
        guard book.totalPages > 0, book.pagesRemaining > 0 else { return [] }
        let calendar = Calendar.current
        let perDay: Int
        if let needed = book.pagesPerDayNeeded() {
            perDay = max(1, needed)
        } else {
            perDay = max(1, Int(ceil(Double(book.pagesRemaining) / Double(days))))
        }

        var plan: [SmartPlanDay] = []
        var cursorPage = book.currentPage
        for offset in 0..<days {
            guard cursorPage < book.totalPages else { break }
            guard let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) else { break }
            let pageFrom = cursorPage
            let pageTo = min(book.totalPages, cursorPage + perDay)
            plan.append(
                SmartPlanDay(
                    id: UUID(),
                    date: date,
                    suggestedPages: pageTo - pageFrom,
                    pageFrom: pageFrom,
                    pageTo: pageTo,
                    note: "Read pages \(pageFrom + 1)–\(pageTo)"
                )
            )
            cursorPage = pageTo
        }
        return plan
    }

    func acceptSmartPlan(_ plan: [SmartPlanDay], for book: Book) {
        for day in plan {
            let task = ReadingTask(
                title: book.title,
                chapter: "Pages \(day.pageFrom + 1)–\(day.pageTo)",
                dueDate: day.date.addingTimeInterval(18 * 3600),
                notes: day.note,
                bookId: book.id
            )
            readingTasks.append(task)
            itemsCreated += 1
        }
        if var updated = books.first(where: { $0.id == book.id }), updated.status == .want {
            updated.status = .reading
            updateBook(updated)
        }
        recordActivity(minutes: 2)
        evaluateAchievements()
    }

    // MARK: - Reading Planner

    func addReadingTask(title: String, chapter: String, dueDate: Date, notes: String, bookId: UUID? = nil) {
        let task = ReadingTask(title: title, chapter: chapter, dueDate: dueDate, notes: notes, bookId: bookId)
        readingTasks.append(task)
        itemsCreated += 1
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func updateReadingTask(_ task: ReadingTask) {
        guard let index = readingTasks.firstIndex(where: { $0.id == task.id }) else { return }
        readingTasks[index] = task
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func deleteReadingTask(id: UUID) {
        readingTasks.removeAll { $0.id == id }
    }

    func completeReadingTask(id: UUID) {
        guard let index = readingTasks.firstIndex(where: { $0.id == id }) else { return }
        var task = readingTasks[index]
        guard !task.isCompleted else { return }
        let now = Date()
        task.isCompleted = true
        task.completedAt = now
        readingTasks[index] = task
        completedReadingTasks += 1
        totalSessionsCompleted += 1
        applyCompletionMetrics(createdAt: task.createdAt, completedAt: now)
        recordActivity(minutes: 2)
        evaluateAchievements()
    }

    // MARK: - Scheduler

    func addSchedulerTask(title: String, dueDate: Date, bookId: UUID? = nil) {
        let task = SchedulerTask(title: title, dueDate: dueDate, bookId: bookId)
        schedulerTasks.append(task)
        itemsCreated += 1
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func updateSchedulerTask(_ task: SchedulerTask) {
        guard let index = schedulerTasks.firstIndex(where: { $0.id == task.id }) else { return }
        schedulerTasks[index] = task
        recordActivity(minutes: 1)
        evaluateAchievements()
    }

    func deleteSchedulerTask(id: UUID) {
        schedulerTasks.removeAll { $0.id == id }
    }

    func completeSchedulerTask(id: UUID) {
        guard let index = schedulerTasks.firstIndex(where: { $0.id == id }) else { return }
        var task = schedulerTasks[index]
        guard !task.isCompleted else { return }
        let now = Date()
        task.isCompleted = true
        task.completedAt = now
        schedulerTasks[index] = task
        completedSchedulerEntries.append(CompletedTaskEntry(id: task.id, completedAt: now))
        totalSessionsCompleted += 1
        applyCompletionMetrics(createdAt: task.createdAt, completedAt: now)
        recordActivity(minutes: 2)
        evaluateAchievements()
    }

    func toggleSchedulerTask(id: UUID) {
        guard let index = schedulerTasks.firstIndex(where: { $0.id == id }) else { return }
        if schedulerTasks[index].isCompleted {
            schedulerTasks[index].isCompleted = false
            schedulerTasks[index].completedAt = nil
            completedSchedulerEntries.removeAll { $0.id == id }
        } else {
            completeSchedulerTask(id: id)
        }
    }

    // MARK: - Insights helpers

    func historyCount(for day: Date) -> Int {
        taskCompletionHistory[Self.dayKey(day)] ?? 0
    }

    func dailyCounts(forMonthContaining date: Date) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        var result: [(Date, Int)] = []
        var cursor = interval.start
        while cursor < interval.end {
            result.append((cursor, historyCount(for: cursor)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    // MARK: - Achievements

    func isAchievementUnlocked(_ id: String) -> Bool {
        achievementsUnlocked[id] != nil
    }

    func evaluateAchievements() {
        var newlyUnlocked: [String] = []
        let checks: [(String, Bool)] = [
            ("first_task", itemsCreated >= 1),
            ("task_enthusiast", itemsCreated >= 10),
            ("reading_planner", streakDays >= 7),
            ("busy_reader", totalSessionsCompleted >= 5),
            ("task_mastery", itemsCreated >= 20),
            ("consistent_planner", streakDays >= 14),
            ("comprehensive_organizer", totalSessionsCompleted >= 15),
            ("ultimate_achiever", streakDays >= 30)
        ]
        for (id, condition) in checks {
            if condition, achievementsUnlocked[id] == nil {
                achievementsUnlocked[id] = Date()
                newlyUnlocked.append(id)
            }
        }
        if !newlyUnlocked.isEmpty {
            pendingAchievementIds.append(contentsOf: newlyUnlocked)
            NotificationCenter.default.post(name: .achievementUnlocked, object: newlyUnlocked)
        }
    }

    func consumeNextAchievementBanner() -> String? {
        guard !pendingAchievementIds.isEmpty else { return nil }
        return pendingAchievementIds.removeFirst()
    }

    // MARK: - Reset

    func resetAllData() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        defaults.synchronize()
        reloadFromDefaults()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    // MARK: - Private

    private func applyCompletionMetrics(createdAt: Date, completedAt: Date) {
        tasksCompletedCount += 1
        let duration = max(0, Int(completedAt.timeIntervalSince(createdAt)))
        completionDurations.append(duration)
        if !completionDurations.isEmpty {
            averageCompletionTimeSec = completionDurations.reduce(0, +) / completionDurations.count
        }
        taskCompletionHistory[Self.dayKey(completedAt), default: 0] += 1
    }

    private func recordActivity(minutes: Int) {
        totalMinutesUsed += max(0, minutes)
        updateStreak()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if gap == 1 {
                streakDays += 1
            } else if gap > 1 {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = Date()
        if streakDays > longestStreakDays {
            longestStreakDays = streakDays
        }
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked, defaults: defaults) ?? [:]
        itemsCreated = defaults.integer(forKey: Keys.itemsCreated)
        books = Self.loadCodable([Book].self, key: Keys.books, defaults: defaults) ?? []
        readingSessions = Self.loadCodable([ReadingSession].self, key: Keys.readingSessions, defaults: defaults) ?? []
        quotes = Self.loadCodable([QuoteNote].self, key: Keys.quotes, defaults: defaults) ?? []
        readingGoals = Self.loadCodable(ReadingGoals.self, key: Keys.readingGoals, defaults: defaults) ?? .default
        readingTasks = Self.loadCodable([ReadingTask].self, key: Keys.readingTasks, defaults: defaults) ?? []
        completedReadingTasks = defaults.integer(forKey: Keys.completedReadingTasks)
        schedulerTasks = Self.loadCodable([SchedulerTask].self, key: Keys.schedulerTasks, defaults: defaults) ?? []
        completedSchedulerEntries = Self.loadCodable([CompletedTaskEntry].self, key: Keys.completedSchedulerEntries, defaults: defaults) ?? []
        tasksCompletedCount = defaults.integer(forKey: Keys.tasksCompletedCount)
        averageCompletionTimeSec = defaults.integer(forKey: Keys.averageCompletionTimeSec)
        longestStreakDays = defaults.integer(forKey: Keys.longestStreakDays)
        taskCompletionHistory = Self.loadCodable([String: Int].self, key: Keys.taskCompletionHistory, defaults: defaults) ?? [:]
        completionDurations = defaults.array(forKey: Keys.completionDurations) as? [Int] ?? []
        pendingAchievementIds = []
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadCodable<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
