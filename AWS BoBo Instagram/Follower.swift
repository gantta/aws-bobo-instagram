//
//  Follower.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/4/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import Foundation

class Follower : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var id  : String = ""
    var follower  : String = ""
    var following   : String = ""
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
        super.init()
        
        if dictionaryValue["id"] != nil {
            id = dictionaryValue["id"] as! String
        }
        
        if dictionaryValue["follower"] != nil {
            follower = dictionaryValue["follower"] as! String
        }
        
        if dictionaryValue["following"] != nil {
            following = dictionaryValue["following"] as! String
        }
    }
    
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Followers"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
