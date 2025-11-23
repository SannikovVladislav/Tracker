//
//  MainTabBarViewController.swift
//  Tracker
//
//  Created by Владислав on 06.10.2025.
//
import UIKit

final class MainTabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabBarAppearance()
        setupViewControllers()        
    }
    
    private func setupTabBarAppearance() {
        tabBar.tintColor = .blueYP
        tabBar.unselectedItemTintColor = .grayYP
        tabBar.backgroundColor = .whiteDay
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupViewControllers() {
        let trackersVC = TrackersViewController()
        let statisticsVC = StatisticsViewController()
        
        trackersVC.tabBarItem = UITabBarItem(
            title: LocalizedStrings.trackers,
            image: UIImage(resource: .trackersIcon),
            tag: 0
        )
        
        statisticsVC.tabBarItem = UITabBarItem(
            title: LocalizedStrings.statistics,
            image: UIImage(resource: .statisticIcon),
            tag: 1
        )
        
        let trackersNC = UINavigationController(rootViewController: trackersVC)
        let statisticsNC = UINavigationController(rootViewController: statisticsVC)
        
        viewControllers = [trackersNC, statisticsNC]
    }
}
