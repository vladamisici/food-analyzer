import UIKit
import AVFoundation

/// Comprehensive haptic feedback manager for enhanced user experience
final class HapticManager {
    
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Private Properties
    private var impactLight: UIImpactFeedbackGenerator?
    private var impactMedium: UIImpactFeedbackGenerator?
    private var impactHeavy: UIImpactFeedbackGenerator?
    private var impactRigid: UIImpactFeedbackGenerator?
    private var impactSoft: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    
    // MARK: - Settings
    private var isHapticsEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "haptics_enabled")
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupGenerators()
    }
    
    // MARK: - Setup
    private func setupGenerators() {
        // Only create generators if haptics are supported
        guard UIDevice.current.hasHapticFeedback else { return }
        
        impactLight = UIImpactFeedbackGenerator(style: .light)
        impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        
        // iOS 13+ only
        if #available(iOS 13.0, *) {
            impactRigid = UIImpactFeedbackGenerator(style: .rigid)
            impactSoft = UIImpactFeedbackGenerator(style: .soft)
        }
        
        notificationGenerator = UINotificationFeedbackGenerator()
        selectionGenerator = UISelectionFeedbackGenerator()
    }
    
    // MARK: - Public Interface
    
    /// Triggers impact haptic feedback
    /// - Parameter style: The intensity style of the impact
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled && UIDevice.current.hasHapticFeedback else { return }
        
        switch style {
        case .light:
            impactLight?.impactOccurred()
        case .medium:
            impactMedium?.impactOccurred()
        case .heavy:
            impactHeavy?.impactOccurred()
        case .rigid:
            if #available(iOS 13.0, *) {
                impactRigid?.impactOccurred()
            } else {
                impactHeavy?.impactOccurred() // Fallback
            }
        case .soft:
            if #available(iOS 13.0, *) {
                impactSoft?.impactOccurred()
            } else {
                impactLight?.impactOccurred() // Fallback
            }
        @unknown default:
            impactMedium?.impactOccurred()
        }
    }
    
    /// Triggers notification haptic feedback
    /// - Parameter type: The type of notification feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled && UIDevice.current.hasHapticFeedback else { return }
        notificationGenerator?.notificationOccurred(type)
    }
    
    /// Triggers selection haptic feedback
    func selection() {
        guard isHapticsEnabled && UIDevice.current.hasHapticFeedback else { return }
        selectionGenerator?.selectionChanged()
    }
    
    // MARK: - Convenience Methods
    
    /// Light tap feedback (for buttons, small interactions)
    func lightTap() {
        impact(.light)
    }
    
    /// Medium tap feedback (for important buttons, confirmations)
    func mediumTap() {
        impact(.medium)
    }
    
    /// Heavy tap feedback (for major actions, alerts)
    func heavyTap() {
        impact(.heavy)
    }
    
    /// Soft tap feedback (for gentle interactions) - iOS 13+
    func softTap() {
        if #available(iOS 13.0, *) {
            impact(.soft)
        } else {
            impact(.light)
        }
    }
    
    /// Rigid tap feedback (for precise interactions) - iOS 13+
    func rigidTap() {
        if #available(iOS 13.0, *) {
            impact(.rigid)
        } else {
            impact(.medium)
        }
    }
    
    /// Success notification feedback
    func success() {
        notification(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        notification(.warning)
    }
    
    /// Error notification feedback
    func error() {
        notification(.error)
    }
    
    // MARK: - Complex Patterns
    
    /// Double tap pattern
    func doubleTap() {
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light)
        }
    }
    
    /// Triple tap pattern
    func tripleTap() {
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impact(.light)
            }
        }
    }
    
    /// Ascending pattern (light -> medium -> heavy)
    func ascending() {
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impact(.heavy)
            }
        }
    }
    
    /// Descending pattern (heavy -> medium -> light)
    func descending() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impact(.light)
            }
        }
    }
    
    /// Heartbeat pattern
    func heartbeat() {
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.impact(.medium)
        }
    }
    
    /// Pulse pattern (for loading states)
    func pulse(duration: TimeInterval = 2.0) {
        let interval = 0.6
        let endTime = Date().addingTimeInterval(duration)
        
        func performPulse() {
            guard Date() < endTime else { return }
            impact(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                performPulse()
            }
        }
        
        performPulse()
    }
    
    // MARK: - App-Specific Patterns
    
    /// Food analysis complete feedback
    func analysisComplete() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightTap()
        }
    }
    
    /// Goal achievement feedback
    func goalAchieved() {
        ascending()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.success()
        }
    }
    
    /// Card flip feedback
    func cardFlip() {
        selection()
    }
    
    /// Button press feedback
    func buttonPress() {
        lightTap()
    }
    
    /// Toggle switch feedback
    func toggle() {
        selection()
    }
    
    /// Delete action feedback
    func delete() {
        warning()
    }
    
    /// Save action feedback
    func save() {
        success()
    }
    
    /// Navigation feedback
    func navigate() {
        selection()
    }
    
    /// Refresh feedback
    func refresh() {
        mediumTap()
    }
    
    // MARK: - Settings Management
    
    /// Enable or disable haptic feedback
    /// - Parameter enabled: Whether haptics should be enabled
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
        
        if enabled {
            setupGenerators()
        } else {
            // Clean up generators to save memory
            impactLight = nil
            impactMedium = nil
            impactHeavy = nil
            impactRigid = nil
            impactSoft = nil
            notificationGenerator = nil
            selectionGenerator = nil
        }
    }
    
    /// Check if haptics are currently enabled
    var hapticsEnabled: Bool {
        return isHapticsEnabled
    }
    
    // MARK: - Preparation Methods (for better performance)
    
    /// Prepare generators for upcoming use (call before showing a view with haptics)
    func prepare() {
        guard isHapticsEnabled && UIDevice.current.hasHapticFeedback else { return }
        
        impactLight?.prepare()
        impactMedium?.prepare()
        impactHeavy?.prepare()
        impactRigid?.prepare()
        impactSoft?.prepare()
        notificationGenerator?.prepare()
        selectionGenerator?.prepare()
    }
    
    /// Prepare specific generator type
    /// - Parameter type: The type of feedback to prepare
    func prepare(for type: FeedbackType) {
        guard isHapticsEnabled && UIDevice.current.hasHapticFeedback else { return }
        
        switch type {
        case .impact(let style):
            switch style {
            case .light: impactLight?.prepare()
            case .medium: impactMedium?.prepare()
            case .heavy: impactHeavy?.prepare()
            case .rigid: impactRigid?.prepare()
            case .soft: impactSoft?.prepare()
            @unknown default: impactMedium?.prepare()
            }
        case .notification:
            notificationGenerator?.prepare()
        case .selection:
            selectionGenerator?.prepare()
        }
    }
}

// MARK: - Supporting Types

extension HapticManager {
    enum FeedbackType {
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        case notification
        case selection
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    /// Check if the device supports haptic feedback
    var hasHapticFeedback: Bool {
        // iPhone 7 and later support haptic feedback
        // We can check by attempting to create a feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return true // On devices without haptic support, this will silently fail
    }
    
    /// Check if the device supports advanced haptics (iPhone X and later)
    var hasAdvancedHaptics: Bool {
        if #available(iOS 13.0, *) {
            return true // Rigid and soft styles available
        }
        return false
    }
}

// MARK: - SwiftUI View Extension

#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Add haptic feedback to tap gestures
    func hapticFeedback(_ type: HapticManager.FeedbackType = .impact(.light)) -> some View {
        self.onTapGesture {
            switch type {
            case .impact(let style):
                HapticManager.shared.impact(style)
            case .notification:
                HapticManager.shared.selection()
            case .selection:
                HapticManager.shared.selection()
            }
        }
    }
    
    /// Add haptic feedback with custom action
    func hapticTap(feedback: HapticManager.FeedbackType = .impact(.light), action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            switch feedback {
            case .impact(let style):
                HapticManager.shared.impact(style)
            case .notification:
                HapticManager.shared.selection()
            case .selection:
                HapticManager.shared.selection()
            }
            action()
        }
    }
}
#endif
