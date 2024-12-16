//
//  ContentView.swift
//  stoneCracker Watch App
//
//  Created by Miguel Susano on 01/10/2024.
//

import SwiftUI
import HealthKit
import CoreLocation

struct ContentView: View {
    @StateObject private var healthMetricsVM = HealthMetricsViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        TabView {
            heartRateView()
                .containerBackground(Color.red.gradient,for: .tabView)

            performanceMetricsView()
                .containerBackground(Color.green.gradient,for: .tabView)

            oxygenView()
                .containerBackground(Color.purple.gradient, for: .tabView)

            caloriesView()
                .containerBackground(Color.orange.gradient,for: .tabView)
            
            locationView()
                .containerBackground(Color.blue.gradient,for: .tabView)
        }
        .ignoresSafeArea()
        .tabViewStyle(.verticalPage) // Use a page style for watchOS 10
    }

    // MARK: - View Functions
    private func heartRateView() -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.6), Color.red.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Heart Rate")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                if let heartRate = healthMetricsVM.currentHeartRate {
                    Text("\(Int(heartRate))")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: heartRate)
                    
                    Text("BPM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("--")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("BPM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Heart beat animation
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .opacity(healthMetricsVM.currentHeartRate != nil ? 1 : 0.5)
                    .scaleEffect(healthMetricsVM.currentHeartRate != nil ? 1.1 : 1.0)
                    .animation(healthMetricsVM.currentHeartRate != nil ? 
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                        .default, 
                        value: healthMetricsVM.currentHeartRate != nil)
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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Distance")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                if let distance = healthMetricsVM.totalDistance {
                    Text("\(Int(distance))")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("meters")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "figure.walk")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                } else {
                    Text("--")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("meters")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private func caloriesView() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Calories")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                if let calories = healthMetricsVM.caloriesBurned {
                    Text("\(Int(calories))")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("kcal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .opacity(0.8)
                } else {
                    Text("--")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("kcal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private func locationView() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Location")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                if let location = locationManager.currentLocation {
                    VStack(spacing: 4) {
                        Text("\(String(format: "%.4f", location.coordinate.latitude))")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(String(format: "%.4f", location.coordinate.longitude))")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .transition(.scale)
                    
                    Text("coordinates")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                } else {
                    Text("--")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("searching")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            locationManager.startLocationTracking()
        }
        .onDisappear {
            locationManager.stopLocationTracking()
        }
    }

    private func oxygenView() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Oxygen")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                if let spo2 = healthMetricsVM.currentSpO2 {
                    Text("\(Int(spo2))")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                } else {
                    Text("--")
                        .font(.system(size: 70, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
