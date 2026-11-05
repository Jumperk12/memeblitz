import AppTrackingTransparency
import Foundation
import UIKit

/// Manages App Tracking Transparency (ATT) permission and pre-prompt onboarding.
@MainActor
public final class AppTrackingManager: ObservableObject {
    public static let shared = AppTrackingManager()

    private let userDefaultsKey = "hasRequestedAppTracking"

    @Published public var showTrackingExplainer: Bool = false

    private init() {}

    /// Checks if tracking authorization should be prompted to the user on first launch.
    public func checkAndRequestTracking() {
        guard !UserDefaults.standard.bool(forKey: userDefaultsKey) else { return }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            showTrackingExplainer = true
        } else {
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
        }
    }

    /// Triggers Apple's native App Tracking Transparency permission dialog.
    public func requestNativeTracking() {
        showTrackingExplainer = false
        UserDefaults.standard.set(true, forKey: userDefaultsKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ATTrackingManager.requestTrackingAuthorization { status in
                #if DEBUG
                print("🔒 ATT Status: \(status.rawValue)")
                #endif
            }
        }
    }

    /// If user skips the explainer, prompt native ATT directly.
    public func dismissExplainer() {
        requestNativeTracking()
    }
}
