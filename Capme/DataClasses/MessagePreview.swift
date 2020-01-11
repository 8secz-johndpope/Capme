//
//  MessagePreview.swift
//  Capme
//
//  Created by Gabe Wilson on 1/5/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class MessagePreview {
    
    var sender: String!
    var objectId: String!
    var roomName: String!
    var username: String!
    var previewText: String!
    var profilePic: UIImage!
    var date: Date!
    var externalUser: User!
    var isViewed: Bool!
    
    var itemType: String! // message || captionRequest
    
    func getExternalUserFromRoomName(roomName: String) -> User {
        let userIds = roomName.components(separatedBy: "+")
        // Get the external user
        var externalUserId = ""
        if userIds[0] == PFUser.current()?.objectId {
            externalUserId = userIds[1]
        } else if userIds[1] == PFUser.current()?.objectId {
            externalUserId = userIds[0]
        }
        if let i = DataModel.friends.firstIndex(where: { $0.objectId == externalUserId }) {
            return DataModel.friends[i]
        }
        print("Getting data model friends")
        print(DataModel.friends[0].username)
        return User()
    }
    
    func getDateFromString(stringDate: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        var dateObject = dateFormatter.date(from: stringDate)
        if dateObject == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateObject = dateFormatter.date(from: stringDate)
        }
        return dateObject!
    }
    
    func messageBecameViewed() {
        var className = ""
        if self.itemType == "message" {
            className = "Message"
        } else if self.itemType == "captionRequest" {
            className = "Post"
        }
        let query = PFQuery(className: className)
        query.getObjectInBackground(withId: objectId) { (object, error) in
            if error == nil {
                if let object = object {
                    object["isViewed"] = true
                }
                object?.saveInBackground(block: { (success, error) in
                    if error == nil {
                        print("Success: Updated the \(className) to viewed")
                    }
                })
            }
        }
    }
    
    func sortByCreatedAt(messagePreviewsToSort: [MessagePreview]) -> [MessagePreview] {
        return messagePreviewsToSort.sorted(by: { $0.date > $1.date })
    }
    
}
