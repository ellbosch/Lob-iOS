//
//  MainTabBarController.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/30/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nil)
        
        setupTabController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupTabController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
    }

    func setupTabController() {
        // set up view controllers and icons
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // first tab: feed vc of trending content
        let trendingVC = mainStoryboard.instantiateViewController(withIdentifier: "HotFeedViewController")
        trendingVC.tabBarItem = UITabBarItem(title: "Today", image: UIImage(named: "sun"), tag: 0)
        
        // second tab: nav controller for channels view
        let channelsVC = mainStoryboard.instantiateViewController(withIdentifier: "SportsListViewController")
        channelsVC.tabBarItem = UITabBarItem(title: "Channels", image: UIImage(named: "menu"), tag: 1)
        let navController = UINavigationController(rootViewController: channelsVC)
        navController.title = "Channels"
        
        let viewControllers = [trendingVC, navController]
        self.setViewControllers(viewControllers, animated: false)
    }
}
