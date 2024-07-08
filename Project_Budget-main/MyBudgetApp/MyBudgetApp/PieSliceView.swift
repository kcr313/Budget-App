import SwiftUI

struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width: CGFloat = min(geometry.size.width, geometry.size.height)
                let height = width
                let center = CGPoint(x: width * 0.5, y: height * 0.5)
                let currentStartAngle = Angle(degrees: startAngle)
                let currentEndAngle = Angle(degrees: endAngle)
                
                path.move(to: center)
                path.addArc(center: center, radius: width * 0.5, startAngle: currentStartAngle, endAngle: currentEndAngle, clockwise: false)
            }
            .fill(color)
        }
    }
}
