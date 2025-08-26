import SwiftUI
import WatchKit
import Combine

enum BreathPhase: String {
    case idle = "Ready to start"
    case starting = "Starting"
    case breathing = "Breathing"
    case holding = "Holding"
    case preRecovery = "Inhale deeply"
    case recovery = "Recovery"
}

class BreathViewModel: ObservableObject {
    @Published var phase: BreathPhase = .idle
    @Published var breathCount = 0
    @Published var holdTime: TimeInterval = 0
    @Published var recoveryTime: TimeInterval = 15
    @Published var isActive = false
    @Published var round = 1
    @Published var totalBreaths = 30
    @Published var breathLength: TimeInterval = 5.5
    @Published var breathProgress: Double = 0
    @Published var isInhale = true
    @Published var phaseDisplay = "Ready to start"
    @Published var timerDisplay = ""
    @Published var breathScale: CGFloat = 0.01
    
    private var startTimer: TimeInterval = 3
    private var timer: Timer?
    private var breathTimer: TimeInterval = 0
    
    var currentBreathNumber: Int {
        return (breathCount / 2) + 1
    }
    
    init() {
        updateDisplay()
    }
    
    func startStop() {
        if !isActive {
            phase = .starting
            startTimer = 3
            isActive = true
            startTimer()
        } else {
            isActive = false
            stopTimer()
        }
        updateDisplay()
    }
    
    func reset() {
        isActive = false
        phase = .idle
        breathCount = 0
        holdTime = 0
        recoveryTime = 15
        round = 1
        startTimer = 3
        isInhale = true
        breathProgress = 0
        breathTimer = 0
        breathScale = 0.01
        stopTimer()
        timerDisplay = ""
        updateDisplay()
    }
    
    func finishHolding() {
        if phase == .holding {
            phase = .preRecovery
            startTimer = 3
            updateDisplay()
        }
    }
    
    func increaseBreaths() {
        if !isActive && totalBreaths < 50 {
            totalBreaths += 5
        }
    }
    
    func decreaseBreaths() {
        if !isActive && totalBreaths > 10 {
            totalBreaths -= 5
        }
    }
    
    func increaseLength() {
        if !isActive && breathLength < 8 {
            breathLength = min(8, breathLength + 0.5)
        }
    }
    
    func decreaseLength() {
        if !isActive && breathLength > 3 {
            breathLength = max(3, breathLength - 0.5)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.timerTick()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timerTick() {
        let delta = 0.05
        
        switch phase {
        case .starting:
            startTimer -= delta
            if startTimer <= 0 {
                phase = .breathing
                breathCount = 0
                isInhale = true
                breathProgress = 0
                breathTimer = 0
                WKInterfaceDevice.current().play(.start)
            }
            
        case .breathing:
            breathTimer += delta
            breathProgress = breathTimer / (breathLength / 2)
            
            if breathProgress >= 1 {
                breathCount += 1
                isInhale.toggle()
                breathProgress = 0
                breathTimer = 0
                
                if isInhale {
                    WKInterfaceDevice.current().play(.click)
                }
                
                if breathCount >= totalBreaths * 2 {
                    phase = .holding
                    holdTime = 0
                    breathScale = 0.01
                    WKInterfaceDevice.current().play(.success)
                }
            }
            updateBreathIndicator()
            
        case .holding:
            holdTime += delta
            
        case .preRecovery:
            startTimer -= delta
            let progress = 1 - (startTimer / 3)
            breathScale = 0.01 + (1 - 0.01) * progress
            
            if startTimer <= 0 {
                phase = .recovery
                recoveryTime = 15
                WKInterfaceDevice.current().play(.start)
            }
            
        case .recovery:
            recoveryTime -= delta
            if recoveryTime <= 0 {
                if round < 3 {
                    round += 1
                    phase = .starting
                    startTimer = 3
                    WKInterfaceDevice.current().play(.notification)
                } else {
                    reset()
                    WKInterfaceDevice.current().play(.stop)
                    return
                }
            }
            
        case .idle:
            break
        }
        
        updateDisplay()
    }
    
    private func updateBreathIndicator() {
        let minScale: CGFloat = 0.01
        let maxScale: CGFloat = 1.0
        
        if isInhale {
            breathScale = minScale + (maxScale - minScale) * CGFloat(breathProgress)
        } else {
            breathScale = maxScale - (maxScale - minScale) * CGFloat(breathProgress)
        }
    }
    
    private func updateDisplay() {
        switch phase {
        case .idle:
            phaseDisplay = "Ready to start"
            
        case .starting:
            phaseDisplay = "Round \(round)/3: Starting"
            timerDisplay = "\(Int(ceil(startTimer)))"
            
        case .breathing:
            phaseDisplay = "Round \(round)/3: Breathing"
            timerDisplay = "\(currentBreathNumber)/\(totalBreaths)"
            
        case .holding:
            phaseDisplay = "Round \(round)/3: Holding"
            timerDisplay = "\(Int(holdTime))s"
            
        case .preRecovery:
            phaseDisplay = "Round \(round)/3: Inhale"
            timerDisplay = "Inhale"
            
        case .recovery:
            phaseDisplay = "Round \(round)/3: Recovery"
            timerDisplay = "\(Int(ceil(recoveryTime)))s"
        }
    }
}