import SwiftUI

@main
struct FinanceManagerApp: App {
    @StateObject private var store = AppDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
