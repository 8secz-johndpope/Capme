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
import ATGMediaBrowser
import ParseLiveQuery

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
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
    //*Local Push Sends
    //*Remote Push Sends
    //*Badge increment and clear
    //*Open to specified location
    //*Message Push Scenarios
    //*Show profile from search (did select)
    //*Handle send requests properly
    //*Profile Posts loading indicator
    //*Take photo option when currentUser's profile pic is selected
    //*Did select users old posts on profile
    //*Open a blank message
    //*Send and receive a message (Parse Live Query)
    //*Populate old messages with parse backend messages
    //*Determine chatroom naming convention
    //*Design workflow for creating receiving messages and caption requests
    //*Update message preview when a new message is sent (Use data model?)
    //*Advanced messaging UI compress messages sent by the same user
    //*Push notifications from messages
    
    /* IN PROGRESS */

    // Support Images, videos, and audio
    // Show the new data associated with the didReceive push (new message (top), friend request item, NOT the favorite caption)
    // Messages push scenarios
    // In foreground - from discover click tab bar (already viewed messages)*, from discover click tab bar (not viewed messages)*, from messages pull to refresh*, select notification discover*, (select notification messages *)
    // From background - notification selected (app is closed*, app is resting in background on discover*, app is resting in background on messages*)
    // From background - (TODO) app selected (app is closed, app is resting in background on discover, app is resting in background on messages)
    
    /* BACK LOG (minor) */
    // Time didnt display properly
    // Remove request until only one left, center remaining
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
    // Is using core data faster than querying from back4app?
    
    var window: UIWindow?
    let reachability = try! Reachability()
    private var observer: NSObjectProtocol?
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            // do whatever you want when the app is brought back to the foreground
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
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
        Message.registerSubclass()
        Room.registerSubclass()
        
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("will present", notification.request.content.userInfo["identifier"] as? String)
        
        if let identifier = notification.request.content.userInfo["identifier"] as? String {
            if identifier == "friendRequest" {
                completionHandler([.alert, .badge, .sound])
                let friendRequestRef = FriendRequest()
                friendRequestRef.getRequestWithId(id: notification.request.content.userInfo["objectId"] as! String) { (request) in
                    if request.receiver.objectId == PFUser.current()!.objectId! {
                        request.sender.requestId = request.objectId
                        print("insert 1")
                        DataModel.receivedRequests.insert(request.sender, at: 0)
                        
                        if let tabBarController =  DataModel.tabBarController {
                            if let badgeValue = tabBarController.tabBar.items?[2].badgeValue,
                                let value = Int(badgeValue) {
                                tabBarController.tabBar.items?[2].badgeValue = String(value + 1)
                            } else {
                                tabBarController.tabBar.items?[2].badgeValue = "1"
                            }
                        }
                    }
                }
            } else if identifier == "favoritedCaption" {
                completionHandler([.alert, .badge, .sound])
                if let tabBarController =  DataModel.tabBarController {
                    if let badgeValue = tabBarController.tabBar.items?[0].badgeValue,
                        let value = Int(badgeValue) {
                        tabBarController.tabBar.items?[0].badgeValue = String(value + 1)
                    } else {
                        tabBarController.tabBar.items?[0].badgeValue = "1"
                    }
                }
            } else if identifier == "captionRequest" {
                completionHandler([.alert, .badge, .sound])
                if let tabBarController =  DataModel.tabBarController {
                    DataModel.newMessageId = notification.request.content.userInfo["objectId"] as! String
                    if let badgeValue = tabBarController.tabBar.items?[1].badgeValue,
                        let value = Int(badgeValue) {
                        tabBarController.tabBar.items?[1].badgeValue = String(value + 1)
                    } else {
                        tabBarController.tabBar.items?[1].badgeValue = "1"
                    }
                } else {
                    DataModel.pushId = identifier
                }
            } else if identifier == "newMessage" {
                if let tabBarController =  DataModel.tabBarController {
                    
                    if tabBarController.selectedIndex == 1 {
                        // Refresh the existing tableView
                        DataModel.newMessageId = notification.request.content.userInfo["objectId"] as! String
                        if let messagesVC = UIApplication.getTopViewController() as? MessagesVC {
                            messagesVC.getPostWithId()
                        }
                    } else {
                        completionHandler([.alert, .badge, .sound])
                        DataModel.newMessageId = notification.request.content.userInfo["objectId"] as! String
                        if let badgeValue = tabBarController.tabBar.items?[1].badgeValue,
                            let value = Int(badgeValue) {
                            tabBarController.tabBar.items?[1].badgeValue = String(value + 1)
                        } else {
                            tabBarController.tabBar.items?[1].badgeValue = "1"
                        }
                    }
                } else {
                    completionHandler([.alert, .badge, .sound])
                    DataModel.pushId = identifier
                }
            }
        }
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("did receive")
        
        // Continue here... dismiss the controller and then also check if the fpc from friends is causing the crash
        self.window?.rootViewController?.dismiss(animated: false, completion: {
            print("dismissed!!")
        })
        
        // TODO app crashes when post is being created and I try to programmatically open friend requests (or when viewing a post)
        let userInfo = response.notification.request.content.userInfo
        if let identifier = userInfo["identifier"] as? String {
            print("This is the identifier:", identifier)
            if identifier == "friendRequest" {
                if let tabBarController = DataModel.tabBarController {
                    
                    let friendRequestRef = FriendRequest()
                    print(userInfo["objectId"] as! String, "Object Id!!!")
                    friendRequestRef.getRequestWithId(id: userInfo["objectId"] as! String) { (request) in
                        if request.receiver.objectId == PFUser.current()!.objectId! {
                            request.sender.requestId = request.objectId
                            print("insert 2")
                            DataModel.receivedRequests.insert(request.sender, at: 0)
                            if let tabBarController =  DataModel.tabBarController {
                                tabBarController.selectedIndex = 2
                                if let badgeValue = tabBarController.tabBar.items?[2].badgeValue,
                                    let value = Int(badgeValue) {
                                    tabBarController.tabBar.items?[2].badgeValue = String(value + 1)
                                } else {
                                    tabBarController.tabBar.items?[2].badgeValue = "1"
                                }
                            }
                            let navController = tabBarController.viewControllers![2] as! UINavigationController
                            let profileVC = navController.viewControllers[0] as! ProfileVC
                            profileVC.performSegue(withIdentifier: "showFriends", sender: nil)
                        }
                    }
                    
                    
                } else {
                    DataModel.pushId = identifier
                }
            } else if identifier == "favoritedCaption" {
                if let tabBarController =  DataModel.tabBarController {
                    if let badgeValue = tabBarController.tabBar.items?[0].badgeValue,
                        let value = Int(badgeValue) {
                        tabBarController.tabBar.items?[0].badgeValue = String(value + 1)
                    } else {
                        tabBarController.tabBar.items?[0].badgeValue = "1"
                    }
                    print("show discover")
                    tabBarController.selectedIndex = 0
                }
                
                //let discoverVC = storyboard.instantiateViewController(withIdentifier: "discoverVC") as! DiscoverVC
                //self.window?.rootViewController = discoverVC
            } else if identifier == "captionRequest" {
                
                if let tabBarController = DataModel.tabBarController {
                    DataModel.newMessageId = userInfo["objectId"] as! String
                    if tabBarController.selectedIndex != 1 {
                        tabBarController.selectedIndex = 1
                        if let badgeValue = tabBarController.tabBar.items?[1].badgeValue,
                            let value = Int(badgeValue) {
                            tabBarController.tabBar.items?[1].badgeValue = String(value + 1)
                        } else {
                            tabBarController.tabBar.items?[1].badgeValue = "1"
                        }
                    } else {
                        print("print0")
                        if let messagesVC = UIApplication.getTopViewController() as? MessagesVC {
                            print(type(of: messagesVC))
                            messagesVC.getPostWithId()
                            print("this is the top vc")
                        }
                        
                    }
                } else {
                    DataModel.newMessageId = userInfo["objectId"] as! String
                    DataModel.pushId = identifier
                }
                
                // 1 show messages vc
                // 2 show tableview reloading
                // 3 call get post with objectId from message vc ref below
                // 4 Insert the message at the top of the tableview once the message has been received
                // Continue... Open to the actual flow picture
                /*let postRef = Post()
                postRef.getPostWithObjectId(id: userInfo["objectId"] as! String) { (post) in
                    DataModel.newMessage = post
                    if let tabBarController =  DataModel.tabBarController {
                        tabBarController.selectedIndex = 1
                        if let badgeValue = tabBarController.tabBar.items?[1].badgeValue,
                            let value = Int(badgeValue) {
                            tabBarController.tabBar.items?[1].badgeValue = String(value + 1)
                        } else {
                            tabBarController.tabBar.items?[1].badgeValue = "1"
                        }
                    } else {
                        DataModel.pushId = identifier
                    }
                }*/
                
            } else if identifier == "newMessage" {
                if let tabBarController = DataModel.tabBarController {
                    DataModel.newMessageId = userInfo["objectId"] as! String
                    if tabBarController.selectedIndex != 1 {
                        tabBarController.selectedIndex = 1
                        if let badgeValue = tabBarController.tabBar.items?[1].badgeValue,
                            let value = Int(badgeValue) {
                            tabBarController.tabBar.items?[1].badgeValue = String(value + 1)
                        } else {
                            tabBarController.tabBar.items?[1].badgeValue = "1"
                        }
                    } else {
                        print("print0")
                        if let messagesVC = UIApplication.getTopViewController() as? MessagesVC {
                            messagesVC.getPostWithId()
                        }
                    }
                } else {
                    DataModel.newMessageId = userInfo["objectId"] as! String
                    DataModel.pushId = identifier
                }
            }
        }

        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received a push")
        /*if (application.applicationState == .background) {
            print("Received a push while the app in background")
        } else {
            print("Received a push while the app is foreground")
        }*/
        
        if let identifier = userInfo["identifier"] as? String {
            if identifier == "captionRequest" {
                let nav = window?.rootViewController as! UINavigationController
                DataModel.pushId = identifier
            }
        }
        
        if (application.applicationState == .inactive) {
            // App was in closed state
            
        } else {
        
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        DataModel.deviceToken = deviceToken
    }
    
    func createInstallationOnParse(deviceTokenData:Data) {
        if let installation = PFInstallation.current(){
            installation.setDeviceTokenFrom(deviceTokenData)
            installation.setObject(PFUser.current()!, forKey: "user")
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
        requestRef.getRequestsForCurrentUser(query: query) { (queriedRequests) in
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
                    if DataModel.pushId == "newMessage" {
                        if let discoverVC = UIApplication.getTopViewController() as? DiscoverVC {
                            discoverVC.tabBarController?.selectedIndex = 1
                        }
                    }
                }
            }
        }
    }
}

