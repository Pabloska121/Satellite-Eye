import SwiftUI

struct CustomARViewRepresentable: UIViewRepresentable {
    @ObservedObject var satelliteInfo: SatelliteInfo

    func makeUIView(context: Context) -> CustomARView {
        return CustomARView(frame: UIScreen.main.bounds, satelliteInfo: satelliteInfo)  // Pasar satelliteInfo al inicializador
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}
