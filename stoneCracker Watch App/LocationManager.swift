import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?

    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.requestAuthorization()  // Request location authorization
    }

    // Request permission to access location
    func requestAuthorization() {
        guard let locationManager = locationManager else { return }

        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()  // Request location permission
            case .restricted, .denied:
                print("Location access denied")
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location access granted")
            default:
                break
            }
        } else {
            print("Location services are not enabled")
        }
    }

    func startLocationTracking() {
        locationManager?.startUpdatingLocation()
    }

    func stopLocationTracking() {
        locationManager?.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
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
            locationManager?.startUpdatingLocation()  // Start tracking location
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
            locationManager?.requestWhenInUseAuthorization()  // Re-request permission
        @unknown default:
            break
        }
    }
}
