//
//  SnapFaceService.swift
//  Camera
//
//  Created by sy on 2017/2/25.
//  Copyright © 2017年 SS. All rights reserved.
//

import UIKit

extension UIImage {
    func cropImageToRect(_ rect: CGRect, in layer: CALayer) -> UIImage {

        let xRatio = self.size.width / layer.bounds.width
        let yRatio = self.size.height / layer.bounds.height
        let appledRect = rect.applying(CGAffineTransform(scaleX: xRatio, y: yRatio))
        let width = appledRect.width
        let height = appledRect.height
        let finalRect = CGRect(x: appledRect.origin.x - width * 0.5,
                               y: appledRect.origin.y - height * 0.5,
                               width: 2 * width, height: 2 * height)
        
        let sourceImageRef: CGImage? = self.cgImage
        let newImageRef: CGImage = sourceImageRef!.cropping(to: finalRect)!
        
        let newImage = UIImage(cgImage: newImageRef)
        
        return newImage
        
    }
    
}
