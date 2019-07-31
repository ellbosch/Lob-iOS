//
//  AppDelegate.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/1/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import Firebase
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Instantiate views
    func applicationDidFinishLaunching(_ application: UIApplication) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        let tabBarController = MainTabBarController()
        
        window.makeKeyAndVisible()
        window.rootViewController = tabBarController
        self.window = window
        
        // Firebase config
        if FirebaseApp.app() == nil {
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            FirebaseApp.configure()
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {        
        // set up vc
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // create view controllers
        guard let tabVC: UITabBarController = self.window?.rootViewController?.storyboard?.instantiateInitialViewController() as? UITabBarController, let videoVC: VideoViewController = mainStoryboard.instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController else { return false }
        
        // load navigation controller and display views in sequential order
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        self.window?.rootViewController = tabVC
        self.window?.makeKeyAndVisible()

        // app logic if user selects universal link
        if let urlString = userActivity.webpageURL?.absoluteString {
            let queryArray = urlString.components(separatedBy: "/")
            
            // open video vc if user wants to view a specific video
            if queryArray.count > 3 && queryArray[3] == "video" {
                let videoId = queryArray[4]
                
                // makes sure VC knows we're opening from a share link: this controls text of status bar so it's visible
                videoVC.openedFromShare = true
                
                // present viewController
                tabVC.present(videoVC, animated: false, completion: {
                    videoVC.initFromLink(videoId: videoId)
                })
                return true
            }
        }
        
        // display error alert if no video found for specified id
        let alert = UIAlertController(title: "No video found!", message: "Sorry about that.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.window?.rootViewController?.present(alert, animated: true)
        return false

    }
}
