//
//  SettingsController.swift
//  mindful
//
//  Created by Karinna Loo on 1/30/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class SettingsController : UIViewController {
    private let streakLabel = UILabel()
    private let backButton = UIButton()
    private let logoutButton = UIButton()

    private var animatedGradientView : AnimatedGradientView?
    
    func setUpButtons() {
        backButton.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        backButton.center.y = (1/15)*self.view.bounds.height
        backButton.center.x = (1/10)*self.view.bounds.width
        backButton.setImage(#imageLiteral(resourceName: "Back Arrow Icon"), for: UIControlState.normal)
        backButton.setTitle(" Back", for: .normal)
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.addTarget(self,  action: #selector(self.backAction(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(backButton)
        
        logoutButton.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        logoutButton.center.y = (1/15)*self.view.bounds.height
        logoutButton.center.x = (9/10)*self.view.bounds.width
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(UIColor.white, for: .normal)
        logoutButton.addTarget(self,  action: #selector(self.logoutAction(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(logoutButton)
        
        streakLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        streakLabel.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 340)
        streakLabel.textAlignment = NSTextAlignment.center
        streakLabel.numberOfLines = 0;
        streakLabel.textColor =  UIColor.white
        streakLabel.text="Usage Streak: 3"
        self.view.addSubview(streakLabel)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        var mainAppController: RecordViewController? = nil
        mainAppController = RecordViewController()
        self.show(mainAppController!, sender: nil)
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            print ("Error: clicked signed out")
            try firebaseAuth.signOut()
            var mainViewController: MainViewController? = nil
            mainViewController = MainViewController()
            self.show(mainViewController!, sender: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animatedGradientView = AnimatedGradientView(frame: self.view.bounds)
        self.view.addSubview(animatedGradientView!)
        
        setUpButtons()
    }
    
    func configureSettings() throws {
        
    }
}
