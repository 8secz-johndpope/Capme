//
//  ChatVC.swift
//  Capme
//
//  Created by Gabe Wilson on 1/2/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import MessageKit
import InputBarAccessoryView
import ParseLiveQuery
import Parse
import Photos
import ATGMediaBrowser
import ImageViewer


/// A base class for the example controllers
class ChatVC: MessagesViewController, MessagesDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    var skipCount = 0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// The `BasicAudioController` controll the AVAudioPlayer state (play, pause, stop) and udpate audio cell UI accordingly.
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    var messageList: [MockMessage] = []
    
    let refreshControl = UIRefreshControl()
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var roomName = ""
    var currentUser = User()
    var externalUser = User()
    
    // Image Message
    var selectedImage = UIImage()
    
    // Caption Request Fields
    var messagesVcRef = MessagesVC()
    var selectedChatCaptionRequests = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureMessageCollectionView()
        configureMessageInputBar()
        loadFirstMessages()
    }
    
    func setupUI() {
        // 1
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .darkGray
        cameraItem.image = UIImage(named: "add")

        // 2
        cameraItem.addTarget(
          self,
          action: #selector(cameraButtonPressed),
          for: .primaryActionTriggered
        )
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)

        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

        // 3
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatManager.connectToChatRoom(self.roomName)
        chatManager.chatRef = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatManager.disconnectFromChatRoom()
        /*audioController.stopAnyOngoingPlaying()*/
    }
    
    func loadFirstMessages() {
        print("loading first messages")
        DispatchQueue.global(qos: .userInitiated).async {
            let messageRef = Message()
            let messageQuery = PFQuery(className: "Message")
            messageQuery.whereKey("roomName", equalTo: self.roomName)
            
            let receivedPostsQuery = PFQuery(className: "Message")
            receivedPostsQuery.whereKeyExists("post")
            receivedPostsQuery.whereKey("recipients", contains: PFUser.current()?.objectId!)
            receivedPostsQuery.whereKey("author", equalTo: self.externalUser.pfuserRef!)
            print(self.externalUser.pfuserRef, "querying for this external user")
            
            let sentPostsQuery = PFQuery(className: "Message")
            sentPostsQuery.whereKeyExists("post")
            sentPostsQuery.whereKey("author", equalTo: PFUser.current()!)
            sentPostsQuery.whereKey("recipients", contains: self.externalUser.objectId)
            
            let combinedMessagesQuery = PFQuery.orQuery(withSubqueries: [messageQuery, receivedPostsQuery, sentPostsQuery])
            combinedMessagesQuery.includeKey("author")
            combinedMessagesQuery.includeKey("post")
            combinedMessagesQuery.order(byDescending: "createdAt")
            combinedMessagesQuery.limit = 20
            
            messageRef.getMessages(query: combinedMessagesQuery) { (queriedMessages) in
                self.messageList = queriedMessages
                print(self.messageList.count, "This many messages")
                self.messageList = messageRef.sortByCreatedAt(messagesToSort: self.messageList)
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom()
                self.skipCount += 20
            }
        }
    }
    
    @objc private func cameraButtonPressed() {
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
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      picker.dismiss(animated: true, completion: nil)
      
      // 1
      if let asset = info[.phAsset] as? PHAsset {
        let size = CGSize(width: 500, height: 500)
        PHImageManager.default().requestImage(
          for: asset,
          targetSize: size,
          contentMode: .aspectFit,
          options: nil) { result, info in
            
          guard let image = result else {
            
            return
          }
            
          //self.sendPhoto(image)
            let attachment = NSTextAttachment()
            attachment.image = image
            let attString = NSAttributedString(attachment: attachment)
            self.messageInputBar.inputTextView.attributedText = attString
        }

      // 2
      } else if let image = info[.originalImage] as? UIImage {
        //sendPhoto(image)
        let attachment = NSTextAttachment()
        attachment.image = image
        let attString = NSAttributedString(attachment: attachment)
        let oldWidth = attachment.image!.size.width
        let scaleFactor = oldWidth / (self.messageInputBar.inputTextView.frame.size.width - 10); //for the padding inside the textView
        
        // TODO handle image orientation dynamically
        attachment.image = UIImage(cgImage: attachment.image!.cgImage!, scale: scaleFactor, orientation: .right)
        self.messageInputBar.inputTextView.attributedText = attString
      }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func loadMoreMessages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let messageRef = Message()
            let query = PFQuery(className: "Message")
            query.order(byDescending: "createdAt")
            query.limit = 20
            query.skip = self.skipCount
            query.includeKey("author")
            query.whereKey("roomName", equalTo: self.roomName)
            messageRef.getMessages(query: query) { (queriedMessages) in
                self.messageList.insert(contentsOf: queriedMessages, at: 0)
                self.messagesCollectionView.reloadDataAndKeepOffset()
                self.skipCount += 20
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.register(TextMessageCell.self, forCellWithReuseIdentifier: "cell")
        messagesCollectionView.register(MediaMessageCell.self, forCellWithReuseIdentifier: "cell")
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        messagesCollectionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError("The collectionView is not a MessagesCollectionView.")
        }

        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("MessagesDataSource has not been set.")
        }

        if isSectionReservedForTypingIndicator(indexPath.section) {
            return messagesDataSource.typingIndicator(at: indexPath, in: messagesCollectionView)
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        switch message.kind {
        case .text, .attributedText, .emoji:
            let cell = messagesCollectionView.dequeueReusableCell(TextMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        case .photo, .video:
            let cell = messagesCollectionView.dequeueReusableCell(MediaMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            if message.isCaptionRequest {
                cell.imageView.backgroundColor = UIColor.clear
                cell.imageView.layer.cornerRadius = 15.0
                cell.imageView.layer.masksToBounds = true
                cell.imageView.layer.borderWidth = 5.0
                cell.imageView.layer.borderColor = UIColor.primaryColor.cgColor
            } else {
                cell.imageView.layer.borderWidth = 0.0
                cell.imageView.layer.borderColor = UIColor.clear.cgColor
            }
            return cell
        case .location:
            let cell = messagesCollectionView.dequeueReusableCell(LocationMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        case .audio:
            let cell = messagesCollectionView.dequeueReusableCell(AudioMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        case .contact:
            let cell = messagesCollectionView.dequeueReusableCell(ContactMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        case .custom:
            return messagesDataSource.customCell(for: message, at: indexPath, in: messagesCollectionView)
        }
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.primaryColor.withAlphaComponent(0.3),
            for: .highlighted
        )
    }
    
    // MARK: - Helpers
    
    func insertMessage(_ message: MockMessage) {
        print("got a new message")
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            //if self?.isLastSectionVisible() == true {
            self?.messagesCollectionView.scrollToBottom(animated: true)
            //}
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messageList.count else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section + 1].user
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section - 1].user
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        return SampleData.shared.currentSender
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) {
            return NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
}

// MARK: - MessageCellDelegate

extension ChatVC: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let messageType = self.messageForItem(at: indexPath, in: messagesCollectionView)
            print(messageType.isCaptionRequest)
            
            if messageType.isCaptionRequest {
                if messageType.sender.senderId != PFUser.current()!.objectId! {
                    // CONTINUE... messageList does not have the new message in ChatVC
                    if let index = self.messageList.firstIndex(where: { $0.messageId == messageType.messageId }) {
                        Post().getPostWithObjectId(id: self.messageList[index].messageId) { (post) in
                            self.messagesVcRef.showCaptionRequest(captionRequest: post)
                        }
                    }
                } else {
                    print("User tapped his or her own caption request")
                }
            } else {
                if let cell = cell as? MediaMessageCell {
                    if let image = cell.imageView.image {
                        self.selectedImage = cell.imageView.image!
                        self.presentImageGallery(GalleryViewController(startIndex: 0, itemsDataSource: self))
                    }
                }
                
            }
        }
        print("Message tapped")
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }

    func didStartAudio(in cell: AudioMessageCell) {
        print("Did start playing audio sound")
    }

    func didPauseAudio(in cell: AudioMessageCell) {
        print("Did pause audio sound")
    }

    func didStopAudio(in cell: AudioMessageCell) {
        print("Did stop audio sound")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate

extension ChatVC: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }

    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }

    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }

}

// MARK: - MessageInputBarDelegate

extension ChatVC: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {

        // Here we can parse for which substrings were autocompleted
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }
        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "Aa"
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    public func insertImageMessage(_ data: [Any], senderId: String, displayName: String, isCaptionRequest: Bool) {
        for component in data {
            let user = MockUser(senderId: senderId, displayName: displayName)
            if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date(), isCaptionRequest: isCaptionRequest)
                print("Inserting image message")
                insertMessage(message)
            }
        }
    }
    
    public func insertReceivedMessages(_ data: [Any]) {
        for component in data {
            let user = MockUser(senderId: externalUser.objectId, displayName: externalUser.username!)
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                print("Inserting this string:", str)
                insertMessage(message)
            } else if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date(), isCaptionRequest: false)
                print("Inserting message")
                insertMessage(message)
            }
        }
    }

    public func insertMessages(_ data: [Any]) {
        for component in data {
            let user = SampleData.shared.currentSender
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                chatManager.sendMessageText(str)
                insertMessage(message)
            } else if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date(), isCaptionRequest: false)
                chatManager.sendMessageImage(img)
                insertMessage(message)
            }
        }
    }
}

extension ChatVC: GalleryItemsDataSource {
    func itemCount() -> Int {
        return 1
    }

    func provideGalleryItem(_ index: Int) -> GalleryItem {
        var galleryItem: GalleryItem!
        galleryItem = GalleryItem.image { $0(self.selectedImage) }
        return galleryItem
    }
}
