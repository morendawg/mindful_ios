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
   
    @IBOutlet weak var nlpInput: UITextField!
   
    @IBOutlet weak var nlpText: UILabel!
    
    @IBOutlet weak var sentimentLabel: UILabel!

    let cameraController = CameraController()
    let classificationService = ClassificationService()
    
    @IBOutlet fileprivate var captureButton: UIButton!
    @IBOutlet fileprivate var facialExpression: UILabel!
    
    @IBOutlet fileprivate var capturePreviewView: UIView!
    
    
    override var prefersStatusBarHidden: Bool { return true }
    
    //MARK: Actions

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

    override func viewDidLoad() {
        super.viewDidLoad()
        nlpInput.delegate = self
//        textInput.delegate = self
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
        self.facialExpression.text = "😐"
        styleCaptureButton()
        configureCameraController()
        self.cameraController.customDelegate = self
    }
    func changeFacialExpressionLabel(emotion: String?) {
        DispatchQueue.main.async(execute: {
            print(emotion ?? "Neutral")
            self.facialExpression.text = emotion
        })
    }
    
}
