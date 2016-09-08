//
//  UserViewController.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/4/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import Foundation

class UserViewController: UITableViewController {
    
    let databaseService = DatabaseService()
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    var users = [User]()
    var isFollowing = ["": false]
    
    var refresher: UIRefreshControl!
    
    func refresh() {
        let identityId = credentialsProvider.identityId! as String
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let scan = AWSDynamoDBScanExpression()
        
        mapper.scan(User.self, expression: scan).continueWithBlock { (dynamoTask:AWSTask) -> AnyObject? in
            if (dynamoTask.error != nil) {
                print(dynamoTask.error)
            }
            
            if (dynamoTask.exception != nil) {
                print(dynamoTask.exception)
            }
            
            if (dynamoTask.result != nil) {
                self.users.removeAll(keepCapacity: true)
                
                let dynamoResults = dynamoTask.result as! AWSDynamoDBPaginatedOutput
                
                for user in dynamoResults.items as! [User] {
                    
                    if user.id != identityId {
                        self.users.append(user)
                    }
                }
            }
            
            self.databaseService.findFollowings(identityId, map: mapper).continueWithBlock({ (task:AWSTask) -> AnyObject? in

                if (task.error != nil) {
                    print(task.error)
                }
                
                if (task.exception != nil) {
                    print(task.exception)
                }
                
                if (task.result != nil) {
                    for item in task.result as! [Follower] {
                        self.isFollowing[item.following] = true
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    self.refresher.endRefreshing()
                })
                
                return nil
            })
            
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresher = UIRefreshControl()
        
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        
        refresher.addTarget(self, action: #selector(UserViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.addSubview(refresher)
        
        refresh()
        
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = users[indexPath.row].name
        
        let followedObjectId = users[indexPath.row].id
        
        if isFollowing[followedObjectId] == true {
            
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            
        }
        
        return cell
    }
    
    func addFollowing(following: String) {
        let identityId = credentialsProvider.identityId! as String
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let add = Follower()
        
        add.id = NSUUID().UUIDString
        add.follower = identityId
        add.following = following
        
        mapper.save(add)
    }
    
    func removeFollowing(following: String) {
        let identityId = credentialsProvider.identityId! as String
        
        let map = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        self.databaseService.findFollower(identityId, following: following, map: map).continueWithBlock({ (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil) {
                print(task.exception)
            }
            
            if (task.result != nil) {
                let followings = task.result as! [Follower]
                
                for following in followings {
                    map.remove(following)
                }
            }
            
            return nil
        })
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return users.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        let followedObjectId = users[indexPath.row].id
        
        if isFollowing[followedObjectId] == nil || isFollowing[followedObjectId] == false {
            
            isFollowing[followedObjectId] = true
            
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            
            addFollowing(users[indexPath.row].id)
        } else {
            
            isFollowing[followedObjectId] = false
            
            cell.accessoryType = UITableViewCellAccessoryType.None
            
            removeFollowing(users[indexPath.row].id)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let nav = self.navigationController?.navigationBar
        
        nav?.barStyle = UIBarStyle.Default
        //nav?.tintColor = UIColor.whiteColor()
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .ScaleAspectFit
        
        let image = UIImage(named: "Instagram_logo_black.png")
        imageView.image = image
        
        navigationItem.titleView = imageView
    }


}
