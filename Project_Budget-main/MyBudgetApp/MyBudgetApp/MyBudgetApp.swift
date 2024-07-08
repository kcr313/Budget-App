import SwiftUI

@main
struct MyBudgetApp: App {
    @StateObject var incomeManager = IncomeManager()
    @StateObject var expenseManager = ExpenseManager()
    
    init() {
            // Initialize UserDefaults key "balance" with a default value of 0
            UserDefaults.standard.register(defaults: ["Bütçe": 0.0])
        }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(incomeManager)
                .environmentObject(expenseManager)
        }
    }
}

