//
//  FeedVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse
import NVActivityIndicatorView
import ATGMediaBrowser
import FloatingPanel

class DiscoverVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func postAction(_ sender: Any) {
        self.performSegue(withIdentifier: "showCreate", sender: nil)
    }
    
    @IBAction func discoverUnwind(segue: UIStoryboardSegue) {}
    
    var posts = [Post]()
    var selectedUser = User()
    var selectedPost = Post()
    var mediaBrowser: MediaBrowserViewController!
    let fpc = FloatingPanelController()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        
        // Refresh Controller
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))]
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new posts...", attributes: attributes)
        refreshControl.tintColor = #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1)
        refreshControl.addTarget(self, action: #selector(startRefresh), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Table View
        self.tableView.separatorColor = UIColor.clear
        self.tableView.delegate = self
        self.tableView.dataSource = self
        let postRef = Post()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        postRef.getPosts(query: query) { (queriedPosts) in
            self.posts = postRef.sortByReleaseDate(postsToSort: queriedPosts)
            self.tableView.reloadData()
        }
    }
    
    @objc func startRefresh(sender:AnyObject) {
        print("Refreshing...")
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(endRefresh), userInfo: nil, repeats: false)
    }
    
    @objc func endRefresh() {
        print("End Refreshing...")
        self.refreshControl.endRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func getSelectedUser(userId: String) {
        let user = PFUser(withoutDataWithClassName: "_User", objectId: userId)
        user.fetchIfNeededInBackground { (user, error) in
            if error == nil {
                if let queriedUser = user as? PFUser {
                    self.selectedUser = User(user: queriedUser, completion: { (queriedUser) in
                        self.performSegue(withIdentifier: "showProfile", sender: nil)
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedPost = self.posts[indexPath.row]
        mediaBrowser = MediaBrowserViewController(dataSource: self)
        present(mediaBrowser, animated: true, completion: nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let tempVC : CaptionsVC = mainStoryboard.instantiateViewController(withIdentifier: "captionsVC") as! CaptionsVC
        tempVC.discoverRef = self
        tempVC.postId = self.posts[indexPath.row].objectId
        tempVC.mediaBrowserRef = mediaBrowser
        tempVC.captions = self.posts[indexPath.row].captions
        tempVC.view.layer.cornerRadius = 10.0
        tempVC.view.layer.masksToBounds = true
        fpc.set(contentViewController: tempVC)
        DataModel.captionsVC = tempVC
        fpc.isRemovalInteractionEnabled = true
        mediaBrowser.present(fpc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.posts[indexPath.row].captions.count == 1 {
            return 347.0
        } else if self.posts[indexPath.row].captions.count == 2 {
            return 401.0
        } else if self.posts[indexPath.row].captions.count == 3 {
            return 454.0
        }
        return 0.0
    }
    
    func showFavorites(cell: DiscoverTableViewCell) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, animations: {
                cell.firstCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                cell.secondCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                cell.thirdCaptionView.favoriteButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -10)
                print("starting translation")
            }, completion: {
                (value: Bool) in
                print("completed the translation")
                cell.firstCaptionView.favoritesCountLabel.isHidden = false
                cell.secondCaptionView.favoritesCountLabel.isHidden = false
                cell.thirdCaptionView.favoritesCountLabel.isHidden = false
            })
        }
    }
    
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        return 1
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        completion(index, selectedPost.images[0], ZoomScale.default, nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let targetVC = segue.destination as! ProfileVC
            targetVC.selectedUser = self.selectedUser
            targetVC.fromSelectedUser = true
            
        }
    }
    
}

extension DiscoverVC {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DiscoverTableViewCell
        cell.mainImageView.image = self.posts[indexPath.row].images[0]
        cell.usernameLabel.text = self.posts[indexPath.row].sender.username
        cell.dateLabel.text = self.posts[indexPath.row].releaseDateDict[self.posts[indexPath.row].releaseDateDict.keys.first!]!.timeAgo()
        cell.senderProfilePic.image = self.posts[indexPath.row].sender.profilePic
        cell.firstCaptionView.favoriteButtonOutlet.accessibilityLabel = "1"
        cell.secondCaptionView.favoriteButtonOutlet.accessibilityLabel = "2"
        cell.thirdCaptionView.favoriteButtonOutlet.accessibilityLabel = "3"
        
        cell.firstCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[0].userId)
        }
        
        cell.secondCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[1].userId)
        }
        
        cell.thirdCaptionView.showCaptionerAction = { [unowned self] in
            self.getSelectedUser(userId: self.posts[indexPath.row].captions[2].userId)
        }
        
        let currentPostCaptions = self.posts[indexPath.row].captions
        
        cell.firstCaptionView.favoriteAction = { [unowned self] in
            if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)

                if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                self.posts[indexPath.row].captions[0].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                
            }
        }
        
        cell.secondCaptionView.favoriteAction = { [unowned self] in
            if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)
                
                if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                self.posts[indexPath.row].captions[1].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
            }
        }
        
        cell.thirdCaptionView.favoriteAction = { [unowned self] in
            if cell.thirdCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "unfilledStar")) {
                
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "filledStar"), for: .normal)
                self.showFavorites(cell: cell)
                
                if cell.firstCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.firstCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[0].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[0].username, captionText: currentPostCaptions[0].captionText, postId: self.posts[indexPath.row].objectId)
                } else if cell.secondCaptionView.favoriteButtonOutlet.currentImage!.isEqual(UIImage(named: "filledStar")) {
                    cell.secondCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                    self.posts[indexPath.row].captions[1].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[1].username, captionText: currentPostCaptions[1].captionText, postId: self.posts[indexPath.row].objectId)
                }
                
                self.posts[indexPath.row].captions[2].becameFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
                self.tableView.reloadData()
            } else {
                print("should not see this")
                cell.thirdCaptionView.favoriteButtonOutlet.setImage(UIImage(named: "unfilledStar"), for: .normal)
                self.posts[indexPath.row].captions[2].unFavorite(captions: currentPostCaptions, username: currentPostCaptions[2].username, captionText: currentPostCaptions[2].captionText, postId: self.posts[indexPath.row].objectId)
            }
        }
        
        if self.posts[indexPath.row].captions.count > 0 {
            let caption = self.posts[indexPath.row].captions[0]
            cell.firstCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            
            cell.firstCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.firstCaptionView.captionLabel.text = caption.captionText
            
            if self.posts[indexPath.row].captions.count == 1 {
                cell.secondCaptionView.isHidden = true
                cell.thirdCaptionView.isHidden = true
            }
        }
        
        if self.posts[indexPath.row].captions.count > 1 {
            let caption = self.posts[indexPath.row].captions[1]
            cell.secondCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            cell.secondCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.secondCaptionView.captionLabel.text = caption.captionText
            if self.posts[indexPath.row].captions.count == 2 {
                cell.thirdCaptionView.isHidden = true
            }
        }
        
        if self.posts[indexPath.row].captions.count > 2 {
            let caption = self.posts[indexPath.row].captions[2]
            cell.thirdCaptionView.favoritesCountLabel.text = String(describing: caption.favoritesCount)
            cell.thirdCaptionView.usernameButton.setTitle(caption.username, for: .normal)
            cell.thirdCaptionView.captionLabel.text = caption.captionText
        }
        
        return cell
    }
}
