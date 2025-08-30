import Foundation
import HealthKit
import WatchKit

class HeartRateManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    
    @Published var currentHeartRate: Double = 60
    @Published var currentHRV: Double = 50
    @Published var isMonitoring = false
    @Published var heartRateVariability: Double = 0
    
    // HRV ranges for color mapping (in milliseconds)
    let hrvLow: Double = 20    // Stressed/low HRV
    let hrvOptimal: Double = 50 // Optimal HRV
    let hrvHigh: Double = 100   // Very relaxed/high HRV
    
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
        
        startHeartRateQuery()
        startHRVQuery()
        isMonitoring = true
        
        // Start workout session for continuous HR monitoring
        startWorkoutSession()
    }
    
    func stopMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        if let query = hrvQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
        hrvQuery = nil
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
    
    private func startHRVQuery() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        hrvQuery = query
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
            }
        }
    }
    
    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let hrvSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let mostRecent = hrvSamples.last {
                let hrvUnit = HKUnit.secondUnit(with: .milli)
                let hrv = mostRecent.quantity.doubleValue(for: hrvUnit)
                
                // Smooth the HRV changes
                self.currentHRV = self.currentHRV * 0.8 + hrv * 0.2
                
                // Calculate variability for visualization
                self.heartRateVariability = abs(hrv - self.currentHRV) / self.currentHRV
            }
        }
    }
    
    private func startWorkoutSession() {
        // Configure workout session for mindfulness/breathing
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            session.startActivity(with: Date())
            
            // This keeps heart rate monitoring active
            if let device = HKDevice.local() {
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let predicate = HKQuery.predicateForObjects(from: device)
                
                let streamingQuery = HKObserverQuery(sampleType: heartRateType, predicate: predicate) { [weak self] query, completionHandler, error in
                    if error == nil {
                        self?.queryLatestHeartRate()
                    }
                    completionHandler()
                }
                
                healthStore.execute(streamingQuery)
            }
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
        // Map HRV to color gradient
        // Low HRV (stressed): Red/Orange
        // Optimal HRV: Green/Cyan
        // High HRV (very relaxed): Blue/Purple
        
        if currentHRV < hrvLow {
            return Color.red
        } else if currentHRV < hrvOptimal {
            let progress = (currentHRV - hrvLow) / (hrvOptimal - hrvLow)
            return Color(
                hue: 0.08 + progress * 0.42, // Red to green
                saturation: 0.8,
                brightness: 0.9
            )
        } else if currentHRV < hrvHigh {
            let progress = (currentHRV - hrvOptimal) / (hrvHigh - hrvOptimal)
            return Color(
                hue: 0.5 + progress * 0.25, // Green to blue
                saturation: 0.7,
                brightness: 0.9
            )
        } else {
            return Color.purple
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