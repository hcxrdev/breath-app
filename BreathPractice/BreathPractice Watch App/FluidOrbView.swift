import SwiftUI

struct FluidOrbView: View {
    let breathScale: CGFloat
    let isInhale: Bool
    let phase: BreathPhase
    @State private var time: Double = 0
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 2
            
            // Create multiple fluid layers with metaball effect
            for layer in 0..<12 {
                let layerFactor = CGFloat(layer) / 12.0
                let layerTime = time + Double(layer) * 0.15
                
                // Create organic blob path
                let path = createFluidPath(
                    center: center,
                    radius: baseRadius * breathScale * (0.3 + layerFactor * 0.4),
                    time: layerTime,
                    complexity: 8 - layer/2
                )
                
                // Dynamic color based on phase and depth
                let hue = getPhaseHue(phase: phase, isInhale: isInhale) + layerFactor * 0.1
                let saturation = 0.6 + sin(layerTime) * 0.2
                let brightness = 0.9 - layerFactor * 0.3
                
                let layerColor = Color(hue: hue, saturation: saturation, brightness: brightness)
                
                // Apply gradient fill with glow effect
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [
                            layerColor.opacity(0.8 - layerFactor * 0.5),
                            layerColor.opacity(0.4 - layerFactor * 0.3),
                            Color.clear
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: baseRadius * breathScale
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
        }
    }
    
    private func createFluidPath(center: CGPoint, radius: CGFloat, time: Double, complexity: Int) -> Path {
        var path = Path()
        let points = 64
        
        for i in 0...points {
            let angle = Double(i) * 2 * .pi / Double(points)
            
            // Create organic movement with multiple sine waves
            var r = radius
            
            // Primary wave
            r += sin(angle * 3 + time * 2) * radius * 0.15
            
            // Secondary wave
            r += cos(angle * 5 + time * 3) * radius * 0.1
            
            // Tertiary micro-movements
            r += sin(angle * 8 + time * 5) * radius * 0.05
            
            // Breathing pulse
            r += sin(time * 4) * radius * 0.1
            
            // Add noise-like variation
            for j in 1...complexity {
                let freq = Double(j) * 2
                let amp = radius * (0.05 / Double(j))
                r += sin(angle * freq + time * freq * 0.5) * amp
            }
            
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Use curves for smoother shape
                let prevAngle = Double(i-1) * 2 * .pi / Double(points)
                let prevR = radius + 
                    sin(prevAngle * 3 + time * 2) * radius * 0.15 +
                    cos(prevAngle * 5 + time * 3) * radius * 0.1
                
                let prevX = center.x + cos(prevAngle) * prevR
                let prevY = center.y + sin(prevAngle) * prevR
                
                let controlX = (prevX + x) / 2
                let controlY = (prevY + y) / 2
                
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: controlX, y: controlY)
                )
            }
        }
        
        path.closeSubpath()
        return path
    }
    
    private func drawEnergyTendrils(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let tendrilCount = 6
        
        for i in 0..<tendrilCount {
            let angle = Double(i) * 2 * .pi / Double(tendrilCount) + time
            let tendrilPath = Path { path in
                path.move(to: center)
                
                // Create curved tendril
                for t in stride(from: 0.0, to: 1.0, by: 0.02) {
                    let distance = radius * breathScale * t * 1.5
                    let wave = sin(t * .pi * 4 + time * 3) * 20
                    let x = center.x + cos(angle + wave * 0.01) * distance
                    let y = center.y + sin(angle + wave * 0.01) * distance
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let opacity = 0.3 * (1 - abs(sin(time * 2 + Double(i))))
            let tendrilColor = isInhale ? Color.cyan : Color.orange
            
            context.stroke(
                tendrilPath,
                with: .linearGradient(
                    Gradient(colors: [
                        tendrilColor.opacity(opacity),
                        tendrilColor.opacity(opacity * 0.3),
                        Color.clear
                    ]),
                    startPoint: center,
                    endPoint: CGPoint(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                ),
                lineWidth: 2
            )
        }
    }
    
    private func drawPlasmaCore(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Multiple plasma layers for depth
        for i in 0..<5 {
            let layerRadius = radius * (1 - CGFloat(i) * 0.15)
            let plasmaPath = Path(ellipseIn: CGRect(
                x: center.x - layerRadius,
                y: center.y - layerRadius,
                width: layerRadius * 2,
                height: layerRadius * 2
            ))
            
            let pulseIntensity = 0.5 + sin(time * 6 + Double(i)) * 0.5
            
            context.fill(
                plasmaPath,
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(pulseIntensity),
                        phaseColor(for: phase, isInhale: isInhale).opacity(pulseIntensity * 0.8),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: layerRadius
                )
            )
        }
        
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
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            time += 0.016
            waveOffset += 0.02
        }
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