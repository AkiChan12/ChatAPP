//
//  Message.swift
//  UdemyApp17_library
//
//  Created by 清水正明 on 2020/07/28.
//  Copyright © 2020 Masaaki Shimizu. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseFirestore

class Message123 {
    let name :String
    let message:String
    let createdAt: Timestamp
    let uid :String
    
    var partnerUser: User?
    
    init(dic:[String:Any]) {
        self.name = dic["name"] as? String ?? ""
        self.message = dic["message"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.uid = dic["uid"] as? String ?? ""
    }
}
