//
//  User.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/4/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import Foundation

class User : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var id  : String = ""
    var name   : String = ""
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
        super.init()
        id = dictionaryValue["id"] as! String
        name = dictionaryValue["name"] as! String
    }
    
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "InstagramUsers"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
