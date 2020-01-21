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
        newCaption.isSenderFavorite = false
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
    var minDate = Date()
    
    var messagePreviews = [MessagePreview]()
    var allCaptionRequests = [MessagePreview]()
    var selectedChatCaptionRequests = [Post]()

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
                    messagePreview.objectId = preview["messageId"] as? String
                    messagePreview.externalUser = messagePreview.getExternalUserFromRoomName(roomName: messagePreview.roomName)
                    messagePreview.date = messagePreview.getDateFromString(stringDate: preview["createdAt"] as! String)
                    let tempSender = (preview["sender"] as! String)
                    messagePreview.sender = tempSender.replacingOccurrences(of: "_User$", with: "", options: NSString.CompareOptions.literal, range: nil)
                    messagePreview.itemType = "message"
                    if let isViewed = preview["isViewed"] as? Bool {
                        messagePreview.isViewed = isViewed
                    } else {
                        messagePreview.isViewed = false
                    }
                    if let text = preview["message"] as? String {
                        print(text)
                    }
                    print(preview["objectId"] as! String)
                    self.messagePreviews.append(messagePreview)
                    if preview === messagePreviewsDicts.last {
                        // Sort the messages
                        self.messagePreviews = messagePreview.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                        self.getLastCaptionRequest(minDate: self.messagePreviews.last!.date)
                        self.minDate = self.messagePreviews.last!.date
                    }
                }
                if messagePreviewsDicts.count == 0 {
                    let timeInterval  = 1415639000.67457
                    let minDate = NSDate(timeIntervalSince1970: timeInterval)
                    self.getLastCaptionRequest(minDate: minDate as Date)
                    self.minDate = minDate as Date
                }
            }
        }
    }
    
    func getLastCaptionRequest(minDate: Date) {
        
        let postRef = Post()
        let query = PFQuery(className: "Post")
        query.includeKey("sender")
        query.whereKey("recipients", contains: PFUser.current()?.objectId)
        query.whereKey("createdAt", greaterThan: minDate)
        query.whereKey("objectId", notContainedIn: DataModel.captionRequests.map( { $0.objectId }))
        query.order(byDescending: "createdAt")
        postRef.getCaptionRequestPreviews(query: query) { (captionRequests) in
            self.allCaptionRequests = captionRequests
            for (index, preview) in self.messagePreviews.enumerated() {
                // Get the corresponding captionRequest
                if let i = self.allCaptionRequests.firstIndex(where: { $0.externalUser.objectId == preview.externalUser.objectId }) {
                    if self.allCaptionRequests[i].date > preview.date {
                        self.messagePreviews[index] = self.allCaptionRequests[i]
                    }
                }
                if index == self.messagePreviews.count - 1 {
                    self.reloadTableView()
                }
            }
            if self.allCaptionRequests.count == 0 {
                self.reloadTableView()
            }
        }
    }
    
    func reloadTableView() {
        let roomNames = self.messagePreviews.map( {$0.roomName })
        for captionRequest in allCaptionRequests {
            
            var users = [String]()
            users.append(PFUser.current()!.objectId!)
            users.append(captionRequest.externalUser.objectId)
            let sortedUsers = users.sorted { $0 < $1 }
            if !roomNames.contains(sortedUsers[0] + "+" + sortedUsers[1]) {
                self.messagePreviews.insert(captionRequest, at: 0)
                
            }
            
            if captionRequest === allCaptionRequests.last {
                self.messagePreviews = captionRequest.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                self.tableView.reloadData()
            }
        }
        if self.allCaptionRequests.count == 0 && self.messagePreviews.count > 0 {
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
        self.refreshControl.isHidden = true
        if let newSentMessage = DataModel.sentMessagePreview {
            if let index = self.messagePreviews.firstIndex(where: { $0.roomName == newSentMessage.roomName }) {
                self.messagePreviews.remove(at: index)
                self.messagePreviews.insert(newSentMessage, at: 0)
                self.tableView.reloadData()
                DataModel.sentMessagePreview = nil
            }
        }
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
        
        if self.messagePreviews[indexPath.row].isViewed || self.messagePreviews[indexPath.row].sender == PFUser.current()?.objectId {
            cell.profilePicImageView.layer.borderWidth = 0.0
            cell.usernameLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
            cell.usernameLabel.textColor = UIColor.darkGray
        } else {
            cell.profilePicImageView.layer.borderWidth = 2.0
            cell.profilePicImageView.layer.borderColor = CGColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.usernameLabel.textColor = UIColor(#colorLiteral(red: 0, green: 0.2, blue: 0.4, alpha: 1))
            cell.composeImageView.isHidden = false
        }
        
        if self.messagePreviews[indexPath.row].itemType == "message" {
            cell.messageTextLabel.frame.origin = CGPoint(x: 80, y: cell.messageTextLabel.frame.origin.y)
            cell.composeImageView.isHidden = true
        } else if self.messagePreviews[indexPath.row].itemType == "captionRequest" {
            cell.composeImageView.isHidden = false
            cell.messageTextLabel.frame.origin = CGPoint(x: 110, y: cell.messageTextLabel.frame.origin.y)
        }
        return cell
    }
    
    
    func showCaptionRequest(captionRequest: Post) {
        self.selectedPost = captionRequest
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
        self.lowerView.addSubview(self.textView)
        
        self.lowerView.usernameLabel.text = self.selectedPost.sender.username
        self.lowerView.dateLabel.text = "Expires: " +  self.selectedPost.releaseDateDict.keys.first!
    
        self.inspirationButton.isHidden = false
        self.mediaBrowser.view.addSubview(self.inspirationButton)
        self.mediaBrowser.view.addSubview(self.lowerView)
        
        self.present(self.mediaBrowser, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewedMessagePreview = self.messagePreviews[indexPath.row]
        
        if self.messagePreviews[indexPath.row].itemType == "message" {
            self.selectedFriend = viewedMessagePreview.externalUser
            self.performSegue(withIdentifier: "showMessage", sender: nil)
        } else if viewedMessagePreview.itemType == "captionRequest" && !self.messagePreviews[indexPath.row].isViewed {
            self.fromDismiss = true
            self.selectedFriend = viewedMessagePreview.externalUser
            Post().getPostWithObjectId(id: viewedMessagePreview.objectId) { (post) in
                self.showCaptionRequest(captionRequest: post)
            }
        } else if viewedMessagePreview.itemType == "captionRequest" && self.messagePreviews[indexPath.row].isViewed {
            self.selectedFriend = viewedMessagePreview.externalUser
            self.performSegue(withIdentifier: "showMessage", sender: nil)
        }
        if self.messagePreviews[indexPath.row].sender != PFUser.current()?.objectId && !viewedMessagePreview.isViewed {
            // Only the recipient of the views
            viewedMessagePreview.messageBecameViewed()
            viewedMessagePreview.isViewed = true
            self.tableView.reloadData()
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
    
    @objc func getCaptionRequestWithId() {
        tabBarController!.tabBar.items?[1].badgeValue = nil
        if DataModel.newMessageId != "" {
            let messageRef = Message()
            let query = PFQuery(className: "Message")
            query.includeKey("author")
            print("New caption request id:", DataModel.newMessageId)
            query.whereKey("post", equalTo: PFObject(withoutDataWithClassName: "Post", objectId: DataModel.newMessageId))
            query.includeKey("post")
            messageRef.getCaptionRequestFromId(query: query) { (message) in
                if let index = self.messagePreviews.firstIndex(where: { $0.externalUser.username == message.authorName }) {
                    let messagePreview = message.convertMessageToPreview()
                    self.messagePreviews[index] = messagePreview
                    self.messagePreviews = messagePreview.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                    self.tableView.reloadData()
                    if DataModel.pushId == "newMessage" {
                        DataModel.pushId = ""
                        if let index = self.messagePreviews.firstIndex(where: { $0.objectId == DataModel.newMessageId } ) {
                            self.messagePreviews[index].isViewed = true
                            self.messagePreviews[index].messageBecameViewed()
                            self.selectedFriend = self.messagePreviews[index].externalUser
                            self.performSegue(withIdentifier: "showMessage", sender: nil)
                        }
                    } else if DataModel.pushId == "captionRequest" {
                        print("found a caption request")
                    }
                }
            }
        }
    }
    
    @objc func getPostWithId() {
        tabBarController!.tabBar.items?[1].badgeValue = nil
        if DataModel.newMessageId != "" {
            let messageRef = Message()
            let query = PFQuery(className: "Message")
            query.includeKey("author")
            query.whereKey("objectId", equalTo: DataModel.newMessageId)
            messageRef.getMessageFromId(query: query, id: DataModel.newMessageId) { (message) in
                if let index = self.messagePreviews.firstIndex(where: { $0.roomName == message.roomName }) {
                    let messagePreview = message.convertMessageToPreview()
                    self.messagePreviews[index] = messagePreview
                    self.messagePreviews = messagePreview.sortByCreatedAt(messagePreviewsToSort: self.messagePreviews)
                    self.tableView.reloadData()
                    if DataModel.pushId == "newMessage" {
                        DataModel.pushId = ""
                        if let index = self.messagePreviews.firstIndex(where: { $0.objectId == DataModel.newMessageId } ) {
                            self.messagePreviews[index].isViewed = true
                            self.messagePreviews[index].messageBecameViewed()
                            self.selectedFriend = self.messagePreviews[index].externalUser
                            self.performSegue(withIdentifier: "showMessage", sender: nil)
                        }
                    } else if DataModel.pushId == "captionRequest" {
                        print("found a caption request")
                    }
                }
            }
        } else {
            /*
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
            }*/
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
            targetVC.messagesVcRef = self
        }
    }
}
