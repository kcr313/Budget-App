import SwiftUI

struct Income: Identifiable,Codable{
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

class IncomeManager: ObservableObject {
    @Published var incomes: [Income] = []
    
    var totalIncome: Double {
        return incomes.reduce(0) { $0 + $1.amount }
    }
    
    var incomesByCategory: [String: Double] {
        return Dictionary(grouping: incomes.filter { !$0.isArchived }, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    var lastCheckedDate: Date {
        get {
            let date = UserDefaults.standard.object(forKey: "lastCheckedDateIncome") as? Date
            return date ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastCheckedDateIncome")
        }
    }
    
    
    // Function to add an income item to the list
    func addIncome(_ income: Income) {
        incomes.append(income)
        saveIncomes()
    }
    
    func getNextScheduledDate(for income: Income) -> Date? {
        let currentDate = Date()
        switch income.frequency {
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
            if let day = income.customDay {
                newDate = Calendar.current.date(byAdding: .day, value: day, to: newDate!)
            }
            if let month = income.customMonth {
                newDate = Calendar.current.date(byAdding: .month, value: month, to: newDate!)
            }
            if let year = income.customYear {
                newDate = Calendar.current.date(byAdding: .year, value: year, to: newDate!)
            }
            return newDate
        default:
            return nil
        }
    }
    
    // Function to save the incomes to UserDefaults
    func saveIncomes() {
        if let encodedData = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encodedData, forKey: "incomes")
        }
    }
    
    // Function to load incomes from UserDefaults
    func loadIncomes() {
        if let encodedData = UserDefaults.standard.data(forKey: "incomes") {
            if let savedIncomes = try? JSONDecoder().decode([Income].self, from: encodedData) {
                self.incomes = savedIncomes
            }
        }
    }
    
    func removeIncome(incomesToRemove: [Income]) {
        for income in incomesToRemove {
            // Get the amount to be subtracted from the balance
            let amountToSubtract = income.amount
            
            // Remove the income from the list
            if let index = incomes.firstIndex(where: { $0.id == income.id }) {
                incomes.remove(at: index)
            }
            
            // Update the balance in UserDefaults
            let currentBalance = UserDefaults.standard.double(forKey: "balance")
            UserDefaults.standard.set(currentBalance - amountToSubtract, forKey: "balance")
        }
        
        // Save the updated list to UserDefaults
        saveIncomes()
    }
    
    func removeIncomesMatchingCondition(_ predicate: (Income) -> Bool) {
        // Find the indices of the incomes that match the predicate
        let indicesToRemove = incomes.indices.filter { predicate(incomes[$0]) }
        
        // Convert the indices to an IndexSet
        let offsets = IndexSet(indicesToRemove)
        
        // Calculate the total amount to be deducted from the balance, excluding "Monthly budget" category
        let totalAmountToDeduct = offsets.compactMap { incomes[$0].category != "Monthly budget" ? incomes[$0].amount : nil }.reduce(0, +)
        print("Removing \(totalAmountToDeduct)")
        
        // Remove the incomes from the list
        incomes.remove(atOffsets: offsets)
        
        // Update the balance in UserDefaults
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance - totalAmountToDeduct, forKey: "balance")
        
        print("BALANCE after removing: \(currentBalance - totalAmountToDeduct)")
        
        // Save the updated list to UserDefaults
        saveIncomes()
    }



    func deleteAllIncomes() {
        let totalIncomeToRemove = incomes.filter { !$0.isArchived && $0.category != "Monthly budget" }
            .reduce(0) { $0 + $1.amount }
        
        incomes.removeAll { income in
            return !income.isArchived && income.category != "Monthly budget"
        }
        
        // Deduct the total income from the balance
        let currentBalance = UserDefaults.standard.double(forKey: "balance")
        UserDefaults.standard.set(currentBalance - totalIncomeToRemove, forKey: "balance")
        
        saveIncomes()
    }
}

struct IncomeView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var activeSheet: ActiveSheet? //Binding to control the presentation of IncomeView
    
    @State private var incomeName = ""
    @State private var incomeAmount = ""
    
    ///Categories
    let incomeCategoryOptions = ["Work", "Gifts", "Other"]
    @State private var selectedCategory = "Work" //Default category
    
    ///Frequency
    let frequencyOptions = ["One-time", "Every day", "Every week", "Every month", "Every year", "Other"]
    @State private var selectedFrequency = "One-time" //Default frequency
    @State private var customYear: Int = 0
    @State private var customMonth: Int = 0
    @State private var customDay: Int = 0
    
    
    var body: some View {
        NavigationView {
            VStack{
                List{
                    TextField("Income Name", text: $incomeName)
                        .keyboardType(.default)
                        .padding()
                    
                    TextField("Income Amount", text: $incomeAmount)
                        .padding()
                        .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                    
                    Section{
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(incomeCategoryOptions, id: \.self) { category in
                                Text(category)
                            }
                        }
                    }
                    
                    Section {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(frequencyOptions, id: \.self) { frequency in
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
                .navigationTitle("Add income")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: Button(action: {
                        // Handle the action to go back to the MainView
                        activeSheet = nil // Dismiss the IncomeView
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.blue)
                    }
                )
                
                Spacer()
                
                Button(action: {
                    addIncome()
                })
                {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(incomeName.isEmpty || incomeAmount.isEmpty ? .gray : .blue)
                        .overlay(Image(systemName: "plus").font(.title).foregroundColor(.white))
                        .background(Color.clear)
                }
                .disabled(incomeName.isEmpty || incomeAmount.isEmpty) // Disable the button if fields are empty
                .padding()
            }
        }
    }
    
    private func addIncome() {
        if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
            mainViewBalance += number
            
            // Update UserDefaults balance value here
            UserDefaults.standard.set(mainViewBalance, forKey: "balance")
            UserDefaults.standard.synchronize() // Force immediate synchronization
            
            var newIncome = Income(name: incomeName, category: selectedCategory, amount: number, frequency: selectedFrequency, customYear: selectedFrequency == "Other" ? customYear : nil, customMonth: selectedFrequency == "Other" ? customMonth : nil, customDay: selectedFrequency == "Other" ? customDay : nil, creationDate: Date())
            
            newIncome.nextScheduledDate = incomeManager.getNextScheduledDate(for: newIncome)
            
            incomeManager.addIncome(newIncome)
            activeSheet = nil // Dismiss the IncomeView
        }
    }

}

#Preview {
    IncomeView(mainViewBalance: .constant(100.0), activeSheet: .constant(.incomeView))
        .environmentObject(IncomeManager())
}
