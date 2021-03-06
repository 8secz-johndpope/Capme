//
//  Message.swift
//  Capme
//
//  Created by Gabe Wilson on 1/2/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import Parse
import MessageKit

class Message: PFObject, PFSubclassing {
    @NSManaged var author: PFUser?
    @NSManaged var authorName: String?
    @NSManaged var message: String?
    @NSManaged var room: PFObject?
    @NSManaged var roomName: String?
    @NSManaged var isViewed: NSNumber?
    @NSManaged var image: PFFileObject?
    var date: Date?

    class func parseClassName() -> String {
        return "Message"
    }
    
    func sortByCreatedAt(messagesToSort: [MockMessage]) -> [MockMessage] {
        return messagesToSort.sorted(by: { $0.sentDate < $1.sentDate })
    }
    
    func convertMessageToPreview() -> MessagePreview {
        let messagePreview = MessagePreview()
        messagePreview.roomName = self.roomName
        messagePreview.previewText = self.message
        messagePreview.objectId = self.objectId
        if let roomName = messagePreview.roomName {
            messagePreview.externalUser = messagePreview.getExternalUserFromRoomName(roomName: roomName)
        } else {
            if let i = DataModel.friends.firstIndex(where: { $0.username == self.authorName }) {
                messagePreview.externalUser = DataModel.friends[i]
            }
        }
        messagePreview.date = self.date
        messagePreview.isViewed = self.isViewed as? Bool
        messagePreview.itemType = "message"
        return messagePreview
    }
    
    func getCaptionRequestFromId(query: PFQuery<PFObject>, completion: @escaping (_ result: Message)->()) {
        query.getFirstObjectInBackground { (object, error) in
            if error == nil {
                let message = Message()
                if let error = error {
                    print("Error: " + error.localizedDescription)
                    completion(message)
                } else {
                    if let object = object {
                        let post = object["post"] as! PFObject
                        message.date = object.createdAt
                        message.objectId = object.objectId
                        message.authorName = object["authorName"] as? String
                        message.author = object["author"] as? PFUser
                        message.message = post["description"] as? String
                        message.isViewed = object["isViewed"] as! Bool as NSNumber
                        print("got a message!")
                        completion(message)
                    }
                }
            }
        }
    }
    
    func getMessageFromId(query: PFQuery<PFObject>, id: String, completion: @escaping (_ result: Message)->()) {
        query.getObjectInBackground(withId: id) { (object, error) in
            let message = Message()
            if let error = error {
                print("Error: " + error.localizedDescription)
                completion(message)
            } else {
                if let object = object {
                    message.date = object.createdAt
                    message.objectId = id
                    message.authorName = object["authorName"] as? String
                    message.author = object["author"] as? PFUser
                    message.message = object["message"] as? String
                    message.room = object["room"] as? PFObject
                    message.roomName = object["roomName"] as? String
                    message.isViewed = object["isViewed"] as! Bool as NSNumber
                    completion(message)
                }
            }
        }
    }
    
    func getMessages(query: PFQuery<PFObject>, completion: @escaping (_ result: [MockMessage])->()) {
        var messages = [MockMessage]()
        query.findObjectsInBackground {
            (objects:[PFObject]?, error:Error?) -> Void in
            if let error = error {
                print("Error: " + error.localizedDescription)
            } else {
                if objects?.count == 0 || objects?.count == nil {
                    print("No new objects")
                    completion(messages)
                    return
                }
                for object in objects! {
                    let id = object.objectId!
                    let date = object.createdAt!
                    if let captionRequest = object["post"] as? PFObject { // Caption Request
                        let senderId = (captionRequest["sender"] as! PFUser).objectId!
                        let user = MockUser(senderId: senderId, displayName: User().getUsernameFromFriendId(id: senderId))
                        print("GETTING THIS DISPLAY NAME")
                        if let imageFile = captionRequest["image"] as? PFFileObject {
                            imageFile.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                if error == nil  {
                                    if let finalimage = UIImage(data: imageData!) {
                                        let message = MockMessage(image: finalimage, user: user, messageId: captionRequest.objectId!, date: date, isCaptionRequest: true)
                                        messages.append(message)                                        
                                        if messages.count == objects!.count {
                                            completion(messages)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if let text = object["message"] as? String {
                            let user = MockUser(senderId: (object["author"] as! PFUser).objectId!, displayName: object["authorName"] as! String)
                            let message = MockMessage(text: text, user: user, messageId: id, date: date)
                            messages.append(message)
                            if messages.count == objects?.count {
                                completion(messages)
                            }
                        } else { // Message
                            let user = MockUser(senderId: (object["author"] as! PFUser).objectId!, displayName: object["authorName"] as! String)
                            if let imageFile = object["image"] as? PFFileObject {
                                imageFile.getDataInBackground { (imageData:Data?, error:Error?) -> Void in
                                    if error == nil  {
                                        if let finalimage = UIImage(data: imageData!) {
                                            let message = MockMessage(image: finalimage, user: user, messageId: id, date: date, isCaptionRequest: false)
                                            messages.append(message)
                                            if messages.count == objects!.count {
                                                completion(messages)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
}
