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
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Phase display
                Text(viewModel.phase == .idle ? "Breath Practice" : "Round \(viewModel.round)/3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                // Timer display
                Text(viewModel.timerDisplay)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 28)
                
                // Premium fluid orb visualization
                ZStack {
                    // Background particles for depth
                    FireflyParticlesView(
                        breathScale: viewModel.breathScale,
                        isInhale: viewModel.isInhale
                    )
                    .frame(width: 160, height: 160)
                    .opacity(0.3)
                    
                    // Main fluid orb animation
                    FluidOrbView(
                        breathScale: viewModel.breathScale,
                        isInhale: viewModel.isInhale,
                        phase: viewModel.phase
                    )
                    .frame(width: 140, height: 140)
                    
                    // Outer breathing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.6),
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: viewModel.phase == .holding ? 3 : 1.5
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(viewModel.breathScale)
                        .rotationEffect(.degrees(time * 30))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                }
                .frame(width: 140, height: 140)
                .padding(.vertical, 8)
                
                // Control buttons
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Button(action: viewModel.startStop) {
                            Text(viewModel.isActive ? "Pause" : "Start")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(color: .blue))
                        
                        Button(action: viewModel.reset) {
                            Text("Reset")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle(color: .red))
                    }
                    
                    if viewModel.phase == .holding {
                        Button(action: viewModel.finishHolding) {
                            Text("Finish Hold")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(GlassButtonStyle(color: .green))
                    }
                    
                    // Settings (only show when not active)
                    if !viewModel.isActive {
                        HStack(spacing: 12) {
                            // Breaths control
                            VStack(spacing: 2) {
                                Text("BREATHS")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                HStack(spacing: 4) {
                                    Button(action: viewModel.decreaseBreaths) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(viewModel.totalBreaths)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 25)
                                    
                                    Button(action: viewModel.increaseBreaths) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Length control
                            VStack(spacing: 2) {
                                Text("TIME")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                HStack(spacing: 4) {
                                    Button(action: viewModel.decreaseLength) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(String(format: "%.1f", viewModel.breathLength))s")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 35)
                                    
                                    Button(action: viewModel.increaseLength) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            viewModel.updateDisplay()
            // Start rotation animation
            Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
                time += 0.016
            }
        }
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

#Preview {
    ContentView()
}