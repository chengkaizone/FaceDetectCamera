//
//  CameraService.swift
//  Camera
//
//  Created by sy on 2017/2/17.
//  Copyright © 2017年 SS. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage


class CameraService: NSObject {
    
    var currentFlashMode: AVCaptureFlashMode = .off
    var cameraPosititon: AVCaptureDevicePosition = .back
    
    
    let stillImageOutput = AVCaptureStillImageOutput()
    let metaDataOutput = AVCaptureMetadataOutput()
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var session = AVCaptureSession()
    
    
    private override init() {}
    
    convenience init(position: AVCaptureDevicePosition?,
                     sessionPreset: String = AVCaptureSessionPreset1920x1080) {
        self.init()
        
        initCamera(position: position ?? .back, sessionPreset: sessionPreset)
    }
    
    
    private func initCamera(position: AVCaptureDevicePosition,
                            sessionPreset: String) {
        
        device =  device(with: position )
        cameraPosititon = position
        do {
            input = try AVCaptureDeviceInput.init(device: self.device)
            
        }catch{
//            assertionFailure("init AVCaptureDeviceInput failed")
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        if session.canAddOutput(metaDataOutput) {
            session.addOutput(metaDataOutput)
            metaDataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        
        if session.canSetSessionPreset(sessionPreset) {
            session.sessionPreset = sessionPreset
        }
        
    }

}

// MARK:- CustomCameraViewProtocol  -  open func
extension CameraService {
    
    open func startSession() {
        session.startRunning()
    }
    
    
    open func stopSession() {
        session.stopRunning()
    }
    
    open func shutterCamera(videoScaleAndCropFactor: CGFloat, completionHandler:@escaping (_ image: UIImage) -> Swift.Void ) {
        
        guard let stillImageConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) else { return }
        
        stillImageConnection.videoOrientation = .portrait 
        
        stillImageConnection.videoScaleAndCropFactor = videoScaleAndCropFactor
            
        self.stillImageOutput.captureStillImageAsynchronously(from: stillImageConnection, completionHandler: { 
            ( imageDataSampleBuffer, error) -> Void in
            if imageDataSampleBuffer == nil { return }
            guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) else { return }
            guard let image = UIImage(data: imageData) else { return }
            // 修复图片
            completionHandler(image.fixOrientation())
        })
    }
    
    open func changeCameraPosition(position: AVCaptureDevicePosition) {
        
        if position == cameraPosititon {
            return
        }
        
        let cameraCount = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count
        
        if !(cameraCount > 1) { return }
        
        DispatchQueue.global().async {
        
            
            var newInput: AVCaptureDeviceInput?

            guard let camera: AVCaptureDevice = self.device(with: position) else { return }

            do {
                newInput = try AVCaptureDeviceInput(device: camera)
            }
            catch {
                print("switch camera error")
            }
            
            if newInput != nil {

                self.session.stopRunning()
                self.session.beginConfiguration()
                self.session.removeInput(self.input)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.input = newInput
                } else {
                    self.session.addInput(self.input)
                }
                self.session.commitConfiguration()
            }
            self.session.startRunning()
            self.cameraPosititon = position
            self.device = self.device(with: position)

        }
    }
    
    func changeFlashMode(_ mode: AVCaptureFlashMode) {
        
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return }
        try! device.lockForConfiguration()
        if device.hasFlash {
            switch device.flashMode {
            case .off:
                device.flashMode = .on
                currentFlashMode = .on
            case .on:
                device.flashMode = .auto
                currentFlashMode = .auto
            case .auto:
                device.flashMode = .off
                currentFlashMode = .off
            }
        }
        device.unlockForConfiguration()
    }
    
    func tapThenConfigDevice(_ pointInCamera: CGPoint) {
        
        guard let device = device else { return }
        
        try! device.lockForConfiguration()
        
        if device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = pointInCamera
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposurePointOfInterestSupported {
            device.exposureMode = .continuousAutoExposure
            device.exposurePointOfInterest = pointInCamera
        }
        device.isSubjectAreaChangeMonitoringEnabled = true
        device.focusPointOfInterest = pointInCamera
        
        device.unlockForConfiguration()
    }
    
}



// MARK:- Assistant method
extension CameraService {
    
    func device(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if (device as AnyObject).position == position {
                return device as? AVCaptureDevice
            }
        }
        
        return nil
    }
    
}
