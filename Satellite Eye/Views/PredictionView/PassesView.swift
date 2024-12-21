import SwiftUI
import BottomSheet
import MapKit

struct PassesView: View {
    
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var locationManager: Location
    @Binding var passes: [(Date, Date, Double, Date, Visibility, String)]
    @Binding var path: [CLLocationCoordinate2D]
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isSheetPresented: BottomSheetPosition
    @Binding var actualpass: (Date, Date, Double, Date, Visibility, String)
    
    var body: some View {

            if passes.count == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Not Visible")
                            .font(.title2)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack {
                        // Agrupamos los pases por día en una lista ordenada
                        let groupedPasses = agruparPasesPorDia(passes: passes)
                        
                        ForEach(groupedPasses, id: \.0) { (day, dayPasses) in
                            // Título del día
                            Text(day)
                                .font(.headline)
                                .padding(.top)
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                            
                            // Mostrar cada pase para el día actual
                            ForEach(dayPasses, id: \.0) { pass in
                                Button {
                                    displayPredictionPath(for: pass)
                                    actualpass = pass
                                    self.isSheetPresented = .relative(0.85)
                                } label: {
                                    HStack {
                                        cicloDetailView(pass: pass)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }

    }
    
    private func agruparPasesPorDia(passes: [(Date, Date, Double, Date, Visibility, String)]) -> [(String, [(Date, Date, Double, Date, Visibility, String)])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        var pasesAgrupados: [(String, [(Date, Date, Double, Date, Visibility, String)])] = []
        var currentDay: String? = nil
        var currentPasses: [(Date, Date, Double, Date, Visibility, String)] = []
        
        for pass in passes {
            let dayKey = dateFormatter.string(from: pass.0)
            
            // Si cambiamos de día, guardamos el día anterior en la lista agrupada
            if dayKey != currentDay {
                if let currentDay = currentDay {
                    pasesAgrupados.append((currentDay, currentPasses))
                }
                // Reiniciamos el día y los pases
                currentDay = dayKey
                currentPasses = [pass]
            } else {
                // Si es el mismo día, agregamos el pase al día actual
                currentPasses.append(pass)
            }
        }
        
        // Agregar el último día y sus pases si existe
        if let currentDay = currentDay {
            pasesAgrupados.append((currentDay, currentPasses))
        }
        
        return pasesAgrupados
    }
    
    private func displayPredictionPath(for pass: (Date, Date, Double, Date, Visibility, String)) {
        path = []
        guard let selectedSatellite = satelliteManager.selectedSatellite else { return }
        
        let coord = PredictionPath(parameters: selectedSatellite, startDate: pass.0, endDate: pass.1)
        var cordenadasPath: [CLLocationCoordinate2D] = []
        
        for coordinates in coord {
            let latitude = coordinates[0]
            let longitude = coordinates[1]
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            cordenadasPath.append(coordinate)
        }
        
        path = cordenadasPath
        
        locationManager.requestLocation { location in
            if let location = location {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 35)
                ))
            }
        }
    }
    
    // Vista de detalle de cada pase
    private func cicloDetailView(pass: (Date, Date, Double, Date, Visibility, String)) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        let horaInicio = timeFormatter.string(from: pass.0)
        let horaFin = timeFormatter.string(from: pass.1)

        return VStack {
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.25))
                    .background(Blur(radius: 15, opaque: true))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: Color.white.opacity(0.1), radius: 15, x: 0, y: 5)
                    .frame(width: UIScreen.main.bounds.width - 50, height: 120)
                    .overlay {
                        CicloDetailInfoView(horaInicio: horaInicio, horaFin: horaFin, pass: pass)
                    }
            }
           
        }
    }
}
