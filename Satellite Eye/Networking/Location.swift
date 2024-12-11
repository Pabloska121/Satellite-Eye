import CoreLocation
import SwiftUI

class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var lat_et: Double = 0.0
    @Published var lon_et: Double = 0.0
    @Published var alt: Double = 0.0
    @Published var heading: Double {
        willSet {
            objectWillChange.send()
        }
    }
    private var locationCompletion: ((CLLocation?) -> Void)?
    private var locationUpdated: Bool = false
    
    override init() {
        heading = 0
        super.init()
        self.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.locationCompletion = completion
        locationUpdated = false
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            lat_et = location.coordinate.latitude
            lon_et = location.coordinate.longitude
            alt = location.altitude
            if !locationUpdated {
                locationCompletion?(location)  // Call the completion handler once
                locationUpdated = true  // Set the flag to true
            }
            locationManager.stopUpdatingLocation()  // Stop updating location after getting the first update
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = Double(round(1 * newHeading.trueHeading) / 1)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(nil)
    }
}
