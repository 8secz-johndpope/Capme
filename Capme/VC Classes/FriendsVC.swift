//
//  FriendsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse
import WLEmptyState
import FloatingPanel
import SCLAlertView

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, SlidingSegmentedControlDelegate, WLEmptyStateDataSource, FloatingPanelControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var requestOutlet: UIBarButtonItem!
    
    @IBOutlet weak var segmentControl: SlidingSegmentedControl! {
        didSet {
            segmentControl.setButtonTitles(buttonTitles: segmentedTitles, initialIndex: 0)
        }
    }
    
    @IBAction func requestAction(_ sender: Any) {
        print("show requests")
        if DataModel.receivedRequests.count > 0 {
            fpc.show(animated: true) {
                print("should have shown")
            }
        } else {
            let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
            let alert = SCLAlertView(appearance: appearance)
            alert.showInfo("Notice", subTitle: "You do not have any friend requests pending", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        }
        
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var users = [User]()
    var filteredUsers = [User]()
    var segmentedTitles = ["Friends", "Search"]
    var selectedSegment = 0
    
    var bound: CGFloat = 0.0
    var segmentHeight: CGFloat = 0.0
    var tableViewHeight: CGFloat = 0.0
    
    var selectedUser = User()
    
    var restrictedIds = [String]()
    var restrictedOutletTemp = UIBarButtonItem()
    let refreshControl = UIRefreshControl()
    
    let fpc = FloatingPanelController()
    
    override func viewWillDisappear(_ animated: Bool) {
        if DataModel.receivedRequests.count > 0 {
            fpc.hide(animated: true) {
                self.fpc.dismiss(animated: true) {}
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.navigationItem.rightBarButtonItem != nil {
            self.restrictedOutletTemp = self.navigationItem.rightBarButtonItem!
        }
        self.tabBarController?.viewControllers?[2].tabBarItem.badgeValue = nil
    }
    
    override func viewDidLoad() {
        setupUI()
        self.queryUsers()
    }
    
    func setupUI() {
        
        
        // Cannot Friend these object ids
        restrictedIds = DataModel.friends.map { $0.objectId! }
        print("received", DataModel.receivedRequests.map { $0.objectId! })
        restrictedIds.append(contentsOf: DataModel.receivedRequests.map { $0.objectId! })
        
        segmentControl.delegate = self
        // Hide the navigation bar line
        if let navigationControllerItem = navigationController {
            navigationControllerItem.hideLine()
        }
        
        // Search Controller
        searchController.searchResultsUpdater = self
        self.definesPresentationContext = true
        // Place the search bar in the navigation item's title view.
        self.navigationItem.titleView = searchController.searchBar
        // Don't hide the navigation bar because the search bar is in it.
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchTextField.backgroundColor = UIColor.lightText
        searchController.searchBar.autocapitalizationType = .words
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.keyboardAppearance = UIKeyboardAppearance.dark
        searchController.searchBar.isHidden = true
        searchController.searchBar.autocapitalizationType = .none
        
        // Table View
        if DataModel.friends.count == 0 && self.searchController.searchBar.isHidden  { // Show empty set
            self.tableView.emptyStateDataSource = self
            self.tableView.reloadData()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.bound = self.segmentControl.frame.origin.y
        self.segmentHeight = self.segmentControl.frame.height
        self.tableViewHeight = self.tableView.frame.height
        self.tableView.tableFooterView = UIView()
        
        // Refresh Controller
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))]
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new friend requests...", attributes: attributes)
        refreshControl.tintColor = #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1)
        refreshControl.addTarget(self, action: #selector(startRefresh), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(refreshControl)
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "requestsVC") as! RequestsVC
        DataModel.requestsVC = controller
        fpc.set(contentViewController: DataModel.requestsVC)
        DataModel.requestsVC!.friendsRef = self
        fpc.delegate = self
        print("right before")
        self.present(self.fpc, animated: DataModel.receivedRequests.count > 0, completion: {
            if DataModel.receivedRequests.count == 0 {
                self.fpc.show(animated: false) {
                    self.fpc.hide(animated: false) {
                        self.fpc.dismiss(animated: true) {
                            print("dismissed empty fpc")
                            
                        }
                    }
                }
            }
        })
        print("right after")
        
        if DataModel.friends.count == 0 && DataModel.receivedRequests.count == 0 {
            self.changeToIndex(index: 1)
            self.segmentControl.setIndex(index: 1)
        }
        
    
        if DataModel.receivedRequests.count > 0 {
            if let requestVC = DataModel.requestsVC {
                if requestVC.status != "" {
                    
                    fpc.isRemovalInteractionEnabled = true
                    //self.present(fpc, animated: true, completion: nil)
                } else {
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let tempVC : RequestsVC = mainStoryboard.instantiateViewController(withIdentifier: "requestsVC") as! RequestsVC
                    tempVC.receivedRequests = DataModel.receivedRequests
                    tempVC.view.layer.cornerRadius = 10.0
                    tempVC.view.layer.masksToBounds = true
                    tempVC.status = "active"
                    tempVC.friendsRef = self
                    DataModel.requestsVC = tempVC
                    fpc.isRemovalInteractionEnabled = true
                    //self.present(fpc, animated: true, completion: nil)
                }
            }
        }
    }
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return RequestsFloatingPanelLayout()
    }
    
    @objc func selectedImage(sender:UIButton) {
        print("seletced an image")
        self.selectedUser = DataModel.receivedRequests[sender.tag]
        self.performSegue(withIdentifier: "showFriendsProfile", sender: nil)
    }
    
    func queryUsers() {
        let query = PFQuery(className: "_User")
        query.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        let userRef = User()
        userRef.getUsers(query: query) { (queriedUsers) in
            for user in queriedUsers {
                if !self.restrictedIds.contains(user.objectId) {
                    DataModel.users.append(user)
                    self.users.append(user)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.searchController.searchBar.isHidden {
            self.selectedUser = DataModel.friends[indexPath.row]
            self.performSegue(withIdentifier: "showFriendsProfile", sender: nil)
        } else {
            if (searchController.isActive) {
                self.selectedUser = self.filteredUsers[indexPath.row]
            } else {
                self.selectedUser = self.users[indexPath.row]
            }
            self.performSegue(withIdentifier: "showFriendsProfile", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell
        var customUser = User()
        if searchController.searchBar.isHidden {
            customUser = DataModel.friends[indexPath.row]
            cell.addFriendOutlet.isHidden = true
            cell.addFriendLabel.isHidden = true
        } else {
            if (searchController.isActive) {
                customUser = self.filteredUsers[indexPath.row]
                let sentUserIds = DataModel.sentRequests.map { $0.objectId! }
                if sentUserIds.contains(customUser.objectId) {
                    cell.addFriendLabel.text = "Sent ✓"
                } else {
                    cell.addFriendLabel.text = "Add Friend"
                }
            } else {
                customUser = self.users[indexPath.row]
            }
            cell.addFriendOutlet.isHidden = false
            cell.addFriendLabel.isHidden = false
        }
        cell.addFriendOutlet.layer.cornerRadius = 8
        cell.addFriendOutlet.layer.masksToBounds = true
        cell.profilePicImageView.image = customUser.profilePic
        cell.usernameLabel.text = customUser.username
        cell.addFriendOutlet.accessibilityLabel = customUser.objectId
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.isHidden {
            return DataModel.friends.count
        } else {
            if (searchController.isActive) {
                return self.filteredUsers.count
            } else {
                return self.users.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.searchBar.text!.isEmpty {
            self.filteredUsers = users
            self.tableView.reloadData()
            return
        }
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: searchController.searchBar.text!)
        self.filteredUsers = self.users.filter {
            $0.username!.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
        self.tableView.reloadData()
    }
    
    func changeToIndex(index: Int) {
        
        if index == 0 {
            self.selectedSegment = 0
            self.navigationItem.rightBarButtonItem = self.restrictedOutletTemp
            self.searchController.searchBar.isHidden = true
            self.searchController.searchBar.resignFirstResponder()
            if DataModel.receivedRequests.count > 0 {
                self.fpc.dismiss(animated: true) {
                    self.present(self.fpc, animated: true, completion: nil)
                }
            }
        } else if index == 1 {
            if selectedSegment != 1 {
                self.selectedSegment = 1
                self.restrictedOutletTemp = self.navigationItem.rightBarButtonItem!
                self.navigationItem.rightBarButtonItem = nil
                
                // Hide the floating panel.
                self.fpc.show(animated: false) {
                    self.fpc.hide(animated: false) {
                        self.fpc.dismiss(animated: true) {
                            self.searchController.searchBar.isHidden = false
                            self.searchController.searchBar.becomeFirstResponder()
                            //self.fpc.view.removeFromSuperview()
                            //self.fpc.removeFromParent()
                        }
                    }
                }
            } else {
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
        self.tableView.reloadData()
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        self.segmentControl.frame.origin.y = -self.segmentControl.frame.height // Move view 150 points upward
        if let navController = self.navigationController {
            self.tableView.frame.origin.y = navController.navigationBar.frame.origin.y
        }
        
        if let keyboardFrame: NSValue = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let screenSize = UIScreen.main.bounds
            let screenHeight = screenSize.height
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            let compressedHeight = screenHeight - (keyboardHeight)
            self.tableView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: compressedHeight)
        }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        self.segmentControl.frame.origin.y = self.bound
        self.tableView.frame = CGRect(x: 0, y: self.bound + self.segmentHeight, width: self.view.frame.size.width, height: self.tableViewHeight)
    }
    
    func imageForEmptyDataSet() -> UIImage? {
        return UIImage(named: "friendsEmpty")
    }
    
    func titleForEmptyDataSet() -> NSAttributedString {
        let title = NSAttributedString(string: "Grow your captioning network!", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.init(cgColor: #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))])
        return title
    }
    
    func descriptionForEmptyDataSet() -> NSAttributedString {
        let description = "Select the \"SEARCH\" button to find your friends"
        
        let title = NSAttributedString(string: description, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        return title
    }
    
    @objc func startRefresh(sender:AnyObject) {
        print("Refreshing...")
        if let requestVC = DataModel.requestsVC {
            print("here1")
            print("number of items in the collection view", requestVC.collectionView.numberOfItems(inSection: 0))
            print("here2")
            self.fpc.set(contentViewController: requestVC)
            if DataModel.receivedRequests.count > 0 {
                self.fpc.dismiss(animated: true) {
                    self.present(self.fpc, animated: true, completion: {
                        print("refreshing collection view")
                        requestVC.collectionView.reloadData()
                        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.endRefresh), userInfo: nil, repeats: false)
                    })
                }
            }
            print("here3")
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.endRefresh), userInfo: nil, repeats: false)
        }
    }
    
    func getNewFriendRequests() {
        let friendRequestRef = FriendRequest()
        let query = PFQuery(className: "FriendRequest")
        query.whereKey("pending", equalTo: "status")
        query.whereKey("recipient", equalTo: PFUser.current()!)
        print("REQUEST IDS TO EXCLUDE", DataModel.receivedRequests.map( { $0.requestId }))
        query.whereKey("objectId", notContainedIn: DataModel.receivedRequests.map( { $0.requestId! }))
        friendRequestRef.getNewReceivedRequests(query: query) { (queriedRequests) in
            for request in queriedRequests {
                print("got new requests!")
                if request.receiver.objectId == PFUser.current()!.objectId! {
                    request.sender.requestId = request.objectId
                    DataModel.receivedRequests.append(request.sender)
                } else if request.sender.objectId == PFUser.current()!.objectId! {
                    DataModel.sentRequests.append(request.receiver)
                }
                print("RELOADING THE COLLECTION VIEW")
                DataModel.requestsVC!.collectionView.reloadData()
                self.endRefresh()
            }
            if queriedRequests.count == 0 {
                Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.endRefresh), userInfo: nil, repeats: false)
            }
        }
    }
       
   @objc func endRefresh() {
       print("End Refreshing...")
       self.refreshControl.endRefreshing()
   }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFriendsProfile" {
            let targetVC = segue.destination as! ProfileVC
            targetVC.selectedUser = self.selectedUser
            targetVC.fromSelectedUser = true
        }
    }
}

class RequestsFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .half
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            case .full: return 18.0
            case .half: return 262.0
            case .tip: return nil
            case .hidden: return nil
        }
    }
}
