import Foundation

// MARK: - Budget Categories

enum BudgetCategory: String, CaseIterable, Codable, Identifiable {
    case etfSparplan = "ETF Sparplan"
    case urlaub = "Urlaub"
    case auto = "Auto"
    case aktien = "Aktien"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .etfSparplan: return "chart.line.uptrend.xyaxis"
        case .urlaub: return "airplane"
        case .auto: return "car.fill"
        case .aktien: return "dollarsign.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .etfSparplan: return "blue"
        case .urlaub: return "orange"
        case .auto: return "red"
        case .aktien: return "green"
        }
    }
}

// MARK: - Monthly Allocation

struct MonthlyAllocation: Codable, Identifiable {
    var id: UUID
    var category: BudgetCategory
    var plannedAmount: Double
    var actualAmount: Double

    init(id: UUID = UUID(), category: BudgetCategory, plannedAmount: Double = 0, actualAmount: Double = 0) {
        self.id = id
        self.category = category
        self.plannedAmount = plannedAmount
        self.actualAmount = actualAmount
    }

    var difference: Double { plannedAmount - actualAmount }
}

// MARK: - Monthly Entry

struct MonthlyEntry: Codable, Identifiable {
    var id: UUID
    var year: Int
    var month: Int
    var income: Double
    var allocations: [MonthlyAllocation]
    var notes: String

    init(id: UUID = UUID(), year: Int, month: Int, income: Double = 0, notes: String = "") {
        self.id = id
        self.year = year
        self.month = month
        self.income = income
        self.notes = notes
        self.allocations = BudgetCategory.allCases.map {
            MonthlyAllocation(category: $0, plannedAmount: 0, actualAmount: 0)
        }
    }

    var totalPlanned: Double { allocations.reduce(0) { $0 + $1.plannedAmount } }
    var totalActual: Double { allocations.reduce(0) { $0 + $1.actualAmount } }
    var remaining: Double { income - totalPlanned }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.monthSymbols[month - 1]
    }

    var displayTitle: String { "\(monthName) \(year)" }
}

// MARK: - Annual Goal

struct AnnualGoal: Codable, Identifiable {
    var id: UUID
    var year: Int
    var category: BudgetCategory
    var targetAmount: Double

    init(id: UUID = UUID(), year: Int, category: BudgetCategory, targetAmount: Double = 0) {
        self.id = id
        self.year = year
        self.category = category
        self.targetAmount = targetAmount
    }
}

// MARK: - App Data Store

class AppDataStore: ObservableObject {
    @Published var monthlyEntries: [MonthlyEntry] = []
    @Published var annualGoals: [AnnualGoal] = []

    private let entriesKey = "monthlyEntries"
    private let goalsKey = "annualGoals"

    init() {
        load()
        ensureCurrentMonthExists()
    }

    // MARK: - Persistence

    func save() {
        if let encoded = try? JSONEncoder().encode(monthlyEntries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
        if let encoded = try? JSONEncoder().encode(annualGoals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([MonthlyEntry].self, from: data) {
            monthlyEntries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([AnnualGoal].self, from: data) {
            annualGoals = decoded
        }
    }

    private func ensureCurrentMonthExists() {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        if !monthlyEntries.contains(where: { $0.year == year && $0.month == month }) {
            let entry = MonthlyEntry(year: year, month: month)
            monthlyEntries.append(entry)
            save()
        }
    }

    // MARK: - Monthly Entries

    func entry(for year: Int, month: Int) -> MonthlyEntry? {
        monthlyEntries.first { $0.year == year && $0.month == month }
    }

    func upsert(_ entry: MonthlyEntry) {
        if let idx = monthlyEntries.firstIndex(where: { $0.year == entry.year && $0.month == entry.month }) {
            monthlyEntries[idx] = entry
        } else {
            monthlyEntries.append(entry)
        }
        monthlyEntries.sort { ($0.year, $0.month) > ($1.year, $1.month) }
        save()
    }

    func addNewMonth(year: Int, month: Int) {
        guard !monthlyEntries.contains(where: { $0.year == year && $0.month == month }) else { return }
        let entry = MonthlyEntry(year: year, month: month)
        monthlyEntries.append(entry)
        monthlyEntries.sort { ($0.year, $0.month) > ($1.year, $1.month) }
        save()
    }

    // MARK: - Annual Goals

    func goals(for year: Int) -> [AnnualGoal] {
        annualGoals.filter { $0.year == year }
    }

    func goal(for year: Int, category: BudgetCategory) -> AnnualGoal {
        annualGoals.first { $0.year == year && $0.category == category }
            ?? AnnualGoal(year: year, category: category, targetAmount: 0)
    }

    func setGoal(year: Int, category: BudgetCategory, amount: Double) {
        if let idx = annualGoals.firstIndex(where: { $0.year == year && $0.category == category }) {
            annualGoals[idx].targetAmount = amount
        } else {
            annualGoals.append(AnnualGoal(year: year, category: category, targetAmount: amount))
        }
        save()
    }

    // MARK: - Annual Totals

    func annualTotal(for year: Int, category: BudgetCategory, actual: Bool) -> Double {
        monthlyEntries
            .filter { $0.year == year }
            .compactMap { entry in entry.allocations.first { $0.category == category } }
            .reduce(0) { $0 + (actual ? $1.actualAmount : $1.plannedAmount) }
    }

    func annualIncome(for year: Int) -> Double {
        monthlyEntries.filter { $0.year == year }.reduce(0) { $0 + $1.income }
    }

    var availableYears: [Int] {
        let years = Set(monthlyEntries.map { $0.year }).union(Set(annualGoals.map { $0.year }))
        return years.sorted(by: >)
    }
}

// MARK: - Formatter

extension Double {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: self)) ?? "€0,00"
    }
}
