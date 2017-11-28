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


class ViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, FacialExpressionTrackerDelegate, SFSpeechRecognizerDelegate {
    //MARK: Properties
    private let textClassificationService = TextClassificationService()
    
    //MARK : UI
    private let nlpInput =  UITextView()
   
    private let nlpText = UILabel()
    
    private let sentimentLabel = UILabel()
    
    private let journalButton = UIButton()
    
    private let settingsButton = UIButton()

    let cameraController = CameraController()
    let classificationService = ClassificationService()
    
    private let captureButton = UIButton()
    private let facialExpression = UILabel()
    
    private let capturePreviewView =  UIView()
    private let audioWaveFormView = AudioWaveFormView()
    private var animatedGradientView : AnimatedGradientView?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var timer:Timer?
    var change:CGFloat = 0.01
    
    //MARK: Actions

    @objc func toggleRecording(_ sender: UIButton) {
        if (!sender.isSelected) {
            try? self.cameraController.beginRecording()
            handleSpeech()
            print("Stop Recording")
            sender.isSelected = true
        } else {
            try? self.cameraController.stopRecording()
            audioEngine.stop()
            recognitionRequest?.endAudio()
            print("Start Recording")
            sender.isSelected = false
        }
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
                self.sentimentLabel.text = "NLP Sentiment: " + sentiment
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
        nlpInput.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        nlpInput.delegate = self
        nlpInput.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 90)
        nlpInput.backgroundColor = UIColor.clear
        nlpInput.textColor = UIColor.white
        self.view.addSubview(nlpInput)
        sentimentLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        sentimentLabel.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height - 24)
        sentimentLabel.textAlignment = NSTextAlignment.center
        sentimentLabel.text = "NLP Sentiment:"
        sentimentLabel.textColor =  UIColor.white
        self.view.addSubview(sentimentLabel)
    }
    
    func setUpFaceExLabel () {
        facialExpression.frame = CGRect(x: 0, y: 0, width: 500, height: 21)
        facialExpression.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height)
        facialExpression.textAlignment = NSTextAlignment.center
        facialExpression.text = "Facial Expression:"
        facialExpression.textColor =  UIColor.white
        self.view.addSubview(facialExpression)
    }
    
    func setUpButtons() {
        journalButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        journalButton.center.y = (6/7)*self.view.bounds.height
        journalButton.center.x = (1/5)*self.view.bounds.width
        journalButton.setImage(#imageLiteral(resourceName: "Journal Icon"), for: UIControlState.normal)
        self.view.addSubview(journalButton)
        
        settingsButton.frame = CGRect(x: 0, y: 525, width: 30, height: 30)
        settingsButton.center.x = (4/5)*self.view.bounds.width
        settingsButton.center.y = (6/7)*self.view.bounds.height
        settingsButton.setImage(#imageLiteral(resourceName: "Settings Icon"), for: UIControlState.normal)
        self.view.addSubview(settingsButton)
        
    }
    
    func setUpAudioWaveFormView() {
        audioWaveFormView.frame = CGRect(x:0, y:0, width: self.view.bounds.width, height: 50)
        audioWaveFormView.center = self.view.center
        self.view.addSubview(audioWaveFormView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _height = self.view.bounds.height
        let _width = self.view.bounds.width
        self.audioWaveFormView.density = 1.0
        timer = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(ViewController.refreshAudioView(_:)), userInfo: nil, repeats: true)
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
            captureButton.setImage(#imageLiteral(resourceName: "Record Icon"), for: UIControlState.normal)
            captureButton.setImage(#imageLiteral(resourceName: "Stop Icon"), for: UIControlState.selected)
            captureButton.addTarget(self,  action: #selector(self.toggleRecording(_:)), for: UIControlEvents.touchUpInside)
            self.view.addSubview(captureButton)
        }
        func styleAnimatedGradientView() {
            animatedGradientView = AnimatedGradientView(frame: self.view.bounds)
            self.view.addSubview(animatedGradientView!)
        }
        configureCameraController()
        styleAnimatedGradientView()
        styleCaptureButton()
        setUpButtons()
        setUpAudioWaveFormView()
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
    @objc internal func refreshAudioView(_:Timer) {
        if self.audioWaveFormView.amplitude <= self.audioWaveFormView.idleAmplitude || self.audioWaveFormView.amplitude > 1.0 {
            self.change *= -1.0
        }
        
        // Simply set the amplitude to whatever you need and the view will update itself.
        self.audioWaveFormView.amplitude += self.change
    }
    
    func changeFacialExpressionLabel(emotion: String?) {
        DispatchQueue.main.async(execute: {
            self.facialExpression.text = "Facial Expression: "+emotion!
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
