import Foundation

enum BookStatus: String, Codable, CaseIterable, Identifiable {
    case want
    case reading
    case finished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .want: return "Want to Read"
        case .reading: return "Reading"
        case .finished: return "Finished"
        }
    }
}

struct Book: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var author: String
    var status: BookStatus
    var totalPages: Int
    var currentPage: Int
    var totalChapters: Int
    var currentChapter: Int
    var targetFinishDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        status: BookStatus = .want,
        totalPages: Int = 0,
        currentPage: Int = 0,
        totalChapters: Int = 0,
        currentChapter: Int = 0,
        targetFinishDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.status = status
        self.totalPages = max(0, totalPages)
        self.currentPage = max(0, currentPage)
        self.totalChapters = max(0, totalChapters)
        self.currentChapter = max(0, currentChapter)
        self.targetFinishDate = targetFinishDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var pagesRemaining: Int {
        max(0, totalPages - currentPage)
    }

    var pageProgress: Double {
        guard totalPages > 0 else { return 0 }
        return min(1, Double(currentPage) / Double(totalPages))
    }

    var chapterProgress: Double {
        guard totalChapters > 0 else { return 0 }
        return min(1, Double(currentChapter) / Double(totalChapters))
    }

    /// Pages needed per day to hit the target finish date.
    func pagesPerDayNeeded(from date: Date = Date()) -> Int? {
        guard totalPages > 0, let deadline = targetFinishDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: deadline)
        let days = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
        let remaining = pagesRemaining
        guard remaining > 0 else { return 0 }
        return Int(ceil(Double(remaining) / Double(days)))
    }
}

struct ReadingSession: Codable, Identifiable, Equatable {
    var id: UUID
    var bookId: UUID
    var pageFrom: Int
    var pageTo: Int
    var durationMinutes: Int
    var chapterNote: String
    var loggedAt: Date

    init(
        id: UUID = UUID(),
        bookId: UUID,
        pageFrom: Int,
        pageTo: Int,
        durationMinutes: Int,
        chapterNote: String,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.pageFrom = max(0, pageFrom)
        self.pageTo = max(pageFrom, pageTo)
        self.durationMinutes = max(0, durationMinutes)
        self.chapterNote = chapterNote
        self.loggedAt = loggedAt
    }

    var pagesRead: Int { max(0, pageTo - pageFrom) }
}

struct QuoteNote: Codable, Identifiable, Equatable {
    var id: UUID
    var bookId: UUID
    var text: String
    var page: Int
    var tags: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bookId: UUID,
        text: String,
        page: Int,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.text = text
        self.page = max(0, page)
        self.tags = tags
        self.createdAt = createdAt
    }
}

struct ReadingGoals: Codable, Equatable {
    var sessionsPerWeek: Int
    var pagesPerMonth: Int

    static let `default` = ReadingGoals(sessionsPerWeek: 3, pagesPerMonth: 150)

    init(sessionsPerWeek: Int = 3, pagesPerMonth: Int = 150) {
        self.sessionsPerWeek = max(1, sessionsPerWeek)
        self.pagesPerMonth = max(1, pagesPerMonth)
    }
}

struct SmartPlanDay: Identifiable, Equatable {
    var id: UUID
    var date: Date
    var suggestedPages: Int
    var pageFrom: Int
    var pageTo: Int
    var note: String
}

struct ReadingTask: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var chapter: String
    var dueDate: Date
    var notes: String
    var bookId: UUID?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        chapter: String,
        dueDate: Date,
        notes: String,
        bookId: UUID? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.chapter = chapter
        self.dueDate = dueDate
        self.notes = notes
        self.bookId = bookId
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

struct SchedulerTask: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var dueDate: Date
    var bookId: UUID?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date,
        bookId: UUID? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.bookId = bookId
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

struct CompletedTaskEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var completedAt: Date
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_task",
            title: "First Task",
            detail: "Added the first book-related task.",
            symbolName: "bookmark.fill"
        ),
        AchievementDefinition(
            id: "task_enthusiast",
            title: "Task Enthusiast",
            detail: "Created 10 book-related tasks.",
            symbolName: "books.vertical.fill"
        ),
        AchievementDefinition(
            id: "reading_planner",
            title: "Reading Planner",
            detail: "Completed a week of planned reading tasks.",
            symbolName: "calendar"
        ),
        AchievementDefinition(
            id: "busy_reader",
            title: "Busy Reader",
            detail: "Logged tasks in multiple sessions.",
            symbolName: "flame.fill"
        ),
        AchievementDefinition(
            id: "task_mastery",
            title: "Task Mastery",
            detail: "Managed to complete at least half of all created tasks.",
            symbolName: "checkmark.seal.fill"
        ),
        AchievementDefinition(
            id: "consistent_planner",
            title: "Consistent Planner",
            detail: "Kept up with daily task logging for a fortnight.",
            symbolName: "chart.line.uptrend.xyaxis"
        ),
        AchievementDefinition(
            id: "comprehensive_organizer",
            title: "Comprehensive Organizer",
            detail: "Integrated various types of tasks into your planner.",
            symbolName: "square.grid.2x2.fill"
        ),
        AchievementDefinition(
            id: "ultimate_achiever",
            title: "Ultimate Achiever",
            detail: "Reached the milestone of completing all scheduled tasks for a month.",
            symbolName: "star.circle.fill"
        )
    ]
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let openSchedulerAdd = Notification.Name("openSchedulerAdd")
}
