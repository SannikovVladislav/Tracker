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
        
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if hasSeenOnboarding {
            let tabBarVC = MainTabBarViewController()
            window?.rootViewController = tabBarVC
        } else {
            let onboardingVC = OnboardingViewController()
            window?.rootViewController = onboardingVC
        }
        window?.makeKeyAndVisible()
    }
}

