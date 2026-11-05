import MemePuzzleCore
import SwiftUI

/// Compatibility wrapper forwarding to the redesigned arcade-style TimeUpPopupView.
struct FailureView: View {
    @Bindable var model: PuzzleViewModel
    var onTryAgain: () -> Void
    var onLevels: (() -> Void)?
    var onChooseDifficulty: () -> Void

    init(
        model: PuzzleViewModel,
        onTryAgain: @escaping () -> Void,
        onLevels: (() -> Void)? = nil,
        onChooseDifficulty: @escaping () -> Void
    ) {
        self.model = model
        self.onTryAgain = onTryAgain
        self.onLevels = onLevels
        self.onChooseDifficulty = onChooseDifficulty
    }

    var body: some View {
        TimeUpPopupView(
            model: model,
            onTryAgain: onTryAgain,
            onLevels: onLevels ?? onChooseDifficulty,
            onChangeMode: onChooseDifficulty
        )
    }
}
