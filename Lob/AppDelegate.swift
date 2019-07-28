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
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController")
        
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

