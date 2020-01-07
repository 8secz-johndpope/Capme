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
import ATGMediaBrowser
import WLEmptyState

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MediaBrowserViewControllerDelegate, MediaBrowserViewControllerDataSource, UIGestureRecognizerDelegate, UITextViewDelegate, WLEmptyStateDataSource, WLEmptyStateDelegate {
    
    
    @IBAction func addCaptionAction(_ sender: Any) {
        print("Adding a caption")
        self.lowerView.addCaptionOutlet.isHidden = true
        self.lowerView.captionTextView.isHidden = false
        self.sendNewCaptionOutlet.isHidden = false
        self.lowerView.captionTextView.becomeFirstResponder()
    }
    
    @IBAction func addMessageAction(_ sender: Any) {
        self.performSegue(withIdentifier: "showChooseFriend", sender: nil)
    }
    
    @IBOutlet weak var inspirationOutlet: UIButton!
    @IBOutlet weak var selectedPostLowerView: PostDetailsLowerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendNewCaptionOutlet: UIButton!
    
    @IBAction func inspirationAction(_ sender: Any) {
        self.mediaBrowser.dismiss(animated: false) {
            self.performSegue(withIdentifier: "showInspiration", sender: nil)
        }
    }
    
    @IBAction func sendNewCaptionAction(_ sender: Any) {
        let newCaption = Caption()
        newCaption.captionText = self.lowerView.captionTextView.text
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        newCaption.creationDate = formatter.string(from: Date())
        newCaption.username = PFUser.current()!.username!
        newCaption.userId = PFUser.current()!.objectId!
        newCaption.favoritesCount = 0
        newCaption.isCurrentUserFavorite = false
        self.selectedPost.saveNewCaption(caption: newCaption.convertToJSON())
        self.lowerView.captionTextView.text = ""
        self.lowerView.captionTextView.resignFirstResponder()
        self.mediaBrowser.dismiss(animated: false) {
            print("dismissed media browser")
        }
    }
    
    var mediaBrowser: MediaBrowserViewController!
    var selectedPost = Post()
    var lowerView = PostDetailsLowerView()
    let textView = ReadMoreTextView()
    var originalTextFieldHeight: CGFloat = 0.0
    var translatioDistance: CGFloat = 0.0
    var fromDismiss = false
    var blurView = UIImageView()
    var inspirationButton = UIButton()
    let refreshControl = UIRefreshControl()
    var selectedFriend = User()
    var messageItemsPerFriend = [User : Any]() // Can be a message or a caption request
    
    var messagePreviews = [MessagePreview]()
    var captionRequests = [MessagePreview]()

    override func viewDidLoad() {
        setupUI()
    }
    
    // Message + Caption Request Workflow
    // 1) Get last message for each
    // 2) Get all caption requests later than the newest message (only a temp solution - eventually replace with cloud code $in)
    
    
    func getMessageItems() {
        // Get most recent message from each conversation
        PFCloud.callFunction(inBackground: "getMessagePreviews", withParameters: ["roomNames": self.getRoomNames()]) { (result, error) in
            if let messagePreviewsDicts = result as? [NSMutableDictionary] {
                for preview in messagePreviewsDicts {
                    let messagePreview = MessagePreview()
                    messagePreview.roomName = preview["objectId"] as? String
                    messagePreview.previewText = preview["message"] as? String
                    messagePreview.externalUser = messagePreview.getExternalUserFromRoomName(roomName: messagePreview.roomName)
                    print(preview["createdAt"] as! String)
                    messagePreview.date = messagePreview.getDateFromString(stringDate: preview["createdAt"] as! String)
                    messagePreview.itemType = "message"
                    messagePreview.isViewed = false
                    print(preview["message"] as! String)
                    print(preview["objectId"] as! String)
                    self.messagePreviews.append(messagePreview)
                    if preview === messagePreviewsDicts.last {
                        // Sort the messages
                        self.messagePreviews = messagePreview.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                        print(self.messagePreviews.first?.date, "first")
                        print(self.messagePreviews.last?.date, "last")
                        // Get the oldest (messagePreviews.last) message preview
                        self.getCaptionRequests(minDate: self.messagePreviews.last!.date)
                    }
                }
                if messagePreviewsDicts.count == 0 {
                    let timeInterval  = 1415639000.67457
                    let minDate = NSDate(timeIntervalSince1970: timeInterval)
                    self.getCaptionRequests(minDate: minDate as Date)
                }
            }
        }
    }
    
    func getCaptionRequests(minDate: Date) {
        
        let postRef = Post()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        query.whereKey("createdAt", greaterThan: minDate)
        query.whereKey("objectId", notContainedIn: DataModel.captionRequests.map( { $0.objectId }))
        query.order(byDescending: "createdAt")
        postRef.getCaptionRequestPreviews(query: query) { (captionRequests) in
            self.captionRequests = captionRequests
            // CONTINUE HERE: Change loop to track index - 1
            for (index, preview) in self.messagePreviews.enumerated() {
                // Get the corresponding captionRequest
                if let i = captionRequests.firstIndex(where: { $0.externalUser.objectId == preview.externalUser.objectId }) {
                    if captionRequests[i].date > preview.date {
                        // Replace the message preview using index - 2
                        self.messagePreviews[index] = captionRequests[i]
                    }
                }
                if index == self.messagePreviews.count - 1 {
                    print("made it to reload table view")
                    self.reloadTableView()
                }
            }
            if captionRequests.count == 0 {
                self.reloadTableView()
            }
        }
    }
    
    func reloadTableView() {
        let roomNames = self.messagePreviews.map( {$0.roomName })
        for captionRequest in captionRequests {
            
            var users = [String]()
            users.append(PFUser.current()!.objectId!)
            users.append(captionRequest.externalUser.objectId)
            let sortedUsers = users.sorted { $0 < $1 }
            if !roomNames.contains(sortedUsers[0] + "+" + sortedUsers[1]) {
                self.messagePreviews.insert(captionRequest, at: 0)
            }
            
            if captionRequest === captionRequests.last {
                self.messagePreviews = captionRequest.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                self.tableView.reloadData()
            }
        }
        if self.captionRequests.count == 0 && self.messagePreviews.count > 0 {
            self.messagePreviews = self.messagePreviews[0].sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
            self.tableView.reloadData()
        }
    }
    
    func getRoomNames() -> [String] {
        var roomNames = [String]()
        for friend in DataModel.friends {
            var users = [String]()
            users.append(PFUser.current()!.objectId!)
            users.append(friend.objectId)
            let sortedUsers = users.sorted { $0 < $1 }
            roomNames.append(sortedUsers[0] + "+" + sortedUsers[1])
        }
        print("got these roomnames", roomNames)
        return roomNames
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.viewControllers?[1].tabBarItem.badgeValue = nil
         getPostWithId()
    }
    
    fileprivate func addObservers() {
        print("showing the refresh now!")
        NotificationCenter.default.addObserver(self, selector: #selector(getPostWithId), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    fileprivate  func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func setupUI() {
    
        addObservers()
        
        // Lower View
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.lowerView = selectedPostLowerView
        self.lowerView.captionTextView.delegate = self
        self.lowerView.captionTextView.layer.masksToBounds = true
        self.lowerView.captionTextView.layer.cornerRadius = 10
        self.lowerView.captionTextView.isHidden = true
        self.sendNewCaptionOutlet.isHidden = true
        self.lowerView.captionTextView.tintColor = UIColor.white
        
        // Inspiration Outlet
        self.inspirationOutlet.layer.borderWidth = 2.0
        self.inspirationOutlet.layer.borderColor = UIColor.white.cgColor
        self.inspirationOutlet.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        self.inspirationOutlet.layer.cornerRadius = self.inspirationOutlet.frame.height/2
        self.inspirationOutlet.layer.masksToBounds = true
        self.inspirationButton = self.inspirationOutlet
        
        // Refresh Controller
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))]
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new posts...", attributes: attributes)
        refreshControl.tintColor = #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1)
        refreshControl.addTarget(self, action: #selector(startRefresh), for: UIControl.Event.valueChanged)
        self.refreshControl.programaticallyBeginRefreshing(in: self.tableView)
        self.tableView.addSubview(refreshControl)
        
        // Table View
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.getMessageItems()
        
        /*let postRef = Post()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        query.whereKey("objectId", notContainedIn: DataModel.captionRequests.map( { $0.objectId }))
        print("getting posts...", DataModel.newMessageId, DataModel.captionRequests.map( { $0.objectId }))
        
        postRef.getPosts(query: query) { (queriedPosts) in
                        
            for post in queriedPosts {
                if post.objectId == DataModel.newMessageId {
                    print("insert here2")
                    DataModel.captionRequests.insert(post, at: 0)
                } else {
                    if !DataModel.captionRequests.map( { $0.objectId }).contains(post.objectId) {
                        DataModel.captionRequests.append(post)
                    }
                }
                if post === queriedPosts.last {
                    DataModel.captionRequests = postRef.sortByCreatedAt(postsToSort: DataModel.captionRequests)
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            if DataModel.captionRequests.count == 0 && queriedPosts.count == 0 {
                self.refreshControl.endRefreshing()
                self.tableView.emptyStateDataSource = self
                self.tableView.reloadData()
            }
        }*/
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return DataModel.captionRequests.count
        return self.messagePreviews.count
    }
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageTableViewCell
        cell.messageTextLabel.text = self.messagePreviews[indexPath.row].previewText
        cell.profilePicImageView.image = self.messagePreviews[indexPath.row].externalUser.profilePic
        cell.usernameLabel.text = self.messagePreviews[indexPath.row].externalUser.username
        cell.selectionStyle = .none
        
        if self.messagePreviews[indexPath.row].isViewed {
            cell.composeImageView.isHidden = true
            cell.messageTextLabel.frame.origin = CGPoint(x: 80, y: cell.messageTextLabel.frame.origin.y)
            cell.profilePicImageView.layer.borderWidth = 0.0
            cell.usernameLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.semibold)
            cell.usernameLabel.textColor = UIColor.darkGray
        } else {
            cell.profilePicImageView.layer.borderWidth = 2.0
            cell.profilePicImageView.layer.borderColor = CGColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.messageTextLabel.frame.origin = CGPoint(x: 110, y: cell.messageTextLabel.frame.origin.y)
            cell.composeImageView.isHidden = false
        }
        
        /*cell.messageTextLabel.text = DataModel.captionRequests[indexPath.row].description
        cell.usernameLabel.text = DataModel.captionRequests[indexPath.row].sender.username
        cell.profilePicImageView.image = DataModel.captionRequests[indexPath.row].sender.profilePic
        if DataModel.captionRequests[indexPath.row].isViewed {
            cell.composeImageView.isHidden = true
            cell.messageTextLabel.frame.origin = CGPoint(x: 80, y: cell.messageTextLabel.frame.origin.y)
            cell.profilePicImageView.layer.borderWidth = 0.0
            cell.usernameLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.semibold)
            cell.usernameLabel.textColor = UIColor.darkGray
        } else {
            cell.profilePicImageView.layer.borderWidth = 2.0
            cell.profilePicImageView.layer.borderColor = CGColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.messageTextLabel.frame.origin = CGPoint(x: 110, y: cell.messageTextLabel.frame.origin.y)
            cell.composeImageView.isHidden = false
        }
        cell.selectionStyle = .none*/
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.messagePreviews[indexPath.row].isViewed = true
        self.tableView.reloadData()
        
        if self.messagePreviews[indexPath.row].itemType == "message" {
            self.selectedFriend = self.messagePreviews[indexPath.row].externalUser
            self.performSegue(withIdentifier: "showMessage", sender: nil)
        } else if self.messagePreviews[indexPath.row].itemType == "captionRequest" {
            self.fromDismiss = true
            self.messagePreviews[indexPath.row].isViewed = true
            self.tableView.reloadData()
            self.selectedFriend = self.messagePreviews[indexPath.row].externalUser
            
            Post().getPostWithObjectId(id: self.messagePreviews[indexPath.row].captionRequestObjectId) { (post) in
                self.selectedPost = post
                self.mediaBrowser = MediaBrowserViewController(dataSource: self)
                    
                self.lowerView.descriptionTextView.text = self.selectedPost.description
                self.lowerView.descriptionTextView.isHidden = true
                
                self.textView.text = self.selectedPost.description
                self.textView.shouldTrim = true
                self.textView.maximumNumberOfLines = 2
                self.textView.font  = UIFont.systemFont(ofSize: 17.0)
                self.textView.backgroundColor = UIColor.black
                self.textView.textColor = UIColor.white
                let attributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
                self.textView.attributedReadMoreText = NSAttributedString(string: "... More", attributes: attributes)
                self.textView.attributedReadLessText = NSAttributedString(string: " Less", attributes: attributes)
                self.textView.frame = self.lowerView.descriptionTextView.frame
                var selectTextViewGesture:UITapGestureRecognizer = UITapGestureRecognizer()
                selectTextViewGesture = UITapGestureRecognizer(target: self, action: #selector(MessagesVC.tapTextView(sender:)))
                selectTextViewGesture.delegate = self
                self.textView.addGestureRecognizer(selectTextViewGesture)
                self.originalTextFieldHeight = self.textView.frame.height
                print("new height", self.textView.frame.height)
                self.lowerView.addSubview(self.textView)
                
                self.lowerView.usernameLabel.text = self.selectedPost.sender.username
                self.lowerView.dateLabel.text = "Expires: " +  self.selectedPost.releaseDateDict.keys.first!
            
                self.inspirationButton.isHidden = false
                self.mediaBrowser.view.addSubview(self.inspirationButton)
                self.mediaBrowser.view.addSubview(self.lowerView)
                
                self.present(self.mediaBrowser, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.performSegue(withIdentifier: "showMessage", sender: nil)
                }
            }
        }
        
        // TODO Change this conditional to activate when the most recent item is a message
        if true {
            /*if let i = DataModel.friends.firstIndex(where: { $0.objectId == DataModel.captionRequests[indexPath.row].sender.objectId }) {
                print("\(DataModel.friends[i])!")
                self.selectedFriend = DataModel.friends[i]
            }
            self.performSegue(withIdentifier: "showMessage", sender: nil)*/
        }
        
        // TODO Change this conditional to activate when the selected message is a caption request
        if false {
            
        }
        
    }
    
    @objc func tapTextView(sender:UITapGestureRecognizer) {
        let lastChar = self.textView.text.last!
        if lastChar == "s" { // Show less
            self.textView.showLessText()
            let originalTransform = self.textView.transform
            let scaledTransform = originalTransform.scaledBy(x: 1.0, y: 1.0)
            let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: 0.0, y: self.translatioDistance)
            self.blurView.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.lowerView.topView.transform = scaledAndTranslatedTransform
                self.textView.transform = scaledAndTranslatedTransform
            }, completion: {
                (value: Bool) in
                let tempView = self.lowerView.bottomView
                self.lowerView.bottomView.removeFromSuperview()
                self.lowerView.addSubview(tempView!)
            })
        } else if lastChar == "e" {
            self.textView.backgroundColor = UIColor.black
            self.textView.showMoreText()
            self.textView.adjustUITextViewHeight()
            let screenSize = UIScreen.main.bounds
            let screenHeight = screenSize.height
            let originalTransform = self.textView.transform
            let scaledTransform = originalTransform.scaledBy(x: 1.0, y: 1.00)
            
            self.translatioDistance = textView.frame.height - self.lowerView.topView.frame.maxY + 30
            
            self.blurView.isHidden = false
            let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: 0.0, y: -(textView.frame.height - self.lowerView.topView.frame.maxY + 30))
            UIView.animate(withDuration: 0.3, animations: {
                self.lowerView.topView.transform = scaledAndTranslatedTransform
                self.textView.transform = scaledAndTranslatedTransform
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func numberOfItems(in mediaBrowser: MediaBrowserViewController) -> Int {
        return 1
    }
    
    func mediaBrowser(_ mediaBrowser: MediaBrowserViewController, imageAt index: Int, completion: @escaping MediaBrowserViewControllerDataSource.CompletionBlock) {
        completion(index, selectedPost.images[0], ZoomScale.default, nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
     func textViewDidBeginEditing(_ textView: UITextView) {
         if textView.textColor == UIColor.systemGray {
             textView.text = nil
             textView.textColor = UIColor.black
         }
     }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty && textView.textColor != UIColor.systemGray {
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendActive"), for: .normal)
        } else {
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendInactive"), for: .normal)
        }
    }
     
     func textViewDidEndEditing(_ textView: UITextView) {
         if textView.text.isEmpty {
             textView.text = "Add a caption..."
             textView.textColor = UIColor.systemGray
            self.sendNewCaptionOutlet.setImage(UIImage(named: "sendInactive"), for: .normal)
         }
     }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("text", text)
        if text == "\n" {
            print("should close...?")
            self.lowerView.captionTextView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        print("keyboard is showing")
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        print("made it this far")
        let keyboardFrame = keyboardSize.cgRectValue
        self.lowerView.frame.origin.y -= keyboardFrame.height
     }

    @objc func keyboardWillHide(notification: Notification){
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height
         self.lowerView.frame.origin.y += keyboardHeight!
    }
    
    func imageForEmptyDataSet() -> UIImage? {
        return UIImage(named: "envelopeEmpty")
    }
    
    func titleForEmptyDataSet() -> NSAttributedString {
        let title = NSAttributedString(string: "You have no messages", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.init(cgColor: #colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))])
        return title
    }
    
    func descriptionForEmptyDataSet() -> NSAttributedString {
        let description = "Select the button in the top right corner of your screen to create and send a new message"
        
        let title = NSAttributedString(string: description, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        return title
    }
    
    @objc func getPostWithId() {
        print("attempting to refresh...", DataModel.newMessageId)
        tabBarController!.tabBar.items?[1].badgeValue = nil
        if DataModel.newMessageId != "" {
            self.refreshControl.programaticallyBeginRefreshing(in: self.tableView)
            let postRef = Post()
            postRef.getPostWithObjectId(id: DataModel.newMessageId) { (post) in
                print("completed", post)
                if !DataModel.captionRequests.map( {$0.objectId}).contains(post.objectId) {
                    print("inserting new message")
                    DataModel.captionRequests.insert(post, at: 0)
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    DataModel.newMessageId = ""
                }
            }
        } else {
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(endRefresh), userInfo: nil, repeats: false)
        }
        
    }
    
    @objc func startRefresh(sender:AnyObject) {
        print("Refreshing...")
        getPostWithId()
    }
    
    @objc func endRefresh() {
        print("End Refreshing...")
        self.refreshControl.endRefreshing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInspiration" {
            let targetVC = segue.destination as! InspirationVC
            targetVC.selectedPost = self.selectedPost
        } else if segue.identifier == "showChooseFriend" {
            let targetVC = segue.destination as! ChooseFriendsVC
            targetVC.fromNewMessages = true
            
        } else if segue.identifier == "showMessage" {
            let targetVC = segue.destination as! ChatVC
            var users = [String]()
            users.append(PFUser.current()!.objectId!)
            users.append(self.selectedFriend.objectId!)
            let sortedUsers = users.sorted { $0 < $1 }
            targetVC.roomName = sortedUsers[0] + "+" + sortedUsers[1]
            targetVC.externalUser = self.selectedFriend
            DataModel.currentRecipient = self.selectedFriend
            targetVC.currentUser = DataModel.currentUser
            print("Set the roomName:", targetVC.roomName)
        }
    }
}
