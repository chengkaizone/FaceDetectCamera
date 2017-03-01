//
//  ViewController.swift
//  FaceDetectCamera
//
//  Created by sy on 2017/3/1.
//  Copyright © 2017年 sy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let camView = CustomCameraView(service: CameraService(position: .front))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        camView.frame = view.bounds
        view.addSubview(camView)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camView.startSession()
        
        camView.detectFaceImages { _ in
            
        }
        
    }

}

