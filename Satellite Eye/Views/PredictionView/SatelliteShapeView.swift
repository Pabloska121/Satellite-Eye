import SwiftUI

struct SatelliteShapeView: View {
    @State private var angle: Double = -45
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let radius = min(geometry.size.width, geometry.size.height) / 2
                    ZStack {
                        Color.clear
                        ArcShape(startAngle: .degrees(-135), endAngle: .degrees(-45))
                            .stroke(Color.yellow.opacity(0.2), style: StrokeStyle(lineWidth: 20.0, lineCap: .round))
                            .frame(width: 360, height: 360)
                        ArcShape(startAngle: .degrees(-105), endAngle: .degrees(-75))
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 20.0, lineCap: .round))
                            .frame(width: 360, height: 360)
                        DomeShape()
                            .stroke(Color.yellow.opacity(0.35), style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                            .frame(width: 112, height: 60)
                        DomeShapeInterior()
                            .fill(Color.yellow.opacity(0.35))
                            .frame(width: 112, height: 60)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 13, height: 13)
                            .position(pointAtAngle(degrees: -90, center: center, radius: radius))
                            .rotationEffect(.degrees(angle + 4))
                            .offset(y: 135.2)
                        SatelliteShape()
                            .frame(width: 20, height: 20)
                            .position(pointAtAngle(degrees: -90, center: center, radius: radius + 25))
                            .rotationEffect(.degrees(angle + 4))
                            .offset(y: 135.2)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                            angle = 45
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
    }
    
    func pointAtAngle(degrees: CGFloat, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angleInRadians = Angle(degrees: degrees).radians
        let x = center.x + radius * cos(angleInRadians)
        let y = center.y + radius * sin(angleInRadians)
        return CGPoint(x: x, y: y)
    }
}

struct SatelliteShape: View {
    var body: some View {
        HStack(spacing: 2) {
            Rectangle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 1, height: 15)
                .padding(.horizontal, 3.0)
            Rectangle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 1, height: 15)
                .padding(.trailing, 1.5)
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
            Rectangle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 1, height: 15)
                .padding(.leading, 1.5)
            Rectangle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 1, height: 15)
                .padding(.horizontal, 3.0)
        }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Definimos el centro del arco en el borde superior
        let center = CGPoint(x: rect.midX, y: rect.midY + 135.2) // El centro está en la parte inferior
        let radius = min(rect.size.width, rect.size.height) / 2
        
        // Creamos el arco con el mismo radio
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return path
    }
}

struct DomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY - 120 + 135.2)
        let topLeft = CGPoint(x: rect.minX + 9, y: -rect.maxY - 84 + 135.2)
        let topRight = CGPoint(x: rect.maxX - 9, y: -rect.maxY - 84 + 135.2)
        
        path.move(to: topLeft)
        path.addLine(to: center)
        path.addLine(to: topRight)
        path.addQuadCurve(to: topLeft, control: CGPoint(x: rect.midX, y: -156 + 135.2))
        
        path.closeSubpath()
        return path
    }
}

struct DomeShapeInterior: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let topLeft = CGPoint(x: rect.minX + 22.2, y: -rect.maxY - 84 + 135.2)
        let topRight = CGPoint(x: rect.maxX - 22.2, y: -rect.maxY - 84 + 135.2)
        
        path.move(to: topLeft)
        path.addLine(to: center)
        path.addLine(to: topRight)
        path.addQuadCurve(to: topLeft, control: CGPoint(x: rect.midX, y: -156 + 135.2))
        
        path.closeSubpath()
        return path
    }
}

struct SatelliteShapeView_Previews: PreviewProvider {
    static var previews: some View {
        SatelliteShapeView()
    }
}
