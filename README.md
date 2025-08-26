# Breath Practice for Apple Watch

A watchOS app for guided breathing exercises based on the Wim Hof method. This app helps users practice controlled breathing with visual and haptic feedback.

## Features

- **3-Round Breathing Sessions**: Each session consists of 3 rounds of breathing exercises
- **Customizable Settings**:
  - Number of breaths per round (10-50)
  - Breath length (3.0-8.0 seconds)
- **Visual Breath Indicator**: Animated circle that expands on inhale and contracts on exhale
- **Haptic Feedback**: Feel the rhythm of your breathing through watch haptics
- **Breath Phases**:
  1. Starting countdown
  2. Breathing phase (customizable number of breaths)
  3. Holding phase (track how long you can hold)
  4. Recovery phase (15 seconds)

## How to Use

1. Open the app in Xcode
2. Select your Apple Watch as the target device
3. Build and run the project
4. On your Apple Watch:
   - Tap "Start" to begin a session
   - Follow the visual indicator for breathing rhythm
   - Hold your breath when prompted
   - Tap "Finish Hold" when ready to continue
   - Complete all 3 rounds

## Project Structure

- `BreathPracticeApp.swift` - Main app entry point
- `ContentView.swift` - Main UI view with controls and animations
- `BreathViewModel.swift` - Business logic and state management

## Requirements

- Xcode 14.0+
- watchOS 9.0+
- Apple Watch Series 3 or newer

## Installation

1. Clone the repository
2. Open `BreathPractice.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run on your Apple Watch

## Based On

This watchOS app is based on a JavaScript web implementation of a breath practice tool, adapted for the Apple Watch platform with native SwiftUI components and haptic feedback.