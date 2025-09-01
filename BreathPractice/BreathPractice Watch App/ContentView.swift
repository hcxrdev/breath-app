//
//  ContentView.swift
//  BreathPractice Watch App
//
//  Created by Sean Thomas Evans on 2025-08-25.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var viewModel = BreathViewModel()
    @StateObject private var heartRateManager = HeartRateManager()
    @State private var time: Double = 0
    @State private var gradientAngle: Double = 0
    @State private var animationTimer: Timer?
    @State private var extendedSession: WKExtendedRuntimeSession?
    @State private var sessionDelegate: ExtendedSessionDelegate?
    
    var body: some View {
        ZStack {
            // Animated darker background gradient - optimized
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.2),
                    Color.black.opacity(0.3)
                ]),
                startPoint: UnitPoint(x: 0.5 + cos(gradientAngle) * 0.3, 
                                     y: 0.5 + sin(gradientAngle) * 0.3),
                endPoint: UnitPoint(x: 0.5 - cos(gradientAngle) * 0.3, 
                                   y: 0.5 - sin(gradientAngle) * 0.3)
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add padding at top to move text below the time
                Spacer()
                    .frame(height: 25)
                
                // Phase display with heart rate
                HStack(spacing: 8) {
                    Text(viewModel.phase == .idle ? "Shakti:Breath" : "Round \(viewModel.round)/3")
                        .font(.system(size: viewModel.phase == .idle ? 20 : 10, weight: viewModel.phase == .idle ? .light : .medium))
                        .foregroundColor(.white.opacity(viewModel.phase == .idle ? 0.9 : 0.7))
                    
                    if heartRateManager.isMonitoring {
                        HStack(spacing: 4) {
                            // Heart rate with pulse indicator
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(heartRateManager.getHRVColor())
                                Text("\(Int(heartRateManager.currentHeartRate))")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // HRV indicator - more subtle display
                            Text("HRV:\(Int(heartRateManager.currentHRV))")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(heartRateManager.getHRVColor().opacity(0.8))
                        }
                    }
                }
                
                // Timer display
                Text(viewModel.timerDisplay)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 20)
                
                // Premium fluid orb visualization - sized for watch
                ZStack {
                    // Background particles - completely disabled for performance
                    // FireflyParticlesView removed for performance
                    
                    // Animated glow behind orb - bigger and smoother
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.7),
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.4),
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 160, height: 160) // 25% bigger glow
                        .blur(radius: 15)
                        .scaleEffect(viewModel.breathScale)
                        .opacity(0.8)
                    
                    // Main fluid orb animation - 25% bigger
                    if viewModel.phase == .holding {
                        // Special power orb for holding phase
                        PowerOrbView(holdTime: viewModel.holdTime, heartRateManager: heartRateManager)
                            .frame(width: 115, height: 115)  // Reduced from 125
                    } else {
                        FluidOrbView(
                            breathScale: viewModel.breathScale,
                            isInhale: viewModel.isInhale,
                            phase: viewModel.phase,
                            heartRateManager: heartRateManager
                        )
                        .frame(width: 115, height: 115)  // Reduced from 125
                    }
                    
                    // Prominent glowing outer ring - 25% bigger
                    ZStack {
                        // Glow layer
                        Circle()
                            .stroke(
                                phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale),
                                lineWidth: viewModel.phase == .holding ? 5 : 3
                            )
                            .frame(width: 115, height: 115)  // Reduced from 125
                            .blur(radius: 5)
                            .opacity(0.8)
                            .scaleEffect(viewModel.breathScale)
                        
                        // Main ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale),
                                        phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.8),
                                        phaseSecondaryColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: viewModel.phase == .holding ? 4 : 2.5
                            )
                            .frame(width: 115, height: 115)  // Reduced from 125
                            .scaleEffect(viewModel.breathScale)
                            .rotationEffect(.degrees(time * 30))
                    }
                    .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                }
                .frame(width: 115, height: 115)  // Reduced from 125 to give more room
                .padding(.vertical, 0) // Removed padding
                
                // Control buttons - more compact
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Button(action: viewModel.startStop) {
                            Text(viewModel.isActive ? "PAUSE" : "START")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CompactGlassButtonStyle(color: .blue))
                        
                        Button(action: viewModel.reset) {
                            Text("RESET")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CompactGlassButtonStyle(color: .red))
                    }
                    
                    if viewModel.phase == .holding {
                        Button(action: viewModel.finishHolding) {
                            Text("FINISH HOLD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(BrightGlassButtonStyle(color: .green))
                    }
                    
                    // Settings (only show when not active)
                    if !viewModel.isActive {
                        HStack(spacing: 6) {
                            // Breaths control
                            VStack(spacing: 0) {
                                Text("BREATHS")
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 1) {
                                    Button(action: viewModel.decreaseBreaths) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(viewModel.totalBreaths)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 18)
                                    
                                    Button(action: viewModel.increaseBreaths) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Length control
                            VStack(spacing: 0) {
                                Text("TIME")
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 1) {
                                    Button(action: viewModel.decreaseLength) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(String(format: "%.1f", viewModel.breathLength))s")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 28)
                                    
                                    Button(action: viewModel.increaseLength) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 20, height: 20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)  // Increased bottom padding to clear rounded edge
        }
        .onAppear {
            viewModel.updateDisplay()
            startAnimationTimer()
        }
        .onDisappear {
            stopAnimationTimer()
            endExtendedSession()
        }
        .onChange(of: viewModel.isActive) { oldValue, newValue in
            if newValue {
                startExtendedSession()
                heartRateManager.startMonitoring()
            } else {
                endExtendedSession()
                heartRateManager.stopMonitoring()
            }
        }
    }
    
    private func startAnimationTimer() {
        // Cancel any existing timer first
        stopAnimationTimer()
        
        // Create a single timer for all animations - optimized for performance
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/6.0, repeats: true) { _ in
            time += 0.166
            // Very slow gradient animation - subtle movement
            if viewModel.isActive {
                gradientAngle += 0.012  // Super slow rotation
            }
        }
        
        // Keep the run loop active
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func startExtendedSession() {
        guard extendedSession == nil else { return }
        
        sessionDelegate = ExtendedSessionDelegate()
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = sessionDelegate
        extendedSession?.start()
        
        // Small haptic to wake screen
        WKInterfaceDevice.current().play(.success)
    }
    
    private func endExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
        sessionDelegate = nil
    }
    
    func phaseColor(for phase: BreathPhase, isInhale: Bool) -> Color {
        switch phase {
        case .holding:
            return Color.purple
        case .recovery, .preRecovery:
            return Color.green
        default:
            return isInhale ? Color.cyan : Color.orange
        }
    }
    
    func phaseSecondaryColor(for phase: BreathPhase, isInhale: Bool) -> Color {
        switch phase {
        case .holding:
            return Color.indigo
        case .recovery, .preRecovery:
            return Color.mint
        default:
            return isInhale ? Color.blue : Color.yellow
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(configuration.isPressed ? 0.3 : 0.2))
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CompactGlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                    
                    // Color tint layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(configuration.isPressed ? 0.25 : 0.15))
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .foregroundColor(.white)
            .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct BrightGlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    // Bright base layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(configuration.isPressed ? 0.6 : 0.4))
                    
                    // Glow effect
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    color.opacity(0.5),
                                    color.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Strong inner highlight
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .foregroundColor(.white)
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// Extended session delegate to keep app active
class ExtendedSessionDelegate: NSObject, WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Session started
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Session expiring
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        // Session ended
    }
}

#Preview {
    ContentView()
}