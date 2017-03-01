//
//  CustomCameraView.swift
//  Camera
//
//  Created by sy on 2017/1/18.
//  Copyright © 2017年 SS. All rights reserved.
//

import UIKit
import AVFoundation

typealias captureOutputHandler = (UIImage) -> Swift.Void
typealias captureFaceImageHandler = ([UIImage]) -> Swift.Void

protocol CustomCameraViewProtocol {
    var isFaceDetectOn: Bool { get set }
    var gestureRecognizerShouldBegin: Bool { get set }
    var previewLayer: AVCaptureVideoPreviewLayer { get }
    var currentFlashMode: AVCaptureFlashMode { get }
    
    mutating func startSession()
    mutating func stopSession()
    mutating func changeFlashMode(_ mode: AVCaptureFlashMode)
    mutating func changeCameraPosition(position: AVCaptureDevicePosition)
    mutating func shutterCamera(handler: @escaping captureOutputHandler)
    mutating func detectFaceImages(handler: @escaping captureFaceImageHandler)
}


// MARK:- Properties & initialize
class CustomCameraView: UIView, CustomCameraViewProtocol {
    
    var captureFaceImageHandler: captureFaceImageHandler?   
    
    var isFaceDetectOn: Bool = true
    
    var cameraPosititon: AVCaptureDevicePosition {
        return service!.cameraPosititon
    }
    var currentFlashMode: AVCaptureFlashMode {
        return service!.currentFlashMode
    }
    
    var gestureRecognizerShouldBegin: Bool = true
    
    var previewLayer: AVCaptureVideoPreviewLayer
    
    // zoom prewiewLayer
    fileprivate var effectiveScale: CGFloat = 1.0
    fileprivate var beginGestureScale: CGFloat = 1.0
    
    //service
    fileprivate var service: CameraService?
    
   
    private override init(frame: CGRect) {
        previewLayer = AVCaptureVideoPreviewLayer.init(session: service?.session)
        super.init(frame: frame)
        
    }
    
    convenience init(service: CameraService) {
        self.init()
        self.service = service
        previewLayer = AVCaptureVideoPreviewLayer.init(session: service.session)
        clipsToBounds = true
        layer.addSublayer(previewLayer)
        
        // add tapGesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToFocus))
        addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoomToFocus))
        pinch.delegate = self;
        addGestureRecognizer(pinch)
        
        service.metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()
        previewLayer.frame = bounds
    }
    
}

// MARK:open func
extension CustomCameraView {
    open func startSession() {
        service?.session.startRunning()
    }
    open func stopSession() {
        service?.session.stopRunning()
    }
    
    open func changeCameraPosition(position: AVCaptureDevicePosition) {
        if position == cameraPosititon { return }
        
        ShowLayerService.shared.removeAllFaceLayers()
        
        service?.changeCameraPosition(position: position)
        
        let transition = CATransition.init()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = "oglFlip"
        transition.subtype = kCATransitionFromLeft
        previewLayer.add(transition, forKey: nil)
    }
    
    open func changeFlashMode(_ mode: AVCaptureFlashMode) {
        service?.changeFlashMode(mode)
    }
    
    open func shutterCamera(handler: @escaping captureOutputHandler) {
        service?.shutterCamera(videoScaleAndCropFactor: effectiveScale) { image in
            handler(image)
        }
    }
    
    open func detectFaceImages(handler: @escaping captureFaceImageHandler) {
        self.captureFaceImageHandler = handler
    }
  
}


extension CustomCameraView: UIGestureRecognizerDelegate, ShowLayerSquareProtocol {
    
    // MARK:- tapToFocus
    @objc fileprivate func tapToFocus(tap: UITapGestureRecognizer) {
        
        if !gestureRecognizerShouldBegin { return }
        
        if cameraPosititon == .front { return }
    
        let point = tap.location(in: self)
        
        showFocusSquare(at: point, width: 60, color: .blue)
        
        let pointInCamera = previewLayer.captureDevicePointOfInterest(for: point)
        
        service?.tapThenConfigDevice(pointInCamera)
       
    }
    // MARK:- pinch gesture
    @objc fileprivate func zoomToFocus(pinch: UIPinchGestureRecognizer) {
        if !gestureRecognizerShouldBegin { return }
        
        var allTouchFlag: Bool = true
        let touchCount = pinch.numberOfTouches
        
        for index in 0..<touchCount {
            let location = pinch.location(ofTouch: index, in: self)
            let convertPoint = previewLayer.convert(location, from: previewLayer.superlayer)
            if !previewLayer.contains(convertPoint) {
                allTouchFlag = false
                break
            }
        }
        
        if allTouchFlag {
            effectiveScale = beginGestureScale * pinch.scale
            if effectiveScale < 1.0 {
                effectiveScale = 1.0
            }
            guard let maxScaleAndCropFactor = service?.stillImageOutput
                .connection(withMediaType: AVMediaTypeVideo)
                .videoMaxScaleAndCropFactor
                else { return }
            
            if effectiveScale > maxScaleAndCropFactor {
                effectiveScale = maxScaleAndCropFactor
            }
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.15)
            previewLayer.setAffineTransform(CGAffineTransform(scaleX: effectiveScale, y: effectiveScale))
            CATransaction.commit()
        }
        
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginGestureScale = effectiveScale
        }
        return true
    }
    
}

// MARK:- AVCaptureMetadataOutputObjectsDelegate
extension CustomCameraView: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!,
                       from connection: AVCaptureConnection!) {
        
        if !isFaceDetectOn { return }
        
        if let metadataObjs = metadataObjects as? [AVMetadataFaceObject] {
        
            guard let faceBounds = ShowLayerService.shared
                .showFaceSquares(faces: metadataObjs, in: self.previewLayer)
                else { return }
            
            if faceBounds.isEmpty { return }
            
            self.shutterCamera(handler: { [weak self] image in
                
                guard let `self` = self else { return }
                
                var images = [UIImage]()
                for faceBound in faceBounds {
                    let croppedImage =  image.cropImageToRect(faceBound, in: self.previewLayer)
                    images.append(croppedImage)
                }
                
                // 回调crop后的images出去
                self.captureFaceImageHandler?(images)
            })
        }
    }
 
}








