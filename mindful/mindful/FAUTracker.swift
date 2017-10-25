//
//  FAUTracker.swift
//  mindful
//
//  Created by Daniel Moreno on 10/24/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Foundation
import Vision


class FaceActionUnitTracker : NSObject {
    
}

extension FaceActionUnitTracker {
    func setNeutralLandmark(){}
    func calculateMostLikelyExpression(landmarks:VNFaceLandmarks2D)->String{
        print(landmarks.allPoints?.normalizedPoints.count)
//        print(distance((landmarks.nose?.normalizedPoints[0])!, (landmarks.rightEyebrow?.normalizedPoints[0])!))
        return "FACE EXP"
    }
    
}

extension FaceActionUnitTracker {
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
}
