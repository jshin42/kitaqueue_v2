import SwiftUI
import SpriteKit

/// Embeds the SpriteKit GameScene into SwiftUI with overlay buttons.
struct GameplayContainerView: View {
    let levelId: Int
    let appState: AppState
    @State private var coordinator = GameSceneCoordinator()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit scene
                SpriteView(scene: coordinator.makeScene(size: geo.size))
                    .ignoresSafeArea()

                // Overlay buttons
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

                        // Pause/Settings button
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
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            coordinator.startLevel(id: levelId)
        }
    }
}
