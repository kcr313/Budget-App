import SwiftUI

struct BeginningBudgetView: View {
    @EnvironmentObject var incomeManager: IncomeManager
    
    @Binding var mainViewBalance: Double // Binding to update the balance in MainView
    @Binding var activeSheet: ActiveSheet?
    
    @State private var incomeName = "Aylık Bütçen"
    @State private var incomeAmount = ""
    
    //let incomeCategoryOptions = ["Beginning Budget"]
    let selectedCategory = "Aylık Bütçe" //Default category
    let selectedFrequency = "Her Ay"
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center){
                
                Spacer()
                
                TextField("1234.56*", text: $incomeAmount)
                    .multilineTextAlignment(.center)
                    //.border(Color.black)
                    .padding(.horizontal, 15.0)
                    .keyboardType(.decimalPad) // Use .decimalPad for decimal input
                    .font(.system(size: 75))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { addIncome() })
                {
                    Image(systemName: "plus.circle.fill")
                        //.font(.largeTitle)
                        .font(.system(size: 60))
                        .foregroundColor(incomeAmount.isEmpty ? .gray : .green)
                        .background(Color.clear)
                }
                .disabled(incomeAmount.isEmpty) // Disable the button if fields are empty
                .padding()
                
                Text("*Aylık hacadığın miktar")
                    .fontWeight(.thin)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("SET MONTHLY BUDGET")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func addIncome(){
        
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            // Preprocess the input to replace commas with periods
            // Validate and update balance
            if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
                mainViewBalance = number
                
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM"
                let monthName = dateFormatter.string(from: currentDate)
                
                // Update UserDefaults balance value here
                UserDefaults.standard.set(mainViewBalance, forKey: "balance")
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                updateMonthlyBudget(newBudget: number)
                UserDefaults.standard.synchronize() // Force immediate synchronization
                let newIncome = Income(name: "Budget for \(monthName)", category: "Monthly budget", amount: number, frequency: "Every month", customYear: nil, customMonth: nil, customDay: nil, creationDate: Date())
                incomeManager.addIncome(newIncome)
            }
        }
        else {
            if let number = Double(incomeAmount.replacingOccurrences(of: ",", with: ".")) {
                updateMonthlyBudget(newBudget: number)
            }
        }
        
        activeSheet = nil // Dismiss the IncomeView
    }
    
    func updateMonthlyBudget(newBudget: Double) {
        UserDefaults.standard.set(newBudget, forKey: "nextMonthBudget")
        print("Next month's budget set to \(newBudget)")
    }
}

#Preview {
    BeginningBudgetView(mainViewBalance: .constant(100.0), activeSheet: .constant(.beginningBudgetView))
        .environmentObject(IncomeManager())
}
