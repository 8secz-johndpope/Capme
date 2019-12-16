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

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, SlidingSegmentedControlDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var segmentControl: SlidingSegmentedControl! {
        didSet {
            segmentControl.setButtonTitles(buttonTitles: segmentedTitles, initialIndex: 0)
        }
    }
    
    let searchController = UISearchController(searchResultsController: nil)

    var friends = [User]()
    var sentRequests = [User]()
    var recievedRequests = [User]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var segmentedTitles = ["Friends", "Search"]
    
    var restrictedIds = [String]()
    
    override func viewDidLoad() {
        setupUI()
        self.queryUsers()
    }
    
    func setupUI() {
        
        // Cannot Friend these object ids
        restrictedIds = self.friends.map { $0.objectId! }
        print("sent", self.sentRequests.map { $0.objectId! })
        print("recieved", self.recievedRequests.map { $0.objectId! })
        restrictedIds.append(contentsOf: self.sentRequests.map { $0.objectId! })
        restrictedIds.append(contentsOf: self.recievedRequests.map { $0.objectId! })
        
        segmentControl.delegate = self
        // Hide the navigation bar line
        if let navigationControllerItem = navigationController as? UINavigationController {
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
        
        // Table View
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func queryUsers() {
        let query = PFQuery(className: "_User")
        query.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        let userRef = User()
        userRef.getUsers(query: query) { (queriedUsers) in
            for user in queriedUsers {
                if !self.restrictedIds.contains(user.objectId) {
                    self.users.append(user)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell
        var customUser = User()
        if searchController.searchBar.isHidden {
            customUser = self.friends[indexPath.row]
            cell.addFriendOutlet.isHidden = true
            cell.addFriendLabel.isHidden = true
        } else {
            customUser = self.users[indexPath.row]
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
            return self.friends.count
        } else {
            return self.users.count
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
        self.filteredUsers = self.users.filter {
            $0.username!.range(of: searchController.searchBar.text!, options: .caseInsensitive) != nil
        }
        self.tableView.reloadData()
    }
    
    func changeToIndex(index: Int) {
        if index == 0 {
            self.searchController.searchBar.isHidden = true
            self.searchController.searchBar.resignFirstResponder()
        } else if index == 1 {
            self.searchController.searchBar.isHidden = false
            self.searchController.searchBar.becomeFirstResponder()
        }
        self.tableView.reloadData()
    }
    
}
