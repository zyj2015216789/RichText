//
//  AppDelegate.swift
//  playGroundTest
//
//  Created by job zhao on 2021/7/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func applicationDidFinishLaunching(_ application: UIApplication) {
        window = UIWindow()
        window?.frame = UIScreen.main.bounds
        window?.rootViewController = myViewController()
        window?.makeKeyAndVisible()
    }
}

