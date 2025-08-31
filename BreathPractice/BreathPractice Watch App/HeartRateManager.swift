import Foundation
import HealthKit
import WatchKit
import SwiftUI

class HeartRateManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    
    @Published var currentHeartRate: Double = 60
    @Published var currentHRV: Double = 30  // RMSSD in ms
    @Published var isMonitoring = false
    
    // Store recent heartbeat intervals for HRV calculation
    private var recentBeatIntervals: [TimeInterval] = []
    private var lastHeartbeatTime: Date?
    private let maxIntervals = 20  // Keep last 20 intervals for RMSSD calculation
    
    // HRV RMSSD ranges for color mapping (in milliseconds)
    // Based on typical RMSSD values during breathing exercises
    let hrvLow: Double = 15     // Low HRV (stressed)
    let hrvOptimal: Double = 40  // Good HRV
    let hrvHigh: Double = 70     // Excellent HRV (very relaxed)
    
    // Heart rate ranges
    let hrResting: Double = 60
    let hrModerate: Double = 100
    let hrHigh: Double = 140
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available")
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let typesToRead: Set<HKObjectType> = [heartRateType, hrvType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Clear previous data
        recentBeatIntervals.removeAll()
        lastHeartbeatTime = nil
        
        startHeartRateQuery()
        isMonitoring = true
        
        // Start workout session for continuous HR monitoring
        startWorkoutSession()
    }
    
    func stopMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
        
        if let session = workoutSession {
            session.end()
        }
        workoutSession = nil
        
        isMonitoring = false
    }
    
    private func startHeartRateQuery() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        heartRateQuery = query
        healthStore.execute(query)
    }
    
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let mostRecent = heartRateSamples.last {
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let heartRate = mostRecent.quantity.doubleValue(for: heartRateUnit)
                
                // Smooth the heart rate changes
                self.currentHeartRate = self.currentHeartRate * 0.7 + heartRate * 0.3
                
                // Calculate beat-to-beat interval for HRV
                let currentTime = mostRecent.endDate
                if let lastTime = self.lastHeartbeatTime {
                    let interval = currentTime.timeIntervalSince(lastTime)
                    
                    // Only use reasonable intervals (between 0.4 and 2 seconds = 30-150 BPM)
                    if interval > 0.4 && interval < 2.0 {
                        self.recentBeatIntervals.append(interval)
                        
                        // Keep only recent intervals
                        if self.recentBeatIntervals.count > self.maxIntervals {
                            self.recentBeatIntervals.removeFirst()
                        }
                        
                        // Calculate RMSSD (Root Mean Square of Successive Differences)
                        self.calculateHRV()
                    }
                }
                self.lastHeartbeatTime = currentTime
            }
        }
    }
    
    private func calculateHRV() {
        guard recentBeatIntervals.count >= 3 else { return }
        
        var successiveDifferences: [Double] = []
        
        // Calculate successive differences
        for i in 1..<recentBeatIntervals.count {
            let diff = (recentBeatIntervals[i] - recentBeatIntervals[i-1]) * 1000 // Convert to ms
            successiveDifferences.append(diff * diff) // Square the difference
        }
        
        // Calculate mean of squared differences
        let sumSquared = successiveDifferences.reduce(0, +)
        let meanSquared = sumSquared / Double(successiveDifferences.count)
        
        // Take square root to get RMSSD
        let rmssd = sqrt(meanSquared)
        
        // Smooth the HRV value
        currentHRV = currentHRV * 0.7 + rmssd * 0.3
    }
    
    private func startWorkoutSession() {
        // Configure workout session for mindfulness/breathing
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.startActivity(with: Date())
            
            // This keeps heart rate monitoring active
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            
            let streamingQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
                if error == nil {
                    self?.queryLatestHeartRate()
                }
                completionHandler()
            }
            
            healthStore.execute(streamingQuery)
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }
    
    private func queryLatestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            self?.processHeartRateSamples(samples)
        }
        healthStore.execute(query)
    }
    
    func getHRVColor() -> Color {
        // Map RMSSD HRV to color gradient
        // RMSSD values during breathing:
        // < 15ms: Low HRV (stressed) - Red/Orange
        // 15-40ms: Moderate HRV - Orange to Green
        // 40-70ms: Good HRV - Green to Cyan
        // > 70ms: Excellent HRV (very relaxed) - Blue/Purple
        
        if currentHRV < hrvLow {
            // Very low HRV - red
            return Color(hue: 0.0, saturation: 0.9, brightness: 0.8)
        } else if currentHRV < hrvOptimal {
            // Low to moderate - red to green gradient
            let progress = (currentHRV - hrvLow) / (hrvOptimal - hrvLow)
            return Color(
                hue: progress * 0.33, // Red (0) to green (0.33)
                saturation: 0.8,
                brightness: 0.85
            )
        } else if currentHRV < hrvHigh {
            // Good HRV - green to cyan gradient
            let progress = (currentHRV - hrvOptimal) / (hrvHigh - hrvOptimal)
            return Color(
                hue: 0.33 + progress * 0.17, // Green to cyan
                saturation: 0.7,
                brightness: 0.9
            )
        } else {
            // Excellent HRV - blue/purple
            let excess = min((currentHRV - hrvHigh) / 30, 1.0)
            return Color(
                hue: 0.5 + excess * 0.25, // Cyan to purple
                saturation: 0.6,
                brightness: 0.95
            )
        }
    }
    
    func getHRVDescription() -> String {
        if currentHRV < hrvLow {
            return "Low"
        } else if currentHRV < hrvOptimal {
            return "Moderate"
        } else if currentHRV < hrvHigh {
            return "Good"
        } else {
            return "Excellent"
        }
    }
    
    func getPulseInterval() -> TimeInterval {
        // Convert BPM to seconds between beats
        return 60.0 / currentHeartRate
    }
    
    func getHeartRateNormalized() -> Double {
        // Normalize heart rate to 0-1 range for visualization
        let clamped = min(max(currentHeartRate, 40), 180)
        return (clamped - 40) / 140
    }
}