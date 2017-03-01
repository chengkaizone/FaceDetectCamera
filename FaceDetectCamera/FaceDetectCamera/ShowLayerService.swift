//
//  ShowLayerService.swift
//  Camera
//
//  Created by sy on 2017/2/23.
//  Copyright © 2017年 SS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class ShowLayerService {
    ///singleton
    private static let _shared = ShowLayerService()
    
    static var shared: ShowLayerService {
        return _shared
    }
    
    private init() { }
    
    private var faceLayers = [CAShapeLayer]()
    private var faceIDs = [Int]()
    private var tempFaceIDs = [Int]()
    private var faceBounds = [CGRect]()
    
    open func showFaceSquares(faces: [AVMetadataFaceObject], in layer: AVCaptureVideoPreviewLayer) -> [CGRect]? {
        
        faceBounds.removeAll()
        tempFaceIDs.removeAll()
        
        if faces.isEmpty {
            faceLayers.forEach{ $0.removeFromSuperlayer() }
            faceLayers.removeAll()
            faceIDs.removeAll()
            return nil
        }
        
        faces.forEach{ originFace in
            guard let face = layer.transformedMetadataObject(for: originFace) as? AVMetadataFaceObject else { return }
            
            if !tempFaceIDs.contains(face.faceID) {
                tempFaceIDs.append(face.faceID)
            }
            
            if faceIDs.contains(face.faceID) {
                let existFaceLayer = faceLayers.filter{ $0.name == "\(face.faceID)" }
                existFaceLayer.first?.frame = face.bounds
                return
            }
            
            let square = creatreSquare(id: face.faceID, frame: face.bounds)
            if faceLayers.contains(square) { return }
            faceLayers.append(square)
            layer.addSublayer(square)
            faceIDs.append(face.faceID)
            
            faceBounds.append(face.bounds)
        }
        
        faceLayers.filter{ !tempFaceIDs.contains(Int($0.name!)!) }.forEach{ $0.removeFromSuperlayer() }
     
        return faceBounds
    }
    
    open func removeAllFaceLayers() {
        faceBounds.removeAll()
        tempFaceIDs.removeAll()
        faceLayers.forEach{ $0.removeFromSuperlayer() }
        faceLayers.removeAll()
        faceIDs.removeAll()
    }
}

extension ShowLayerService {
    
    fileprivate func creatreSquare(id: Int, frame: CGRect) -> CAShapeLayer {
        let square = CAShapeLayer.init()
        square.name = "\(id)"
        square.contents = UIImage(named:"CustomCameraSources.bundle/customCameraSquare")?.cgImage
        square.contentsGravity = kCAGravityResizeAspectFill
        square.frame = frame
        return square
    }
    
}
