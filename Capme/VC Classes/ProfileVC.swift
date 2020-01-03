//
//  ProfileVC.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import Parse
import ATGMediaBrowser
import FloatingPanel

class ProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shadowLabel: UILabel!
    @IBOutlet weak var postsCollectionView: UICollectionView!
    @IBOutlet weak var noPostsImageView: UIImageView!
    @IBOutlet weak var noPostsLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var collectionViewTitles = ["RECEIVED", "SENT", "FRIENDS"]
    var collectionViewCounts = ["---", "---", "---"]
    
    var friends = [User]()
    var posts = [Post]()
    
    var selectedUser = User()
    var selectedUsersFriends = [User]()
    var selectedPost = Post()
    var fromSelectedUser = false
    
    let fpc = FloatingPanelController()
    var mediaBrowser: MediaBrowserViewController!

    var selectedUserIsFriend = false
    
    @IBAction func logoutAction(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Log Out") {
            PFUser.logOut()
            self.performSegue(withIdentifier: "profileUnwind", sender: nil)
        }
        alert.showInfo("Notice", subTitle: "Are you sure you want to log out?", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
        DataModel.profilePic = UIImage()
        DataModel.friends = [User]()
        DataModel.users = [User]()
        DataModel.sentRequests = [User]()
        DataModel.receivedRequests = [User]()
    }
    
    override func viewDidLoad() {
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.viewControllers?[2].tabBarItem.badgeValue = nil
    }
    
    func setupUI() {
        
        // Loading Indicator
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.startAnimating()
        
        if self.fromSelectedUser {
            self.selectedUserIsFriend = DataModel.friends.map( { $0.objectId }).contains(self.selectedUser.objectId)
            if self.selectedUserIsFriend { // Selected User is a friend
                // Query their friends
                var predicates: [NSPredicate] = []
                print("querying friends of this user:", self.selectedUser.username)
                predicates.append(NSPredicate(format: "recipient = %@", self.selectedUser.pfuserRef!))
                predicates.append(NSPredicate(format: "sender = %@", self.selectedUser.pfuserRef!))
                let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                
                let query = PFQuery(className: "FriendRequest", predicate: predicate)
                query.whereKey("status", equalTo: "accepted")
                query.includeKey("recipient")
                query.includeKey("sender")
                let requestRef = FriendRequest()
                    
                requestRef.getRequestsForAnotherUser(query: query, user: self.selectedUser.pfuserRef!) { (queriedRequests) in
                    self.loadingIndicator.stopAnimating()
                    self.loadingIndicator.isHidden = true

                    for request in queriedRequests {
                        if request.receiver.objectId == self.selectedUser.objectId {
                            print("receiver:", request.receiver.username, "sender:", request.sender.username, "append sender")
                            self.selectedUsersFriends.append(request.sender)
                        } else if request.sender.objectId == self.selectedUser.objectId {
                            print("receiver:", request.receiver.username, "sender:", request.sender.username, "append receiver")
                            self.selectedUsersFriends.append(request.receiver)
                            
                        }
                    }
                    
                    self.collectionViewCounts[2] = String(describing: queriedRequests.count)
                    self.collectionView.reloadData()
                }

                
            } else {
                self.collectionViewCounts[2] = "---"
            }
            
            self.profilePicImageView.image = self.selectedUser.profilePic
            self.usernameLabel.text = self.selectedUser.username
            self.navigationItem.rightBarButtonItem = nil
            self.getCurrentUsersPosts(currentUser: selectedUser.pfuserRef!)
            // Get the users posts
            // Query Users
            // Keep track of the number of friends per user? NO query users because we will show the list anyway
            
        } else { // Current Users posts and profile
            
            
            // Profile Picture
            self.getCurrentUsersPosts(currentUser: PFUser.current()!)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            profilePicImageView.isUserInteractionEnabled = true
            profilePicImageView.addGestureRecognizer(tapGestureRecognizer)
            self.usernameLabel.text = PFUser.current()?.username!
            if DataModel.profilePic != UIImage() {
                self.profilePicImageView.image = DataModel.profilePic
            } else {
                self.profilePicImageView.image = UIImage(named: "defaultProfilePic")
            }
            if DataModel.friends.count == 0 {
                self.collectionViewCounts[2] = "+"
            } else {
                self.collectionViewCounts[2] = String(describing: DataModel.friends.count)
            }
        }
        
        // Actions Collection View
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        self.collectionView.layer.cornerRadius = 3
        self.collectionView.reloadData()
        
        // Posts Collection View
        self.postsCollectionView.delegate = self
        self.postsCollectionView.dataSource = self
        
        let postsLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        postsLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        postsLayout.itemSize = CGSize(width: (screenWidth / 3) - 1, height: (screenWidth / 3) - 1)
        postsLayout.minimumInteritemSpacing = 0.5
        postsLayout.minimumLineSpacing = 1.0
        self.postsCollectionView.collectionViewLayout = postsLayout
        
        shadowLabel.layer.shadowPath = UIBezierPath(rect: shadowLabel.bounds).cgPath
        shadowLabel.layer.shadowRadius = 3
        shadowLabel.layer.shadowOffset = .zero
        shadowLabel.layer.shadowOpacity = 0.8
        
        
        self.collectionView.reloadData()
        
        // Profile Picture Image View
        self.profilePicImageView.layer.borderWidth = 3.0
        self.profilePicImageView.layer.borderColor = UIColor.white.cgColor
        self.profilePicImageView.layer.cornerRadius = self.profilePicImageView.frame.height/2
        self.profilePicImageView.layer.masksToBounds = true
        
        
    }
    
    func getCurrentUsersPosts(currentUser: PFUser) {
        let postsRef = Post()
        let query = PFQuery(className: "Post")
        query.whereKey("sender", equalTo: currentUser)
        query.includeKey("sender")
        postsRef.getPosts(query: query) { (userPosts) in
            self.posts.append(contentsOf: userPosts)
            for post in userPosts {
                print(post.description, "post description")
                if post === userPosts.last {
                    self.posts = postsRef.sortByCreatedAt(postsToSort: self.posts)
                }
            }
            if userPosts.count == 0  && !self.fromSelectedUser {
                
                let addPostFirst = Post()
                addPostFirst.images.append(UIImage(named: "addPostFirst")!)
                let addPostInfo = Post()
                addPostInfo.images.append(UIImage(named: "addPostInfo")!)
                let addPostNew = Post()
                addPostNew.images.append(UIImage(named: "addPostNew")!)
                self.posts.append(addPostFirst)
                self.posts.append(addPostInfo)
                self.posts.append(addPostNew)
            } else if userPosts.count == 1  && !self.fromSelectedUser {
                let addPostInfo = Post()
                addPostInfo.images.append(UIImage(named: "addPostInfo")!)
                let addPostNew = Post()
                addPostNew.images.append(UIImage(named: "addPostNew")!)
                self.posts.append(addPostInfo)
                self.posts.append(addPostNew)
            } else if userPosts.count == 2  && !self.fromSelectedUser {
                let addPost = Post()
                addPost.images.append(UIImage(named: "addPostNew")!)
                self.posts.append(addPost)
            } else if self.fromSelectedUser && self.posts.count == 0 {
                self.noPostsImageView.isHidden = false
                self.noPostsLabel.isHidden = false
            }
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true
            self.postsCollectionView.reloadData()
            self.postsCollectionView.frame = CGRect(x: self.postsCollectionView.frame.minX, y: self.postsCollectionView.frame.minY, width: self.postsCollectionView.frame.width, height: self.postsCollectionView.collectionViewLayout.collectionViewContentSize.height)
            self.scrollView.updateContentView(addInset: 0.0)
            
            if (self.scrollView.contentSize.height < self.scrollView.frame.size.height) {
               self.scrollView.isScrollEnabled = false
            } else {
               self.scrollView.isScrollEnabled = true
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.postsCollectionView {
            if self.posts[indexPath.row].images[0] == UIImage(named: "addPostNew") { // Add Button
                print("selected add button")
                tabBarController?.selectedIndex = 0
                if let discoverVC = UIApplication.getTopViewController() as? DiscoverVC {
                    print(type(of: discoverVC))
                    discoverVC.postAction(self)
                    print("this is the top vc")
                }
            } else if self.posts[indexPath.row].images[0] == UIImage(named: "addPostFirst") {
                let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
                let alert = SCLAlertView(appearance: appearance)
                if DataModel.friends.count == 0 {
                    alert.addButton("Add Friends") {
                        self.performSegue(withIdentifier: "showFriends", sender: nil)
                    }
                } else {
                    alert.addButton("Caption Your Image") {
                        self.tabBarController?.selectedIndex = 0
                        if let discoverVC = UIApplication.getTopViewController() as? DiscoverVC {
                            discoverVC.postAction(self)
                        }
                    }
                }
                alert.showInfo("Your Posts:\nInfo", subTitle: "Capme lets you pick any number of friends to create the best caption for your images", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "exclamation"), animationStyle: .topToBottom)
            } else if self.posts[indexPath.row].images[0] == UIImage(named: "addPostInfo") {
                let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!, kTextFont: UIFont(name: "HelveticaNeue", size: 14)!, kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!, showCloseButton: true)
                let alert = SCLAlertView(appearance: appearance)
                alert.showInfo("Your Posts:\nTiming", subTitle: "Choose a deadline for your captioners to write their captions. Once their time is up, your post with their captions will be published and the favoriting competition begins!", closeButtonTitle: "Close", timeout: .none, colorStyle: 0x003366, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "hourglass"), animationStyle: .topToBottom)
            } else {
                self.selectedPost = self.posts[indexPath.row]
                self.selectedPost = self.posts[indexPath.row]
                mediaBrowser = MediaBrowserViewController(dataSource: self)
                present(mediaBrowser, animated: true, completion: nil)
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let tempVC : CaptionsVC = mainStoryboard.instantiateViewController(withIdentifier: "captionsVC") as! CaptionsVC
                tempVC.profileRef = self
                tempVC.fromProfile = true
                tempVC.postId = self.posts[indexPath.row].objectId
                tempVC.mediaBrowserRef = mediaBrowser
                tempVC.captions = self.posts[indexPath.row].captions
                tempVC.view.layer.cornerRadius = 10.0
                tempVC.view.layer.masksToBounds = true
                fpc.set(contentViewController: tempVC)
                DataModel.captionsVC = tempVC
                fpc.isRemovalInteractionEnabled = true
                mediaBrowser.present(fpc, animated: true, completion: nil)
                //self.performSegue(withIdentifier: "showPost", sender: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return self.collectionViewTitles.count
        } else {
            return self.posts.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProfileCollectionViewCell
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectionViewTapped(tapGestureRecognizer:)))
            tapGestureRecognizer.accessibilityLabel = collectionViewTitles[indexPath.row] + "_" + String(describing: collectionViewCounts[indexPath.row])
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(tapGestureRecognizer)
            cell.titleLabel.text = collectionViewTitles[indexPath.row]
            cell.countLabel.text = String(describing: collectionViewCounts[indexPath.row])
            return cell
        } else if collectionView == self.postsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProfilePostsCollectionViewCell
            cell.postImageView.image = self.posts[indexPath.row].images[0]
            if UIImage(named: "addPostNew")! == self.posts[indexPath.row].images[0] || UIImage(named: "addPostFirst")! == self.posts[indexPath.row].images[0] || UIImage(named: "addPostInfo")! == self.posts[indexPath.row].images[0] {
                cell.postImageView.frame = CGRect(x: cell.postImageView.frame.midX - (50/2), y: cell.postImageView.frame.midY - (50/2), width: 50.0, height: 50.0)
                cell.postImageView.contentMode = .center
            } else {
                cell.postImageView.contentMode = .scaleAspectFill
            }
            return cell
        }
        return UICollectionViewCell()
        
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        
        let messageAttrString = NSMutableAttributedString(string: "Choose Image From:", attributes: nil)
        
        alert.setValue(messageAttrString, forKey: "attributedMessage")
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { _ in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let userRef = User()
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.profilePicImageView.image = img
            userRef.updateProfilePicture(userId: (PFUser.current()?.objectId!)!, data: img.jpegData(compressionQuality: 1.0)!)
        } else if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profilePicImageView.image = img
            userRef.updateProfilePicture(userId: (PFUser.current()?.objectId!)!, data: img.jpegData(compressionQuality: 1.0)!)
        }
        dismiss(animated:true, completion: nil)
    }
    
    @objc func collectionViewTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        var count = 0
        let stringParam = tapGestureRecognizer.accessibilityLabel
        let end = stringParam!.index(after: stringParam!.firstIndex(of: "_")!)
        count = String(stringParam![...end]).convertStringToInt()
        if (stringParam!.contains("RECEIVED")) {
            self.receivedSelected(count: count)
        } else if (stringParam!.contains("SENT")) {
            self.sentSelected(count: count)
        } else if (stringParam!.contains("FRIENDS")) {
            self.friendsSelected(count: count)
        }
    }
    
    func receivedSelected(count: Int) {
    }
    
    func sentSelected(count: Int) {
    }
    
    func friendsSelected(count: Int) {
        // TODO determine if we will show friends of other users
        if !fromSelectedUser || self.selectedUserIsFriend {
            self.performSegue(withIdentifier: "showFriends", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFriends" {
            let targetVC = segue.destination as! FriendsVC
            targetVC.selectedUserIsFriend = self.selectedUserIsFriend
            targetVC.selectedUsersFriends = self.selectedUsersFriends
            if self.selectedUserIsFriend {
                targetVC.selectedUser = self.selectedUser
            }
        } else if segue.identifier == "showPost" {
            let targetVC = segue.destination as! PostDetailsVC
        }
    }
}

extension ProfileVC {
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        return 1
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        completion(index, selectedPost.images[0], ZoomScale.default, nil)
    }
}
