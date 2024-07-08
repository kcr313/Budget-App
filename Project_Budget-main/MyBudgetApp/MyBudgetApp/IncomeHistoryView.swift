import SwiftUI


struct IncomeHistoryView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    @Binding var activeSheet: ActiveSheet?
    
    var currentMonthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            List{
                ForEach(incomeManager.incomes.filter { !$0.isArchived }.reversed()) { income in
                    VStack(alignment: .leading) {
                        Text("\(income.name)")
                            .fontWeight(.bold)
                        Text("Category: \(income.category)")
                        Text("Amount: ")
                            + Text("\(formatAsCurrency(amount: income.amount))")
                                .fontWeight(.heavy)
                        if income.frequency == "Other", let year = income.customYear, let month = income.customMonth, let day = income.customDay {
                            Text("Frequency: Every \(year > 0 ? "\(year) year\(year != 1 ? "s" : ""), " : "")\(month > 0 ? "\(month) month\(month != 1 ? "s" : ""), " : "")\(day > 0 ? "\(day) day\(day != 1 ? "s" : "")" : "")")
                        } else {
                            Text("Frequency: \(income.frequency)")
                        }
                    }
                }
                .onDelete { offsets in
                    let incomesToDelete = offsets.map { incomeManager.incomes.count - 1 - $0 }
                    .compactMap { index -> Income? in
                        let income = incomeManager.incomes[index]
                        return income.category != "Monthly budget" ? income : nil
                    }
                    
                    incomeManager.removeIncome(incomesToRemove: incomesToDelete)
                }


            }
            .navigationBarTitle("\(currentMonthName)'s INCOMES")
            .navigationBarItems(
                leading: Button(action: {
                    activeSheet = nil
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                },
                trailing: Button(action: {
                    incomeManager.deleteAllIncomes()
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
    IncomeHistoryView(activeSheet: .constant(.incomeHistoryView))
        .environmentObject(IncomeManager())
}
