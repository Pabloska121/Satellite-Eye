import SwiftUI
import MapKit

struct MapControlsView: View {
    @State private var isLocalizationPressed = false
    @State private var isMapPressed = false
    
    @StateObject private var locationManager = Location()
    
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isStandardMapStyle: Bool
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            isMapPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                isMapPressed = false
                            }
                        }
                        isStandardMapStyle.toggle()
                    }) {
                        Image(systemName: isMapPressed ? "map.fill" : "map")
                            .font(.title3)
                            .padding(9)
                            .background(
                                .thickMaterial)
                            .clipShape(
                                .rect(topLeadingRadius: 8, topTrailingRadius: 8)
                            )
                            .foregroundStyle(isMapPressed ? Color.blue : Color.gray)
                            .overlay(
                                Image(systemName: isMapPressed ? "map.fill" : "map")
                                    .font(.title3)
                                    .foregroundStyle(isMapPressed ? Color.blue : Color.gray)
                                    .scaleEffect(isMapPressed ? 1.3 : 1.0)
                            )
                    }
                    Divider()
                        .frame(width: 40, height: 0.3)
                    Button(action: {
                        withAnimation {
                            isLocalizationPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                isLocalizationPressed = false
                            }
                        }
                        
                        locationManager.requestLocation { location in
                            if let location = location {
                                cameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)))
                            }
                        }
                    }) {
                        Image(systemName: isLocalizationPressed ? "location.fill" : "location")
                            .font(.title3)
                            .padding(10)
                            .background(.thickMaterial)
                            .foregroundStyle(isLocalizationPressed ? Color.blue : Color.gray)
                            .clipShape(
                                .rect(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                            )
                            .foregroundStyle(isLocalizationPressed ? Color.blue : Color.gray)
                            .overlay(
                                Image(systemName: isLocalizationPressed ? "location.fill" : "location")
                                    .font(.title3)
                                    .foregroundStyle(isLocalizationPressed ? Color.blue : Color.gray)
                                    .scaleEffect(isLocalizationPressed ? 1.3 : 1.0)
                            )
                    }
                    Spacer()
                }
                .padding(.top, 30.0)
            }
            .padding(.trailing)
        }
    }
}
