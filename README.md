# Shakti:Breath - Biometric Breathing Practice for Apple Watch

A sophisticated watchOS app for guided breathing exercises based on the Wim Hof method, enhanced with real-time biometric monitoring. This app synchronizes breathing exercises with your heart rate to optimize your practice through visual, haptic, and biometric feedback.

## Features

### Core Breathing Practice
- **3-Round Breathing Sessions**: Each session consists of 3 rounds of breathing exercises
- **Customizable Settings**:
  - Number of breaths per round (10-50)
  - Breath length (3.0-8.0 seconds)
- **Breath Phases**:
  1. Starting countdown
  2. Breathing phase (customizable number of breaths)
  3. Holding phase (track how long you can hold)
  4. Recovery phase (15 seconds)

### Biometric Integration
- **Real-Time Heart Rate Monitoring**: The breathing orb pulses in perfect sync with your heartbeat
- **Heart Rate Variability (HRV) Tracking**: 
  - Monitors HRV using RMSSD (Root Mean Square of Successive Differences) algorithm
  - Color-coded feedback indicates your stress/relaxation state:
    - 🔴 Red/Orange: Low HRV (stressed)
    - 🟢 Green: Optimal HRV 
    - 🔵 Blue/Purple: Excellent HRV (very relaxed)
- **HealthKit Integration**: Seamlessly reads heart rate data with proper permissions

### Advanced Visualizations
- **Fluid Orb Animation**: Beautiful, organic breathing visualization that responds to your physiology
- **Power Orb During Hold**: Special visualization during breath holds that grows with time and pulses with your heart
- **Firefly Particles**: Ambient particle effects that react to breathing patterns
- **Dynamic Gradient Background**: Slowly rotating gradient for a calming effect

### Enhanced User Experience
- **Haptic Feedback**: Strategic haptic cues at key transitions
- **Extended Runtime Session**: Keeps the app active during long breathing sessions
- **Clean, Modern UI**: Uppercase buttons, optimal sizing for watch interface

## How to Use

1. Open the app in Xcode
2. Select your Apple Watch as the target device
3. Build and run the project
4. On your Apple Watch:
   - Grant HealthKit permissions when prompted
   - Tap "START" to begin a session
   - Follow the visual indicator for breathing rhythm
   - Watch the orb pulse with your heartbeat
   - Hold your breath when prompted
   - Tap "FINISH HOLD" when ready to continue
   - Complete all 3 rounds

## Project Structure

- `BreathPracticeApp.swift` - Main app entry point
- `ContentView.swift` - Main UI view with controls and animations
- `BreathViewModel.swift` - Business logic and state management
- `HeartRateManager.swift` - HealthKit integration and HRV calculations
- `FluidOrbView.swift` - Main breathing orb visualization
- `PowerOrbView.swift` - Special visualization for breath hold phase
- `ParticleView.swift` - Firefly particle effects
- `Info.plist` - App configuration including HealthKit permissions

## Requirements

- Xcode 16.0+
- watchOS 11.0+
- Apple Watch Series 4 or newer (for best heart rate monitoring)

## Installation

1. Clone the repository
2. Open `BreathPractice.xcodeproj` in Xcode
3. Select your development team in project settings
4. Ensure HealthKit capability is enabled
5. Build and run on your Apple Watch

## Privacy & Permissions

This app requires the following permissions:
- **HealthKit Read Access**: To monitor heart rate and HRV
- **HealthKit Write Access**: Optional, for tracking breathing sessions as mindfulness activities

All health data remains private on your device and is never transmitted or stored externally.

## Based On

This watchOS app is inspired by the Wim Hof breathing method and enhanced with modern biometric monitoring capabilities. It combines ancient breathing practices with cutting-edge health technology to provide a uniquely powerful breathing practice tool.

## Version History

- **v2.0** - Added real-time heart rate synchronization, HRV monitoring, and renamed to Shakti:Breath
- **v1.0** - Initial release with basic Wim Hof breathing exercises