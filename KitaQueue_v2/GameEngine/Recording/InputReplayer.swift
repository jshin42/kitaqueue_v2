import Foundation

/// Replays a recorded input sequence against a simulation for determinism verification.
final class InputReplayer {
    let simulation: GameSimulation
    let inputs: [PlayerInput]
    private var inputIndex: Int = 0

    init(simulation: GameSimulation, inputs: [PlayerInput]) {
        self.simulation = simulation
        self.inputs = inputs
    }

    /// Run the simulation to completion (all shuriken resolved or fail).
    func runToCompletion() {
        let fixedDt = 1.0 / 60.0
        let maxSteps = 60 * 60 // 60 seconds max

        for _ in 0..<maxSteps {
            // Apply any inputs scheduled for this timestep
            while inputIndex < inputs.count {
                let input = inputs[inputIndex]
                let inputTimestep: Int
                switch input {
                case .place(_, _, let ts): inputTimestep = ts
                case .undo(let ts): inputTimestep = ts
                }

                if inputTimestep <= simulation.state.timestep {
                    _ = simulation.applyInput(input)
                    inputIndex += 1
                } else {
                    break
                }
            }

            simulation.tick(dt: fixedDt)

            if simulation.state.phase == .won || simulation.state.phase == .failed {
                break
            }
        }
    }
}
