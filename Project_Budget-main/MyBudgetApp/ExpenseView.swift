import SwiftUI

struct Expense: Identifiable,Codable{
    var id = UUID()
    var name: String
    var category: String
    var amount: Double
    var frequency: String
    var customYear: Int?
    var customMonth: Int?
    var customDay: Int?
    var isArchived: Bool = false
    var nextScheduledDate: Date?
    var creationDate: Date
}

class ExpenseManager: ObservableObject {
    @Published var expenses: [Expense] = []
    
    var totalExpense: Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    var expensesByCategory: [String: Double] {
        return Dictionary(grouping: expenses.filter { !$0.isArchived }, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var lastCheckedDate: Date {
        get {
            let date = UserDefaults.standard.object(forKey: "lastCheckedDate") as? Date
            return date ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastCheckedDate")
        }
    }
    
    func addExpense(_ expense: Expense){
        expenses.append(expense)
        saveExpenses()
    }
    
    func getNextScheduledDate(for expense: Expense) -> Date? {
        let currentDate = Date()
        switch expense.frequency {
        case "Every day":
            return Calendar.current.date(byAdding: .day, value: 1, to: currentDate)
        case "Every week":
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)
        case "Every month":
            return Calendar.current.date(byAdding: .month, value: 1, to: currentDate)
        case "Every year":
            return Calendar.current.date(byAdding: .year, value: 1, to: currentDate)
        case "Other":
            var newDate: Date? = currentDate
            if let day = expense.customDay {
                newDate = Calendar.current.date(byAdding: .day, value: day, to: newDate!)
            }
            if let month = expense.customMonth {
                newDate = Calendar.current.date(byAdding: .month, value: month, to: newDate!)
            }
            if let year = expense.customYear {
                newDate = Calendar.current.date(byAdding: .year, value: year, to: newDate!)
            }
            return newDate
        default:
            return nil
        }
    }
    
    // Function to save the expenses to UserDefaults
    func saveExpenses() {
        if let encodedData = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedData, forKey: "expenses")
        }
        //print("Saved expenses: \(expenses)")
    }
    
    // Function to load expenses from UserDefaults
    func loadExpenses() {
        if let encodedData = UserDefaults.standard.data(forKey: "expenses") {
            if let savedExpenses = try? JSONDecoder().decode([Expense].self, from: encodedData) {
                self.expenses = savedExpenses
            }
        }
    }
    
    // Function to remove an income item from the list
    func removeExpense(at offsets: IndexSet) {
        // Get the amount to be subtracted from the balance
        let amountToAdd = expenses[offsets.first!].amount
        // Remove the income from the list
        expenses.remove(atOffsets: offsets)
        
        // Update the balance in UserDefaults
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance + amountToAdd, forKey: "balance")
        // Save the updated list to UserDefaults
        saveExpenses()
    }
    
    func removeExpensesMatchingCondition(_ predicate: (Expense) -> Bool) {
            // Find the indices of the expenses that match the predicate
            let indicesToRemove = expenses.indices.filter { predicate(expenses[$0]) }
            
            // Convert the indices to an IndexSet
            let offsets = IndexSet(indicesToRemove)
            
            // Calculate the total amount to be added back to the balance
            let totalAmountToDeduct = offsets.compactMap { expenses[$0].amount }.reduce(0, +)
            print("Adding \(totalAmountToDeduct)")
            // Remove the expenses from the list
            expenses.remove(atOffsets: offsets)
            
            // Update the balance in UserDefaults
            let currentBalance = UserDefaults.standard.double(forKey: "balance")
            UserDefaults.standard.set(currentBalance + totalAmountToDeduct, forKey: "balance")
            
            print("balance after re-adding: \(currentBalance + totalAmountToDeduct)")
        
            // Save the updated list to UserDefaults
            saveExpenses()
        }

    
    func deleteAllExpenses() {
        let totalExpenseToRemove = expenses.filter { !$0.isArchived }
            .reduce(0) { $0 + $1.amount }
        
        expenses.removeAll { !$0.isArchived }
        
        
        // Add the total expense back to the balance
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance + totalExpenseToRemove, forKey: "balance")
        
        saveExpenses()
        
    }

}

struct ExpenseView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var activeSheet: ActiveSheet? // Binding to control the presentation of expenseView
    
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    
    ///Categories
    let expenseCategoryOptions = ["Personal", "Food", "Work", "Health", "Travel", "Bills" ,"Gifts" ,"Other"]
    @State private var selectedCategory = "Personal" //Default category
    
    ///Frequency of expense
    let frequencyOptions = ["One-time", "Every day", "Every week", "Every month", "Every year", "Other"]
    @State private var selectedFrequency = "One-time" //Default frequency
    @State private var customYear: Int = 0
    @State private var customMonth: Int = 0
    @State private var customDay: Int = 0
    
    
    var body: some View {
        NavigationView {
            VStack{
                List{
                    Section{
                        TextField("Expense Name", text: $expenseName)
                            .keyboardType(.default)
                            .padding()
                        
                        TextField("Expense Amount", text: $expenseAmount)
                            .padding()
                            .keyboardType(.decimalPad)
                    }
                    
                    Section{
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(expenseCategoryOptions, id: \.self) { category in
                                Text(category)
                            }
                        }
                    }
                    
                    Section{
                        Picker("Frequency", selection: $selectedFrequency){
                            ForEach(frequencyOptions, id: \.self){ frequency in
                                Text(frequency)
                            }
                        }
                        
                        if selectedFrequency == "Other" {
                            HStack {
                                Picker("", selection: $customYear) {
                                    ForEach(0..<21) { year in
                                        Text("\(year) year\(year != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 80)
                                
                                Picker("", selection: $customMonth) {
                                    ForEach(0..<12) { month in
                                        Text("\(month) month\(month != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)
                                
                                Picker("", selection: $customDay) {
                                    ForEach(0..<31) { day in
                                        Text("\(day) day\(day != 1 ? "s" : "")")
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 80)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    addExpense()
                })
                {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(expenseName.isEmpty || expenseAmount.isEmpty ? .gray : .blue)
                        .overlay(Image(systemName: "minus").font(.title).foregroundColor(.white))
                        .background(Color.clear)
                }
                .disabled(expenseName.isEmpty || expenseAmount.isEmpty)
                .padding()
            }
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    activeSheet = nil
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
            )
        }
    }
    
    private func addExpense(){
        // Preprocess the input to replace commas with periods
        // Validate and update balance
        if let number = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance -= number
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            
            var expense = Expense(name: expenseName, category: selectedCategory, amount: number, frequency: selectedFrequency, customYear: selectedFrequency == "Other" ? customYear : nil, customMonth: selectedFrequency == "Other" ? customMonth : nil, customDay: selectedFrequency == "Other" ? customDay : nil, creationDate: Date())
            
            expense.nextScheduledDate = expenseManager.getNextScheduledDate(for: expense)

            expenseManager.addExpense(expense)
            activeSheet = nil // Dismiss the expenseView
        }
    }
    
    
}

#Preview {
    ExpenseView(mainViewBalance: .constant(100.0), activeSheet: .constant(.expenseView))
        .environmentObject(ExpenseManager())
}
