import SwiftUI
import SpriteKit

/// Embeds the SpriteKit GameScene into SwiftUI with overlay buttons.
struct GameplayContainerView: View {
    let levelId: Int
    let appState: AppState
    @State private var coordinator = GameSceneCoordinator()
    @State private var transitioning = false

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
                            transitionToNextLevel()
                        },
                        onHome: {
                            coordinator.saveWinProgression()
                            appState.sessionWinCount += 1
                            appState.navigationPath.removeAll()
                        }
                    )
                    .transition(.opacity)
                }

                // Fail overlay
                if coordinator.gamePhase == .failed {
                    FailOverlayView(
                        coordinator: coordinator,
                        appState: appState,
                        onRetry: {
                            appState.sessionFailCount += 1
                            coordinator.retry()
                        },
                        onFixIt: {
                            appState.sessionFixItCount += 1
                            coordinator.resumeFromFixIt()
                        },
                        onHome: {
                            appState.sessionFailCount += 1
                            appState.navigationPath.removeAll()
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
        }
    }

    private func transitionToNextLevel() {
        transitioning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            coordinator.nextLevel()
            transitioning = false
        }
    }
}
