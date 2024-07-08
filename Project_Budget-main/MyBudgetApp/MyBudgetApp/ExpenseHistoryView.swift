import SwiftUI

struct ExpenseHistoryView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    @Binding var activeSheet: ActiveSheet?
    
    var currentMonthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            List{
                ForEach(expenseManager.expenses.filter { !$0.isArchived }.reversed()) { expense in
                    VStack(alignment: .leading) {
                        Text("\(expense.name)")
                            .fontWeight(.bold)
                        Text("Category: \(expense.category)")
                        Text("Amount: ")
                        + Text("- \(formatAsCurrency(amount: expense.amount))")
                            .fontWeight(.heavy)
                        if expense.frequency == "Other", let year = expense.customYear, let month = expense.customMonth, let day = expense.customDay {
                            Text("Frequency: Every \(year) year(s), \(month) month(s), \(day) day(s)")
                        } else {
                            Text("Frequency: \(expense.frequency)")
                        }
                    }
                }
                .onDelete { offsets in
                    let reversedOffsets = offsets.map { expenseManager.expenses.count - 1 - $0 }
                    expenseManager.removeExpense(at: IndexSet(reversedOffsets))
                }
            }
            .navigationBarTitle("\(currentMonthName)'s EXPENSES")
            .navigationBarItems(
                leading: Button(action: {
                    activeSheet = nil
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                },
                trailing: Button(action: {
                    expenseManager.deleteAllExpenses()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.blue)
                }
            )
        }
    }
    
    func formatAsCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "" // Remove the default currency symbol
        formatter.locale = Locale.current
        
        // Get the formatted string without the currency symbol
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        
        // Append the currency symbol at the end
        if let currencySymbol = Locale.current.currencySymbol {
            return "\(formattedAmount)\(currencySymbol)"
        } else {
            return formattedAmount
        }
    }
    
}


#Preview {
    ExpenseHistoryView(activeSheet: .constant(.expenseHistoryView))
        .environmentObject(ExpenseManager())
}
