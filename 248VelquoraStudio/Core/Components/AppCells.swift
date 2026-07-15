import SwiftUI

// MARK: - Base surfaces

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    var accentBorder: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppDepth.cardCorner, style: .continuous)
                    .fill(accentBorder ? AppDepth.cardAccentFill : AppDepth.cardFill)
                    .volumeStroke(accent: accentBorder)
                    .cardElevation()
            )
    }
}

struct SectionHeaderLabel: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppAccent"))
            }
        }
    }
}

struct IconBadge: View {
    let symbol: String
    var size: CGFloat = 48
    var filled: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(filled ? AppDepth.primarySoftFill : AppDepth.insetFill)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(filled ? 0.22 : 0.08), lineWidth: 1)
                )
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(Color("AppPrimary"))
        }
    }
}

struct MetaPill: View {
    let text: String
    var emphasized: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(emphasized ? Color("AppBackground") : Color("AppTextSecondary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(emphasized ? AppDepth.primaryFill : AppDepth.insetFill)
                    .overlay(
                        Capsule()
                            .stroke(
                                emphasized ? Color("AppAccent").opacity(0.35) : Color("AppTextSecondary").opacity(0.12),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppDepth.insetFill)
                Capsule()
                    .fill(AppDepth.primaryFill)
                    .frame(width: max(height, geo.size.width * CGFloat(min(1, max(0, value)))))
                    .overlay(
                        Capsule()
                            .stroke(Color("AppTextPrimary").opacity(0.12), lineWidth: 0.5)
                    )
            }
        }
        .frame(height: height)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var symbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("AppAccent"))
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppDepth.insetFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.12), lineWidth: 1)
                )
        )
    }
}

struct SoftReminderCell: View {
    let title: String
    let message: String

    var body: some View {
        SurfaceCard(accentBorder: true) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(symbol: "lightbulb.fill", size: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppPrimary"))
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color("AppPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: AppDepth.controlCorner, style: .continuous)
                    .fill(AppDepth.primarySoftFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDepth.controlCorner, style: .continuous)
                            .stroke(AppDepth.accentEdge, lineWidth: 1.4)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            SensoryFeedback.lightTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(selected ? AppDepth.primaryFill : AppDepth.insetFill)
                        .overlay(
                            Capsule()
                                .stroke(
                                    selected ? Color("AppAccent").opacity(0.3) : Color("AppTextSecondary").opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature cells

struct BookShelfCell: View {
    let book: Book
    var sessionCount: Int = 0

    var body: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                bookSpine
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(2)
                            Text(book.author.isEmpty ? "Unknown author" : book.author)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Spacer(minLength: 8)
                        MetaPill(text: book.status.title, emphasized: book.status == .reading)
                    }

                    if book.totalPages > 0 {
                        ProgressBar(value: book.pageProgress, height: 9)
                        HStack {
                            Text("p. \(book.currentPage)/\(book.totalPages)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color("AppAccent"))
                            Spacer()
                            if sessionCount > 0 {
                                Label("\(sessionCount)", systemImage: "text.book.closed")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    } else if book.totalChapters > 0 {
                        ProgressBar(value: book.chapterProgress, height: 9)
                        Text("Ch. \(book.currentChapter)/\(book.totalChapters)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }

                    if let perDay = book.pagesPerDayNeeded(), perDay > 0 {
                        Label("\(perDay) pages/day to deadline", systemImage: "speedometer")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
        }
    }

    private var bookSpine: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppDepth.primaryFill)
                .frame(width: 52, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
                )
            // Cheap spine highlight — volume without a second shadow
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color("AppTextPrimary").opacity(0.22))
                .frame(width: 3, height: 56)
                .offset(x: -18)
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color("AppBackground").opacity(0.25))
                    .frame(width: 28, height: 3)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color("AppBackground"))
            }
        }
    }
}

struct SessionCell: View {
    let session: ReadingSession
    let bookTitle: String
    var onDelete: (() -> Void)? = nil

    var body: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(symbol: "bookmark.fill", size: 46)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(bookTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                        Spacer()
                        Text(session.loggedAt, style: .date)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    HStack(spacing: 8) {
                        MetaPill(text: "p. \(session.pageFrom)–\(session.pageTo)", emphasized: true)
                        MetaPill(text: "\(session.durationMinutes) min")
                        MetaPill(text: "+\(session.pagesRead) pg")
                    }
                    if !session.chapterNote.isEmpty {
                        Text(session.chapterNote)
                            .font(.system(size: 13))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(3)
                    }
                }
            }
        }
        .contextMenu {
            if let onDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}

struct PlannerTaskCell: View {
    let task: ReadingTask
    let bookTitle: String?
    let isPulsing: Bool
    var onComplete: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var isOverdue: Bool {
        !task.isCompleted && task.dueDate < Date()
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: task.dueDate)
    }

    var body: some View {
        SurfaceCard(accentBorder: isPulsing || isOverdue) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    IconBadge(
                        symbol: task.isCompleted ? "checkmark.circle.fill" : (isOverdue ? "exclamationmark.circle.fill" : "calendar"),
                        size: 46,
                        filled: !task.isCompleted
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .strikethrough(task.isCompleted, color: Color("AppTextSecondary"))
                        if let bookTitle {
                            Text(bookTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                        if !task.chapter.isEmpty {
                            Text(task.chapter)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color("AppPrimary"))
                        }
                        Label(dateText, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(isOverdue ? Color("AppPrimary") : Color("AppTextSecondary"))
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.system(size: 12))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(2)
                        }
                    }
                }

                if !task.isCompleted {
                    HStack(spacing: 10) {
                        if let onComplete {
                            Button {
                                SensoryFeedback.mediumTap()
                                onComplete()
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color("AppBackground"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(minHeight: 44)
                                    .background(Capsule().fill(AppDepth.primaryFill))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        if let onEdit {
                            Button {
                                SensoryFeedback.lightTap()
                                onEdit()
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        if let onDelete {
                            Button {
                                SensoryFeedback.warning()
                                onDelete()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.red.opacity(0.85))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .opacity(task.isCompleted ? 0.72 : 1)
        .animation(.easeInOut(duration: 0.35), value: isPulsing)
        .contextMenu {
            if let onEdit { Button("Edit", action: onEdit) }
            if let onComplete, !task.isCompleted { Button("Complete", action: onComplete) }
            if let onDelete { Button("Delete", role: .destructive, action: onDelete) }
        }
    }
}

struct SchedulerTaskCell: View {
    let task: SchedulerTask
    let bookTitle: String?
    let isAnimating: Bool
    var onToggle: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: task.dueDate)
    }

    var body: some View {
        SurfaceCard(accentBorder: isAnimating) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? Color("AppAccent") : Color("AppTextSecondary"))
                        .scaleEffect(isAnimating ? 1.2 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimating)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .strikethrough(task.isCompleted, color: Color("AppTextSecondary"))
                    if let bookTitle {
                        Text(bookTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    Text(dateText)
                        .font(.system(size: 12))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .contextMenu {
            Button("Edit", action: onEdit)
            Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete", action: onToggle)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

struct QuoteCell: View {
    let quote: QuoteNote
    let bookTitle: String
    var onDelete: (() -> Void)? = nil

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color("AppPrimary"))
                    Text(quote.text)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    MetaPill(text: bookTitle)
                    MetaPill(text: "p. \(quote.page)", emphasized: true)
                }
                if !quote.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quote.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color("AppAccent"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color("AppBackground").opacity(0.5)))
                            }
                        }
                    }
                }
            }
        }
        .contextMenu {
            if let onDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}

struct HubRowCell: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        SurfaceCard {
            HStack(spacing: 14) {
                IconBadge(symbol: symbol, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }
}

struct AchievementCell: View {
    let definition: AchievementDefinition
    let unlocked: Bool
    let unlockedAt: Date?

    var body: some View {
        SurfaceCard(padding: 14, accentBorder: unlocked) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(unlocked ? AppDepth.primarySoftFill : AppDepth.insetFill)
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(
                                    unlocked ? Color("AppPrimary").opacity(0.35) : Color("AppTextSecondary").opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                    Image(systemName: definition.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.4))
                }
                Text(definition.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(unlocked ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(definition.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                if unlocked, let unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                } else {
                    MetaPill(text: "Locked")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 168)
        }
        .opacity(unlocked ? 1 : 0.78)
    }
}

struct SettingsRowCell: View {
    let title: String
    let symbol: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(destructive ? Color.red.opacity(0.9) : Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(destructive ? Color.red.opacity(0.95) : Color("AppTextPrimary"))
                Spacer()
                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CustomSegmentedControl: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    SensoryFeedback.lightTap()
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection = index
                    }
                } label: {
                    Text(titles[index])
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(selection == index ? Color("AppBackground") : Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .frame(minHeight: 44)
                        .background {
                            if selection == index {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppDepth.primaryFill)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppDepth.cardFill)
                .volumeStroke(corner: 16)
                .cardElevation()
        )
    }
}
