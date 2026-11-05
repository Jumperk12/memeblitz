import AVKit
import SwiftUI

/// Edge-to-edge animated video launch screen for Meme Blitz.
struct LaunchScreenView: View {
    let onFinished: () -> Void

    @State private var player: AVPlayer?
    @State private var isDismissed = false
    @State private var observerToken: Any?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let player {
                LaunchVideoPlayerRepresentable(player: player)
                    .ignoresSafeArea()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Unskippable: tapping the launch screen will not dismiss or skip it.
            // Video must play through to completion.
        }
        .onAppear {
            setupAndPlayVideo()
        }
        .onDisappear {
            cleanup()
        }
    }

    private func setupAndPlayVideo() {
        guard let url = Bundle.main.url(forResource: "launch_animation", withExtension: "mp4") else {
            // If resource is not bundled, finish immediately
            finishLaunch()
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none
        self.player = newPlayer

        // Observe end of playback
        let token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            self.finishLaunch()
        }
        self.observerToken = token

        newPlayer.play()

        // Fallback safety timeout (~6.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.2) {
            self.finishLaunch()
        }
    }

    private func finishLaunch() {
        guard !isDismissed else { return }
        isDismissed = true
        cleanup()
        withAnimation(.easeInOut(duration: 0.35)) {
            onFinished()
        }
    }

    private func cleanup() {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
        player?.pause()
        player = nil
    }
}

/// Custom UIViewRepresentable for edge-to-edge AVPlayerLayer with resizeAspectFill
struct LaunchVideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    class PlayerUIView: UIView {
        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }
    }
}
