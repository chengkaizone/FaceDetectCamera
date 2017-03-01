//
//  ShowLayerSquareProtocol.swift
//  Camera
//
//  Created by sy on 2017/1/23.
//  Copyright © 2017年 SS. All rights reserved.
//

import Foundation
import UIKit

fileprivate let faceLayerName = "ProtocolFaceLayerName"

protocol ShowLayerSquareProtocol {
    mutating func showFocusSquare(at point: CGPoint, width: CGFloat, color: UIColor)
}

extension ShowLayerSquareProtocol where Self: UIView {
    
    // MARK:- Show focus square
    func showFocusSquare(at point: CGPoint, width: CGFloat, color: UIColor) {
        
        let focusLayerName = "focusLayerName"
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                if layer.name == focusLayerName {
                    layer.removeFromSuperlayer()
                }
            }
        }
        // create a box layer
        let width = width
        let box = CAShapeLayer.init()
        box.frame = CGRect(x: point.x - width/2, y: point.y - width/2, width: width, height: width)
        box.borderWidth = 1
        box.borderColor = color.cgColor
        box.name = focusLayerName
        self.layer.addSublayer(box)
        
        // animation
        let alphaAnimation = CABasicAnimation.init(keyPath: "opacity")
        alphaAnimation.fromValue = 1
        alphaAnimation.toValue = 0
        alphaAnimation.duration = 0.01
        alphaAnimation.beginTime = CACurrentMediaTime()
        
        let scaleAnimation = CABasicAnimation.init(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.2
        scaleAnimation.toValue = 1
        scaleAnimation.duration = 0.35
        scaleAnimation.beginTime = CACurrentMediaTime()
        
        box.add(alphaAnimation, forKey: nil)
        box.add(scaleAnimation, forKey: nil)
        
        //remove square
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            box.removeFromSuperlayer()
        }
    }
    
}
