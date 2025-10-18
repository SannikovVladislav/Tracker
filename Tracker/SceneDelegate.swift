//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        let tabBarVC = MainTabBarViewController()
        window?.rootViewController = tabBarVC
        window?.makeKeyAndVisible()
    }
}

