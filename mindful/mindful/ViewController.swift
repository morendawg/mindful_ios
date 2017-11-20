//
//  ViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import VisionLab
import Speech


class ViewController: UIViewController, UITextFieldDelegate, FacialExpressionTrackerDelegate, SFSpeechRecognizerDelegate {
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
    private var animatedGradientView : AnimatedGradientView?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    //MARK: Actions

    @objc func startRecording(_ sender: UIButton) {
        print("Start Recording")
        captureButton.layer.borderColor = UIColor.red.cgColor
        captureButton.layer.borderWidth = 8
        try? self.cameraController.beginRecording()
        
        handleSpeech()
    }
    
    @objc func stopRecording(_ sender: UIButton) {
        print("Stop Recording")
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        try? self.cameraController.stopRecording()
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        captureButton.isEnabled = false
    }
    
    func handleSpeech() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.nlpInput.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.captureButton.isEnabled = true
                let sentiment = self.textClassificationService.predictSentiment(from: self.nlpInput.text!)
                self.sentimentLabel.text = sentiment
                self.animatedGradientView?.changeSentimentGradient(sentiment: sentiment)
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
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
        animatedGradientView?.changeSentimentGradient(sentiment: sentiment)
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
        func styleAnimatedGradientView() {
            animatedGradientView = AnimatedGradientView(frame: self.view.bounds)
            self.view.addSubview(animatedGradientView!)
        }
        configureCameraController()
        styleAnimatedGradientView()
        styleCaptureButton()
        setUpNLPLabels()
        setUpFaceExLabel()
        self.cameraController.customDelegate = self
        
        speechRecognizer.delegate = self;
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.captureButton.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    func changeFacialExpressionLabel(emotion: String?) {
        DispatchQueue.main.async(execute: {
            print(emotion ?? "Neutral")
            self.facialExpression.text = emotion
        })
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            captureButton.isEnabled = true
        } else {
            captureButton.isEnabled = false
        }
    }
    
}
