//
//  User.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 18/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import CoreLocation

enum AccountType: Int{
    case passenger
    case driver
}

struct User {
    let fullname: String
    let email: String
    var accountType: AccountType!
    var location: CLLocation?
    let uid: String

    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        
        if let index = dictionary["accountType"] as? Int {
            self.accountType = AccountType(rawValue: index)
        }
    }
}
