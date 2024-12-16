import SwiftUI
import HealthKit
import CoreLocation

struct ContentView: View {
    @StateObject private var healthMetricsVM = HealthMetricsViewModel()
    @StateObject private var locationManager = LocationManager() // Add LocationManager

    var body: some View {
        TabView {
            // Second Tab: Heart Rate
            heartRateView()
                .containerBackground(Color.red.gradient, for: .tabView)

            // Third Tab: Performance Metrics
            performanceMetricsView()
                .containerBackground(Color.green.gradient, for: .tabView)

            // Fourth Tab: Calories
            caloriesView()
                .containerBackground(Color.orange.gradient, for: .tabView)

            // New Tab: Location
            locationView()
                .containerBackground(Color.blue.gradient, for: .tabView)
        }
        .ignoresSafeArea()
        .tabViewStyle(.verticalPage) // Use a page style for watchOS 10
    }

    // MARK: - View Functions

    private func heartRateView() -> some View {
        VStack {
            if let heartRate = healthMetricsVM.currentHeartRate {
                Text("Heart Rate: \(heartRate, specifier: "%.0f") BPM")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Fetching heart rate...")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            healthMetricsVM.startMonitoringHealthData()
        }
        .onDisappear {
            healthMetricsVM.stopMonitoringHealthData()
        }
    }

    private func performanceMetricsView() -> some View {
        VStack {
            if let distance = healthMetricsVM.totalDistance {
                Text("Total Distance: \(distance, specifier: "%.2f") m")
            }
        }
        .padding()
    }

    private func caloriesView() -> some View {
        VStack {
            if let calories = healthMetricsVM.caloriesBurned {
                Text("Calories Burned: \(calories, specifier: "%.0f") kcal")
            } else {
                Text("Fetching calories...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    private func locationView() -> some View {
        VStack {
            if let location = locationManager.currentLocation {
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")
            } else {
                Text("Fetching location...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            locationManager.startLocationTracking()
        }
        .onDisappear {
            locationManager.stopLocationTracking()
        }
    }
}

#Preview {
    ContentView()
}