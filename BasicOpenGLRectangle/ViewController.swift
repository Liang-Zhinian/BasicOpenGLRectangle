//
//  ViewController.swift
//  BasicOpenGLRectangle
//
//  Created by Krzysztof Deneka on 04.08.2017.
//  Copyright © 2017 biz.blastar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.lightGray
        
        let frame = UIScreen.main.bounds
        let _glView = OpenGLView(frame: CGRect(x: 10, y: 10, width: frame.size.width - 20.0, height: frame.size.height - 20.0))
        
        self.view.addSubview(_glView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

