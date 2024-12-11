import SwiftUI

struct DisplayView: View {
    @ObservedObject var satelliteInfo: SatelliteInfo
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var show = false
    
    @Namespace var namespace
    
    var body: some View {
        ZStack {
            if !show {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            Text("Display satellite information")
                                .font(.callout.weight(.medium))
                                .matchedGeometryEffect(id: "title", in: namespace)
                            Image(systemName: "chevron.right")
                                .font(.callout)
                        }
                        .padding(7)
                        .foregroundStyle(.blue)
                        .background(.thinMaterial)
                        .matchedGeometryEffect(id: "background", in: namespace)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .shadow(color: .gray.opacity(0.5), radius: 1)
                    .padding(.bottom)
                    Spacer()
                }
            } else {
                VStack {
                    satelliteInfoView()
                }
                .padding([.leading, .bottom, .trailing])
            }
        }
        .onTapGesture {
            withAnimation {
                show.toggle()
            }
        }
    }
    
    private func satelliteInfoView() -> some View {
        VStack {
            if let position = satelliteInfo.position {
                Spacer()
                VStack {
                    HStack {
                        Text("\(position.name)")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .gray : .black)
                            .textCase(.uppercase)
                            
                    }
                    .matchedGeometryEffect(id: "background", in: namespace)
                    
                    Divider()
                    
                    HStack(spacing: 0) {
                        Spacer()
                        coordinateView(label: "LAT", value: position.latitude, unit: "º")
                        Spacer()
                        coordinateView(label: "LON", value: position.longitude, unit: "º")
                        Spacer()
                        coordinateView(label: "ALT", value: position.altitude, unit: "km")
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        Spacer()
                        coordinateView(label: "AZ", value: position.azimut, unit: "º")
                        Spacer()
                        coordinateView(label: "ELEV", value: position.elevationAngle, unit: "º")
                        Spacer()
                        coordinateView(label: "SPEED", value: position.velocity, unit: "km/s")
                        Spacer()
                    }
                }
                .padding(.all)
                .background(colorScheme == .dark ? .thinMaterial : .thickMaterial)
                
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .gray.opacity(0.5), radius: 1)
                
            } else {
                Spacer()
                VStack {
                    HStack {
                        Spacer()
                        Text("No satellite data available")
                            .font(.callout.weight(.medium))
                            .matchedGeometryEffect(id: "title", in: namespace)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .symbolEffect(.variableColor.iterative.reversing)
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                 }
                 .padding(.all, 11.0)
                 .background(.thickMaterial)
                 .matchedGeometryEffect(id: "background", in: namespace)
                 .clipShape(RoundedRectangle(cornerRadius: 15))
                 .shadow(color: .gray.opacity(0.5), radius: 1)
            }
        }
    }
    
    private func coordinateView(label: String, value: Double, unit: String) -> some View {
        VStack {
            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("\(String(format: "%.2f", value))\(unit)")
                .font(.body)
                .padding(.all, 10.0)
                .foregroundStyle(Color.black)
                .background(colorScheme == .dark ? Color.gray : .white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 2)
    }
}
