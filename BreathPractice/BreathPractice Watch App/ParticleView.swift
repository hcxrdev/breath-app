import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var angle: Double
    var speed: Double
    var orbit: Double
}

struct FireflyParticlesView: View {
    let breathScale: CGFloat
    let isInhale: Bool
    let phase: BreathPhase
    @State private var particles: [Particle] = []
    @State private var time: Double = 0
    
    let particleCount = 60 // Increased for richer pattern
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                particleColor(for: phase, isInhale: isInhale).opacity(0.9),
                                particleSecondaryColor(for: phase, isInhale: isInhale).opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 1
                        )
                    )
                    .frame(width: particle.scale * 3, height: particle.scale * 3)
                    .opacity(particle.opacity)
                    .position(
                        x: 70 + particle.x * 70 * breathScale, // Scaled to 2x (70 radius instead of 35)
                        y: 70 + particle.y * 70 * breathScale
                    )
                    .blendMode(.plusLighter)
            }
        }
        .frame(width: 140, height: 140) // 2x size
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onChange(of: breathScale) { oldValue, newValue in
            updateParticles()
        }
    }
    
    private func initializeParticles() {
        particles = (0..<particleCount).map { i in
            let golden = (1 + sqrt(5)) / 2 // Golden ratio
            let angleOffset = Double(i) * 2 * Double.pi * golden // Fibonacci spiral
            let radius = sqrt(Double(i)) / sqrt(Double(particleCount))
            
            return Particle(
                x: CGFloat(cos(angleOffset) * radius),
                y: CGFloat(sin(angleOffset) * radius),
                scale: CGFloat.random(in: 0.3...1.2),
                opacity: Double.random(in: 0.5...1.0),
                angle: angleOffset,
                speed: Double.random(in: 0.5...2.0),
                orbit: Double.random(in: 0.3...1.0)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            time += 0.05
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            let particle = particles[i]
            
            // Lissajous curves for complex patterns
            let a = 3.0
            let b = 4.0
            let delta = Double.pi / 2
            
            // Base position using Lissajous curves
            let lissajousX = sin(a * time * particle.speed + particle.angle)
            let lissajousY = sin(b * time * particle.speed + delta + particle.angle)
            
            // Spiral expansion based on breathing
            let spiralRadius = particle.orbit * (0.3 + 0.7 * sin(time * 2))
            
            // Rose curve modulation for flower-like patterns
            let rose = cos(4 * (particle.angle + time * 0.5))
            let roseRadius = spiralRadius * (0.8 + 0.2 * rose)
            
            // Combine patterns
            particles[i].x = CGFloat(lissajousX * roseRadius)
            particles[i].y = CGFloat(lissajousY * roseRadius)
            
            // Pulsing opacity creates twinkling effect
            particles[i].opacity = 0.4 + 0.6 * sin(time * 3 * particle.speed + Double(i))
            
            // Scale variation for depth
            particles[i].scale = CGFloat(0.3 + 0.7 * (sin(time * 2 + Double(i) * 0.2) + 1) / 2)
        }
    }
    
    func particleColor(for phase: BreathPhase, isInhale: Bool) -> Color {
        switch phase {
        case .holding:
            return Color.purple
        case .recovery, .preRecovery:
            return Color.green
        default:
            return isInhale ? Color.cyan : Color.orange
        }
    }
    
    func particleSecondaryColor(for phase: BreathPhase, isInhale: Bool) -> Color {
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