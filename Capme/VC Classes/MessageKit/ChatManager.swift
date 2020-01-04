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
        
        /*Room.query()?.whereKey("name", equalTo: room).getFirstObjectInBackground()
            .continueOnSuccessWith(block: { task -> Any? in
            
        })*/
    }

    func disconnectFromChatRoom() {
        print("Success: Disconnected from the chat room")
        liveQueryClient.unsubscribe(messagesQuery, handler: subscription!)
    }

    func sendMessage(_ msg: String) {
        let message = Message()
        message.author = PFUser.current()
        message.authorName = message.author?.username
        message.message = msg
        message.room = currentChatRoom
        message.roomName = currentChatRoom?.name
        message.saveInBackground()
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
            print("New Message:", message.message!)
            DispatchQueue.main.async {
                self.chatRef.insertReceivedMessages([message.message!])
            }
        }
    }

    fileprivate func printMessage(_ message: Message) {
        let createdAt = message.createdAt ?? Date()
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
            chatManager.sendMessage(inputString)
        } else {
            chatManager.connectToChatRoom(inputString)
        }
    }
}

