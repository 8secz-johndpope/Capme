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

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, SlidingSegmentedControlDelegate, WLEmptyStateDataSource, FloatingPanelControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var segmentControl: SlidingSegmentedControl! {
        didSet {
            segmentControl.setButtonTitles(buttonTitles: segmentedTitles, initialIndex: 0)
        }
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var users = [User]()
    var filteredUsers = [User]()
    var segmentedTitles = ["Friends", "Search"]
    
    var bound: CGFloat = 0.0
    var segmentHeight: CGFloat = 0.0
    var tableViewHeight: CGFloat = 0.0
    
    var selectedUser = User()
    
    var restrictedIds = [String]()
    
    let fpc = FloatingPanelController()
    
    override func viewWillDisappear(_ animated: Bool) {
        if DataModel.receivedRequests.count > 0 {
            fpc.hide(animated: true) {
                self.fpc.dismiss(animated: true) {}
            }
        }
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
        
        if DataModel.friends.count == 0 {
            self.changeToIndex(index: 1)
            self.segmentControl.setIndex(index: 1)
        }
        
        // Show Floating Requests Panel
        fpc.delegate = self
        if DataModel.receivedRequests.count > 0 {
            if DataModel.requestsVC.status != "" {
                fpc.set(contentViewController: DataModel.requestsVC)
                fpc.isRemovalInteractionEnabled = true
                self.present(fpc, animated: true, completion: nil)
            } else {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let tempVC : RequestsVC = mainStoryboard.instantiateViewController(withIdentifier: "requestsVC") as! RequestsVC
                tempVC.receivedRequests = DataModel.receivedRequests
                tempVC.view.layer.cornerRadius = 10.0
                tempVC.view.layer.masksToBounds = true
                fpc.set(contentViewController: tempVC)
                tempVC.status = "active"
                tempVC.friendsRef = self
                DataModel.requestsVC = tempVC
                fpc.isRemovalInteractionEnabled = true
                self.present(fpc, animated: true, completion: nil)
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
            self.searchController.searchBar.isHidden = true
            self.searchController.searchBar.resignFirstResponder()
            if DataModel.receivedRequests.count > 0 {
                self.fpc.dismiss(animated: true) {
                    self.present(self.fpc, animated: true, completion: nil)
                }
            }
        } else if index == 1 {
            self.searchController.searchBar.isHidden = false
            self.searchController.searchBar.becomeFirstResponder()
            // Hide the floating panel.
            if DataModel.receivedRequests.count > 0 {
                fpc.hide(animated: true) {
                    self.fpc.dismiss(animated: true) {
                        
                    }
                    
                    //self.fpc.view.removeFromSuperview()
                    //self.fpc.removeFromParent()
                }
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
