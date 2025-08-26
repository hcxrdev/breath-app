import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var angle: Double
}

struct FireflyParticlesView: View {
    let breathScale: CGFloat
    let isInhale: Bool
    @State private var particles: [Particle] = []
    @State private var time: Double = 0
    
    let particleCount = 40 // Reduced for performance
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(isInhale ? Color.cyan : Color.orange)
                    .frame(width: 2, height: 2)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(
                        x: 35 + particle.x * 30 * breathScale,
                        y: 35 + particle.y * 30 * breathScale
                    )
                    .blendMode(.plusLighter)
            }
        }
        .frame(width: 70, height: 70)
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onChange(of: breathScale) { _ in
            updateParticles()
        }
    }
    
    private func initializeParticles() {
        particles = (0..<particleCount).map { i in
            let angle = Double(i) * (360.0 / Double(particleCount)) * .pi / 180
            let radius = Double.random(in: 0.3...1.0)
            return Particle(
                x: CGFloat(cos(angle) * radius),
                y: CGFloat(sin(angle) * radius),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.4...0.9),
                angle: angle
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            time += 0.1
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            let baseAngle = particles[i].angle + time * 0.5
            let turbulence = sin(time * 3 + Double(i)) * 0.1
            let radius = (0.3 + sin(time * 2 + Double(i) * 0.5) * 0.3)
            
            particles[i].x = CGFloat(cos(baseAngle + turbulence) * radius)
            particles[i].y = CGFloat(sin(baseAngle + turbulence) * radius)
            particles[i].opacity = 0.4 + sin(time * 4 + Double(i) * 0.3) * 0.3
        }
    }
}