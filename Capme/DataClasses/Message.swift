//
//  Message.swift
//  Capme
//
//  Created by Gabe Wilson on 1/2/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import Parse

class Message: PFObject, PFSubclassing {
    @NSManaged var author: PFUser?
    @NSManaged var authorName: String?
    @NSManaged var message: String?
    @NSManaged var room: PFObject?
    @NSManaged var roomName: String?
    @NSManaged var isViewed: NSNumber?
    var date: Date?

    class func parseClassName() -> String {
        return "Message"
    }
    
    func convertMessageToPreview() -> MessagePreview {
        let messagePreview = MessagePreview()
        messagePreview.roomName = self.roomName
        messagePreview.previewText = self.message
        messagePreview.objectId = self.objectId
        messagePreview.externalUser = messagePreview.getExternalUserFromRoomName(roomName: messagePreview.roomName)
        messagePreview.date = self.date
        messagePreview.isViewed = self.isViewed as? Bool
        messagePreview.itemType = "message"
        return messagePreview
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
                    let messageText = object["message"] as! String
                    let id = object.objectId!
                    let date = object.createdAt!
                    let user = MockUser(senderId: (object["author"] as! PFUser).objectId!, displayName: object["authorName"] as! String)
                    let message = MockMessage(text: messageText, user: user, messageId: id, date: date)
                    messages.append(message)
                    if object == objects?.last {
                        completion(messages)
                    }
                }
            }
        }
    }
}
