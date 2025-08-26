import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BreathViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Breath Practice")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(viewModel.phaseDisplay)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(viewModel.timerDisplay)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 35)
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    viewModel.isInhale ? Color.purple : Color.orange,
                                    viewModel.isInhale ? Color.purple.opacity(0.6) : Color.yellow
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(viewModel.breathScale)
                        .animation(.linear(duration: 0.05), value: viewModel.breathScale)
                }
                .frame(width: 80, height: 80)
                .padding(.vertical, 10)
                
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: viewModel.startStop) {
                            Text(viewModel.isActive ? "Pause" : "Start")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(StartButtonStyle())
                        
                        Button(action: viewModel.reset) {
                            Text("Reset")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(ResetButtonStyle())
                    }
                    
                    if viewModel.phase == .holding {
                        Button(action: viewModel.finishHolding) {
                            Text("Finish Hold")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(FinishButtonStyle())
                    }
                }
                
                if !viewModel.isActive {
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: viewModel.decreaseBreaths) {
                                Image(systemName: "minus")
                            }
                            .buttonStyle(AdjustButtonStyle())
                            
                            Text("Breaths: \(viewModel.totalBreaths)")
                                .font(.system(size: 12))
                                .frame(minWidth: 80)
                            
                            Button(action: viewModel.increaseBreaths) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(AdjustButtonStyle())
                        }
                        
                        HStack {
                            Button(action: viewModel.decreaseLength) {
                                Image(systemName: "minus")
                            }
                            .buttonStyle(AdjustButtonStyle())
                            
                            Text("Length: \(String(format: "%.1f", viewModel.breathLength))s")
                                .font(.system(size: 12))
                                .frame(minWidth: 80)
                            
                            Button(action: viewModel.increaseLength) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(AdjustButtonStyle())
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.16, blue: 0.42),
                    Color(red: 0.7, green: 0.12, blue: 0.12),
                    Color(red: 0.99, green: 0.73, blue: 0.18)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(red: 0.99, green: 0.73, blue: 0.18))
            .foregroundColor(Color(red: 0.1, green: 0.16, blue: 0.42))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ResetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(red: 0.7, green: 0.12, blue: 0.12))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct FinishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(red: 0.1, green: 0.16, blue: 0.42))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct AdjustButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 28, height: 28)
            .background(Color(red: 0.1, green: 0.16, blue: 0.42))
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}