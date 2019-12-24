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
import Reachability
import SCLAlertView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /* COMPLETE */
    //*Registration
    //*Friends and search friends tableviews side by side
    //*Select friends' profiles
    //*Filter users (Search) by username
    //*Logout alert view color
    //*Floating panel crashes when it attempts to present on null
    //*Remove requests from the collection view
    //*Capture friends, requests, and users data in DataModel to make VCs more dynamic
    //*Friends (Search) shrink tableview to be the height of the keyboard
    //*Change the settings alert view tint color
    //*Wifi alert view
    //*Update the caption json favorite count
    //*Discover Item separator
    //*Fix Add Location textfield drop down
    //*Discover Loading Indicator
    
    /* IN PROGRESS */
    
    
    /* BACK LOG */
    // Incorporate tags in discover item details
    // Add contact picker to send invite to use the app
    // Add blur to the image when the user presses "More..." (recieved image)
    // Corner radius of the Requests Floating Panel
    // Request deletion animation
    // Center odd requests in the collection view
    // Remove the intermediate floating panel (equivalent to the size of the nav bar)
    // Use ML and public insta webscrape to find good captions
    
    let reachability = try! Reachability()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do {
          try reachability.startNotifier()
        } catch {
          print("could not start reachability notifier")
        }
        
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
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        switch reachability.connection {
            case .wifi:
                print("Reachable via WiFi")
            case .cellular:
                print("Reachable via Cellular")
            case .unavailable:
              print("Network not reachable")
              let alertViewIcon = UIImage(named: "noWifi")
              let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
              let alert = SCLAlertView(appearance: appearance)
              alert.showInfo("Notice", subTitle: "You must connect to a wifi network", closeButtonTitle: "Done", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: alertViewIcon, animationStyle: .topToBottom)
            case .none:
              print("none case")
        }
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

