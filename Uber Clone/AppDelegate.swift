//
//  AppDelegate.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 16/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = HomeVC()
        
        return true
    }

}

