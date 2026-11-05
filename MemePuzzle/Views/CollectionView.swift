import MemeBlitzCore
import SwiftUI

/// The redesigned Meme Vault: A premium collectible gallery featuring completion tracking,
/// difficulty filtering, responsive grid cards, and dedicated detail inspections.
struct CollectionView: View {
    let onStart: (PuzzleSession) -> Void

    @State private var viewModel = CollectionViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Banner: MEME VAULT & Completion Meter
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.stack.fill")
                                    .foregroundStyle(Theme.neonViolet)
                                Text("MEME VAULT")
                                    .font(.system(size: 13, weight: .black))
                                    .tracking(1.4)
                                    .foregroundStyle(Theme.neonViolet)
                            }

                            Text("\(viewModel.collectedCount) of \(viewModel.totalCount) Collected")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Restore internet memes across all four difficulty ranks.")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.6))
                        }

                        Spacer()

                        // Circular or pill completion percentage
                        VStack(spacing: 2) {
                            Text("\(viewModel.completionPercentage)%")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.neonGold)
                            Text("RESTORED")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .arcadeGlass(
                            stroke: Theme.neonGold.opacity(0.4),
                            cornerRadius: 14,
                            fillOpacity: 0.1
                        )
                    }

                    // Linear Collection Progress Bar
                    ArcadeProgressBar(
                        progress: viewModel.completionFraction,
                        height: 7,
                        gradient: LinearGradient(
                            colors: [Theme.neonViolet, Theme.neonGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .padding(18)
                .arcadeGlass(
                    stroke: Theme.neonViolet.opacity(0.3),
                    cornerRadius: 20,
                    fillOpacity: 0.1
                )

                // Horizontally Scrollable Difficulty Filter Chips
                ArcadeDifficultyFilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    counts: viewModel.countsByFilter
                )
                .padding(.horizontal, -16)

                // Responsive Two-Column Image Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredMemes) { template in
                        let status = viewModel.unlockStatus(for: template)
                        MemeGalleryCard(
                            template: template,
                            isSolved: status.isSolved,
                            isPlayable: status.isPlayable,
                            requirementText: status.requirementText,
                            bestTime: viewModel.bestTime(for: template)
                        ) {
                            viewModel.selectMeme(template)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 110) // clearance for persistent bottom navigation dock
        }
        .background(Theme.background)
        .navigationTitle("Meme Vault")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onVaultAppear()
        }
        .sheet(item: $viewModel.selectedMemeForDetail) { template in
            MemeDetailView(
                template: template,
                onPlay: { session in
                    viewModel.clearSelection()
                    onStart(session)
                },
                onDismiss: {
                    viewModel.clearSelection()
                }
            )
        }
    }
}
