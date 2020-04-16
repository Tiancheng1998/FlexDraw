//
//  ViewController.swift
//  draw
//
//  Created by Tony Wang on 11/26/19.
//  Copyright © 2019 Tony Wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // https://medium.com/better-programming/creating-uiviews-programmatically-in-swift-55f5d14502ae
    
    
    var canvas: DrawingView?
    
    @IBAction func reset(_ sender: Any) {
        guard let c = canvas else{ return }
        c.cleanUp()
        
    }
    
    @IBOutlet weak var editButton: UIButton!
    
    @IBAction func editMode(_ sender: Any) {
        guard let c = canvas else { return }
        if c.editMode {
            editButton.backgroundColor = UIColor.white
            editButton.setTitleColor(.systemBlue, for: .normal)
        } else {
            editButton.backgroundColor = UIColor.systemBlue
            editButton.setTitleColor(.white, for: .normal)
        }
        c.editMode = !c.editMode
    }
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var warning: UILabel!
    
    @IBAction func slide(_ sender: Any) {
        guard let c = canvas else { return }
        c.epsilon = Double(slider.value)
    }
    //    @IBAction func drawSpline(_ sender: Any) {
//        guard let c = canvas else { return }
//        c.renderSpline()
//
//    }
    
//    use loadView to programmatically define views, alternative to storyboarding.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        canvas = DrawingView()
        if let alarm = warning {
            canvas!.warning = alarm // before I figure out how to override initializers properly
        }

        guard let c = canvas else{ return }
//        slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        
        view.addSubview(c)
        c.backgroundColor = .white
        c.frame = view.frame
        view.sendSubviewToBack(c)
        
        
    }

}

