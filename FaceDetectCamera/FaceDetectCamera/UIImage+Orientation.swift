//
//  UIImage+Orientation.swift
//  Camera
//
//  Created by sy on 2017/2/17.
//  Copyright © 2017年 SS. All rights reserved.
//

import UIKit


extension UIImage {
    
    //called after shutter camera
    func fixOrientation() -> UIImage {
        // No-op if the orientation is already correct
        if self.imageOrientation == .up {
            return self
        }
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -(CGFloat)(M_PI_2))
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: self.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.height), height: CGFloat(self.size.width)))
        default:
            ctx?.draw( self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.width), height: CGFloat(self.size.height)))
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgimg = ctx?.makeImage()
        let img = UIImage(cgImage: cgimg!)
        
        return img
    }

}
