//
//  AppDelegate.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import UIKit
import Parse
import WLEmptyState
import DropDown

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /* COMPLETE */
    //*Registration
    //*Friends and search friends tableviews side by side
    //*Select friends' profiles
    //*Filter users (Search) by username
    //*Logout alert view color
    //*Floating panel crashes when it attempts to present on null
    
    /* IN PROGRESS */
    // Capture friends, requests, and users data in DataModel to make VCs more dynamic
    // Add contact picker to send invite to use the app
    // Wifi alert view
    // Remove requests from the collection view
    
    /* BACK LOG */
    // Add blur to the image when the user presses "More..." (recieved image)
    // Friends (Search) shrink tableview to be the height of the keyboard
    // Change the settings alert view tint color
    // Corner radius of the Requests Floating Panel
    // Request deletion animation
    // Center odd requests in the collection view
    // Remove the intermediate floating panel (equivalent to the size of the nav bar)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Configure Parse client
        let configuration = ParseClientConfiguration {
            $0.applicationId = "1I5ln2S1erGZTcjiEzmt0TccGrALbxR81u8ONETx"
            $0.clientKey = "oHmjv3beFFvBtvZSceeYpOK8Vr24ua07wmHqrrRE"
            $0.server = "https://parseapi.back4app.com"
        }
        Parse.initialize(with: configuration)
        
        UINavigationBar.appearance().barTintColor = UIColor.darkGray
        UINavigationBar.appearance().tintColor = UIColor(red: 252/255, green: 209/255, blue: 42/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(red: 252/255, green: 209/255, blue: 42/255, alpha: 1)]
        
        // Empty State
        WLEmptyState.configure()
        
        DropDown.startListeningToKeyboard()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

