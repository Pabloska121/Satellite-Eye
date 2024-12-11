import SwiftUI
import MapKit

struct PredictionView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var satelliteInfo: SatelliteInfo
    @ObservedObject var locationManager: Location
    @ObservedObject var settingsModel: SettingsModel
    @State private var utcTime = Date() // Hora UTC de la predicción
    @State private var passes: [(Date, Date, Double, Visibility, String)] = [] // Pasajes de satélites
    @State private var isLoading = false // Para mostrar un indicador de carga
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var path: [CLLocationCoordinate2D] = []
    @State private var predictionDone: Bool = false
    @Binding var selectedView: Int
    
    @Environment(\.colorScheme) var colorScheme
    
    init(satelliteManager: SatelliteManager, satelliteInfo: SatelliteInfo, locationManager: Location, selectedView: Binding<Int>, settingsModel: SettingsModel) {
        self.satelliteManager = satelliteManager
        self.satelliteInfo = satelliteInfo
        self.locationManager = locationManager
        self._selectedView = selectedView
        self.settingsModel = settingsModel
    }
    
    var body: some View {
        VStack {
            // Header con botón para cambiar el satélite actual
            ChangeSatelliteView(satelliteInfo: satelliteInfo, selectedView: $selectedView)
            
            // Título de la predicción
            HStack {
                Text("Prediction")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding([.leading, .bottom])
            
            // Vista de las predicciones agrupadas por día
            if predictionDone {
                PassesView(colorScheme: _colorScheme, satelliteManager: satelliteManager, locationManager: locationManager, passes: $passes, path: $path, cameraPosition: $cameraPosition)
                
            }else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Mapa con la predicción visualizada
            VStack {
                Map(position: $cameraPosition) {
                    MapPolyline(coordinates: path)
                        .stroke(.red, lineWidth: 2)
                }
                .frame(height: 250)
                .cornerRadius(20)
                .padding()
            }
            .shadow(color: .gray.opacity(0.5), radius: 1)
        }
        .background(.thinMaterial)
        .onAppear {
            Task {
                await calculatePredictions()
            }
        }
    }
    
    // Función para calcular las predicciones
    private func calculatePredictions() async {
        // Asegurarnos de que hay un satélite seleccionado antes de proceder
        guard let selectedSatellite = satelliteManager.selectedSatellite else {
            return
        }
        
        // Crear una instancia de SatelliteCalc para obtener las predicciones de pasajes
        let satelliteCalc = SatelliteCalc(tle: selectedSatellite)
        
        var passes_tuple = satelliteCalc.getNextPasses(utcTime: utcTime, length: 24 * settingsModel.predictionDays, lon: locationManager.lon_et, lat: locationManager.lat_et, alt: locationManager.alt, sunriseDeg: settingsModel.twilightAngle)
        
        if settingsModel.showVisibleOnly {
            passes_tuple = passes_tuple.filter { pass in
                pass.3 == .visible
            }
        }
        
        do {
            passes = try await addMeteo(passesTuple: passes_tuple, colorScheme: colorScheme)
        } catch {
            print("Error al añadir meteo: \(error)")
            passes = []
        }

        predictionDone = true
        
    }
    
    private func addMeteo(passesTuple: [(Date, Date, Double, Visibility)], colorScheme: ColorScheme) async throws -> [(Date, Date, Double, Visibility, String)] {
        var updatedPasses: [(Date, Date, Double, Visibility, String)] = []
        let targetDates: [Date] = passesTuple.map { $0.0 }
        
        let weatherService = MetWeatherService()
        let colorString = colorScheme == .dark ? "darkmode" : "lightmode"
        let weather = try await weatherService.getWeatherForDate(
            loc: Loc(lat: locationManager.lat_et, lon: locationManager.lon_et),
            targetDates: targetDates,
            mode: colorString
        )
        for (index, (startDate, endDate, value, visibility)) in passesTuple.enumerated() {
            // Asegurarnos de que la fecha esté en el mismo índice que la fecha de weather
            let weatherType = weather[index].weatherType
            updatedPasses.append((startDate, endDate, value, visibility, weatherType))
        }
        return updatedPasses
    }
}
