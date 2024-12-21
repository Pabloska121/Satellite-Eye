import SwiftUI

struct CicloDetailInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var horaInicio: String
    var horaFin: String
    var pass: (Date, Date, Double, Date, Visibility, String)
    
    var body: some View {
        
        HStack {
            VStack {
                HStack {
                    Image(systemName: "arrow.up.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(horaInicio)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .font(.title3)
                    Divider()
                    Image(systemName: "arrow.down.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(horaFin)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .font(.title3)
                }
                HStack {
                    Image(systemName: "angle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("Max elev: \(String(format: "%.2f", pass.2))º")
                        .font(.title3)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.bottom, 2)
                HStack {
                    if pass.4 == .visible {
                        Image(systemName: "eye")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "eye.slash")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    Text(pass.4.description)
                        .font(.title3)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            Spacer()
            Divider()
            Spacer()
            if pass.5 == "" {
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                    .frame(alignment: .center)
            } else {
                Image(pass.5)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50, alignment: .center)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.bottom)
    }
}
