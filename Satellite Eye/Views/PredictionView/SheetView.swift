import SwiftUI
import MapKit

struct SheetView: View {
    @ObservedObject var notify: NotificationHandler
    @ObservedObject var satelliteInfo: SatelliteInfo
    
    @Binding var cameraPosition: MapCameraPosition
    @Binding var path: [CLLocationCoordinate2D]
    @Binding var actualpass: (Date, Date, Double, Date, Visibility, String, Double)
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE dd/MM/yyyy"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack {
                mapView()
                
                ZStack(alignment: .center) {
                    VStack {
                        infoView()
                        SatelliteShapeView()
                            .offset(x: -13, y: -135)
                        Text(String(format: "%.1f", actualpass.2) + "º")
                            .foregroundStyle(Color.white)
                            .padding(.bottom, 35)
                    }
                }
                .frame(width: 350, height: 200)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 50))
                
                notificationButton()
                    .padding(20)
                    .padding(.bottom, 100)
            }
        }
    }
    
    // Función para crear el mapa y las anotaciones
    private func mapView() -> some View {
        return Map(position: $cameraPosition) {
            MapPolyline(coordinates: path)
                .stroke(.red, lineWidth: 2)
            
            if let firstPoint = path.first {
                Annotation("", coordinate: firstPoint) {
                    Image(systemName: "arrow.up.to.line")
                        .foregroundColor(Color.white)
                        .font(.title)
                }
            }
            
            if let lastPoint = path.last {
                Annotation("", coordinate: lastPoint) {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundColor(Color.white)
                        .font(.title)
                }
            }
            
            UserAnnotation()
        }
        .frame(width: 350, height: 250)
        .cornerRadius(50)
        .padding()
        .shadow(color: .gray.opacity(0.5), radius: 1)
    }
    
    // Función para mostrar la información relacionada con el tiempo y ubicaciones
    private func infoView() -> some View {
        return VStack {
            Text(dateFormatter.string(from: actualpass.3))
                .font(.title2)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .leading, endPoint: .trailing))
                .padding(.top, 15)
            
            HStack {
                VStack {
                    Text(timeFormatter.string(from: actualpass.0))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, 2)
                    Image(systemName: "arrow.up.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .padding(.leading, 18)
                
                Spacer()
                
                VStack {
                    Text(timeFormatter.string(from: actualpass.1))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, 2)
                    Image(systemName: "arrow.down.to.line")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .padding(.trailing, 18)
            }
            .padding(.top, 3)
        }
    }
    
    @State private var isButtonPressed = false

    private func notificationButton() -> some View {
        return VStack {
            HStack(spacing: 20) {
                Button(action: {
                    let notificationTime = Calendar.current.date(byAdding: .minute, value: -5, to: actualpass.0)!
                    
                    // Enviamos la notificación para 5 minutos antes del paso
                    if !isButtonPressed {
                        notify.sendNotification(date: notificationTime, type: "date", title: "\(satelliteInfo.position?.name ?? "Unknown") passing in 5 minutes!", body: "The satellite will pass at \(timeFormatter.string(from: actualpass.0))") { _ in}
                    }
                    // Cambiar el estado del botón para mostrar que está presionado
                    withAnimation(.easeOut(duration: 0.2)) {
                        isButtonPressed = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 50)
                            .fill(LinearGradient(gradient: Gradient(colors: [.cyan, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .background(Blur(radius: 15, opaque: true))
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                            .overlay {
                                RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            }
                            .shadow(color: Color.white.opacity(0.1), radius: 15, x: 0, y: 5)
                            .frame(width: UIScreen.main.bounds.width - 50, height: 60)
                            .overlay {
                                VStack {
                                    Spacer()
                                    if isButtonPressed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .transition(.scale)
                                    } else {
                                        Text("Set a reminder for satellite pass")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding()
                                    }
                                    Spacer()
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
