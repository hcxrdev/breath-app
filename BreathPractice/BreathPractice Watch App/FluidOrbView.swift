import SwiftUI

struct FluidOrbView: View {
    let breathScale: CGFloat
    let isInhale: Bool
    let phase: BreathPhase
    @ObservedObject var heartRateManager: HeartRateManager
    @State private var time: Double = 0
    @State private var waveOffset: CGFloat = 0
    @State private var animationTimer: Timer?
    @State private var heartPulse: Double = 0
    @State private var pulseTimer: Timer?
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 2
            
            // Calculate heart-synchronized pulse scale
            let heartBeatScale = 1.0 + sin(heartPulse * .pi * 2) * 0.15
            
            // Only 2 layers to maintain performance over long sessions
            for layer in 0..<2 {
                let layerFactor = CGFloat(layer) / 2.0
                let layerTime = time + Double(layer) * 0.25
                
                // Create simpler blob path with heart rate pulse
                let path = createFluidPath(
                    center: center,
                    radius: baseRadius * breathScale * (0.5 + layerFactor * 0.3) * heartBeatScale,
                    time: layerTime,
                    complexity: 2 - layer
                )
                
                // Use normal phase colors
                let hue = getPhaseHue(phase: phase, isInhale: isInhale) + layerFactor * 0.1
                let saturation = 0.7 + sin(layerTime * 0.5) * 0.2
                let brightness = 0.95 - layerFactor * 0.2
                let layerColor = Color(hue: hue, saturation: saturation, brightness: brightness)
                
                // Apply gradient fill with glow effect
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [
                            layerColor.opacity(0.9 - layerFactor * 0.4),
                            layerColor.opacity(0.5 - layerFactor * 0.3),
                            layerColor.opacity(0.1),
                            Color.clear
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: baseRadius * breathScale * 1.2
                    )
                )
                
                // Add inner glow
                if layer < 3 {
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.3 - layerFactor * 0.2),
                                layerColor.opacity(0.2)
                            ]),
                            startPoint: CGPoint(x: center.x - 20, y: center.y - 20),
                            endPoint: CGPoint(x: center.x + 20, y: center.y + 20)
                        ),
                        lineWidth: 2 - layerFactor
                    )
                }
            }
            
            // Energy tendrils emanating from center
            drawEnergyTendrils(context: context, center: center, radius: baseRadius)
            
            // Bright core with plasma effect
            drawPlasmaCore(context: context, center: center, radius: baseRadius * 0.15 * breathScale)
        }
        .blendMode(.plusLighter)
        .onAppear {
            startAnimation()
            startHeartPulse()
        }
        .onDisappear {
            stopAnimation()
            stopHeartPulse()
        }
    }
    
    private func createFluidPath(center: CGPoint, radius: CGFloat, time: Double, complexity: Int) -> Path {
        var path = Path()
        let points = 20 // Slightly more points for smoother shape
        
        for i in 0...points {
            let angle = Double(i) * 2 * .pi / Double(points)
            
            // Organic movement with breathing rhythm - smoother
            var r = radius
            
            // Primary breathing wave - slower
            r += sin(angle * 3 + time * 0.8) * radius * 0.15
            
            // Secondary wave for organic feel - gentler
            r += cos(angle * 4 + time * 1.0) * radius * 0.08
            
            // Add subtle complexity based on layer
            if complexity > 2 {
                r += sin(angle * 6 + time * 1.5) * radius * 0.04
            }
            
            // Very gentle pulsing
            r *= (1 + sin(time * 1.0) * 0.03)
            
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Simple lines instead of curves for performance
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
    
    private func drawEnergyTendrils(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Skip tendrils for performance
        return
    }
    
    private func drawPlasmaCore(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Just one simple plasma layer for performance
        let plasmaPath = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        context.fill(
            plasmaPath,
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.9),
                    phaseColor(for: phase, isInhale: isInhale).opacity(0.7),
                    Color.clear
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
        
        // Bright white core
        let corePath = Path(ellipseIn: CGRect(
            x: center.x - radius * 0.3,
            y: center.y - radius * 0.3,
            width: radius * 0.6,
            height: radius * 0.6
        ))
        
        context.fill(corePath, with: .color(.white.opacity(0.95)))
    }
    
    private func startAnimation() {
        // Cancel any existing timer first
        stopAnimation()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/15.0, repeats: true) { _ in
            withAnimation(.linear(duration: 0.066)) {
                time += 0.05  // Slower time progression
                waveOffset += 0.06
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func startHeartPulse() {
        stopHeartPulse()
        
        // Update pulse based on actual heart rate
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { _ in
            let pulseInterval = heartRateManager.getPulseInterval()
            // Create smooth heartbeat animation
            heartPulse += 1.0 / (pulseInterval * 30.0)
            if heartPulse >= 1.0 {
                heartPulse -= 1.0
            }
        }
    }
    
    private func stopHeartPulse() {
        pulseTimer?.invalidate()
        pulseTimer = nil
    }
    
    private func getPhaseHue(phase: BreathPhase, isInhale: Bool) -> Double {
        switch phase {
        case .holding:
            return 0.75 // Purple
        case .recovery, .preRecovery:
            return 0.33 // Green
        default:
            return isInhale ? 0.5 : 0.08 // Cyan or Orange
        }
    }
    
    private func phaseColor(for phase: BreathPhase, isInhale: Bool) -> Color {
        switch phase {
        case .holding:
            return Color.purple
        case .recovery, .preRecovery:
            return Color.green
        default:
            return isInhale ? Color.cyan : Color.orange
        }
    }
}