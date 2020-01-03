//
//  Room.swift
//  Capme
//
//  Created by Gabe Wilson on 1/2/20.
//  Copyright © 2020 Gabe Wilson. All rights reserved.
//

import Foundation
import Parse

class Room: PFObject, PFSubclassing {
    @NSManaged var name: String?

    static func parseClassName() -> String {
        return "Room"
    }
}
