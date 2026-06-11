//
//  AppDelegate.swift
//  SampleApp
//

import GoogleCast
import TrainingKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: "ABCDEF123"))
        options.physicalVolumeButtonsWillControlDeviceVolume = true
        options.disableDiscoveryAutostart = false // Do not disable discovery.

        let launchOptions = GCKLaunchOptions()
        launchOptions.androidReceiverCompatible = true
        options.launchOptions = launchOptions

        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false

        return true
    }
}
