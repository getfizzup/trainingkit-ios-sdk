//
//  MonGoModeController.swift
//  SampleApp
//

import Combine
import Foundation
import TrainingKit

class MonGoModeController: ClassicWorkoutController {
    var publisher: AnyPublisher<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()

    // MARK: -

    override func saveSession(state: SaveWorkoutState) {
        super.saveSession(state: state)

        // User state data to read workout infos.

        // Simulate 5 sec delay for workout save then resolve the promise.
        publisher = Future<Void, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { promise(.success(())) }
        }.eraseToAnyPublisher()
    }

    override func displayPostWorkout() -> AnyPublisher<Void, Never> {
        guard let publisher else { return super.displayPostWorkout() }

        publisher.sink(receiveCompletion: { [weak self] _ in
            self?.dismiss(animated: true)
        }, receiveValue: {}).store(in: &subscriptions)

        return publisher
    }
}
