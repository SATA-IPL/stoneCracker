//
//  ContentView.swift
//  stoneCracker Watch App
//
//  Created by Miguel Susano on 01/10/2024.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderViewModel()
    @StateObject private var healthMetricsVM = HealthMetricsViewModel()

    var body: some View {
        TabView {
            // First Tab: Audio Recorder
            audioRecorderView()
            
            // Second Tab: Heart Rate
            heartRateView()
                .containerBackground(Color.red.gradient,for: .tabView)

            // Third Tab: Performance Metrics
            performanceMetricsView()
                .containerBackground(Color.green.gradient,for: .tabView)


            // Fourth Tab: Calories
            caloriesView()
                .containerBackground(Color.orange.gradient,for: .tabView)

        }
        .ignoresSafeArea()
        .tabViewStyle(.verticalPage) // Use a page style for watchOS 10
    }

    // MARK: - View Functions

    private func audioRecorderView() -> some View {
        VStack {
            Button(action: {
                if audioRecorder.isPlaying {
                    audioRecorder.togglePlayback()
                } else {
                    audioRecorder.toggleRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .trim(from: 0.0, to: audioRecorder.isPlaying ? audioRecorder.playbackProgress : 1.0)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .foregroundStyle(.ultraThinMaterial)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.2), value: audioRecorder.playbackProgress)

                    if audioRecorder.isRecording {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red)
                            .frame(width: 75, height: 75)
                            .transition(.scale)
                    } else {
                        Circle()
                            .fill(audioRecorder.isPlaying ? Color.blue : Color.red)
                            .padding(10)
                            .transition(.scale)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding()
        }
    }

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
}

#Preview {
    ContentView()
}
