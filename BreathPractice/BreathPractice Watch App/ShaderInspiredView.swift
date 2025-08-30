import SwiftUI

struct ShaderInspiredView: View {
    let breathScale: CGFloat
    let isInhale: Bool
    let phase: BreathPhase
    @State private var time: Double = 0
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2
            
            // Simulate ray marching with multiple layers
            drawRayMarchedVolume(context: context, center: center, maxRadius: maxRadius)
            
            // Create multiple layers for depth (simulating volumetric rendering)
            for layer in 0..<8 {
                let layerTime = time + Double(layer) * 0.2
                let layerScale = 1.0 - Double(layer) * 0.1
                let layerDepth = Double(layer) / 8.0
                
                // Create path with mathematical distortions
                var path = Path()
                let points = 256 // Higher resolution for smoother curves
                
                for i in 0...points {
                    let angle = Double(i) * 2 * .pi / Double(points)
                    
                    // GLSL-inspired SDF (Signed Distance Function) simulation
                    var radius = maxRadius * 0.3 * layerScale * breathScale
                    
                    // Implement the GLSL formula: p += cos(p.yzx*2.)*.2
                    let px = cos(angle) * radius
                    let py = sin(angle) * radius
                    let pz = layerDepth * 24 - 12 // Simulate z-depth
                    
                    // Fractal octaves similar to: s -= abs(dot(sin(p * a), .3+p-p)) / a
                    var fractalAccum = 0.0
                    var amplitude = 0.6
                    for octave in 1...4 {
                        let a = amplitude * pow(2, Double(octave))
                        let fx = sin(px * a + layerTime * 2)
                        let fy = sin(py * a + layerTime * 3)
                        let fz = sin(pz * a + layerTime * 4)
                        fractalAccum += abs(fx * fy * fz) / a
                        amplitude *= 0.5
                    }
                    
                    radius -= fractalAccum * 10
                    
                    // Add rotation matrix transformation: p.xz *= mat2(cos(t*.1+vec4(0,33,11,0)))
                    let rotAngle = time * 0.1 + Double(layer) * 0.5
                    let rotatedX = cos(angle + rotAngle) * radius
                    let rotatedY = sin(angle + rotAngle) * radius
                    
                    // Add multiple sphere SDF influences
                    let sphere1 = sin(sin(time * 2) + time * 0.7) * 6
                    let sphere2 = sin(sin(time * 3) + time * 0.5) * 6
                    let sphereInfluence = exp(-abs(angle - sphere1) * 0.5) + exp(-abs(angle - sphere2) * 0.3)
                    radius += sphereInfluence * 8 * breathScale
                    
                    let x = center.x + CGFloat(rotatedX)
                    let y = center.y + CGFloat(rotatedY)
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()
                
                // Enhanced color based on depth and phase
                let baseColor = phaseColor(for: phase, isInhale: isInhale)
                let depthColor = Color(
                    hue: (layerDepth * 0.1 + time * 0.05).truncatingRemainder(dividingBy: 1.0),
                    saturation: 0.8,
                    brightness: 0.9
                )
                
                // Simulate volumetric lighting with tanh (from GLSL: o = tanh(vec4(1,1,9,0)*o / 1e1))
                let intensity = tanh(Double(8 - layer) / 3.0)
                let opacity = intensity * 0.4 / (Double(layer) + 1)
                
                // Fill with enhanced gradient
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [
                            baseColor.opacity(opacity * 3),
                            depthColor.opacity(opacity * 1.5),
                            baseColor.opacity(opacity * 0.5),
                            Color.clear
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: maxRadius * breathScale * layerScale
                    )
                )
                
                // Add chromatic aberration effect
                let aberrationOffset = 1.0 + sin(time * 2) * 0.5
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.red.opacity(opacity * 0.3),
                            baseColor.opacity(opacity * 0.8),
                            Color.blue.opacity(opacity * 0.3)
                        ]),
                        startPoint: CGPoint(x: center.x - aberrationOffset, y: center.y),
                        endPoint: CGPoint(x: center.x + aberrationOffset, y: center.y)
                    ),
                    lineWidth: 0.5
                )
            }
            
            // Central orb with fractal patterns
            drawCentralOrb(context: context, center: center, size: size)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func drawRayMarchedVolume(context: GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
        // Simulate ray marching steps from GLSL
        let steps = 20
        for step in 0..<steps {
            let t = Double(step) / Double(steps)
            // Removed unused depth variable
            
            // Calculate distance field
            // Removed unused stepTime variable
            let stepRadius = maxRadius * 0.8 * (1.0 - t * 0.5) * breathScale
            
            // Create volumetric circle at this depth
            let volumePath = Path(ellipseIn: CGRect(
                x: center.x - stepRadius,
                y: center.y - stepRadius,
                width: stepRadius * 2,
                height: stepRadius * 2
            ))
            
            // Simulate fog/volume accumulation
            let opacity = 0.02 * exp(-t * 2) * breathScale
            let volumeColor = phaseColor(for: phase, isInhale: isInhale)
            
            context.fill(
                volumePath,
                with: .radialGradient(
                    Gradient(colors: [
                        volumeColor.opacity(opacity * 2),
                        volumeColor.opacity(opacity),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: stepRadius * 0.5,
                    endRadius: stepRadius
                )
            )
        }
    }
    
    private func drawCentralOrb(context: GraphicsContext, center: CGPoint, size: CGSize) {
        let orbRadius = min(size.width, size.height) * 0.15 * breathScale
        
        // Multiple orbital rings
        for i in 0..<8 {
            let ringTime = time * (1 + Double(i) * 0.2)
            let angle = ringTime + Double(i) * .pi / 4
            
            let ringRadius = orbRadius * (0.5 + 0.5 * sin(ringTime * 0.5))
            let ringX = center.x + cos(angle) * ringRadius * 0.8
            let ringY = center.y + sin(angle) * ringRadius * 0.8
            
            let ringPath = Path(ellipseIn: CGRect(
                x: ringX - ringRadius/4,
                y: ringY - ringRadius/4,
                width: ringRadius/2,
                height: ringRadius/2
            ))
            
            let ringColor = phaseColor(for: phase, isInhale: isInhale)
            context.fill(
                ringPath,
                with: .radialGradient(
                    Gradient(colors: [
                        ringColor.opacity(0.6),
                        ringColor.opacity(0.2),
                        Color.clear
                    ]),
                    center: CGPoint(x: ringX, y: ringY),
                    startRadius: 0,
                    endRadius: ringRadius/2
                )
            )
        }
        
        // Main orb
        let orbPath = Path(ellipseIn: CGRect(
            x: center.x - orbRadius,
            y: center.y - orbRadius,
            width: orbRadius * 2,
            height: orbRadius * 2
        ))
        
        context.fill(
            orbPath,
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.9),
                    phaseColor(for: phase, isInhale: isInhale).opacity(0.7),
                    phaseSecondaryColor(for: phase, isInhale: isInhale).opacity(0.3),
                    Color.clear
                ]),
                center: center,
                startRadius: 0,
                endRadius: orbRadius
            )
        )
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            time += 0.016
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
    
    private func phaseSecondaryColor(for phase: BreathPhase, isInhale: Bool) -> Color {
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

// Parametric shape generator for more complex patterns
struct ParametricShape: Shape {
    let time: Double
    let breathScale: CGFloat
    let complexity: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        for i in 0...360 {
            let angle = Double(i) * .pi / 180
            
            // Parametric equations inspired by GLSL shader
            var r = radius * breathScale
            
            // Superformula-like shape
            let m = 8.0
            let n1 = sin(time * 2) * 2 + 3
            let n2 = cos(time * 1.5) * 2 + 3
            let n3 = 2.0
            
            let a = 1.0
            let b = 1.0
            
            let mt = m * angle / 4
            
            let term1 = pow(abs(cos(mt) / a), n2)
            let term2 = pow(abs(sin(mt) / b), n3)
            let superRadius = pow(term1 + term2, -1/n1)
            
            r *= superRadius
            
            // Add fractal noise
            for harmonic in 1...complexity {
                let h = Double(harmonic)
                r += sin(angle * h * 2 + time * h) * (radius / (h * 3))
            }
            
            let x = center.x + CGFloat(cos(angle) * r)
            let y = center.y + CGFloat(sin(angle) * r)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}