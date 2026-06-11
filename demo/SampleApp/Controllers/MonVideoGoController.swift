//
//  MonVideoGoController.swift
//  SampleApp
//

import Combine
import Foundation
import GoogleCast
import TrainingKit
import UIKit

class MonVideoGoController: StreamingWorkoutController {
    // MARK: - Workout save

    var saveProm: AnyPublisher<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()

    override func saveSession(state: SaveWorkoutState) {
        super.saveSession(state: state)

        saveProm = Future<Void, Never> { promise in
            // Simulate 5sec delay for workout save.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    // MARK: - Google Cast

    private let castButton = configure(GCKUICastButton()) {
        $0.tintColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let item = UIBarButtonItem(customView: castButton)
        leftItems = [item]

        // Create and assign manager.
        let manager = GoogleCastManager(video: video, metadata: metadata)
        remoteManager = manager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let manager = remoteManager as? GCKSessionManagerListener {
            GCKCastContext.sharedInstance().sessionManager.add(manager)
        }
    }
}
