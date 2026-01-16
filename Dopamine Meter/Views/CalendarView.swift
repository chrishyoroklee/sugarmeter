import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var loggedDateKeys: Set<String> = []
    @State private var selectedLog: DayLogSelection?

    private let store = DailySugarLogStore()
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let minYear = 2000
    private let maxYear = 2100
    private static let selectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    weekdayHeader
                    monthGrid
                    selectedLogCard
                    streakInfo
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.backgroundTop,
                        AppTheme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loggedDateKeys = store.loggedDateKeys()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(AppTheme.secondary.opacity(0.6))
                    )
            }
            .disabled(!canMoveToPreviousMonth)
            .opacity(canMoveToPreviousMonth ? 1 : 0.4)

            Text("\(monthName(for: selectedMonth)) \(selectedYear)")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(AppTheme.secondary.opacity(0.6))
                    )
            }
            .disabled(!canMoveToNextMonth)
            .opacity(canMoveToNextMonth ? 1 : 0.4)
        }
        .padding(.top, 8)
    }

    private var weekdayHeader: some View {
        let symbols = weekdaySymbols()
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let grid = daysGrid(for: selectedMonth)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(grid.indices, id: \.self) { index in
                let day = grid[index]
                if let day {
                    dayCell(day: day, month: selectedMonth)
                } else {
                    Color.clear
                        .frame(height: 24)
                }
            }
        }
    }

    private var streakInfo: some View {
        VStack(spacing: 8) {
            Text("Current Streak")
                .font(.custom("AvenirNext-DemiBold", size: 14))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 2) {
                Text("\(currentStreak)")
                    .font(.custom("AvenirNext-Heavy", size: 28))
                    .foregroundStyle(AppTheme.primary)

                Text(currentStreak == 1 ? "Day" : "Days")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.primary.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.top, 4)
    }

    private func dayCell(day: Int, month: Int) -> some View {
        let dateKey = dateKeyString(year: selectedYear, month: month, day: day)
        let isLogged = loggedDateKeys.contains(dateKey)

        return Text("\(day)")
            .font(.custom("AvenirNext-Medium", size: 11))
            .foregroundStyle(isLogged ? Color.white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 24)
            .background(
                Circle()
                    .fill(isLogged ? AppTheme.primary : Color.clear)
            )
            .contentShape(Circle())
            .onTapGesture {
                if isLogged, let date = dateFromComponents(year: selectedYear, month: month, day: day) {
                    let log = store.log(for: date)
                    selectedLog = DayLogSelection(date: date, grams: log.grams)
                } else {
                    selectedLog = nil
                }
            }
    }

    private func daysGrid(for month: Int) -> [Int?] {
        guard let startOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Int?] = Array(repeating: nil, count: leadingBlanks)
        days += range.map { Optional($0) }

        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }
        return days
    }

    private func dateKeyString(year: Int, month: Int, day: Int) -> String {
        let components = DateComponents(year: year, month: month, day: day)
        let date = calendar.date(from: components) ?? Date()
        return store.dateKeyString(for: date)
    }

    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL"
        let date = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var selectedLogCard: some View {
        Group {
            if let selection = selectedLog {
                VStack(spacing: 6) {
                    Text("Logged on \(formattedDate(selection.date))")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Total sugar: \(selection.grams)g")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.primary.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.top, 4)
    }

    private func dateFromComponents(year: Int, month: Int, day: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    private func formattedDate(_ date: Date) -> String {
        Self.selectionFormatter.string(from: date)
    }


    private var currentStreak: Int {
        let today = Date()
        let todayKey = store.dateKeyString(for: today)

        let startDate: Date
        if loggedDateKeys.contains(todayKey) {
            startDate = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  loggedDateKeys.contains(store.dateKeyString(for: yesterday)) {
            startDate = yesterday
        } else {
            return 0
        }

        var count = 0
        var cursor = startDate

        while loggedDateKeys.contains(store.dateKeyString(for: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return count
    }

    private var canMoveToPreviousMonth: Bool {
        selectedYear > minYear || selectedMonth > 1
    }

    private var canMoveToNextMonth: Bool {
        selectedYear < maxYear || selectedMonth < 12
    }

    private func moveMonth(by offset: Int) {
        var year = selectedYear
        var month = selectedMonth + offset

        if month < 1 {
            month = 12
            year -= 1
        } else if month > 12 {
            month = 1
            year += 1
        }

        guard year >= minYear, year <= maxYear else { return }
        selectedYear = year
        selectedMonth = month
        selectedLog = nil
    }
}

private struct DayLogSelection {
    let date: Date
    let grams: Int
}
