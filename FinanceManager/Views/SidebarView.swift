import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: AppDataStore
    @Binding var selectedTab: AppTab
    @Binding var selectedYear: Int
    @State private var showAddMonth = false
    @State private var newMonthYear = Calendar.current.component(.year, from: Date())
    @State private var newMonthMonth = Calendar.current.component(.month, from: Date())

    private var allYears: [Int] {
        let years = Set(store.monthlyEntries.map { $0.year })
        let currentYear = Calendar.current.component(.year, from: Date())
        return years.union([currentYear]).sorted(by: >)
    }

    private func entries(for year: Int) -> [MonthlyEntry] {
        store.monthlyEntries
            .filter { $0.year == year }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        List(selection: Binding(
            get: { selectedTab },
            set: { if let v = $0 { selectedTab = v } }
        )) {
            // Dashboard
            Section {
                Label("Übersicht", systemImage: "house.fill")
                    .tag(AppTab.dashboard)
            }

            // Annual Goals
            Section {
                Label("Jahresziele \(selectedYear)", systemImage: "target")
                    .tag(AppTab.annualGoals)
            }

            // Monthly entries per year
            ForEach(allYears, id: \.self) { year in
                Section(header: yearHeader(year)) {
                    ForEach(entries(for: year)) { entry in
                        HStack {
                            Label(entry.displayTitle, systemImage: "calendar")
                            Spacer()
                            if entry.income > 0 {
                                Text(entry.income.currencyString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(AppTab.monthly(year: entry.year, month: entry.month))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Finance Manager")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddMonth = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddMonth) {
            AddMonthSheet(isPresented: $showAddMonth)
        }
        .onChange(of: selectedTab) { tab in
            if case .monthly(let year, _) = tab {
                selectedYear = year
            }
        }
    }

    @ViewBuilder
    private func yearHeader(_ year: Int) -> some View {
        HStack {
            Text(String(year))
            Spacer()
            Text(store.annualIncome(for: year).currencyString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AddMonthSheet: View {
    @EnvironmentObject var store: AppDataStore
    @Binding var isPresented: Bool
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())

    private let monthNames: [String] = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        return df.monthSymbols
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Jahr") {
                    Picker("Jahr", selection: $selectedYear) {
                        ForEach((2020...2030), id: \.self) { Text(String($0)).tag($0) }
                    }
                    .pickerStyle(.wheel)
                }
                Section("Monat") {
                    Picker("Monat", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text(monthNames[m - 1]).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Monat hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        store.addNewMonth(year: selectedYear, month: selectedMonth)
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
