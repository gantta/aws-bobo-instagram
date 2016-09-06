//
//  PostViewController.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/5/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import Foundation

class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    
    var activityIndicator = UIActivityIndicatorView()
    
    let S3BucketName = "bobo-instagram-clone" //this needs to be moved to a settings file
    
    @IBOutlet var imagePost: UIImageView!
    
    @IBOutlet var setMessage: UITextField!
    
    @IBAction func chooseAnImage(sender: AnyObject) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.dismissViewControllerAnimated(true, completion:nil)
        imagePost.image = image
    }
    
    @IBAction func postAnImage(sender: AnyObject) {
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        let netConfig = AWSNetworkingConfiguration()
        netConfig.timeoutIntervalForRequest = 180
        
        let S3UploadKeyName = NSUUID().UUIDString + ".png"
        var location = ""
        
        if let data = UIImagePNGRepresentation(self.imagePost.image!) {
            location = databaseService.getDocumentsDirectory().stringByAppendingPathComponent(S3UploadKeyName)
            data.writeToFile(location, atomically: true)
        } else {
            self.displayAlert("Error", message: "Could not process selected image. UIImagePNGRepresentation failed.")
            return
        }
        
        let uploadFileUrl = NSURL.fileURLWithPath(location)
        
        
        
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: NSProgress) in
            print("Progress is: %f", progress.fractionCompleted)
        }
        
        let completionHandler = { (task, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                
                if error != nil {
                    print(error)
                    self.displayAlert("Could not post image", message: "Please try again later")
                } else {
                    self.savePostToDatabase(self.S3BucketName, key: S3UploadKeyName)
                }
            })
            } as AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        
        transferUtility.uploadFile(uploadFileUrl, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHander: completionHandler).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                print("Error: %@", error.localizedDescription);
                //self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                print("Exception: %@", exception.description);
                //self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                print("Upload Started")
            }
            
            return nil;
        }
 
        
    }
    
    func savePostToDatabase(bucket: String, key: String) {
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let post = Post()
        
        post.id = NSUUID().UUIDString
        post.bucket = bucket
        post.filename = key
        post.userId = identityId
        
        if (!self.setMessage.text!.isEmpty) {
            post.message = self.setMessage.text!
        } else {
            post.message = nil //we cannot save a message that is an empty string
        }
        
        mapper.save(post).continueWithBlock { (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil) {
                print(task.exception)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.displayAlert("Saved", message: "Your post has been saved")
            })
            
            return nil
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        })))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
