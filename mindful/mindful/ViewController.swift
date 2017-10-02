//
//  ViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let cameraController = CameraController()
    
    @IBOutlet fileprivate var captureButton: UIButton!
    
    ///Displays a preview of the video output generated by the device's cameras.
    @IBOutlet fileprivate var capturePreviewView: UIView!
    
    
    override var prefersStatusBarHidden: Bool { return true }
    
    @IBAction func startRecording(_ sender: UIButton) {
        print("Start Recording")
        captureButton.layer.borderColor = UIColor.red.cgColor
        captureButton.layer.borderWidth = 8
        try? self.cameraController.beginRecording()
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        print("Stop Recording")
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        try? self.cameraController.stopRecording()
    }
}

extension ViewController {
    override func viewDidLoad() {
        func configureCameraController() {
            cameraController.prepare {(error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.capturePreviewView)
            }
        }
        do {
            try self.cameraController.switchCameras()
        }
        catch {
            print(error)
        }
        func styleCaptureButton() {
            captureButton.layer.borderColor = UIColor.black.cgColor
            captureButton.layer.borderWidth = 2
            captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
        }
        
        styleCaptureButton()
        configureCameraController()
    }
}
