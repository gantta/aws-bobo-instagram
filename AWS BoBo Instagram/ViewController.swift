//
//  ViewController.swift
//  AWS BoBo Instagram
//
//  Created by Adam Gantt on 9/2/16.
//  Copyright © 2016 Adam Gantt. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, AWSIdentityProviderManager {
    
    @IBOutlet weak var messageLabel: UILabel!
    var googleIdToken = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //messageLabel.text = "A very basic social app where users can share photos. Built on AWS services with S3, DynamoDB, and Lambda"
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {

        
        if (error == nil) {
            googleIdToken = user.authentication.idToken
            
            /* @todo: Add an activity refresher during the Cognito signin process 
             */
            signInToCognito(user)
            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func logins() -> AWSTask {
        let result = NSDictionary(dictionary: [AWSIdentityProviderGoogle: googleIdToken])
        
        return AWSTask(result: result)
    }
    
    func signInToCognito(user: GIDGoogleUser!) {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:c1842f3f-808f-4e40-9bb2-260afa44b18e", identityProviderManager: self)
        
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        credentialsProvider.getIdentityId().continueWithBlock {(task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print("Kabloomy: Cognito signin error 1")
                print(task.error)
                return nil
            }
            
            let syncClient = AWSCognito.defaultCognito()
            let dataset = syncClient.openOrCreateDataset("instagramDataSet")
            
            dataset.setString(user.profile.email, forKey: "email")
            dataset.setString(user.profile.name, forKey: "name")
            
            let result = dataset.synchronize()
            
            result.continueWithBlock( { (task:AWSTask) -> AnyObject? in
                if task.error != nil {
                    print("Kabloomy: Cognito signin error 2")
                    print(task.error)
                } else {
                    print("Cognito signin successful")
                    //print(task.result)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.performSegueWithIdentifier("login", sender: self)
                    })
                    
                }
                
                return nil
            })
            
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let nav = self.navigationController?.navigationBar
        
        nav?.barStyle = UIBarStyle.Black
        nav?.tintColor = UIColor.yellowColor()
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .ScaleAspectFit
        
        let image = UIImage(named: "Instagram_logo_black.png")
        imageView.image = image
        
        navigationItem.titleView = imageView
    }


}

