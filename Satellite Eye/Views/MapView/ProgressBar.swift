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
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.lightGray).opacity(0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.5),
                    Color.black
                ]),
                center: UnitPoint(x: 0.1, y: 1.5),
                startRadius: 650, // Radio inicial
                endRadius: 1200   // Radio final
            )
            .edgesIgnoringSafeArea(.all)
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.4))
                .background(Blur(radius: 15, opaque: true))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
                .shadow(color: Color.white.opacity(0.1), radius: 15, x: 0, y: 5)
                .frame(width: UIScreen.main.bounds.width - 50, height: 80)
                .overlay {
                    VStack(alignment: .leading, spacing: 7) {
                        headerView()
                        progressBarView()
                    }
                }
            .onChange(of: satelliteManager.downloadProgress) {
                handleProgressChange()
            }
        }
    }
    
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
                        Color.white
                    )
            }
            Spacer()
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: width)
    }
    
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
