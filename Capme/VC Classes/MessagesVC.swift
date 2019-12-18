//
//  MessagesVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.queryFriendRequests()
    }
    
    func queryFriendRequests() {
        let query = PFQuery(className: "FriendRequest")
        query.whereKey("recipient", equalTo: PFUser.current()!.objectId!)
        query.whereKey("status", equalTo: "pending")
        let userRef = User()
        userRef.getUsers(query: query) { (userRequests) in
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}
