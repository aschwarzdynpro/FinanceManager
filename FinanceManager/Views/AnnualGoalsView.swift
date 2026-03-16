import SwiftUI

struct AnnualGoalsView: View {
    @EnvironmentObject var store: AppDataStore
    let year: Int

    @State private var editingGoals: [BudgetCategory: String] = [:]
    @State private var hasChanges = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                headerCard

                // Goal cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(BudgetCategory.allCases) { category in
                        GoalEditCard(
                            category: category,
                            year: year,
                            goalText: binding(for: category),
                            onSave: { saveGoal(category: category) }
                        )
                    }
                }

                // Save all button
                if hasChanges {
                    Button(action: saveAll) {
                        Label("Alle Ziele speichern", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(12)
                }

                // Annual summary
                annualSummarySection

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Jahresziele \(year)")
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadGoals)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.title)
                    .foregroundColor(.white)
                Text("Jahresziele \(year)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            Text("Lege deine finanziellen Ziele für das Jahr \(year) fest und verfolge deinen Fortschritt.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
        .background(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
    }

    private var annualSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Jahresüberblick \(year)")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(BudgetCategory.allCases) { category in
                    let goal = store.goal(for: year, category: category).targetAmount
                    let actual = store.annualTotal(for: year, category: category, actual: true)
                    let planned = store.annualTotal(for: year, category: category, actual: false)

                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(categoryColorFor(category))
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(actual.currencyString)
                                    .font(.subheadline)
                                    .foregroundColor(categoryColorFor(category))
                                if goal > 0 {
                                    Text("Ziel: \(goal.currencyString)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if goal > 0 {
                            ProgressView(value: min(actual / goal, 1.0))
                                .tint(categoryColorFor(category))
                        } else {
                            HStack {
                                Text("Geplant: \(planned.currencyString)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding()

                    if category != BudgetCategory.allCases.last {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private func categoryColorFor(_ category: BudgetCategory) -> Color {
        switch category {
        case .etfSparplan: return .blue
        case .urlaub: return .orange
        case .auto: return .red
        case .aktien: return .green
        }
    }

    private func binding(for category: BudgetCategory) -> Binding<String> {
        Binding(
            get: { editingGoals[category] ?? "" },
            set: { editingGoals[category] = $0; hasChanges = true }
        )
    }

    private func loadGoals() {
        for category in BudgetCategory.allCases {
            let goal = store.goal(for: year, category: category)
            editingGoals[category] = goal.targetAmount == 0 ? "" : String(format: "%.2f", goal.targetAmount).replacingOccurrences(of: ".", with: ",")
        }
    }

    private func saveGoal(category: BudgetCategory) {
        guard let text = editingGoals[category] else { return }
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        let amount = Double(normalized) ?? 0
        store.setGoal(year: year, category: category, amount: amount)
    }

    private func saveAll() {
        for category in BudgetCategory.allCases {
            saveGoal(category: category)
        }
        hasChanges = false
    }
}

struct GoalEditCard: View {
    let category: BudgetCategory
    let year: Int
    @Binding var goalText: String
    let onSave: () -> Void

    @EnvironmentObject var store: AppDataStore

    private var actual: Double { store.annualTotal(for: year, category: category, actual: true) }
    private var goal: Double {
        let normalized = goalText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }
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
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Jahresziel (€)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("0,00", text: $goalText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { onSave() }
                    Button(action: onSave) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(categoryColor)
                }
            }

            if goal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Erreicht: \(actual.currencyString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                    }
                    ProgressView(value: progress)
                        .tint(categoryColor)
                }
            } else {
                Text("Kein Ziel gesetzt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
