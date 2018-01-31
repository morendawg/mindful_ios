//
//  AnimatedGradientView.swift
//  mindful
//
//  Created by Daniel Moreno on 11/20/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Foundation
import UIKit

class AnimatedGradientView : UIView {
    let gradient = CAGradientLayer()
    var gradientSet = [[CGColor]]()
    var currentGradient: Int = 0
    var minGradient: Int = 0
    var maxGradient: Int = 2
    
    let positiveOne = UIColor(red: 50/255, green: 48/255, blue: 90/255, alpha: 1).cgColor
    let positiveTwo = UIColor(red: 70/255, green: 200/255, blue: 150/255, alpha: 1).cgColor
    let positiveThree = UIColor(red: 100/255, green: 240/255, blue: 100/255, alpha: 1).cgColor
    
    let neutralOne = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).cgColor
    let neutralTwo = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).cgColor
    let neutralThree = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1).cgColor
    
    let negativeOne = UIColor(red: 48/255, green: 62/255, blue: 80/255, alpha: 1).cgColor
    let negativeTwo = UIColor(red: 244/255, green: 88/255, blue: 53/255, alpha: 1).cgColor
    let negativeThree = UIColor(red: 196/255, green: 70/255, blue: 60/255, alpha: 1).cgColor
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientSet.append([positiveOne, positiveTwo])
        gradientSet.append([positiveTwo, positiveThree])
        gradientSet.append([positiveThree, positiveOne])
        
        gradientSet.append([neutralOne, neutralTwo])
        gradientSet.append([neutralTwo, neutralThree])
        gradientSet.append([neutralThree, neutralOne])
        
        gradientSet.append([negativeOne, negativeTwo])
        gradientSet.append([negativeTwo, negativeThree])
        gradientSet.append([negativeThree, negativeOne])
        
        
        gradient.frame = self.bounds
        gradient.colors = gradientSet[currentGradient]
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        self.layer.addSublayer(gradient)
        
        animateGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gradientSet.append([positiveOne, positiveTwo])
        gradientSet.append([positiveTwo, positiveThree])
        gradientSet.append([positiveThree, positiveOne])
        
        gradientSet.append([neutralOne, neutralTwo])
        gradientSet.append([neutralTwo, neutralThree])
        gradientSet.append([neutralThree, neutralOne])
        
        gradientSet.append([negativeOne, negativeTwo])
        gradientSet.append([negativeTwo, negativeThree])
        gradientSet.append([negativeThree, negativeOne])
        
        
        
        gradient.frame = self.bounds
        gradient.colors = gradientSet[currentGradient]
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        self.layer.addSublayer(gradient)
        
        animateGradient()
        
    }


    func animateGradient() {
        if currentGradient < maxGradient - 1 {
            currentGradient += 1
        } else {
            currentGradient = minGradient
        }
        
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = 5.0
        gradientChangeAnimation.toValue = gradientSet[currentGradient]
        gradientChangeAnimation.fillMode = kCAFillModeForwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }
    
    func changeSentimentGradient(sentiment : String) {
        switch sentiment {
        case "positive":
            minGradient = 0
            maxGradient = 2
            currentGradient = 0
            gradient.removeAllAnimations()
            animateGradient()
        case "neutral":
            minGradient = 3
            maxGradient = 5
            currentGradient = 3
            gradient.removeAllAnimations()
            animateGradient()
        case "negative":
            minGradient = 6
            maxGradient = 8
            currentGradient = 6
            gradient.removeAllAnimations()
            animateGradient()
        default:
            minGradient = 0
            maxGradient = 2
             currentGradient = 0
            gradient.removeAllAnimations()
            animateGradient()
        }
    }
    
}
