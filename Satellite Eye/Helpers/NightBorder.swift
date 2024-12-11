import Foundation
import CoreLocation

class NightBorder {
    static func Get_border(t_now: Date) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var cte = 1.0
        
        let suncoord = Extra.calculateSolarPosition(timedt: t_now)
        let lats = atan2(suncoord.2, sqrt(suncoord.0 * suncoord.0 + suncoord.1 * suncoord.1)) * 180 / Double.pi
        let lons = atan2(suncoord.1, suncoord.0) * 180 / Double.pi
        
        if lats > 0 {
            cte = cte * -1.0
        }
        
        coordinates.append(CLLocationCoordinate2D(latitude: cte * 90.0, longitude: -180.0))
        
        let terminatorLat1 = calculateTerminatorLatitude(for: -180, sunLongitude: lons, sunLatitude: lats)
        
        for lon in stride(from: -180.0, to: 180.0, by: 1.0) {
            let terminatorLat = calculateTerminatorLatitude(for: lon, sunLongitude: lons, sunLatitude: lats)
            coordinates.append(CLLocationCoordinate2D(latitude: terminatorLat, longitude: lon))
        }
        coordinates.append(CLLocationCoordinate2D(latitude: terminatorLat1, longitude: -180))
        coordinates.append(CLLocationCoordinate2D(latitude: cte * 90.0, longitude: 180.0))
        
        return coordinates
    }

    static func calculateTerminatorLatitude(for longitude: Double, sunLongitude: Double, sunLatitude: Double) -> Double {
        let declination = sunLatitude
        let hourAngle = longitude - sunLongitude
        let lat = atan(-cos(hourAngle * .pi / 180.0) / tan(declination * .pi / 180.0)) * 180.0 / .pi

        return lat
    }
}
