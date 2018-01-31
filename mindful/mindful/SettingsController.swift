//
//  SettingsController.swift
//  mindful
//
//  Created by Karinna Loo on 1/30/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import Foundation
import UIKit

class SettingsController : UIViewController {
    private let settingsLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        settingsLabel.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 340)
        settingsLabel.textAlignment = NSTextAlignment.center
        settingsLabel.numberOfLines = 0;
        settingsLabel.textColor =  UIColor.black
        settingsLabel.text="Usage Streak: 3"
        self.view.addSubview(settingsLabel)
        
        print("hello")
    }
    
    func configureSettings() throws {
        
    }
}
