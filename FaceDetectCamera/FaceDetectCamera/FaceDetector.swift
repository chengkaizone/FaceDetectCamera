//
//  FaceDetector.swift
//  Camera
//
//  Created by sy on 2017/2/17.
//  Copyright © 2017年 SS. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class FaceDetector {
    
    private static let _shared = FaceDetector()
    
    static var shared: FaceDetector {
        return _shared
    }
    
    private init() { }
    
    lazy var detector: CIDetector = {
        let context = CIContext(options:[kCIContextPriorityRequestLow : true,
                                         CIDetectorTracking : true])
        let detector = CIDetector(ofType:CIDetectorTypeFace, context:context, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return detector!
    }()
    

    class func faceCountInImage(_ image: UIImage) -> Int{
        return FaceDetector.shared.faceCountInImage(image)
    }
    
    class func detectFaceInImage(_ image: UIImage,
                                 in layer: CALayer,
                                 effectiveScale: CGFloat,
                                 frontDevice: Bool,
                                 completion: @escaping (_ faceFrame: CGRect?) -> Swift.Void){
        return FaceDetector.shared.detectFaceInImage(image,
                                                     in: layer,
                                                     effectiveScale: effectiveScale,
                                                     frontDevice: frontDevice,
                                                     completion: completion)
    }
    
    
    private func detectFaceInImage(_ image: UIImage,
                           in layer: CALayer,
                           effectiveScale: CGFloat,
                           frontDevice: Bool = false,
                           completion: @escaping (_ faceFrame: CGRect?) -> Swift.Void) {
        
        guard let faceImage = CIImage(image: image) else { return }
        
        let faces = detector.features(in: faceImage)
        
        if faces.count == 0 {
            completion(nil)
            return
        }
        
        // For converting the Core Image Coordinates to UIView Coordinates
        let ciImageSize = faceImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        if let face = faces.first as? CIFaceFeature {
            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = layer.bounds.size
            let scale = min(viewSize.width / ciImageSize.width,
                            viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale * effectiveScale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale * effectiveScale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale * effectiveScale, y: scale * effectiveScale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            if frontDevice {
                faceViewBounds.origin.x = viewSize.width - faceViewBounds.origin.x - faceViewBounds.size.width
            }
            completion(faceViewBounds)
        }
    }
    
    
   
    private func faceCountInImage(_ image: UIImage) -> Int {
        let ciImg = CIImage(cgImage: image.cgImage!)
        let features = detector.features(in: ciImg)
        return features.count
    }
    
}

