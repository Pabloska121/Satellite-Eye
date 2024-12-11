import SwiftUI
import MapKit

struct PassesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    
    @ObservedObject var satelliteManager: SatelliteManager
    @ObservedObject var locationManager: Location
    @Binding var passes: [(Date, Date, Double, Visibility, String)]
    @Binding var path: [CLLocationCoordinate2D]
    @Binding var cameraPosition: MapCameraPosition
    
    var body: some View {
        VStack {
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
                    HStack {
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
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.horizontal)
    }
    
    private func agruparPasesPorDia(passes: [(Date, Date, Double, Visibility, String)]) -> [(String, [(Date, Date, Double, Visibility, String)])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        var pasesAgrupados: [(String, [(Date, Date, Double, Visibility, String)])] = []
        var currentDay: String? = nil
        var currentPasses: [(Date, Date, Double, Visibility, String)] = []
        
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
    
    private func displayPredictionPath(for pass: (Date, Date, Double, Visibility, String)) {
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
                    span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
                ))
            }
        }
    }
    
    // Vista de detalle de cada pase
    private func cicloDetailView(pass: (Date, Date, Double, Visibility, String)) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy" // Formato completo de fecha "Monday 11/11/2024"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss" // Formato de hora "04:40:29"

        let horaInicio = timeFormatter.string(from: pass.0)
        let horaFin = timeFormatter.string(from: pass.1)

        return HStack {
            VStack {
                HStack {
                    Image(systemName: "arrow.up.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(horaInicio)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .font(.title3)
                    Divider()
                    Image(systemName: "arrow.down.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(horaFin)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .font(.title3)
                }
                HStack {
                    Image(systemName: "angle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("Max elev: \(String(format: "%.2f", pass.2))º")
                        .font(.title3)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.bottom, 2)
                HStack {
                    if pass.3 == .visible {
                        Image(systemName: "eye")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "eye.slash")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    Text(pass.3.description)
                        .font(.title3)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            Spacer()
            Divider()
            Spacer()
            if pass.4 == "" {
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                    .frame(alignment: .center)
            } else {
                Image(pass.4)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50, alignment: .center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.bottom)
    }
}
