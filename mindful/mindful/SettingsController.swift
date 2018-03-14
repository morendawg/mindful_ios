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
    private let streakLabel = UILabel()
    private let backButton = UIButton()
    private var animatedGradientView : AnimatedGradientView?
    
    func setUpButtons() {
        streakLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        streakLabel.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 340)
        streakLabel.textAlignment = NSTextAlignment.center
        streakLabel.numberOfLines = 0;
        streakLabel.textColor =  UIColor.white
        streakLabel.text="Usage Streak: 3"
        self.view.addSubview(streakLabel)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromLeft
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                present(RecordViewController(), animated: false, completion: nil)
                print("right swipe")
            default:
                break
            }
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
