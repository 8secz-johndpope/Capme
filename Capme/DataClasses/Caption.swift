//
//  Caption.swift
//  Capme
//
//  Created by Gabe Wilson on 12/22/19.
//  Copyright © 2019 Gabe Wilson. All rights reserved.
//


import Foundation

class Caption: Codable {
    
    // New Caption Creator
    var userId = String()
    var username = String()
    var captionText = String()
    var creationDate = String()
    var favoritesCount = Int()
    var isCurrentUserFavorite = Bool()
    
    func convertToJSON() -> String {
        print(self.convertToString!)
        return self.convertToString!
    }
}
