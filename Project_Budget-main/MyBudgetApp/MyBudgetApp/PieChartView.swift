import SwiftUI

extension Color{
    static let expense1 = Color(red: 90/255, green: 17/255, blue: 12/255)
    static let expense2 = Color(red: 108/255, green: 21/255, blue: 15/255)
    static let expense3 = Color(red: 126/255, green: 24/255, blue: 17/255)
    static let expense4 = Color(red: 144/255, green: 28/255, blue: 20/255)
    static let expense5 = Color(red: 162/255, green: 31/255, blue: 22/255)
    static let expense6 = Color(red: 180/255, green: 35/255, blue: 24/255)
    static let expense7 = Color(red: 197/255, green: 38/255, blue: 27/255)
    static let expense8 = Color(red: 215/255, green: 42/255, blue: 29/255)
    static let expense9 = Color(red: 226/255, green: 52/255, blue: 40/255)
    
    
    static let income1 = Color(red: 74/255, green: 120/255, blue: 86/255)
    static let income2 = Color(red: 52/255, green: 88/255, blue: 48/255)
    static let income3 = Color(red: 30/255, green: 63/255, blue: 32/255)
    static let income4 = Color(red: 26/255, green: 31/255, blue: 22/255)
}

struct PieChartView: View {
    var data: [PieChartData]
    @Binding var activeSheet: ActiveSheet?
    
    // Compute the angles for each data point
    var angles: [(start: Double, end: Double)] {
        var cumulativeAngle: Double = 0.0
        var result: [(start: Double, end: Double)] = []
        
        for entry in data {
            let percentage = entry.amount / totalAmount
            let start = cumulativeAngle
            cumulativeAngle += 360 * percentage
            let end = cumulativeAngle
            result.append((start, end))
        }
        
        return result
    }
    
    var totalAmount: Double {
        return data.map { $0.amount }.reduce(0, +)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(data, id: \.amount) { entry in
                    if let index = data.firstIndex(where: { $0.amount == entry.amount }) {
                        PieSlice(startAngle: .degrees(self.angles[index].start),
                                 endAngle: .degrees(self.angles[index].end))
                            .fill(entry.color)
                            .onTapGesture {
                                switch entry.type {
                                case .income:
                                    activeSheet = .incomeHistoryView
                                case .expense:
                                    activeSheet = .expenseHistoryView
                                }
                            }
                    }
                }
            }
        }
    }
}

