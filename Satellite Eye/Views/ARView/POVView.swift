import SwiftUI
import RealityKit
import ARKit

struct POVView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var satelliteInfo: SatelliteInfo
    @ObservedObject var locationManager: Location
    
    @State private var satelliteTimer: DispatchSourceTimer?
    @State private var compassxpos: CGFloat = UIScreen.main.bounds.minX + 80
    @State private var compassypos: CGFloat = UIScreen.main.bounds.maxY - 230
    @State private var centercompass: Bool = false
    
    private var satelliteUpdateInterval: TimeInterval = 1.0
    
    @Binding var selectedView: Int
    
    @Environment(\.colorScheme) var colorScheme
    
    init(satelliteManager: SatelliteManager, satelliteInfo: SatelliteInfo, locationManager: Location, selectedView: Binding<Int>) {
        self.satelliteManager = satelliteManager
        self.satelliteInfo = satelliteInfo
        self.locationManager = locationManager
        self._selectedView = selectedView
    }
    
    var body: some View {
        ZStack {
            CustomARViewRepresentable(satelliteInfo: satelliteInfo)
            CompassView(locationManager: locationManager)
                .scaleEffect(centercompass ? 1.0 : 0.4)
                .position(x: centercompass ? UIScreen.main.bounds.midX : UIScreen.main.bounds.minX + 80, y: centercompass ? UIScreen.main.bounds.midY : UIScreen.main.bounds.maxY - 240)
                .zIndex(1)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3)) {
                        centercompass.toggle()
                    }
                }
        }
        .onAppear(perform: setupTimers)
        .onDisappear(perform: stopTimers)
    }
    
    private func setupTimers() {
        satelliteTimer = DispatchSource.makeTimerSource()
        satelliteTimer?.schedule(deadline: .now(), repeating: satelliteUpdateInterval)
        satelliteTimer?.setEventHandler {
            Task { await updateSatelliteInfo() }
        }
        satelliteTimer?.resume()
    }
    
    private func updateSatelliteInfo() async {
        if let selectedSatellite = satelliteManager.selectedSatellite {
            await SatelliteInfo.requestSatelliteData(satelliteInfo: satelliteInfo, selectedSatellite, lat_et: locationManager.lat_et, lon_et: locationManager.lon_et, observerAlt: locationManager.alt)
        }
    }
    
    private func stopTimers() {
        satelliteTimer?.cancel()
    }
}
