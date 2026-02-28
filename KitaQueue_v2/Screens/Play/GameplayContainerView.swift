import SwiftUI
import SpriteKit

/// Embeds the SpriteKit GameScene into SwiftUI with overlay buttons.
struct GameplayContainerView: View {
    let levelId: Int
    let appState: AppState
    @State private var coordinator = GameSceneCoordinator()
    @State private var transitioning = false
    @State private var fixItUsedThisAttempt = 0

    private var adsRemoved: Bool {
        PersistenceService.shared.loadSettings().adsRemoved
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit scene
                SpriteView(scene: coordinator.makeScene(size: geo.size))
                    .ignoresSafeArea()

                // HUD buttons (only visible during gameplay)
                if coordinator.gamePhase == .playing || coordinator.gamePhase == .preview {
                    VStack {
                        Spacer()

                        HStack {
                            // Undo button
                            Button {
                                SoundManager.shared.playButtonTap()
                                coordinator.undoLastOperator()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.white.opacity(0.15)))
                            }

                            Spacer()

                            // Pause button
                            Button {
                                SoundManager.shared.playButtonTap()
                                coordinator.pauseGame()
                            } label: {
                                Image(systemName: "pause.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.white.opacity(0.15)))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }
                }

                // Win overlay
                if coordinator.gamePhase == .won {
                    WinOverlayView(
                        coordinator: coordinator,
                        appState: appState,
                        onNext: {
                            coordinator.saveWinProgression()
                            appState.sessionWinCount += 1
                            handlePostWinAd {
                                transitionToNextLevel()
                            }
                        },
                        onHome: {
                            coordinator.saveWinProgression()
                            appState.sessionWinCount += 1
                            handlePostWinAd {
                                appState.navigationPath.removeAll()
                            }
                        }
                    )
                    .transition(.opacity)
                }

                // Fail overlay
                if coordinator.gamePhase == .failed {
                    FailOverlayView(
                        coordinator: coordinator,
                        appState: appState,
                        showFixIt: canShowFixIt,
                        onRetry: {
                            appState.sessionFailCount += 1
                            let fixItWasShown = canShowFixIt
                            handlePostFailAd(fixItShown: fixItWasShown) {
                                fixItUsedThisAttempt = 0
                                coordinator.retry()
                            }
                        },
                        onFixIt: {
                            handleFixIt()
                        },
                        onHome: {
                            appState.sessionFailCount += 1
                            let fixItWasShown = canShowFixIt
                            handlePostFailAd(fixItShown: fixItWasShown) {
                                appState.navigationPath.removeAll()
                            }
                        }
                    )
                    .transition(.opacity)
                }

                // Pause menu
                if coordinator.gamePhase == .paused {
                    PauseMenuView(
                        onResume: {
                            coordinator.resumeGame()
                        },
                        onRestart: {
                            fixItUsedThisAttempt = 0
                            coordinator.retry()
                        },
                        onQuit: {
                            appState.navigationPath.removeAll()
                        }
                    )
                    .transition(.opacity)
                }

                // Fade-to-dark transition
                if transitioning {
                    Color.black
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: coordinator.gamePhase)
            .animation(.easeInOut(duration: 0.3), value: transitioning)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            coordinator.startLevel(id: levelId)
            Task { await AdManager.shared.preloadAds() }
        }
    }

    // MARK: - Fix It Qualification (mirrors FailOverlayView logic)

    private var canShowFixIt: Bool {
        guard appState.sessionFixItCount < GameConstants.fixItMaxPerSession else { return false }
        guard fixItUsedThisAttempt < GameConstants.fixItMaxPerAttempt else { return false }
        if case .overflow = coordinator.failReason { return true }
        let remaining = coordinator.totalShuriken - coordinator.bankedCount
        return remaining <= 3
    }

    // MARK: - Ad Flows

    private func handlePostWinAd(then action: @escaping () -> Void) {
        Task {
            _ = await AdManager.shared.handlePostWin(
                winCount: appState.sessionWinCount,
                level: coordinator.currentLevel,
                adsRemoved: adsRemoved
            )
            action()
        }
    }

    private func handlePostFailAd(fixItShown: Bool, then action: @escaping () -> Void) {
        Task {
            _ = await AdManager.shared.handlePostFail(
                failCount: appState.sessionFailCount,
                level: coordinator.currentLevel,
                adsRemoved: adsRemoved,
                fixItShown: fixItShown
            )
            action()
        }
    }

    private func handleFixIt() {
        let requiresAd = AdPolicy.fixItRequiresAd(level: coordinator.currentLevel)

        if requiresAd {
            Task {
                let earned = await AdManager.shared.showRewardedForFixIt()
                if earned {
                    applyFixIt()
                }
            }
        } else {
            applyFixIt()
        }
    }

    private func applyFixIt() {
        fixItUsedThisAttempt += 1
        appState.sessionFixItCount += 1
        coordinator.resumeFromFixIt()
    }

    private func transitionToNextLevel() {
        transitioning = true
        fixItUsedThisAttempt = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            coordinator.nextLevel()
            transitioning = false
        }
    }
}
