//
//  ViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import VisionLab


class ViewController: UIViewController, UITextFieldDelegate, FacialExpressionTrackerDelegate {
    //MARK: Properties
    private let textClassificationService = TextClassificationService()
    
    //MARK : UI
    private let nlpInput =  UITextField()
   
    private let nlpText = UILabel()
    
    private let sentimentLabel = UILabel()

    let cameraController = CameraController()
    let classificationService = ClassificationService()
    
    private let captureButton = UIButton()
    private let facialExpression = UILabel()
    
   private let capturePreviewView =  UIView()
    
    
    override var prefersStatusBarHidden: Bool { return true }
    
    //MARK: Actions

    @objc func startRecording(_ sender: UIButton) {
        print("Start Recording")
        captureButton.layer.borderColor = UIColor.red.cgColor
        captureButton.layer.borderWidth = 8
        try? self.cameraController.beginRecording()
    }
    
    @objc func stopRecording(_ sender: UIButton) {
        print("Stop Recording")
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        try? self.cameraController.stopRecording()
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        nlpText.text = nlpInput.text
        let sentiment = textClassificationService.predictSentiment(from: nlpInput.text!)
        sentimentLabel.text = sentiment
    }
    
    func setUpNLPLabels() {
        nlpInput.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        nlpInput.delegate = self
        nlpInput.center = CGPoint(x: 160, y: 100)
        nlpInput.placeholder = "Tap to Edit"
        nlpInput.textColor = UIColor.blue
        self.view.addSubview(nlpInput)
        nlpText.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        nlpText.center = CGPoint(x: 160, y: 125)
        nlpText.textAlignment = NSTextAlignment.left
        nlpText.text = "."
        nlpText.textColor = UIColor.white
        self.view.addSubview(nlpText)
        sentimentLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        sentimentLabel.center = CGPoint(x: 160, y: 150)
        sentimentLabel.textAlignment = NSTextAlignment.left
        sentimentLabel.text = "."
        sentimentLabel.textColor =  UIColor.white
        self.view.addSubview(sentimentLabel)
       
        
    }
    
    func setUpFaceExLabel () {
        facialExpression.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        facialExpression.center = CGPoint(x: 160, y: 175)
        facialExpression.textAlignment = NSTextAlignment.left
        facialExpression.text = "Facial Expression"
        facialExpression.textColor =  UIColor.white
        self.view.addSubview(facialExpression)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _height = self.view.bounds.height
        let _width = self.view.bounds.width
        func configureCameraController() {
            capturePreviewView.frame = self.view.bounds
            self.view.addSubview(capturePreviewView)
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
            let kButtonDiameter = 100
            captureButton.frame = CGRect(x: 0, y: 0, width: kButtonDiameter, height: kButtonDiameter)
            captureButton.center.x = self.view.center.x
            captureButton.center.y = (6/7)*self.view.bounds.height
            captureButton.addTarget(self,  action: #selector(self.startRecording(_:)), for: UIControlEvents.touchDown)
            captureButton.addTarget(self,  action: #selector(self.stopRecording(_:)), for: UIControlEvents.touchUpInside)
            captureButton.layer.backgroundColor = UIColor.white.cgColor
            captureButton.layer.borderColor = UIColor.black.cgColor
            captureButton.layer.borderWidth = 2
            captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
            self.view.addSubview(captureButton)
        }
        configureCameraController()
        styleCaptureButton()
        setUpNLPLabels()
        setUpFaceExLabel()
        self.cameraController.customDelegate = self
    }
    func changeFacialExpressionLabel(emotion: String?) {
        DispatchQueue.main.async(execute: {
            print(emotion ?? "Neutral")
            self.facialExpression.text = emotion
        })
    }
    
}
