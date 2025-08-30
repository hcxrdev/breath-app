import SwiftUI

struct PowerOrbView: View {
    let holdTime: TimeInterval
    @State private var energyPulse: Double = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 2
            
            // Calculate growth based on hold time
            // Starts as a dot, grows significantly at 60s, massive at 120s+
            let growthFactor = calculateGrowthFactor(holdTime)
            let orbRadius = baseRadius * growthFactor
            
            // Calculate color transition from orange to reddish purple
            let colorProgress = min(holdTime / 120.0, 1.0)
            
            // Draw energy field when approaching/past 120s
            if holdTime > 90 {
                drawEnergyField(context: context, center: center, radius: orbRadius, intensity: colorProgress)
            }
            
            // Draw multiple layers for depth
            for layer in stride(from: 3, through: 0, by: -1) {
                let layerFactor = CGFloat(layer) / 3.0
                let layerRadius = orbRadius * (0.7 + layerFactor * 0.3)
                
                // Create pulsing effect that intensifies with time
                let pulseAmount = sin(energyPulse * (2 + holdTime / 60)) * (0.1 + holdTime / 600)
                let actualRadius = layerRadius * (1 + pulseAmount)
                
                // Dynamic color based on time and layer
                let layerColor = getLayerColor(progress: colorProgress, layer: layer)
                
                // Create the orb path
                let orbPath = createPowerPath(
                    center: center,
                    radius: actualRadius,
                    time: energyPulse + Double(layer) * 0.2,
                    intensity: colorProgress
                )
                
                // Apply gradient fill
                context.fill(
                    orbPath,
                    with: .radialGradient(
                        Gradient(colors: [
                            layerColor.opacity(0.9 - layerFactor * 0.3),
                            layerColor.opacity(0.5 - layerFactor * 0.2),
                            Color.clear
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: actualRadius
                    )
                )
                
                // Add inner glow for power effect
                if layer == 0 && holdTime > 30 {
                    context.stroke(
                        orbPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.5 * colorProgress),
                                layerColor.opacity(0.3)
                            ]),
                            startPoint: CGPoint(x: center.x - 20, y: center.y - 20),
                            endPoint: CGPoint(x: center.x + 20, y: center.y + 20)
                        ),
                        lineWidth: 2
                    )
                }
            }
            
            // Draw bright core that intensifies with time
            drawPowerCore(context: context, center: center, radius: orbRadius * 0.3, intensity: colorProgress)
            
            // Add lightning/energy effects at high power levels
            if holdTime > 100 {
                drawEnergyBolts(context: context, center: center, radius: orbRadius, intensity: colorProgress)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func calculateGrowthFactor(_ time: TimeInterval) -> CGFloat {
        // Exponential growth curve
        // Starts at 0.05 (tiny dot), reaches 0.5 at 60s, 0.8 at 120s, continues growing
        
        if time < 10 {
            // Very small at start
            return 0.05 + (time / 10) * 0.1
        } else if time < 60 {
            // Gradual growth to 60s
            return 0.15 + (time - 10) / 50 * 0.35
        } else if time < 120 {
            // Accelerating growth from 60-120s
            let t = (time - 60) / 60
            return 0.5 + t * 0.3 + pow(t, 2) * 0.1
        } else {
            // Continue growing but slower after 120s
            let excess = (time - 120) / 120
            return min(0.9 + excess * 0.1, 1.0)
        }
    }
    
    private func getLayerColor(progress: Double, layer: Int) -> Color {
        // Transition from orange to reddish purple
        let hue: Double
        let saturation: Double
        let brightness: Double
        
        if progress < 0.5 {
            // Orange to red transition
            hue = 0.08 - progress * 0.08 // Orange to red
            saturation = 0.9
            brightness = 0.9 - Double(layer) * 0.1
        } else {
            // Red to purple transition
            hue = 0.0 + (progress - 0.5) * 0.6 // Red to purple
            saturation = 0.8 + progress * 0.2
            brightness = 0.8 - Double(layer) * 0.1
        }
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func createPowerPath(center: CGPoint, radius: CGFloat, time: Double, intensity: Double) -> Path {
        var path = Path()
        let points = 32
        
        for i in 0...points {
            let angle = Double(i) * 2 * .pi / Double(points)
            
            // Create increasingly chaotic movement at higher power
            var r = radius
            
            // Base wave
            r += sin(angle * 3 + time * 2) * radius * 0.1
            
            // Power surge waves that increase with intensity
            if intensity > 0.3 {
                r += cos(angle * 5 + time * 3) * radius * 0.1 * intensity
            }
            
            if intensity > 0.7 {
                // Chaotic energy at high power
                r += sin(angle * 8 + time * 5) * radius * 0.05 * intensity
                r += cos(angle * 11 + time * 7) * radius * 0.03 * intensity
            }
            
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
    
    private func drawPowerCore(context: GraphicsContext, center: CGPoint, radius: CGFloat, intensity: Double) {
        // Multiple glow layers
        for i in 0..<3 {
            let glowRadius = radius * (1 + CGFloat(i) * 0.3)
            let glowPath = Path(ellipseIn: CGRect(
                x: center.x - glowRadius,
                y: center.y - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            ))
            
            context.fill(
                glowPath,
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.9 - Double(i) * 0.2),
                        getLayerColor(progress: intensity, layer: 0).opacity(0.5 - Double(i) * 0.1),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )
        }
    }
    
    private func drawEnergyField(context: GraphicsContext, center: CGPoint, radius: CGFloat, intensity: Double) {
        // Rotating energy field
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 + energyPulse * 0.5
            let fieldPath = Path { path in
                path.move(to: center)
                
                let endX = center.x + cos(angle) * radius * 1.5
                let endY = center.y + sin(angle) * radius * 1.5
                
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            
            let opacity = 0.2 * intensity * (0.5 + sin(energyPulse * 3 + Double(i)) * 0.5)
            
            context.stroke(
                fieldPath,
                with: .linearGradient(
                    Gradient(colors: [
                        getLayerColor(progress: intensity, layer: 0).opacity(opacity),
                        Color.clear
                    ]),
                    startPoint: center,
                    endPoint: CGPoint(x: center.x + cos(angle) * radius * 1.5,
                                    y: center.y + sin(angle) * radius * 1.5)
                ),
                lineWidth: 2
            )
        }
    }
    
    private func drawEnergyBolts(context: GraphicsContext, center: CGPoint, radius: CGFloat, intensity: Double) {
        // Lightning-like energy bolts
        for i in 0..<4 {
            let baseAngle = Double(i) * .pi / 2 + energyPulse
            let boltPath = Path { path in
                path.move(to: center)
                
                // Create jagged bolt path
                var currentRadius: CGFloat = 0
                while currentRadius < radius * 1.2 {
                    currentRadius += 10
                    let jitter = CGFloat.random(in: -5...5)
                    let angle = baseAngle + sin(currentRadius * 0.1 + energyPulse * 5) * 0.2
                    
                    let x = center.x + cos(angle) * (currentRadius + jitter)
                    let y = center.y + sin(angle) * (currentRadius + jitter)
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let boltOpacity = 0.5 * intensity * (0.3 + sin(energyPulse * 10 + Double(i) * 2) * 0.7)
            
            context.stroke(
                boltPath,
                with: .color(Color.white.opacity(boltOpacity)),
                lineWidth: 1.5
            )
        }
    }
    
    private func startAnimation() {
        stopAnimation()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { _ in
            energyPulse += 0.05
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}