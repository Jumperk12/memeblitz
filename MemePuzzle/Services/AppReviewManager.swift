import Foundation
import StoreKit
import UIKit

/// Manages App Store review requests via StoreKit.
/// Triggered automatically once the user finishes their first 2 puzzles.
@MainActor
public final class AppReviewManager: ObservableObject {
    public static let shared = AppReviewManager()

    private let reviewRequestedKey = "hasRequestedAppStoreReview"

    @Published public var showReviewPrompt: Bool = false

    private init() {}

    /// Checks if the player just hit the 2-puzzle solved milestone.
    public func checkMilestone() {
        guard !UserDefaults.standard.bool(forKey: reviewRequestedKey) else { return }

        if GameProfile.shared.totalSolvedCount == 2 {
            showReviewPrompt = true
        }
    }

    /// Invokes Apple's native StoreKit in-app rating dialog.
    public func requestNativeReview() {
        showReviewPrompt = false
        UserDefaults.standard.set(true, forKey: reviewRequestedKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }

    public func dismissPrompt() {
        showReviewPrompt = false
        UserDefaults.standard.set(true, forKey: reviewRequestedKey)
    }
}
