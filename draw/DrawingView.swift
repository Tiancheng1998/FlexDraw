//
//  DrawingView.swift
//  draw
//
//  Created by Tony Wang on 11/28/19.
//  Copyright © 2019 Tony Wang. All rights reserved.
//

import Foundation
import UIKit
import Accelerate


struct LineSegment {
    var points = [CGPoint]()
    var c:CGColor?
}


class DrawingView: UIView {
    
    
    var touchPoints = [CGPoint]()
    let detectRadiusSquared = 12.00
    var splines = [Spline]()
    var epsilon = 0.5
    var warning: UILabel?
    var editMode = false
    var selectedControl: (Int, Int)?
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if editMode {
            guard let loc = touches.first?.location(in: nil) else { return }
            var closestPointIndex: (Int, Int)?
            var closestDist = Double.infinity
            for (i,spline) in splines.enumerated() {
                for (j,control) in spline.originalPoints.enumerated() {
                    let controlToContactVector = Vector.vectorSubtract(v1: Vector(x: Double(control.x), y: Double(control.y)), v2: Vector(x: Double(loc.x), y: Double(loc.y)))
                    let dist = Vector.norm(v1: controlToContactVector)
                    if  closestDist > dist {
                        closestDist = dist
                        closestPointIndex = (i,j)
                    }
                }
            }
            guard let closestP = closestPointIndex else {return}
            if closestDist < detectRadiusSquared {
                selectedControl = closestP
                return
            } else {
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if editMode {
            guard let selected = selectedControl else {
                return
            }
            guard let loc = touches.first?.location(in: nil) else { return }
            splines[selected.0].originalPoints[selected.1] = loc
            splines[selected.0].recompute()
            setNeedsDisplay()
        } else {
            guard let loc = touches.first?.location(in: nil) else { return }
            touchPoints.append(loc)
            setNeedsDisplay()
        }
    }
    
    // make the spline and render it according to the touch points sampled on the current drawing path when the current touch ends.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if editMode {
            selectedControl = nil
        } else {
            guard let w = warning else { return }
            if touchPoints.count < 2 {
                w.isHidden = false
                touchPoints = [CGPoint]()
            } else {
                w.isHidden = true
                let simplifieds = Ramer_Douglas_Peucker(points: touchPoints, epsilon: epsilon)
                renderSpline(on: simplifieds)
            }
        }
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        
        // render the splines
        for spline in splines {
            context.setStrokeColor(UIColor.black.cgColor)
            for c in spline.curves {
                context.move(to: c.ctr1)
                context.addCurve(to: c.ctr4, control1: c.ctr2, control2: c.ctr3)
            }
            context.strokePath()
            UIColor.red.setFill()
            for p in spline.originalPoints {
                context.addArc(center: p, radius: 3, startAngle: 0, endAngle: CGFloat(2*Float.pi), clockwise: false)
                context.fillPath()
            }
            
        }
        
        context.setStrokeColor(UIColor.black.cgColor)
        // render the touch points on the current drawing path.
        for (i,tp) in touchPoints.enumerated() {
            if i == 0 {
                context.move(to: tp)
            } else {
                context.addLine(to: tp)
            }
        }
        context.strokePath()
        
//        UIColor.red.setStroke()
//        for (i,tp) in simplifieds.enumerated() {
//            if i == 0 {
//                context.move(to: tp)
//            } else {
//                context.addLine(to: tp)
//            }
//        }
//
//        context.strokePath()
    }
    
    
    func renderSpline(on simplifieds: [CGPoint]) {
        let spline = Spline(pts: simplifieds)
        
        splines.append(spline)
        touchPoints = [CGPoint]()
        setNeedsDisplay()
    }
    
    // clean up all splines on the screen and clean up related data. Triggered when the trash can logo is taped.
    func cleanUp(){
        touchPoints = [CGPoint]()
        splines = [Spline]()
        selectedControl = nil
        setNeedsDisplay()
    }
}
