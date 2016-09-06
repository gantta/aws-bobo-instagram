//
//  FeedViewController.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/5/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import Foundation

class FeedViewController: UITableViewController {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
    
    var imageFiles = [Post]()
    
    func refresh() {
        
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        self.imageFiles.removeAll(keepCapacity: true)
        
        databaseService.findFollowings(identityId, map: mapper).continueWithBlock({ (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil) {
                print(task.exception)
            }
            
            if (task.result != nil) {
                for item in task.result as! [Follower] {
                    let result = self.getPosts(item.following, map: mapper)
                    
                    result.continueWithBlock({ (task:AWSTask) -> AnyObject? in
                        let posts = task.result as! [Post]
                        
                        for post in posts {
                            self.imageFiles.append(post)
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData()
                        })
                        
                        return nil
                    })
                }
            }
            
            return nil
        })
    }
    
    func getPosts(userId: String, map: AWSDynamoDBObjectMapper) -> AWSTask {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "userId = :userId"
        scan.expressionAttributeValues = [":userId":userId]
        
        return map.scan(Post.self, expression: scan).continueWithBlock { (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil){
                print(task.exception)
            }
            
            if (task.result != nil) {
                let result = task.result as! AWSDynamoDBPaginatedOutput
                return result.items as! [Post]
            }
            
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
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
        
        return imageFiles.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = imageFiles[indexPath.row]
        let myCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! cell
        
        let currentLocation = self.databaseService.getDocumentsDirectory().stringByAppendingPathComponent(post.filename)
        let manager = NSFileManager.defaultManager()
        
        if (manager.fileExistsAtPath(currentLocation)) {
            myCell.postedImage.image = UIImage(contentsOfFile: currentLocation)
        } else {
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: NSProgress) in
                print("Download Progress is: %f", progress.fractionCompleted)
            }
            
            self.completionHandler = { (task, location, data, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    myCell.postedImage.image = UIImage(data: data!)
                    
                    /* @todo: Sometimes the image resizer fails to work properly.
                     * Add some additional handling to check if the thumbnail failed
                     * then try to pull the original image from the source bucket.
                     */
                    
                    if (myCell.postedImage.image != nil) {

                        if let imagedata = UIImagePNGRepresentation(myCell.postedImage.image!) {
                            let location = self.databaseService.getDocumentsDirectory().stringByAppendingPathComponent(post.filename)
                            imagedata.writeToFile(location, atomically: true)
                        }
                        
                    }
                })
            }
            
            transferUtility.downloadDataFromBucket(post.bucket + "-resized", key: "resized-" + post.filename, expression: expression, completionHander: completionHandler);
        }
        
        
        myCell.message.text = post.message != nil ? post.message : ""
        
        return myCell
    }
}
