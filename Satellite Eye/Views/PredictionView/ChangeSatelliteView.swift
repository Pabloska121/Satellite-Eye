import SwiftUI

struct ChangeSatelliteView: View {
    @ObservedObject var satelliteInfo: SatelliteInfo

    @Binding var selectedView: Int
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        selectedView = 2
                    }, label: {
                        HStack {
                            Text("Change Current Satellite: \(satelliteInfo.position?.name ?? "Unknown")")
                                .font(.callout.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.callout)
                        }
                        .padding(7)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    })
                }
                .shadow(color: .gray.opacity(0.5), radius: 1)
                Spacer()
            }
        }
        .padding(.top, 10)
    }
}
