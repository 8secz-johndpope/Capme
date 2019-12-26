//
//  CaptionsVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/23/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import  UIKit
import Parse
import ATGMediaBrowser

class CaptionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var postId = String()
    var captions = [Caption]()
    var selectedUser = User()
    var discoverRef = DiscoverVC()
    var mediaBrowserRef: MediaBrowserViewController!
    
    // Fields to Handle Favorite/Unfavorite
    var favoriteIndex = -2
    
    
    override func viewDidLoad() {
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // TODO this could potentially be dangerous
        discoverRef.tableView.reloadData()
    }
    
    func setupUI() {
        
        if DataModel.favoritedPosts.keys.contains(postId) {
            for (index, element) in captions.enumerated() {
                print("Item \(index): \(element)")
                if  element.username + "*" + element.captionText == DataModel.favoritedPosts[postId] {
                    favoriteIndex = index
                }
            }
        }
        
        if (self.tableView.contentSize.height < tableView.frame.size.height) {
            self.tableView.isScrollEnabled = false
         } else {
            self.tableView.isScrollEnabled = true
         }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.reloadData()
    }
    
    func getSelectedUser(userId: String) {
        let user = PFUser(withoutDataWithClassName: "_User", objectId: userId)
        user.fetchIfNeededInBackground { (user, error) in
            if error == nil {
                if let queriedUser = user as? PFUser {
                    self.selectedUser = User(user: queriedUser, completion: { (queriedUser) in
                        self.dismiss(animated: true) {
                            self.mediaBrowserRef.dismiss(animated: false, completion: nil)
                            self.discoverRef.performSegue(withIdentifier: "showProfile", sender: nil)
                        }
                    })
                }
            }
        }
    }
    
    func saveFavorite(username: String, captionText: String) {
        if DataModel.favoritedPosts[postId] == username + "*" + captionText {
            DataModel.favoritedPosts.removeValue(forKey: postId)
        }
        DataModel.favoritedPosts[postId] = username + "*" + captionText
        print("check here", DataModel.favoritedPosts)
    }
    
    func unsaveFavorite(username: String, captionText: String) {
        DataModel.favoritedPosts.removeValue(forKey: postId)
        print("removed", DataModel.favoritedPosts)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt  indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CaptionTableViewCell
        cell.selectionStyle = .none
        cell.textView.text = self.captions[indexPath.row].captionText
        cell.usernameOutlet.setTitle(self.captions[indexPath.row].username, for: .normal)
        cell.textView.sizeToFit()

        
        if self.favoriteIndex > -1 { // Favorited
            self.saveFavorite(username: cell.usernameOutlet.titleLabel!.text!, captionText: cell.textView.text)
            cell.favoritesCountLabel.isHidden = false
            cell.favoriteOutlet.transform = CGAffineTransform(translationX: 0, y: -5)
            
            if indexPath.row == self.favoriteIndex {
                cell.favoriteOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
            } else {
                // Check if another cell is already favorited
                if cell.favoriteOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    self.captions[indexPath.row].unFavorite(captions: self.captions, username: self.captions[indexPath.row].username, captionText: self.captions[indexPath.row].captionText, postId: self.postId)
                }
                cell.favoriteOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
            }
        } else if self.favoriteIndex == -1 { // Unfavorited current
            self.unsaveFavorite(username: cell.usernameOutlet.titleLabel!.text!, captionText: cell.textView.text)
            cell.favoritesCountLabel.isHidden = true
            cell.favoriteOutlet.transform = CGAffineTransform(translationX: 0, y: 5)
            cell.favoriteOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        } else if self.favoriteIndex == -2 { // Untouched
            self.saveFavorite(username: cell.usernameOutlet.titleLabel!.text!, captionText: cell.textView.text)
            cell.favoriteOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
        }
        
        cell.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId:self.captions[indexPath.row].userId)
        }
        
        cell.favoriteAction = { [unowned self] in
            if cell.favoriteOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                //cell.favoriteOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.captions[indexPath.row].unFavorite(captions: self.captions, username: self.captions[indexPath.row].username, captionText: self.captions[indexPath.row].captionText, postId: self.postId)
                //self.captions[indexPath.row].favoritesCount -= 1
                cell.favoritesCountLabel.text = String(describing: self.captions[indexPath.row])
                self.favoriteIndex = -1
                let captionRef = Caption()
                self.captions = captionRef.sortByFavoritesCount(captionsToSort: self.captions)
                self.tableView.reloadData()
            } else {
                //cell.favoriteOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.captions[indexPath.row].becameFavorite(captions: self.captions, username: self.captions[indexPath.row].username, captionText: self.captions[indexPath.row].captionText, postId: self.postId)
                //self.captions[indexPath.row].favoritesCount += 1
                cell.favoritesCountLabel.text = String(describing: self.captions[indexPath.row].favoritesCount)
                
                let textBeforeSort = self.captions[indexPath.row].captionText
                let usernameBeforeSort = self.captions[indexPath.row].username
                
                let captionRef = Caption()
                self.captions = captionRef.sortByFavoritesCount(captionsToSort: self.captions)
                
                self.favoriteIndex = self.captions.firstIndex(where: { (item) -> Bool in
                    item.captionText == textBeforeSort && item.username == usernameBeforeSort
                })!
                print("this is the favorite index (should be 0)", self.favoriteIndex)
                
                self.tableView.reloadData()
            }
        }
        
        cell.favoritesCountLabel.text = String(describing: self.captions[indexPath.row].favoritesCount)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return captions.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let lblDescLong = UITextView()
        lblDescLong.textAlignment = .left
        lblDescLong.text = self.captions[indexPath.row].captionText
        lblDescLong.font = UIFont(name: "HelveticaNeue", size: 14)
        let newSize = lblDescLong.sizeThatFits(CGSize(width: 260.0, height: CGFloat.greatestFiniteMagnitude))
        print(self.captions[indexPath.row].captionText)
        return newSize.height + 25
    }
    
}
