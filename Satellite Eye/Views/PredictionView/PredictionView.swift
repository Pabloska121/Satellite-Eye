import SwiftUI
import MapKit
import BottomSheet

struct PredictionView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var satelliteInfo: SatelliteInfo
    @ObservedObject var locationManager: Location
    @ObservedObject var settingsModel: SettingsModel
    @ObservedObject var notify: NotificationHandler
    @State var bottomSheetPosition: BottomSheetPosition = .hidden
    @State var hasDragged: Bool = false
    @State private var utcTime = Date() // Hora UTC de la predicción
    @State private var passes: [(Date, Date, Double, Date, Visibility, String)] = [] // Pasajes de satélites
    @State private var isLoading = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var path: [CLLocationCoordinate2D] = []
    @State private var predictionDone: Bool = false
    @State private var actualpass: (Date, Date, Double, Date, Visibility, String) = (Date(), Date(), 0.0, Date(), .none, "")
    @Binding var selectedView: Int
    
    @Environment(\.colorScheme) var colorScheme
    
    init(satelliteManager: SatelliteManager, satelliteInfo: SatelliteInfo, locationManager: Location, selectedView: Binding<Int>, settingsModel: SettingsModel, notify: NotificationHandler) {
        self.satelliteManager = satelliteManager
        self.satelliteInfo = satelliteInfo
        self.locationManager = locationManager
        self._selectedView = selectedView
        self.settingsModel = settingsModel
        self.notify = notify
    }
    
    var body: some View {
        ZStack {
            backgroundGradient()
            
            VStack {
                headerView()
                titleView()
                predictionContentView()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all).opacity(0.1))
        .onAppear {
            Task {
                await calculatePredictions()
            }
        }
        .onDisappear {
            predictionDone.toggle()
        }
        .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [.relativeTop(0.85)], headerContent: {
            sheetHeaderView()
        }) {
            SheetView(notify: notify, satelliteInfo: satelliteInfo, cameraPosition: $cameraPosition, path: $path, actualpass: $actualpass)
        }
        .customAnimation(.linear.speed(1.2))
        .customBackground(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.white.opacity(0.25))
                .background(Blur(radius: 15, opaque: true))
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .overlay {
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                }
        )
        .sheetWidth(.relative(1))
        .showCloseButton()
        .enableTapToDismiss()
        .enableSwipeToDismiss()
        .enableContentDrag()
        .showDragIndicator()
        .foregroundStyle(.white)
    }
    
    // Función para mostrar el fondo
    private func backgroundGradient() -> some View {
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
    }
    
    // Vista para el encabezado
    private func headerView() -> some View {
        ChangeSatelliteView(satelliteInfo: satelliteInfo, selectedView: $selectedView)
    }
    
    // Vista para el título de la predicción
    private func titleView() -> some View {
        HStack {
            Text("Prediction")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.white)
            Spacer()
        }
        .padding([.leading, .bottom])
    }
    
    // Vista que muestra las predicciones o el indicador de carga
    private func predictionContentView() -> some View {
        Group {
            if predictionDone {
                PassesView(satelliteManager: satelliteManager, locationManager: locationManager, passes: $passes, path: $path, cameraPosition: $cameraPosition, isSheetPresented: $bottomSheetPosition, actualpass: $actualpass)
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    // Vista para el encabezado del sheet
    private func sheetHeaderView() -> some View {
        HStack {
            Spacer()
            VStack {
                Text(satelliteInfo.position?.name ?? "Unknown")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.white)
                    .padding(.leading, 25)
            }
            Spacer()
        }
        .padding(.top)
    }

    // Función para calcular las predicciones
    private func calculatePredictions() async {
        // Asegurarnos de que hay un satélite seleccionado antes de proceder
        guard let selectedSatellite = satelliteManager.selectedSatellite else {
            return
        }
        
        // Crear una instancia de SatelliteCalc para obtener las predicciones de pasajes
        let satelliteCalc = SatelliteCalc(tle: selectedSatellite)
        
        var passes_tuple = satelliteCalc.getNextPasses(utcTime2: utcTime, length: 24 * settingsModel.predictionDays, lon: locationManager.lon_et, lat: locationManager.lat_et, alt: locationManager.alt, sunriseDeg: settingsModel.twilightAngle)
        
        if settingsModel.showVisibleOnly {
            passes_tuple = passes_tuple.filter { pass in
                pass.4 == .visible
            }
        }
        
        do {
            passes = try await addMeteo(passesTuple: passes_tuple, colorScheme: colorScheme)
            
            var magnitudes: [Double] = [] // Para almacenar las magnitudes aparentes por pasaje

            for pass in passes {
                let maxTime = pass.3

                let apparentMagnitude = satelliteCalc.getApparentMagnitude(utcTime: maxTime, observerLon: locationManager.lon_et, observerLat: locationManager.lat_et, observerAlt: locationManager.alt)

                magnitudes.append(apparentMagnitude)
            }
        } catch {
            print("Error al añadir meteo: \(error)")
            passes = []
        }
        
        predictionDone = true
    }
    
    private func addMeteo(passesTuple: [(Date, Date, Double, Date, Visibility)], colorScheme: ColorScheme) async throws -> [(Date, Date, Double, Date, Visibility, String)] {
        var updatedPasses: [(Date, Date, Double, Date, Visibility, String)] = []
        let targetDates: [Date] = passesTuple.map { $0.0 }
        
        let weatherService = MetWeatherService()
        let colorString = colorScheme == .dark ? "darkmode" : "lightmode"
        let weather = try await weatherService.getWeatherForDate(
            loc: Loc(lat: locationManager.lat_et, lon: locationManager.lon_et),
            targetDates: targetDates,
            mode: colorString
        )
        
        for (index, pass) in passesTuple.enumerated() {
            let (startDate, endDate, value, maxDate, visibility) = pass
            let weatherType = weather[index].weatherType
            updatedPasses.append((startDate, endDate, value, maxDate, visibility, weatherType))
        }
        return updatedPasses
    }
}
