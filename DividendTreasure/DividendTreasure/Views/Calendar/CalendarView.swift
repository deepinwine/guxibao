//
//  CalendarView.swift
//  DividendTreasure
//
//  日历页面 - 显示股息到账日期和金额
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var portfolios: [Portfolio]

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    // 缓存股息事件，避免在 body 中每次渲染都全量重算（原实现每次 render 调用 2+ 次）。
    @State private var cachedEvents: [DividendCalendarEvent] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月份导航
                MonthNavigationBar(displayedMonth: $displayedMonth)

                // 日历网格
                CalendarGrid(
                    displayedMonth: displayedMonth,
                    selectedDate: $selectedDate,
                    dividendEvents: cachedEvents
                )

                // 选中日期的股息详情
                SelectedDateDetails(
                    date: selectedDate,
                    events: getEventsForDate(selectedDate)
                )
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("日历")
            .task {
                // 首次加载
                cachedEvents = computeDividendEvents()
            }
            .onChange(of: displayedMonth) { _, _ in
                // 切换月份时重算（按所看月份的年份生成事件）
                cachedEvents = computeDividendEvents()
            }
        }
    }

    private var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    private func computeDividendEvents() -> [DividendCalendarEvent] {
        var events: [DividendCalendarEvent] = []

        for holding in allHoldings {
            let months = parseDividendMonths(holding.expectedDividendMonths)
            let calendar = Calendar.current
            // 事件年份跟随当前查看的月份，使切换到任意月份都能看到对应事件
            let eventYear = calendar.component(.year, from: displayedMonth)

            for month in months {
                var components = DateComponents()
                components.year = eventYear
                components.month = month
                components.day = 15

                if let date = calendar.date(from: components) {
                    let event = DividendCalendarEvent(
                        date: date,
                        symbol: holding.symbol,
                        name: holding.name,
                        amount: holding.annualDividendPerShare * holding.quantity / Double(months.count),
                        market: holding.market
                    )
                    events.append(event)
                }
            }
        }

        return events.sorted { $0.date < $1.date }
    }

    private func getEventsForDate(_ date: Date) -> [DividendCalendarEvent] {
        let calendar = Calendar.current
        return cachedEvents.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }

    private func parseDividendMonths(_ monthsString: String) -> [Int] {
        guard !monthsString.isEmpty else { return [] }
        let components = monthsString.components(separatedBy: ",")
        return components.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

// MARK: - 日历事件模型

struct DividendCalendarEvent: Identifiable {
    let id = UUID()
    let date: Date
    let symbol: String
    let name: String
    let amount: Double
    let market: String
}

// MARK: - 月份导航栏

struct MonthNavigationBar: View {
    @Binding var displayedMonth: Date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter
    }()

    var body: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(dateFormatter.string(from: displayedMonth))
                .font(.headline)

            Spacer()

            Button(action: { changeMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func changeMonth(_ offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - 日历网格

struct CalendarGrid: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let dividendEvents: [DividendCalendarEvent]

    private let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            // 星期标题
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(getDaysInMonth().enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                            hasDividend: hasDividendOnDate(date),
                            dividendAmount: getDividendAmountForDate(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }

    private func getDaysInMonth() -> [Date?] {
        var days: [Date?] = []

        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return days
        }

        let firstDay = monthInterval.start
        let lastDay = monthInterval.end

        // 获取第一天是星期几（0 = 周日）
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1

        // 添加前面的空位
        for _ in 0..<firstWeekday {
            days.append(nil)
        }

        // 添加实际日期
        var currentDay = firstDay
        while currentDay < lastDay {
            days.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }

        return days
    }

    private func hasDividendOnDate(_ date: Date) -> Bool {
        dividendEvents.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func getDividendAmountForDate(_ date: Date) -> Double {
        dividendEvents
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - 日历单元格

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasDividend: Bool
    let dividendAmount: Double

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isCurrentMonth ? .primary : .secondary)

            if hasDividend {
                Text(CurrencyFormatter.formatCompact(dividendAmount))
                    .font(.system(size: 8))
                    .foregroundStyle(.green)
                    .lineLimit(1)
            } else {
                Spacer()
                    .frame(height: 10)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - 选中日期详情

struct SelectedDateDetails: View {
    let date: Date
    let events: [DividendCalendarEvent]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if events.isEmpty {
                ContentUnavailableView(
                    "当日无股息",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("这一天没有预计的股息到账")
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(dateFormatter.string(from: date))
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(events) { event in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.symbol)
                                    .font(.headline)
                                Text(event.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(CurrencyFormatter.format(event.amount))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 8)

                        if event.id != events.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
