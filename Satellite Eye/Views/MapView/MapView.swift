import SwiftUI
import MapKit
import BottomSheet

struct MapView: View {
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var satelliteInfo: SatelliteInfo
    @ObservedObject var settingsModel: SettingsModel
    @ObservedObject var notify: NotificationHandler
    @ObservedObject var locationManager: Location

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var path: [CLLocationCoordinate2D] = []
    @State private var nightArea: [CLLocationCoordinate2D] = []
    @State private var suncoord = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

    @State private var isStandardMapStyle = true
    @State private var initialSetupDone = false
    @State var bottomSheetPosition: BottomSheetPosition = .hidden

    private var satelliteUpdateInterval: TimeInterval = 1.0
    private var sunUpdateInterval: TimeInterval = 30.0

    @State private var satelliteTimer: DispatchSourceTimer?
    @State private var sunTimer: DispatchSourceTimer?

    @Binding var selectedView: Int
    
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
            Map(position: $cameraPosition) {
                // Mapa de la zona de noche
                MapPolygon(coordinates: nightArea)
                    .foregroundStyle(.black.opacity(0.3))
                
                // Posición del Sol
                Annotation("", coordinate: suncoord) {
                    Image("sun")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                
                // Posición del Satélite
                if let position = satelliteInfo.position {
                    Annotation(position.name, coordinate: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)) {
                        Button(action: focusOnSatellite) {
                            Image("satelite")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                
                // Trayectoria del Satélite
                MapPolyline(coordinates: path)
                    .stroke(.red, lineWidth: 2)
                
                // Usuario
                UserAnnotation()
            }
            .mapStyle(isStandardMapStyle ? .standard : .hybrid)
            .mapControls {
                MapCompass()
            }
            // Controles de cámara y estilo
            MapControlsView(cameraPosition: $cameraPosition, isStandardMapStyle: $isStandardMapStyle)
            
            // Display de información satélite
            DisplayView(satelliteInfo: satelliteInfo)
            
        }
        .onAppear(perform: initializeMap)
        .onDisappear(perform: stopTimers)
        /*
        .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [.relativeTop(0.85)], headerContent: {
        }) {
            
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
         */
    }

    private func initializeMap() {
        locationManager.requestLocation { _ in }
        requestNotifications()
        setupInitialData()
        refreshPathandCamera()
        setupTimers()
    }

    private func requestNotifications() {
        notify.askPermission { _ in }
    }
    
    private func setupInitialData() {
        guard !initialSetupDone else { return }
        Task {
            // Inicializamos con el primer satélite que puede ser el ISS (ZARYA) o cualquier otro
            satelliteManager.fetchSatelliteData(satelliteName: "ISS (ZARYA)")  // Cargamos los datos del satélite seleccionado
            await updateSunData()
            refreshPathandCamera()
            initialSetupDone = true
        }
    }
    
    private func refreshPathandCamera() {
        Task {
            if let selectedSatellite = satelliteManager.selectedSatellite {
                await SatelliteInfo.requestSatelliteData(satelliteInfo: satelliteInfo, selectedSatellite, lat_et: locationManager.lat_et, lon_et: locationManager.lon_et, observerAlt: locationManager.alt)
                updateCameraPosition()
            }
            await updatePath()
        }
    }

    private func setupTimers() {
        // Temporizador para actualización del satélite cada 2 segundos
        satelliteTimer = DispatchSource.makeTimerSource()
        satelliteTimer?.schedule(deadline: .now(), repeating: satelliteUpdateInterval)
        satelliteTimer?.setEventHandler {
            Task { await updateSatelliteInfo() }
        }
        satelliteTimer?.resume()

        // Temporizador para actualización del sol cada 30 segundos
        sunTimer = DispatchSource.makeTimerSource()
        sunTimer?.schedule(deadline: .now(), repeating: sunUpdateInterval)
        sunTimer?.setEventHandler {
            Task { await updateSunData() }
        }
        sunTimer?.resume()
    }

    private func stopTimers() {
        satelliteTimer?.cancel()
        satelliteTimer = nil
        sunTimer?.cancel()
        sunTimer = nil
    }

    private func focusOnSatellite() {
        if let position = satelliteInfo.position {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
                )
            )
        }
    }

    private func updateSatelliteInfo() async {
        if let selectedSatellite = satelliteManager.selectedSatellite {
            await SatelliteInfo.requestSatelliteData(satelliteInfo: satelliteInfo, selectedSatellite, lat_et: locationManager.lat_et, lon_et: locationManager.lon_et, observerAlt: locationManager.alt)
        }
    }

    private func updatePath() async {
        if let selectedSatellite = satelliteManager.selectedSatellite {
            path = []
            let coord = Path(parameters: selectedSatellite)
            var cordenadas_path: [CLLocationCoordinate2D] = []
            for coordinates in coord {
                let latitude = coordinates[0]
                let longitude = coordinates[1]
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                cordenadas_path.append(coordinate)
            }
            path = cordenadas_path
        }
    }

    private func updateSunData() async {
        nightArea = NightBorder.Get_border(t_now: Date())

        let suncoordxyz = Extra.calculateSolarPosition(timedt: Date())
        let latitude = atan2(suncoordxyz.2, sqrt(suncoordxyz.0 * suncoordxyz.0 + suncoordxyz.1 * suncoordxyz.1)) * 180 / .pi
        let longitude = atan2(suncoordxyz.1, suncoordxyz.0) * 180 / .pi
        suncoord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func updateCameraPosition() {
        let latitude = satelliteInfo.position?.latitude ?? 0.0
        let longitude = satelliteInfo.position?.longitude ?? 0.0
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 45)
        )
        cameraPosition = .region(region)
    }
}
