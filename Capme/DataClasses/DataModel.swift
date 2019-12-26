//
//  DataModel.swift
//  Capme
//
//  Created by Gabe Wilson on 12/14/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//

import Foundation
import UIKit

struct DataModel {
    
    static var profilePic = UIImage()
    
    
    /* Users Network (Profile) */
    static var users = [User]()
    static var friends = [User]()
    static var receivedRequests = [User]()
    static var sentRequests = [User]()
    
    static var requestsVC = RequestsVC()
    static var captionsVC = CaptionsVC()
    
    static var newPost = Post()
    
    static var favoritedPosts = [String: String]()
    
    
}
    
