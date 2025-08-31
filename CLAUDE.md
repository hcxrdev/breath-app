# Shakti:Breath - Project Context for Claude

## Project Overview
Shakti:Breath is a sophisticated watchOS app for guided breathing exercises based on the Wim Hof method, enhanced with real-time biometric monitoring. The app synchronizes breathing visualizations with the user's actual heart rate for a deeply personalized experience.

## Current State (as of August 31, 2025)
The app is fully functional with heart rate integration working on physical Apple Watch devices. All major features have been implemented and tested.

### Key Features Implemented
1. **Biometric Integration**
   - Real-time heart rate monitoring via HealthKit
   - HRV (Heart Rate Variability) calculation using RMSSD algorithm
   - Color-coded stress/relaxation feedback
   - Orb pulsation synchronized with actual heartbeat

2. **Visual Design**
   - FluidOrbView: Main breathing visualization with heart sync
   - PowerOrbView: Special hold phase visualization that grows over time
   - Firefly particles for ambient effect
   - Slowly rotating gradient background (1/4 speed)
   - Color changes based on breathing phase and HRV

3. **User Interface**
   - "Shakti:Breath" branding (20pt light font when idle)
   - Uppercase button text (START, PAUSE, RESET, FINISH HOLD)
   - Brighter "FINISH HOLD" button with custom BrightGlassButtonStyle
   - Proper padding to avoid cutoff on watch's rounded edges
   - Compact +/- controls for breaths and time settings

4. **Haptic Feedback**
   - Stronger haptics using .directionUp and .success
   - Removed repetitive chiming at end of breath hold
   - Single haptic at key transitions
   - 60-second milestone haptics during hold

## Technical Details

### File Structure
```
BreathPractice/
├── BreathPractice Watch App/
│   ├── BreathPracticeApp.swift     - App entry point
│   ├── ContentView.swift            - Main UI (imports HeartRateManager)
│   ├── BreathViewModel.swift        - Core logic and state
│   ├── HeartRateManager.swift       - HealthKit integration, HRV calculation
│   ├── FluidOrbView.swift          - Breathing orb with heart sync
│   ├── PowerOrbView.swift          - Hold phase orb with heart sync
│   ├── ParticleView.swift          - Firefly particle effects
│   ├── ShaderInspiredView.swift    - Additional visual effects
│   └── Info.plist                  - Includes HealthKit permissions
```

### Key Technical Implementations

#### HRV Calculation (HeartRateManager.swift)
- Uses RMSSD (Root Mean Square of Successive Differences)
- Maintains rolling window of 20 heartbeat intervals
- Smooths values with 0.7 weight to previous, 0.3 to new
- Color mapping: <15ms red, 15-40ms orange→green, 40-70ms green→cyan, >70ms blue/purple

#### Heart Sync Implementation
Both FluidOrbView and PowerOrbView:
- Use `heartPulse` state variable (0.0 to 1.0)
- Timer at 30fps updates based on `heartRateManager.getPulseInterval()`
- Applies `sin(heartPulse * π * 2)` for smooth pulsation
- PowerOrbView: amplitude grows with hold time, but frequency stays locked to heart rate

#### Build Configuration
- Info.plist must have CFBundleExecutable, CFBundleIdentifier, etc.
- GENERATE_INFOPLIST_FILE = NO in project settings
- INFOPLIST_FILE = "BreathPractice Watch App/Info.plist"
- HealthKit entitlements enabled

### Known Issues Resolved
1. ✅ Fixed duplicate Info.plist build errors
2. ✅ Fixed HeartRateManager not being in Xcode project
3. ✅ Fixed button cutoff at bottom of watch screen
4. ✅ Fixed excessive haptic chiming
5. ✅ Fixed heart rate sync speeding up at end of hold

## Testing Commands
```bash
# Run linting/typechecking if available
# npm run lint
# npm run typecheck

# Build and test
# In Xcode: Product → Build
# Deploy to watch via Xcode
```

## GitHub Repository
- URL: https://github.com/hcxrdev/breath-app
- Main branch: main
- Authentication: Uses SSH key (configured for user's GitHub account)

## Next Potential Improvements

### High Priority
1. **Add Breathing Statistics**
   - Track session history in HealthKit
   - Show average hold times
   - Display HRV trends over time

2. **Customizable Breathing Patterns**
   - Add 4-7-8 breathing option
   - Box breathing (4-4-4-4)
   - Custom user-defined patterns

3. **Complications Support**
   - Add watch face complication
   - Quick launch from watch face
   - Show last session time

### Medium Priority
1. **Audio Cues**
   - Optional voice guidance
   - Breathing rhythm sounds
   - End of phase chimes

2. **iPhone Companion App**
   - View detailed statistics
   - Configure advanced settings
   - Export session data

3. **Improved Animations**
   - Particle effects during transitions
   - More dynamic color shifts
   - Smoother gradient rotations

### Low Priority
1. **Social Features**
   - Share sessions with friends
   - Group breathing sessions
   - Leaderboards for hold times

2. **Advanced Biometrics**
   - SpO2 monitoring (if available)
   - Respiratory rate detection
   - Stress level calculation

## Development Notes

### When Resuming Work
1. Open project in Xcode
2. Check that HeartRateManager.swift is in project navigator
3. Ensure Info.plist is properly configured
4. Test on physical device for heart rate features
5. Monitor console for HealthKit permission issues

### Code Style Guidelines
- NO comments unless specifically requested
- Use SwiftUI's declarative style
- Keep haptics subtle but noticeable
- Maintain 115x115 orb size for proper layout
- Test all UI changes on smallest watch size

### Git Workflow
```bash
# Stage changes
git add -A

# Commit with descriptive message
git commit -m "Description of changes

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to GitHub
git push origin main
```

## User Preferences
- Likes stronger haptic feedback
- Prefers uppercase text for buttons
- Wants clean, minimalist UI
- Values biometric accuracy
- Appreciates smooth, non-jarring animations

## Session Summary
Successfully implemented full heart rate integration with HRV monitoring, creating a unique biometric-enhanced breathing app. The app is production-ready and deployed to user's Apple Watch. All code is committed and pushed to GitHub.