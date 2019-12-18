//
//  RequestsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/16/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

class RequestsVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    var recievedRequests = [User]()
    var status = ""
    var selectedUser = User()
    var friendsRef = FriendsVC()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        
        // Collection View
        //Define Layout here
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let inset = (screenWidth - 200.0)/3
        layout.sectionInset = UIEdgeInsets(top: 0, left: 30.0, bottom: 0, right: 30.0)
        layout.itemSize = CGSize(width: 125.0, height: collectionView.frame.height)
        layout.minimumInteritemSpacing = inset
        layout.minimumLineSpacing = 60.0
        collectionView!.collectionViewLayout = layout
        self.collectionView.layer.masksToBounds = true
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        DataModel.recievedRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RequestCollectionViewCell
        cell.profilePicImageView.image = DataModel.recievedRequests[indexPath.row].profilePic
        cell.usernameLabel.text = DataModel.recievedRequests[indexPath.row].username
        cell.removeOutlet.accessibilityLabel =  DataModel.recievedRequests[indexPath.row].objectId
        cell.acceptOutlet.accessibilityLabel =  DataModel.recievedRequests[indexPath.row].objectId
        print(DataModel.recievedRequests[indexPath.row].requestId!)
        cell.requestId = DataModel.recievedRequests[indexPath.row].requestId!
        cell.acceptOutlet.layer.cornerRadius = 8
        cell.acceptOutlet.layer.masksToBounds = true
        cell.removeOutlet.layer.cornerRadius = 8
        cell.removeOutlet.layer.masksToBounds = true
        
        cell.profilePicOutlet.tag = indexPath.row
        cell.profilePicOutlet.addTarget(self.friendsRef, action: #selector(FriendsVC.selectedImage(sender:)), for: UIControl.Event.touchUpInside)
        cell.removeOutlet.tag = indexPath.row
        cell.removeOutlet.addTarget(self, action: #selector(removeRequest(sender:)), for: UIControl.Event.touchUpInside)
        
        cell.acceptOutlet.tag = indexPath.row
        cell.acceptOutlet.addTarget(self, action: #selector(acceptRequest(sender:)), for: UIControl.Event.touchUpInside)
        return cell
    }
    
    @objc func removeRequest(sender:UIButton) {
        let index = sender.tag
        DataModel.recievedRequests.remove(at: index)
        self.collectionView.reloadData()
    }
    
    @objc func acceptRequest(sender:UIButton) {
        let index = sender.tag
        let newFriend = DataModel.recievedRequests.remove(at: index)
        DataModel.friends.insert(newFriend, at: 0)
        self.collectionView.reloadData()
        friendsRef.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let targetVC = segue.destination as! ProfileVC
            targetVC.selectedUser = self.selectedUser
            targetVC.fromSelectedUser = true
        }
    }
    
}
