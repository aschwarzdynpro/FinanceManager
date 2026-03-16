import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppDataStore
    let year: Int

    private var yearEntries: [MonthlyEntry] {
        store.monthlyEntries.filter { $0.year == year }.sorted { $0.month < $1.month }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Year summary header
                yearSummaryCard

                // Category progress cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(BudgetCategory.allCases) { category in
                        CategorySummaryCard(year: year, category: category)
                    }
                }

                // Monthly income chart
                monthlyIncomeSection

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Übersicht \(year)")
        .background(Color(.systemGroupedBackground))
    }

    private var yearSummaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Jahresübersicht \(year)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            HStack(spacing: 0) {
                summaryItem(title: "Einnahmen", value: store.annualIncome(for: year), color: .white)
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                summaryItem(title: "Geplant", value: yearEntries.reduce(0) { $0 + $1.totalPlanned }, color: .white)
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                summaryItem(title: "Tatsächlich", value: yearEntries.reduce(0) { $0 + $1.totalActual }, color: .white)
            }
            .padding()
        }
        .background(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
    }

    private func summaryItem(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(color.opacity(0.8))
            Text(value.currencyString)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthlyIncomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monatliche Einnahmen")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(yearEntries) { entry in
                    HStack {
                        Text(entry.monthName)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { geo in
                            let maxIncome = yearEntries.map { $0.income }.max() ?? 1
                            let ratio = maxIncome > 0 ? entry.income / maxIncome : 0
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemFill))
                                    .frame(height: 24)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: geo.size.width * ratio, height: 24)
                            }
                        }
                        .frame(height: 24)

                        Text(entry.income.currencyString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct CategorySummaryCard: View {
    @EnvironmentObject var store: AppDataStore
    let year: Int
    let category: BudgetCategory

    private var actual: Double { store.annualTotal(for: year, category: category, actual: true) }
    private var planned: Double { store.annualTotal(for: year, category: category, actual: false) }
    private var goal: Double { store.goal(for: year, category: category).targetAmount }
    private var progress: Double { goal > 0 ? min(actual / goal, 1.0) : 0 }

    var categoryColor: Color {
        switch category {
        case .etfSparplan: return .blue
        case .urlaub: return .orange
        case .auto: return .red
        case .aktien: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(categoryColor)
                    .font(.title2)
                Spacer()
                if goal > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)

            if goal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(categoryColor)
                    HStack {
                        Text(actual.currencyString)
                            .font(.caption)
                            .foregroundColor(categoryColor)
                        Spacer()
                        Text("/ \(goal.currencyString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tatsächlich")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(actual.currencyString)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Geplant")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(planned.currencyString)
                        .font(.caption)
                }
                Spacer()
                if goal > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Verbleibend")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(max(goal - actual, 0).currencyString)
                            .font(.caption)
                            .foregroundColor(actual >= goal ? .green : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
