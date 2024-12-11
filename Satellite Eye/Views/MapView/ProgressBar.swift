import SwiftUI
import MapKit

struct ProgressBar: View {
    @ObservedObject var satelliteManager: SatelliteManager
    
    var width: CGFloat = 300
    var height: CGFloat = 12
    var CRadius: CGFloat = 10

    @State private var showCompleted = false

    var body: some View {
        ZStack {
            Map()
            VStack(alignment: .leading, spacing: 7) {
                headerView()
                progressBarView()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0.0, y: 0.0)
            .onChange(of: satelliteManager.downloadProgress) {
                handleProgressChange()
            }
        }
    }
    
    /// Vista del encabezado con el texto y el ícono
    private func headerView() -> some View {
        HStack {
            if showCompleted {
                Text("Download Completed!")
                    .bold()
                    .font(.callout)
                    .foregroundColor(.green)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            satelliteManager.isLoading = false
                        }
                    }
            } else {
                Text("\(Int(satelliteManager.downloadProgress * 100)) % To Complete")
                    .bold()
                    .font(.callout)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            Spacer()
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.7))
        }
        .frame(width: width)
    }
    
    /// Vista de la barra de progreso
    private func progressBarView() -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: CRadius)
                .frame(width: width, height: height)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .cyan]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(0.05)
                )
            
            RoundedRectangle(cornerRadius: CRadius)
                .frame(width: satelliteManager.downloadProgress * width, height: height)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .cyan]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
    
    /// Manejar el cambio de progreso
    private func handleProgressChange() {
        if satelliteManager.downloadProgress >= 1.0 {
            withAnimation(.easeInOut(duration: 1.0)) {
                showCompleted = true
            }
        } else {
            showCompleted = false
        }
    }
}
