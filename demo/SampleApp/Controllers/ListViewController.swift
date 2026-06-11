//
//  ListViewController.swift
//  SampleApp
//

import Apollo
import DemoCloud
import Foundation
import UIKit

class ListViewController: UIViewController {
    enum Section {
        case playlist
        case main
    }

    var dataSource: UICollectionViewDiffableDataSource<Section, WorkoutPreviewItem>!
    var collectionView: UICollectionView!

    var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .positional // Ensures HH:MM:SS or MM:SS format
        formatter.zeroFormattingBehavior = .pad // Ensures two-digit formatting

        return formatter
    }

    var loader: UIView = {
        var loader = UIView()
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemPink
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false

        loader.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loader.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loader.centerYAnchor),
        ])

        loader.backgroundColor = .label.withAlphaComponent(0.3)

        return loader
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("list_title", comment: "")
        configureHierarchy()
        configureDataSource()

        Task { [weak self] in
            do {
                try await self?.fetchList()
                self?.loader.isHidden = true

            } catch {
                self?.handleError(error.localizedDescription)
            }
        }
    }

    func handleError(_ message: String?) {
        loader.isHidden = true

        let alert = UIAlertController(title: NSLocalizedString("common_error", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("common_ok", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: -

extension ListViewController {
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        collectionView.delegate = self

        loader.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.topAnchor.constraint(equalTo: view.topAnchor),
            loader.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, WorkoutPreviewItem> { [weak self] cell, _, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.name
            content.secondaryText = "\(self?.formatter.string(from: TimeInterval(item.duration)) ?? "-") min - \(item.format.rawValue)"
            content.image = UIImage(systemName: item.format == .play ? "ipad.gen2.landscape.badge.play" : "iphone.gen3.badge.play")
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, WorkoutPreviewItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: WorkoutPreviewItem) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
    }

    // MARK: -

    func fetchList() async throws {
        let request = try DemoCloudClient.shared.fetch(query: GetSessionsQuery(), fetchBehavior: .CacheAndNetwork)

        for try await response in request {
            let items = response.data?.publicWorkouts.edges.compactMap(\.node.fragments.workoutPreviewItem)
            if let items, items.isEmpty == false {
                var snapshot = NSDiffableDataSourceSnapshot<Section, WorkoutPreviewItem>()
                snapshot.appendSections([.playlist])
                snapshot.appendItems(items, toSection: .playlist)

                await dataSource.apply(snapshot, animatingDifferences: false)

            } else {
                handleError(NSLocalizedString("error_empty_list", comment: ""))
            }
        }
    }
}

// MARK: -

extension ListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        Task { [weak self] in
            do {
                try await self?.fetchWorkoutSession(at: indexPath)
                self?.loader.isHidden = true

            } catch {
                self?.handleError(error.localizedDescription)
            }
        }
    }

    private func fetchWorkoutSession(at indexPath: IndexPath) async throws {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        print("Selected \"\(item.name)\". Fetching workout preview...")
        loader.isHidden = false

        let response = try await DemoCloudClient.shared.fetch(query: GetSessionQuery(id: item.id), cachePolicy: .networkOnly)

        guard let preview = response.data?.publicWorkout.fragments.workoutPreviewItem else {
            handleError(String(format: NSLocalizedString("error_cannot_fetch_info", comment: ""), item.id))
            return
        }

        let alert = UIAlertController(title: preview.name,
                                      message: String(format: NSLocalizedString("common_workout_fetch_info", comment: ""), item.id),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("common_cancel", comment: ""), style: .cancel, handler: { [weak self] _ in
            self?.loader.isHidden = true
        }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("common_continue", comment: ""), style: .default, handler: { [weak self] _ in
            Task {
                do { try await self?.fetchWorkoutContents(at: indexPath) }
                catch { self?.handleError(error.localizedDescription) }
            }
        }))

        present(alert, animated: true)
    }

    private func fetchWorkoutContents(at indexPath: IndexPath) async throws {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        print("Selected \"\(item.name)\". Fetching workout contents...")

        let response = try await DemoCloudClient.shared.fetch(query: GetSessionContentQuery(id: item.id), cachePolicy: .networkOnly)

        // Retrieve token to use fetched data.
        guard let wk = response.extensions?["workoutkit"] as? [String: String], let token = wk["token"] else { return }

        guard let data = try? response.data?.publicWorkoutSession.asJSONData() else { return }

        Task { [weak self] in
            do {
                var controller: UIViewController?

                // Check data type to open the right controller.
                if response.data?.publicWorkoutSession.asWorkoutBlockSession != nil {
                    controller = try await MonGoModeController(data: data, token: token)
                } else if response.data?.publicWorkoutSession.asWorkoutVideoSession != nil {
                    controller = try await MonVideoGoController(data: data, token: token)
                }

                guard let controller else {
                    self?.handleError(String(format: NSLocalizedString("error_cannot_open", comment: ""), item.id))
                    return
                }

                controller.modalPresentationStyle = .fullScreen
                self?.present(controller, animated: true)

            } catch {
                print(error)
            }
        }
    }
}
