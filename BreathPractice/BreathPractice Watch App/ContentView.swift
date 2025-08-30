//
//  ContentView.swift
//  BreathPractice Watch App
//
//  Created by Sean Thomas Evans on 2025-08-25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BreathViewModel()
    @State private var time: Double = 0
    @State private var gradientAngle: Double = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            // Animated darker background gradient
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
            .animation(.linear(duration: 1), value: gradientAngle)
            
            VStack(spacing: 0) {
                // Phase display
                Text(viewModel.phase == .idle ? "Shakti:Breath" : "Round \(viewModel.round)/3")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                // Timer display
                Text(viewModel.timerDisplay)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 20)
                
                // Premium fluid orb visualization - sized for watch
                ZStack {
                    // Background particles - disabled during active breathing for performance
                    if !viewModel.isActive {
                        FireflyParticlesView(
                            breathScale: viewModel.breathScale,
                            isInhale: viewModel.isInhale
                        )
                        .frame(width: 120, height: 120)
                        .opacity(0.3)
                    }
                    
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
                        .scaleEffect(viewModel.breathScale * (0.95 + sin(time * 0.5) * 0.05))
                        .opacity(0.8 + sin(time * 0.8) * 0.2)
                        .animation(.easeInOut(duration: 0.2), value: time)
                    
                    // Main fluid orb animation - 25% bigger
                    FluidOrbView(
                        breathScale: viewModel.breathScale,
                        isInhale: viewModel.isInhale,
                        phase: viewModel.phase
                    )
                    .frame(width: 125, height: 125) // 25% bigger orb
                    
                    // Prominent glowing outer ring - 25% bigger
                    ZStack {
                        // Glow layer
                        Circle()
                            .stroke(
                                phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale),
                                lineWidth: viewModel.phase == .holding ? 5 : 3
                            )
                            .frame(width: 125, height: 125)
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
                            .frame(width: 125, height: 125)
                            .scaleEffect(viewModel.breathScale)
                            .rotationEffect(.degrees(time * 30))
                    }
                    .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                }
                .frame(width: 125, height: 125)
                .padding(.vertical, 0) // Removed padding
                
                // Control buttons - more compact
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Button(action: viewModel.startStop) {
                            Text(viewModel.isActive ? "Pause" : "Start")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CompactGlassButtonStyle(color: .blue))
                        
                        Button(action: viewModel.reset) {
                            Text("Reset")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CompactGlassButtonStyle(color: .red))
                    }
                    
                    if viewModel.phase == .holding {
                        Button(action: viewModel.finishHolding) {
                            Text("Finish Hold")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(CompactGlassButtonStyle(color: .green))
                    }
                    
                    // Settings (only show when not active)
                    if !viewModel.isActive {
                        HStack(spacing: 10) {
                            // Breaths control
                            VStack(spacing: 2) {
                                Text("BREATHS")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 4) {
                                    Button(action: viewModel.decreaseBreaths) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(viewModel.totalBreaths)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 25)
                                    
                                    Button(action: viewModel.increaseBreaths) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Length control
                            VStack(spacing: 2) {
                                Text("TIME")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 4) {
                                    Button(action: viewModel.decreaseLength) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(String(format: "%.1f", viewModel.breathLength))s")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 35)
                                    
                                    Button(action: viewModel.increaseLength) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            viewModel.updateDisplay()
            startAnimationTimer()
        }
        .onDisappear {
            stopAnimationTimer()
        }
    }
    
    private func startAnimationTimer() {
        // Cancel any existing timer first
        stopAnimationTimer()
        
        // Create a single timer for all animations
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/15.0, repeats: true) { _ in
            withAnimation(.linear(duration: 0.066)) {
                time += 0.066
                // Slow gradient animation only during breathing
                if viewModel.isActive {
                    gradientAngle += 0.02
                }
            }
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
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

#Preview {
    ContentView()
}