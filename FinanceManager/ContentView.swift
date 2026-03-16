import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppDataStore
    @State private var selectedTab: AppTab = .dashboard
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab, selectedYear: $selectedYear)
        } detail: {
            switch selectedTab {
            case .dashboard:
                DashboardView(year: selectedYear)
            case .monthly(let year, let month):
                MonthlyDetailView(year: year, month: month)
            case .annualGoals:
                AnnualGoalsView(year: selectedYear)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

enum AppTab: Hashable {
    case dashboard
    case monthly(year: Int, month: Int)
    case annualGoals
}
