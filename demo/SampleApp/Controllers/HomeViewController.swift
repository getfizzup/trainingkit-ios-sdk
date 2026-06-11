//
//  HomeViewController.swift
//  SampleApp
//

import AVFAudio
import Combine
import LocalizedDeviceModel
import TrainingKit
import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var label: UILabel!
    @IBOutlet var label2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        label.text = UIDevice.current.localizedProductName
        label2.text = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"

        TrainingKitConfig.reset()

        let listButton = UIButton(primaryAction: UIAction(title: NSLocalizedString("home_list_cta", comment: ""), image: UIImage(systemName: "list.bullet.rectangle.portrait"), handler: { [weak self] _ in
            self?.navigationController?.pushViewController(ListViewController(), animated: true)
        }))
        listButton.configuration = .tinted()

        let audioButton = UIButton(primaryAction: UIAction(title: NSLocalizedString("home_settings_cta", comment: ""), image: UIImage(systemName: "speaker.wave.3.fill"), handler: { [weak self] _ in
            let controller = AudioSettingsController()
            self?.present(UINavigationController(rootViewController: controller), animated: true)
        }))
        audioButton.configuration = .tinted()
        audioButton.tintColor = .systemMint

        let stack = UIStackView(arrangedSubviews: [listButton, audioButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
        ])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
