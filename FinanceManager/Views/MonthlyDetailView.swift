import SwiftUI

struct MonthlyDetailView: View {
    @EnvironmentObject var store: AppDataStore
    let year: Int
    let month: Int

    @State private var entry: MonthlyEntry = MonthlyEntry(year: 0, month: 0)
    @State private var incomeText: String = ""
    @State private var isEditingIncome = false

    private var annualGoals: [BudgetCategory: Double] {
        Dictionary(uniqueKeysWithValues: BudgetCategory.allCases.map {
            ($0, store.goal(for: year, category: $0).targetAmount)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Income card
                incomeCard

                // Allocations
                VStack(spacing: 12) {
                    ForEach($entry.allocations) { $allocation in
                        AllocationRow(
                            allocation: $allocation,
                            annualGoal: annualGoals[allocation.category] ?? 0,
                            annualActual: store.annualTotal(for: year, category: allocation.category, actual: true),
                            onChange: saveEntry
                        )
                    }
                }

                // Summary footer
                summaryCard

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(entry.displayTitle)
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadEntry)
        .onChange(of: month) { _ in loadEntry() }
        .onChange(of: year) { _ in loadEntry() }
    }

    // MARK: - Income Card

    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Einnahmen")
                .font(.headline)

            HStack {
                Image(systemName: "eurosign.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                if isEditingIncome {
                    TextField("Betrag", text: $incomeText)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit { commitIncome() }
                } else {
                    Text(entry.income.currencyString)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Bearbeiten") {
                        incomeText = String(format: "%.2f", entry.income).replacingOccurrences(of: ".", with: ",")
                        isEditingIncome = true
                    }
                    .buttonStyle(.bordered)
                }

                if isEditingIncome {
                    Button("Speichern") { commitIncome() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func commitIncome() {
        let normalized = incomeText.replacingOccurrences(of: ",", with: ".")
        entry.income = Double(normalized) ?? entry.income
        isEditingIncome = false
        saveEntry()
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Zusammenfassung")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            HStack(spacing: 0) {
                summaryItem(title: "Einnahmen", value: entry.income)
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                summaryItem(title: "Geplant", value: entry.totalPlanned)
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                summaryItem(title: "Verbleibend", value: entry.remaining)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: entry.remaining >= 0 ? [.green, .green.opacity(0.7)] : [.red, .red.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func summaryItem(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value.currencyString)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data

    private func loadEntry() {
        if let e = store.entry(for: year, month: month) {
            entry = e
        } else {
            entry = MonthlyEntry(year: year, month: month)
        }
    }

    private func saveEntry() {
        store.upsert(entry)
    }
}

// MARK: - Allocation Row

struct AllocationRow: View {
    @Binding var allocation: MonthlyAllocation
    let annualGoal: Double
    let annualActual: Double
    let onChange: () -> Void

    @State private var plannedText: String = ""
    @State private var actualText: String = ""
    @State private var isExpanded = false

    var categoryColor: Color {
        switch allocation.category {
        case .etfSparplan: return .blue
        case .urlaub: return .orange
        case .auto: return .red
        case .aktien: return .green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: allocation.category.icon)
                        .foregroundColor(categoryColor)
                        .font(.title2)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(allocation.category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if annualGoal > 0 {
                            Text("Jahresfortschritt: \(annualActual.currencyString) / \(annualGoal.currencyString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(allocation.plannedAmount.currencyString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                        Text("Geplant")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal)

                VStack(spacing: 12) {
                    if annualGoal > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Jahresfortschritt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(min(annualActual / annualGoal * 100, 100)))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: min(annualActual / annualGoal, 1.0))
                                .tint(categoryColor)
                        }
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Geplant (€)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0,00", text: $plannedText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { commitPlanned() }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tatsächlich (€)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0,00", text: $actualText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { commitActual() }
                        }

                        Button("Speichern") {
                            commitPlanned()
                            commitActual()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(categoryColor)
                    }

                    if allocation.actualAmount > 0 {
                        HStack {
                            Text("Differenz:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(allocation.difference.currencyString)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(allocation.difference >= 0 ? .green : .red)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onAppear {
            plannedText = formatAmount(allocation.plannedAmount)
            actualText = formatAmount(allocation.actualAmount)
        }
    }

    private func formatAmount(_ value: Double) -> String {
        value == 0 ? "" : String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }

    private func commitPlanned() {
        let normalized = plannedText.replacingOccurrences(of: ",", with: ".")
        if let v = Double(normalized) {
            allocation.plannedAmount = v
            onChange()
        }
    }

    private func commitActual() {
        let normalized = actualText.replacingOccurrences(of: ",", with: ".")
        if let v = Double(normalized) {
            allocation.actualAmount = v
            onChange()
        }
    }
}
