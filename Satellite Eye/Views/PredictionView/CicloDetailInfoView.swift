import SwiftUI

struct CicloDetailInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var horaInicio: String
    var horaFin: String
    var pass: (Date, Date, Double, Date, Visibility, String, Double)
    
    var body: some View {
        HStack {
            VStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: Color.white.opacity(0.1), radius: 15, x: 0, y: 5)
                    .frame(width: 180, height: 80)
                    .overlay {
                        VStack(spacing: 3) {
                            HStack {
                                Image(systemName: "arrow.up.to.line.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.blue.opacity(0.6))
                                Text(horaInicio)
                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                            }
                            HStack {
                                Image(systemName: "arrow.down.to.line.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.blue.opacity(0.6))
                                Text(horaFin)
                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 10) // Espaciado interno arriba y abajo
                    }
                HStack {
                    Image(systemName: "angle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("\(String(format: "%.2f", pass.2))º")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.bottom, 2)
            }
            .padding(.trailing, 15)
            VStack {
                HStack {
                    Text(pass.4.description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.89, green: 0.51, blue: 0.259)) // Color del texto
                        .padding(.horizontal, 12) // Espaciado horizontal
                        .padding(.vertical, 6) // Espaciado vertical
                        .background(
                            RoundedRectangle(cornerRadius: 20) // Forma redondeada
                                .fill(Color.yellow.opacity(0.2)) // Fondo amarillo semi-transparente
                        )
                }
                if pass.5 == "" {
                    Image(systemName: "questionmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                        .frame(alignment: .center)
                } else {
                    Image(pass.5)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60, alignment: .center)
                }
                Text("mag: \(String(format: "%.2f", pass.6))º")
                    .font(.custom("Poppins-Black", size: 16))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }
}
