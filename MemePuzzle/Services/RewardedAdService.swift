import Foundation
import GoogleMobileAds
import UIKit

public enum RewardedAdError: Error, LocalizedError, Equatable {
    case adNotReady
    case loadFailed(String)
    case presentationFailed(String)
    case dismissedWithoutReward
    case networkUnavailable
    case noRootViewController

    public var errorDescription: String? {
        switch self {
        case .adNotReady:
            "The rewarded video is buffering. Please try again in a moment."
        case .loadFailed(let msg):
            "Ad loading failed: \(msg)"
        case .presentationFailed(let msg):
            "Failed to present ad: \(msg)"
        case .dismissedWithoutReward:
            "The video was closed before completion. Watch the full ad to earn extra time."
        case .networkUnavailable:
            "Network connection is offline. Connect to the internet to watch an ad."
        case .noRootViewController:
            "Unable to find active screen to present ad."
        }
    }
}

public protocol RewardedAdServiceProtocol: AnyObject, Sendable {
    @MainActor var isAdAvailable: Bool { get }
    @MainActor var statusDescription: String { get }
    func preload() async
    @MainActor
    func showRewardedAd(
        from viewController: UIViewController?,
        onReward: @escaping @Sendable (Int) -> Void
    ) async -> Result<Int, RewardedAdError>
}

/// Production Google Mobile Ads (AdMob) Rewarded Video Service.
///
/// Configured with user's live AdMob credentials:
/// - App ID: ca-app-pub-6761529298065224~9369004306 (Info.plist)
/// - Ad Unit ID: ca-app-pub-6761529298065224/5562008270
@MainActor
public final class RewardedAdService: NSObject, RewardedAdServiceProtocol, GADFullScreenContentDelegate, @unchecked Sendable {
    public static let shared = RewardedAdService()

    /// Live Production Ad Unit ID created by the user in AdMob
    public static let productionAdUnitID = "ca-app-pub-6761529298065224/5562008270"

    /// Google Sample Test Ad Unit ID (guaranteed to fill immediately while new AdMob units propagate)
    public static let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// Additional seconds awarded to continue the puzzle upon watching the ad.
    public static let extensionSeconds = 20

    private var rewardedAd: GADRewardedAd?
    private var isPreloading = false
    private var isShowing = false
    private var didGrantReward = false

    private var presentationContinuation: CheckedContinuation<Result<Int, RewardedAdError>, Never>?

    public var isAdAvailable: Bool {
        rewardedAd != nil && !isShowing
    }

    public var statusDescription: String {
        if isShowing { return "Showing Ad…" }
        if rewardedAd != nil { return "Ad Ready (+20s)" }
        return "Buffering Ad…"
    }

    public func preload() async {
        guard rewardedAd == nil, !isPreloading else { return }
        isPreloading = true
        await loadAdWithFallback(unitID: Self.productionAdUnitID)
    }

    private func loadAdWithFallback(unitID: String) async {
        let request = GADRequest()

        await withCheckedContinuation { continuation in
            GADRewardedAd.load(withAdUnitID: unitID, request: request) { [weak self] ad, error in
                Task { @MainActor [weak self] in
                    guard let self else {
                        continuation.resume()
                        return
                    }

                    if error != nil {
                        // If production unit is newly created and not yet activated by AdMob,
                        // fallback to Google test unit so player is never locked out during onboarding or testing.
                        if unitID == Self.productionAdUnitID {
                            await self.loadAdDirect(unitID: Self.testAdUnitID)
                            continuation.resume()
                            return
                        } else {
                            self.isPreloading = false
                            continuation.resume()
                            return
                        }
                    }

                    ad?.fullScreenContentDelegate = self
                    self.rewardedAd = ad
                    self.isPreloading = false
                    continuation.resume()
                }
            }
        }
    }

    private func loadAdDirect(unitID: String) async {
        let request = GADRequest()
        await withCheckedContinuation { continuation in
            GADRewardedAd.load(withAdUnitID: unitID, request: request) { [weak self] ad, _ in
                Task { @MainActor [weak self] in
                    guard let self else {
                        continuation.resume()
                        return
                    }
                    if let ad {
                        ad.fullScreenContentDelegate = self
                        self.rewardedAd = ad
                    }
                    self.isPreloading = false
                    continuation.resume()
                }
            }
        }
    }

    public func showRewardedAd(
        from viewController: UIViewController?,
        onReward: @escaping @Sendable (Int) -> Void
    ) async -> Result<Int, RewardedAdError> {
        guard !isShowing else {
            return .failure(.presentationFailed("Another ad is already playing."))
        }
        guard let ad = rewardedAd else {
            Task { await self.preload() }
            return .failure(.adNotReady)
        }

        isShowing = true
        didGrantReward = false

        let presentingVC = viewController ?? getTopViewController()
        guard let presentingVC else {
            isShowing = false
            return .failure(.noRootViewController)
        }

        return await withCheckedContinuation { continuation in
            self.presentationContinuation = continuation

            ad.present(fromRootViewController: presentingVC) { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.didGrantReward = true
                    onReward(Self.extensionSeconds)
                }
            }
        }
    }

    // MARK: - GADFullScreenContentDelegate

    public nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.rewardedAd = nil
            self.isShowing = false
            let granted = self.didGrantReward

            if let continuation = self.presentationContinuation {
                self.presentationContinuation = nil
                if granted {
                    continuation.resume(returning: .success(Self.extensionSeconds))
                } else {
                    continuation.resume(returning: .failure(.dismissedWithoutReward))
                }
            }

            await self.preload()
        }
    }

    public nonisolated func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            self.rewardedAd = nil
            self.isShowing = false

            if let continuation = self.presentationContinuation {
                self.presentationContinuation = nil
                continuation.resume(returning: .failure(.presentationFailed(error.localizedDescription)))
            }

            await self.preload()
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = rootViewController
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
