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
import UserNotifications

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
    //*Sort posts by release date
    //*Sort captions by date when the user has not chosen a favorite
    //*Handle favorite and unfavorite action from the details
    //*Sort captions by favorites count (once the favorites are shown)
    //*Unwind when user sends a caption
    //*Incorporate tags in messages item details
    //*Query friends from entry / By pass login
    //*When I send an image I want captioned, it should automatically go to the newsfeed.
    //*All null table views should have empty states
    //*Favoriting between media browser and discover vc
    
    /* IN PROGRESS */
    //
    
    /* BACK LOG (minor) */
    // Add contact picker to send invite to use the app
    // Add blur to the image when the user presses "More..." (recieved image)
    // Corner radius of the Requests Floating Panel
    // Request deletion animation
    // Use ML and public insta webscrape to find good captions
    //5Media Browser Dismissal
    // Add time to release textfield (clock item and text next to the cancel button)
    //1Edit Release date
    //2Center odd requests in the collection view
    
    /* BACK LOG (major) */
    //5AWS S3
    //2Inspiration View for Captioners
    //4Messaging
    //1Push Notifications (Current)
    //3Core data
    
    /* QUESTIONS */
    // Should we support videos?
    // Which image processing library should we use?
    // How to deliver exploitable images content?
    
    var window: UIWindow?
    let reachability = try! Reachability()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        registerForPushNotifications()
        
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
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        window?.makeKeyAndVisible()

        
        UINavigationBar.appearance().barTintColor = UIColor.darkGray
        UINavigationBar.appearance().tintColor = UIColor(red: 252/255, green: 209/255, blue: 42/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(red: 252/255, green: 209/255, blue: 42/255, alpha: 1)]
        
        // Empty State
        WLEmptyState.configure()
        
        DropDown.startListeningToKeyboard()
        
        self.chooseInitialVC()
        
        return true
    }
    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    
    func registerForPushNotifications() {
      UNUserNotificationCenter.current() // 1
        .requestAuthorization(options: [.alert, .sound, .badge]) { // 2
          granted, error in
          print("Permission granted: \(granted)") // 3
            guard granted else { return }
            self.getNotificationSettings()
      }
    }
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
      print("Device Token: \(token)")
        createInstallationOnParse(deviceTokenData: deviceToken)
    }
    
    func createInstallationOnParse(deviceTokenData:Data){
        if let installation = PFInstallation.current(){
            installation.setDeviceTokenFrom(deviceTokenData)
            installation.saveInBackground {
                (success: Bool, error: Error?) in
                if (success) {
                    print("You have successfully saved your push installation to Back4App!")
                } else {
                    if let myError = error{
                        print("Error saving parse installation \(myError.localizedDescription)")
                    }else{
                        print("Uknown error")
                    }
                }
            }
        }
    }
    
    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Failed to register: \(error)")
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
    
    func chooseInitialVC() {
        if PFUser.current() != nil {
            self.queryFriends()
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "LoginSignUpVC")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
    }
    
    func queryFriends() {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "recipient = %@", PFUser.current()!))
        predicates.append(NSPredicate(format: "sender = %@", PFUser.current()!))
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let query = PFQuery(className: "FriendRequest", predicate: predicate)
        query.includeKey("recipient")
        query.includeKey("sender")
        let requestRef = FriendRequest()
        requestRef.getRequests(query: query) { (queriedRequests) in
            print("received this many requests:", queriedRequests.count)
            if queriedRequests.count == 0 {
                /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()*/
            }
            for request in queriedRequests {
                if request.status == "accepted" {
                    if request.receiver.objectId == PFUser.current()!.objectId {
                        DataModel.friends.append(request.sender)
                    } else if request.sender.objectId == PFUser.current()!.objectId {
                        DataModel.friends.append(request.receiver)
                    }
                } else if request.status == "pending" {
                    if request.receiver.objectId == PFUser.current()!.objectId! {
                        request.sender.requestId = request.objectId
                        DataModel.receivedRequests.append(request.sender)
                    } else if request.sender.objectId == PFUser.current()!.objectId! {
                        DataModel.sentRequests.append(request.receiver)
                    }
                }
                if request === queriedRequests.last {
                    /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
                    self.window?.rootViewController = initialViewController
                    self.window?.makeKeyAndVisible()*/
                }
            }
        }
    }
}

