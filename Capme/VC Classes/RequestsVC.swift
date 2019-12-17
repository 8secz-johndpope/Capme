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
        layout.sectionInset = UIEdgeInsets(top: 0, left: 60.0, bottom: 0, right: 60.0)
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
        self.recievedRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RequestCollectionViewCell
        cell.profilePicImageView.image = self.recievedRequests[indexPath.row].profilePic
        cell.usernameLabel.text = self.recievedRequests[indexPath.row].username
        cell.removeOutlet.accessibilityLabel =  self.recievedRequests[indexPath.row].objectId
        cell.acceptOutlet.accessibilityLabel =  self.recievedRequests[indexPath.row].objectId
        print(self.recievedRequests[indexPath.row].requestId!)
        cell.requestId = self.recievedRequests[indexPath.row].requestId!
        cell.acceptOutlet.layer.cornerRadius = 8
        cell.acceptOutlet.layer.masksToBounds = true
        cell.removeOutlet.layer.cornerRadius = 8
        cell.removeOutlet.layer.masksToBounds = true
        return cell
    }
    
    
    
    
}
