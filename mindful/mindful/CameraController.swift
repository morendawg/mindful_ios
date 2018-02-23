//
//  CameraController.swift
//  mindful
//
//  Created by Daniel Moreno on 9/29/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import AVFoundation
import UIKit
import Vision
import Photos
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class CameraController : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, ClassificationServiceDelegate {
    fileprivate(set) var auth:Auth?
    var captureSession : AVCaptureSession?
    var frontCamera : AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var exportURL : URL?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureVideoDataOutput?
    var audioOutput: AVCaptureAudioDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var landmarksLayer: CAShapeLayer?
    var recordingDelegate:AVCaptureFileOutputRecordingDelegate?
    let videoFileOutput = AVCaptureMovieFileOutput()
    var flashMode = AVCaptureDevice.FlashMode.off
    let facesQueue = DispatchQueue(label: "com.mindful.facesQueue", attributes: [])
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    var classificationService = ClassificationService()
    weak var customDelegate: FacialExpressionTrackerDelegate?
}
protocol FacialExpressionTrackerDelegate: class { //Setting up a Custom delegate for this class. I am using `class` here to make it weak.
    func changeFacialExpressionLabel(emotion: String?) //This function will send the data back to origin viewcontroller.
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    public enum CameraPosition {
        case front
        case rear
    }
}

extension CameraController {
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession(){
            self.captureSession = AVCaptureSession()
            self.recordingDelegate = self
        }
        func configureCaptureDevices() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
            let cameras = (session.devices.flatMap { $0 })
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                if camera.position == .back {
                    self.rearCamera = camera
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                self.currentCameraPosition = .rear
            } else if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                else { throw CameraControllerError.inputsAreInvalid }
                
                self.currentCameraPosition = .front
            } else { throw CameraControllerError.noCamerasAvailable }
            do {
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
                
                if captureSession.canAddInput(audioDeviceInput) {
                    captureSession.addInput(audioDeviceInput)
                } else {
                    print("Could not add audio device input to the session")
                }
            } catch {
                print("Could not create audio device input: \(error)")
            }
        }
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            self.videoOutput = AVCaptureVideoDataOutput()
            self.audioOutput = AVCaptureAudioDataOutput()
            let settings: [AnyHashable: Any] = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput?.videoSettings = settings as! [String : Any]
            self.videoOutput?.setSampleBufferDelegate(self, queue: facesQueue)
            if captureSession.canAddOutput(self.videoOutput!) { captureSession.addOutput(self.videoOutput!) }
            if captureSession.canAddOutput(self.audioOutput!) { captureSession.addOutput(self.audioOutput!) }
            captureSession.startRunning()
        }
        DispatchQueue(label : "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
                self.classificationService.setup()
                self.classificationService.delegate = self
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        self.landmarksLayer = CAShapeLayer()
        self.landmarksLayer?.strokeColor = UIColor.green.cgColor
        self.landmarksLayer?.lineWidth = 2.0
        self.landmarksLayer?.setAffineTransform(CGAffineTransform(scaleX:-1, y:-1))
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        view.layer.insertSublayer(self.landmarksLayer!, at: 1)
        self.previewLayer?.frame = view.frame
        self.landmarksLayer?.frame = view.frame
    }
    func switchCameras() throws {
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else {throw CameraControllerError.captureSessionIsMissing}
        func switchToFrontCamera() throws {
            guard let inputs = captureSession.inputs as? [AVCaptureInput], let rearCameraInput = self.rearCameraInput, inputs.contains(rearCameraInput),
            let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            captureSession.removeInput(rearCameraInput)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            } else { throw CameraControllerError.invalidOperation }
        }
        func switchToRearCamera() throws {
            guard let inputs = captureSession.inputs as? [AVCaptureInput], let frontCameraInput = self.frontCameraInput, inputs.contains(frontCameraInput),
            let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            captureSession.removeInput(frontCameraInput)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.currentCameraPosition = .rear
            } else { throw CameraControllerError.invalidOperation }
        }
        switch currentCameraPosition {
        case.front :
            try switchToRearCamera()
        case .rear :
            try switchToFrontCamera()
        }
        captureSession.commitConfiguration()
    }
    func beginRecording () throws {
        self.captureSession?.removeOutput(self.videoOutput!)
        self.captureSession?.addOutput(self.videoFileOutput)
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: now)+".mov"
        let exportPath = NSTemporaryDirectory().appendingFormat(dateString)
        self.exportURL = URL(fileURLWithPath: exportPath)
        self.videoFileOutput.startRecording(to: self.exportURL!, recordingDelegate: self.recordingDelegate!)
    }
    
    func stopRecording() throws {
        self.videoFileOutput.stopRecording()
        self.captureSession?.removeOutput(self.videoFileOutput)
        self.captureSession?.addOutput(self.videoOutput!)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        return
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let videoRef = storageRef.child("videos/"+outputFileURL.lastPathComponent)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mov"
        let uploadTask = videoRef.putFile(from: outputFileURL, metadata: metadata)
        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
        }
        
        uploadTask.observe(.pause) { snapshot in
            // Upload paused
        }
        
        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
        }
        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
        }
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as? NSError {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    // File doesn't exist
                    break
                case .unauthorized:
                    // User doesn't have permission to access file
                    break
                case .cancelled:
                    // User canceled the upload
                    break
                case .unknown:
                    // Unknown error occurred, inspect the server response
                    print("unknown")

                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
            }
        }
        return
    }
    
    func convert(ciImage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))
        self.detectFace(on: ciImageWithOrientation)
        self.classificationService.classify(image: ciImageWithOrientation)
    }
    
    func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                
                DispatchQueue.main.async {
                    self.landmarksLayer?.sublayers?.removeAll()
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        let faceBoundingBox = boundingBox.scaled(to: (self.previewLayer?.bounds.size)!)
                        
                        //different types of landmarks
                        let faceContour = observation.landmarks?.faceContour
                        self.convertPointsForFace(faceContour, faceBoundingBox)
                        
                        let leftEye = observation.landmarks?.leftEye
                        self.convertPointsForFace(leftEye, faceBoundingBox)

                        let rightEye = observation.landmarks?.rightEye
                        self.convertPointsForFace(rightEye, faceBoundingBox)

                        let nose = observation.landmarks?.nose
                        self.convertPointsForFace(nose, faceBoundingBox)

                        let lips = observation.landmarks?.innerLips
                        self.convertPointsForFace(lips, faceBoundingBox)

                        let leftEyebrow = observation.landmarks?.leftEyebrow
                        self.convertPointsForFace(leftEyebrow, faceBoundingBox)

                        let rightEyebrow = observation.landmarks?.rightEyebrow
                        self.convertPointsForFace(rightEyebrow, faceBoundingBox)

                        let noseCrest = observation.landmarks?.noseCrest
                        self.convertPointsForFace(noseCrest, faceBoundingBox)

                        let outerLips = observation.landmarks?.outerLips
                        self.convertPointsForFace(outerLips, faceBoundingBox)
                        
                    }
                }
            }
        }
    }
    
    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) {
        if let points = landmark?.normalizedPoints {
            let faceLandmarkPoints = points.map { (point: CGPoint) -> (x: CGFloat, y: CGFloat) in
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = point.y * boundingBox.height + boundingBox.origin.y
                return (x: pointX, y: pointY)
            }
            DispatchQueue.main.async {
                self.draw(points: faceLandmarkPoints)
            }
        }
    }
    
    func draw(points: [(x: CGFloat, y: CGFloat)]) {
        for i in 0..<points.count {
            let point = CGPoint(x: points[i].x, y: points[i].y)
            let newLayer = CAShapeLayer()
            newLayer.fillColor = UIColor.white.cgColor
            let path = UIBezierPath(arcCenter: point, radius: CGFloat(3), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
            newLayer.path = path.cgPath
            self.landmarksLayer?.addSublayer(newLayer)
            
        }
    }
    
    
    func convert(_ points: UnsafePointer<vector_float2>, with count: Int) -> [(x: CGFloat, y: CGFloat)] {
        var convertedPoints = [(x: CGFloat, y: CGFloat)]()
        for i in 0...count {
            convertedPoints.append((CGFloat(points[i].x), CGFloat(points[i].y)))
        }
        
        return convertedPoints
    }
    
    func classificationService(_ service: ClassificationService, didDetectEmotion emotion: String) {
       customDelegate?.changeFacialExpressionLabel(emotion: emotion)
    }
}

