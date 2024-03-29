//
//  AppDelegate.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        var ref: DatabaseReference!
        
        ref = Database.database().reference()

        let auth = Auth.auth()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        
        let user = auth.currentUser
        if user != nil {
            let uid = user?.uid
            let username = auth.currentUser?.email
            //ref.child("users").child(uid!).setValue(["email": username])
            
            ref.child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let streak = value?["streak"] as? Int ?? 0
                let lastEntry = value?["lastEntry"] as? String ?? "Friday, January 1, 1990"
                
                let userDataEntry = ["email": username ?? "no email",
                                     "streak": streak,
                                     "lastEntry": lastEntry] as [String : Any]
                ref.child("users").child(uid!).setValue(userDataEntry)
            }) { (error) in
                print(error.localizedDescription)
            }
           
            let homeViewController = RecordViewController()
            window!.rootViewController = homeViewController
            
        } else {
            let loginViewController = MainViewController()
            window!.rootViewController = loginViewController
        }
        
        
       
        
        window!.makeKeyAndVisible()
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

