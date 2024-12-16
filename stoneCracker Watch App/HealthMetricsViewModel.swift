//
//  HealthMetricsViewModel.swift
//  stoneCracker Watch App
//
//  Created by Miguel Susano on 01/10/2024.
//

import Foundation
import HealthKit

class HealthMetricsViewModel: ObservableObject {
    private var healthStore = HKHealthStore()

    @Published var currentHeartRate: Double? // Property for heart rate
    @Published var currentHRV: Double? //HRV -> Heart Rate Variability
    @Published var currentSpO2: Double? //SpO2 -> Oxygen Saturation
    @Published var caloriesBurned: Double? // Property for calories burned
    @Published var vo2Max: Double? // VO2 Max -> Maximal oxygen consumption
    @Published var totalDistance: Double? // Property for total distance

    init() {
        requestAuthorization()
    }

    // Request permission to access health data
    func requestAuthorization() {
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, // New distance type
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed")
            }
        }
    }

    // Start monitoring health data
    func startMonitoringHealthData() {
        fetchHeartRate()
        fetchHRV()
        fetchSpO2()
        fetchCaloriesBurned()
        fetchVO2Max()
        fetchTotalDistance()   // Fetch total distance
    }

    // Stop monitoring if necessary (for future use)
    func stopMonitoringHealthData() {}

    private func fetchHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRate(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRate(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample], let latestSample = heartRateSamples.last else { return }

        let heartRateUnit = HKUnit(from: "count/min")
        let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)

        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
        }
    }

    private func fetchHRV() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let query = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRV(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRV(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processHRV(samples: [HKSample]?) {
        guard let hrvSamples = samples as? [HKQuantitySample], let latestSample = hrvSamples.last else { return }

        let hrvUnit = HKUnit.secondUnit(with: .milli)
        let hrv = latestSample.quantity.doubleValue(for: hrvUnit)

        DispatchQueue.main.async {
            self.currentHRV = hrv
        }
    }

    private func fetchSpO2() {
        let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        let query = HKAnchoredObjectQuery(type: spo2Type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSpO2(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSpO2(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processSpO2(samples: [HKSample]?) {
        guard let spo2Samples = samples as? [HKQuantitySample], let latestSample = spo2Samples.last else { return }

        let spo2Unit = HKUnit.percent()
        let spo2 = latestSample.quantity.doubleValue(for: spo2Unit) * 100

        DispatchQueue.main.async {
            self.currentSpO2 = spo2
        }
    }

    private func fetchCaloriesBurned() {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKAnchoredObjectQuery(type: caloriesType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processCaloriesBurned(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processCaloriesBurned(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processCaloriesBurned(samples: [HKSample]?) {
        guard let calorieSamples = samples as? [HKQuantitySample], let latestSample = calorieSamples.last else { return }

        let calorieUnit = HKUnit.kilocalorie()
        let calories = latestSample.quantity.doubleValue(for: calorieUnit)

        DispatchQueue.main.async {
            self.caloriesBurned = calories
        }
    }

    private func fetchVO2Max() {
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        let query = HKAnchoredObjectQuery(type: vo2MaxType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processVO2Max(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processVO2Max(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processVO2Max(samples: [HKSample]?) {
        guard let vo2MaxSamples = samples as? [HKQuantitySample], let latestSample = vo2MaxSamples.last else { return }

        let vo2MaxUnit = HKUnit(from: "ml/kg*min")
        let vo2Max = latestSample.quantity.doubleValue(for: vo2MaxUnit)

        DispatchQueue.main.async {
            self.vo2Max = vo2Max
        }
    }

    // New functions for fetching additional metrics

    private func fetchTotalDistance() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKAnchoredObjectQuery(type: distanceType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTotalDistance(samples: samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTotalDistance(samples: samples)
        }

        healthStore.execute(query)
    }

    private func processTotalDistance(samples: [HKSample]?) {
        guard let distanceSamples = samples as? [HKQuantitySample], let latestSample = distanceSamples.last else { return }

        let distanceUnit = HKUnit.meter()
        let distance = latestSample.quantity.doubleValue(for: distanceUnit)

        DispatchQueue.main.async {
            self.totalDistance = distance
        }
    }
}
