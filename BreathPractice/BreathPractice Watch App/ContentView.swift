//
//  ContentView.swift
//  BreathPractice Watch App
//
//  Created by Sean Thomas Evans on 2025-08-25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BreathViewModel()
    
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
                
                // GLSL-inspired mathematical visualization
                ZStack {
                    // Shader-inspired organic shape
                    ShaderInspiredView(
                        breathScale: viewModel.breathScale,
                        isInhale: viewModel.isInhale,
                        phase: viewModel.phase
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(0.5) // Scale down to fit watch screen
                    
                    // Optional: Keep particles as overlay
                    FireflyParticlesView(
                        breathScale: viewModel.breathScale,
                        isInhale: viewModel.isInhale
                    )
                    .scaleEffect(0.5)
                    .opacity(0.3) // Make particles subtle overlay
                    
                    // Glass ring that expands
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.4),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: viewModel.phase == .holding ? 2 : 1
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(viewModel.breathScale)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                    
                    // Core orb with glow - 2x size and brighter
                    ZStack {
                        // Outer glow layer
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.9),
                                        phaseSecondaryColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.5),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 70, height: 70)
                            .scaleEffect(viewModel.breathScale)
                            .blur(radius: viewModel.phase == .holding ? 3 : 2)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                        
                        // Main bright orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.95),
                                        phaseColor(for: viewModel.phase, isInhale: viewModel.isInhale),
                                        phaseSecondaryColor(for: viewModel.phase, isInhale: viewModel.isInhale).opacity(0.7),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 60, height: 60)
                            .scaleEffect(viewModel.breathScale * 0.9)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                        
                        // Bright center core
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .scaleEffect(viewModel.breathScale * 0.7)
                            .blendMode(.plusLighter)
                            .blur(radius: viewModel.phase == .holding ? 0.5 : 1)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
                    }
                }
                .frame(width: 70, height: 70)
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