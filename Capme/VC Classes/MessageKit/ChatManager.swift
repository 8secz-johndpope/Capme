//
//  ChatManager.swift
//  Capme
//
//  Created by Gabe Wilson on 1/2/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery



let chatManager = ChatRoomManager()
let inputManager = InputManager(chatManager: chatManager)

let liveQueryClient = ParseLiveQuery.Client(server: "wss://capme.back4app.io")

class ChatRoomManager {
    fileprivate var currentChatRoom: Room?
    fileprivate var subscription: Subscription<Message>?

    var chatRef = ChatVC()
    var connected: Bool { return currentChatRoom != nil }
    var messagesQuery: PFQuery<Message> {
        return (Message.query()?
            .whereKey("roomName", equalTo: chatRef.roomName)
            .order(byAscending: "createdAt")) as! PFQuery<Message>
    }

    func connectToChatRoom(_ room: String) {
        if connected {
            disconnectFromChatRoom()
        }
      
        self.currentChatRoom?.name = room
        print("Inside Chat Room", room)
        Room.query()?.whereKey("name", equalTo: room).getFirstObjectInBackground(block: { (roomObject, error) in
            if roomObject == nil {
                let room = Room()
                room.name = self.chatRef.roomName
                room.saveInBackground { (success, error) in
                    if error == nil {
                        print("Success: Saved the new chat room")
                    }
                }
            } else {
                let queriedRoom = Room()
                queriedRoom.name = (roomObject!["name"] as! String)
                self.currentChatRoom = queriedRoom
                print("Connected to room \(self.currentChatRoom?.name ?? "null")")
                self.printPriorMessages()
                self.subscribeToUpdates()
            }
        })
    }

    func disconnectFromChatRoom() {
        print("Success: Disconnected from the chat room")
        liveQueryClient.unsubscribe(messagesQuery, handler: subscription!)
    }
    
    func sendMessageImage(_ img: UIImage) {
        let message = Message()
        message.author = PFUser.current()
        message.authorName = message.author?.username
        message.image = PFFileObject(name: "image", data: img.jpegData(compressionQuality: 1.0)!)
        message.room = currentChatRoom
        message.roomName = currentChatRoom?.name
        message.isViewed = false
        
        let sentMessagePreview = MessagePreview()
        sentMessagePreview.roomName = currentChatRoom?.name
        sentMessagePreview.previewText = "Sent an image"
        sentMessagePreview.objectId = message.objectId
        sentMessagePreview.externalUser = self.chatRef.externalUser
        sentMessagePreview.date = message.createdAt
        sentMessagePreview.itemType = "message"
        sentMessagePreview.sender = PFUser.current()!.objectId!
        sentMessagePreview.isViewed = true
        DataModel.sentMessagePreview = sentMessagePreview
        
        message.saveInBackground { (success, error) in
            if error == nil {
                PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["recipientIds": [self.chatRef.externalUser.objectId], "title": message.authorName!, "message": "Sent you an image", "identifier" : "newMessage", "objectId" : message.objectId!]) {
                    (response, error) in
                    if error == nil {
                        print("Success: Pushed the notification for newMessage")
                    } else {
                        print(error!.localizedDescription, "Cloud Code Push Error")
                    }
                }
            }
        }
    }
    

    func sendMessageText(_ msg: String) {
        
        let message = Message()
        message.author = PFUser.current()
        message.authorName = message.author?.username
        message.message = msg
        message.room = currentChatRoom
        message.roomName = currentChatRoom?.name
        message.isViewed = false
        
        let sentMessagePreview = MessagePreview()
        sentMessagePreview.roomName = currentChatRoom?.name
        sentMessagePreview.previewText = msg
        sentMessagePreview.objectId = message.objectId
        sentMessagePreview.externalUser = self.chatRef.externalUser
        sentMessagePreview.date = message.createdAt
        sentMessagePreview.itemType = "message"
        sentMessagePreview.sender = PFUser.current()!.objectId!
        sentMessagePreview.isViewed = true
        DataModel.sentMessagePreview = sentMessagePreview
        
        message.saveInBackground { (success, error) in
            if error == nil {
                PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["recipientIds": [self.chatRef.externalUser.objectId], "title": message.authorName!, "message": msg, "identifier" : "newMessage", "objectId" : message.objectId!]) {
                    (response, error) in
                    if error == nil {
                        print("Success: Pushed the notification for newMessage")
                    } else {
                        print(error!.localizedDescription, "Cloud Code Push Error")
                    }
                }
            }
        }
    }

    func printPriorMessages() {
        messagesQuery.findObjectsInBackground()
            .continueOnSuccessWith(block: { task -> Any? in
            (task.result as? [Message])?.forEach(self.printMessage)
            return nil
        })
    }
  
    func subscribeToUpdates() {
        subscription = liveQueryClient
            .subscribe(messagesQuery)
            .handle(Event.created) { _, message in
                self.printNewMessage(message)
        }
    }
    
    fileprivate func printNewMessage(_ message: Message) {
        if message.authorName != PFUser.current()!.username {
            if let messageText = message.message {
                if messageText.count > 0 {
                    print("New Message:", message.message!)
                    DispatchQueue.main.async {
                        self.chatRef.insertReceivedMessages([messageText])
                    }
                }
            } else {
                
            }
            
        }
    }

    fileprivate func printMessage(_ message: Message) {
        let createdAt = message.createdAt ?? Date()
        if let image = message.image {
            image.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                if error == nil  {
                    if let finalimage = UIImage(data: imageData!) {
                        self.chatRef.insertReceivedMessages([finalimage])
                    }
                }
            }
        }
        print("\(createdAt) \(message.authorName ?? "unknown"): \(message.message ?? "")")
    }
}

class InputManager {
    let stdinChannel = DispatchIO(__type: DispatchIO.StreamType.stream.rawValue, fd: STDIN_FILENO, queue: DispatchQueue.main) { _ in }
    let chatManager: ChatRoomManager

    init(chatManager: ChatRoomManager) {
        self.chatManager = chatManager

        stdinChannel.setLimit(lowWater: 1)
        stdinChannel.read(offset: 0, length: Int.max, queue: DispatchQueue.main, ioHandler: handleInput)
    }

    fileprivate func handleInput(_ done: Bool, data: DispatchData?, error: Int32) {
        guard
            let inputString = data?.withUnsafeBytes(body: {(b: UnsafePointer<UInt8>) -> String? in
                return String(cString: b)
            })?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                    return
        }

        if chatManager.connected {
            chatManager.sendMessageText(inputString)
        } else {
            chatManager.connectToChatRoom(inputString)
        }
    }
}

