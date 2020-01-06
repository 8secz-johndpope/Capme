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
    
    var roomName: String!
    var username: String!
    var previewText: String!
    var profilePic: UIImage!
    var date: String!
    var viewed: Bool!
    var itemType: String! // message || captionRequest
    var externalUser: User!
    
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
        return User()
    }
    
}
