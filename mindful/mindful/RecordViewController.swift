//
//  RecordViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import VisionLab
import Speech
import Accelerate
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Affdex

class RecordViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, FacialExpressionTrackerDelegate, SFSpeechRecognizerDelegate, AFDXDetectorDelegate {

    
    fileprivate(set) var auth:Auth?
    
    fileprivate(set) var ref: DatabaseReference!
    
    //MARK: Properties
    private let textClassificationService = TextClassificationService()
    
    //MARK: Affdex
    
    var detector: AFDXDetector? = nil
    
    //MARK : UI
    private let nlpInput =  UITextView()
   
    private let nlpText = UILabel()
    
    private let sentimentLabel = UILabel()
    private var emotion = ""
    
    private let userPrompt = UILabel()
    
    private let journalButton = UIButton()
    
    private let settingsButton = UIButton()
    var emojiMap = ["anger": "😡",
                    "contempt": "🙄",
                    "disgust": "🤢",
                    "fear": "😨",
                    "joy": "😃",
                    "sadness": "😔",
                    "surprise": "😮"]

//    let cameraController = CameraController()
    let settingsController = SettingsController()
    let journalController = JournalViewController()
    
    
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
    private var volumeFloat:Float = 0.0
    
    var promptArray = ["What was the best part of your day?", "What was the worst part of your day?", "What are you gonna do tomorrow that you didn't do today?"]
    var promptIndex = 0;
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var timer:Timer?
    var volume_timer:Timer?
    var change:CGFloat = 0.01
    
    //MARK: Actions

    @objc func toggleRecording(_ sender: UIButton) {

        if (!sender.isSelected) {
//            try? self.cameraController.beginRecording()
            handleSpeech()
            print("Start Recording")
            sender.isSelected = true
        } else {
            let user = auth?.currentUser
            let uid = user?.uid
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.full
            let date = dateFormatter.string(from: currentDate) //today's date
            
            let userID = Auth.auth().currentUser?.uid
            ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                
                // Query last entry date
                let value = snapshot.value as? NSDictionary
                let lastEntry = value?["lastEntry"] as? String ?? "Friday, January 1, 1990"
                let lastDateObj = dateFormatter.date(from: lastEntry)
                let email = value?["email"] as? String ?? "no email"
                
                // Query streak count
                let streak = value?["streak"] as? Int ?? 0
                
                // calculate time between date and last entry
                let streakGap = self.calculateDaysBetweenTwoDates(start: lastDateObj!, end: currentDate)
                
                // check if user broke streak
                if (streakGap > 2) {
                    // reset streak
                    let streak = 0
                    let userDataEntry = ["email": email,
                                         "streak": streak,
                                         "lastEntry": date] as [String : Any]
                    self.ref.child("users").child(userID!).setValue(userDataEntry)
                } else if (date != lastEntry) {
                    // update streak
                    let streak = streak + 1
                    let userDataEntry = ["email": email,
                                         "streak": streak,
                                         "lastEntry": date] as [String : Any]
                    self.ref.child("users").child(userID!).setValue(userDataEntry)
                }
            }) { (error) in
                print(error.localizedDescription)
            }

//            try? self.cameraController.stopRecording()
            let entrykey = self.ref.child("entries").childByAutoId().key
            //  location, weather, transcript, emotion, time
            let entry = ["uid": uid ?? "NOUSERID",
                         "location":"here",
                         "weather" : "very cold",
                         "transcript":self.nlpInput.text,
                         "emotion":self.emotion,
                         "emoji":self.emojiMap[self.emotion] ?? "joy",
                         "time": date] as [String : Any]
            let childUpdates = ["/entries/\(entrykey)": entry,
                                "/user-entries/\(uid ?? "NOUSERID")/\(entrykey)/": entry]
            ref.updateChildValues(childUpdates)
            
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
            print("Stop Recording")
            sender.isSelected = false
        }
    }
    
    private func calculateDaysBetweenTwoDates(start: Date, end: Date) -> Int {
        
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start) else {
            return 0
        }
        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end) else {
            return 0
        }
        return end - start
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.left:
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromRight
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                present(settingsController, animated: false, completion: nil)
            case UISwipeGestureRecognizerDirection.right:
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromLeft
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                present(journalController, animated: false, completion: nil)
            default:
                break
            }
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
                self.emotion = self.textClassificationService.predictSentiment(from: self.nlpInput.text!)
                self.sentimentLabel.text = "NLP Sentiment: " + self.emotion
                self.animatedGradientView?.changeSentimentGradient(sentiment: self.emotion)
            }
        })
        
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            
            self.recognitionRequest?.append(buffer)
//            let arraySize = Int(buffer.frameLength)
//            let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count:arraySize))
//            
//            //do something with samples
//            let volume = 20 * log10(floatArray.reduce(0){ $0 + $1} / Float(arraySize))
//            if(!volume.isNaN){
//                print("this is the current volume: \(volume)")
//            }
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
        self.emotion = textClassificationService.predictSentiment(from: nlpInput.text!)
        sentimentLabel.text = self.emotion
        animatedGradientView?.changeSentimentGradient(sentiment: emotion)
    }
    
    func setUpNLPLabels() {
        nlpInput.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        nlpInput.delegate = self
        nlpInput.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 90)
        nlpInput.backgroundColor = UIColor.clear
        nlpInput.textColor = UIColor.white
        nlpInput.isEditable = false;
        nlpInput.isSelectable = false;
        self.view.addSubview(nlpInput)
        
        sentimentLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
        sentimentLabel.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height - 24)
        sentimentLabel.textAlignment = NSTextAlignment.center
        sentimentLabel.text = "NLP Sentiment:"
        sentimentLabel.textColor =  UIColor.white
        self.view.addSubview(sentimentLabel)
        
        userPrompt.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        userPrompt.center = CGPoint(x: self.view.center.x, y: (1/5)*self.view.bounds.height + 340)
        userPrompt.textAlignment = NSTextAlignment.center
        userPrompt.numberOfLines = 0;
        userPrompt.text = "How are you today?"
        userPrompt.textColor =  UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        userPrompt.isUserInteractionEnabled = true
        userPrompt.addGestureRecognizer(tap)
        self.view.addSubview(userPrompt)
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        userPrompt.text = promptArray[promptIndex%promptArray.count];
        promptIndex+=1
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
        journalButton.addTarget(self,  action: #selector(self.openJournal(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(journalButton)
        
        settingsButton.frame = CGRect(x: 0, y: 525, width: 30, height: 30)
        settingsButton.center.x = (4/5)*self.view.bounds.width
        settingsButton.center.y = (6/7)*self.view.bounds.height
        settingsButton.setImage(#imageLiteral(resourceName: "Settings Icon"), for: UIControlState.normal)
        settingsButton.addTarget(self,  action: #selector(self.settingsFunction(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(settingsButton)
        
    }
    
    @objc func settingsFunction(_ sender: UIButton) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        present(settingsController, animated: false, completion: nil)

    }
    
    @objc func openJournal(_ sender: UIButton) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        present(journalController, animated: false, completion: nil)
    }
    
    func setUpAudioWaveFormView() {
        audioWaveFormView.frame = CGRect(x:0, y:0, width: self.view.bounds.width, height: 50)
        audioWaveFormView.center = self.view.center
        self.view.addSubview(audioWaveFormView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        self.auth = Auth.auth()
        let _height = self.view.bounds.height
        let _width = self.view.bounds.width
        self.audioWaveFormView.density = 1.0
        timer = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(RecordViewController.refreshAudioView(_:)), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(timeInterval: 0.1 , target: self, selector: #selector(updateMeter), userInfo: nil, repeats: true)
//        func configureCameraController() {
//            capturePreviewView.frame = self.view.bounds
//            self.view.addSubview(capturePreviewView)
//            cameraController.prepare {(error) in
//                if let error = error {
//                    print(error)
//                }
//
//                try? self.cameraController.displayPreview(on: self.capturePreviewView)
//            }
//        }
//        do {
//            try self.cameraController.switchCameras()
//        }
//        catch {
//            print(error)
//        }
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
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
//        configureCameraController()
        styleAnimatedGradientView()
        styleCaptureButton()
        setUpButtons()
        setUpAudioWaveFormView()
        setUpNLPLabels()
        setUpFaceExLabel()
//        self.cameraController.customDelegate = self
//        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
//        tap.numberOfTapsRequired = 2
//        view.addGestureRecognizer(tap)
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
        detector = AFDXDetector(delegate:self, using:AFDX_CAMERA_FRONT, maximumFaces:1)
        // turning on a few emotions
        
        detector?.setDetectEmojis(true)
        detector?.setDetectAllEmotions(true)
        detector?.setDetectAllExpressions(true)
        detector!.start()
    }
    
    func detectorDidStartDetectingFace(face : AFDXFace) {
        // handle new face
    }
    
    func detectorDidStopDetectingFace(face : AFDXFace) {
        // handle loss of existing face
    }
    
    func detector(_ detector : AFDXDetector, hasResults : NSMutableDictionary?, for forImage : UIImage, atTime : TimeInterval) {
        // handle processed and unprocessed images here
        if hasResults != nil {
            // handle processed image in this block of code
            
            // enumrate the dictionary of faces
            for (_, face) in hasResults! {
                // for each face, get the rage score and print it
                let emotions : AFDXEmotions = (face as AnyObject).emotions
                let scores = ["anger": emotions.anger,
                              "contempt": emotions.contempt,
                              "disgust": emotions.disgust,
                              "fear": emotions.fear,
                              "joy": emotions.joy,
                              "sadness": emotions.sadness,
                              "surprise": emotions.surprise
                ]
                let exp = scores.max{a,b in a.value < b.value}
                if (Float((exp?.value)!) > 60.0) {
                    self.emotion = (exp?.key)!
                    changeFacialExpressionLabel(emotion: exp?.key)
                } else {
                    self.emotion = "joy"
                    changeFacialExpressionLabel(emotion: "neutral")
                }
            }
        } else {
            // handle unprocessed image in this block of code
        }
    }
    
    @objc func doubleTapped(){
        self.animatedGradientView?.isHidden = !((self.animatedGradientView?.isHidden)!)
        self.audioWaveFormView.isHidden = !self.audioWaveFormView.isHidden
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
    
    @objc func updateMeter() {
//        self.audioWaveFormView.amplitude = CGFloat(volumeFloat*100)
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            captureButton.isEnabled = true
        } else {
            captureButton.isEnabled = false
        }
    }
    
}
