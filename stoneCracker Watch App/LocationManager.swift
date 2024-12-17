import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    var locationUpdateHandler: ((CLLocation) -> Void)?
    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestAuthorization()
    }

    func requestAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("Location services are not enabled")
        }
    }

    func startLocationTracking() {
        locationManager.startUpdatingLocation()
    }

    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationUpdateHandler?(location)
        DispatchQueue.main.async {
            self.currentLocation = location
            print("Updated Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access granted")
            locationManager.startUpdatingLocation()  // Start tracking location
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
            locationManager.requestWhenInUseAuthorization()  // Re-request permission
        @unknown default:
            break
        }
    }
}
