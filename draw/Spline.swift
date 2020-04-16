//
//  Spline.swift
//  draw
//
//  Created by Tony Wang on 12/1/19.
//  Copyright © 2019 Tony Wang. All rights reserved.
//

import Foundation
import UIKit
import Accelerate


/*
 a cubic bezier curve is defined by four control points. the first and fourth points are the end points of the curve
 */
struct Curve {
    var ctr1: CGPoint
    var ctr2: CGPoint
    var ctr3: CGPoint
    var ctr4: CGPoint
}


/**
 The spline class models a single spline. A natural cubic spline consists of a sequence of cubic bezier curves concatenated. The first and second derivatives of two neighboring curves agree on the point of concatenation. Besides, the second derivatives of the two end points of a spline is set to zero. This means for any set of n points, we can find a unique natural cubic spline that goes through all n points. The initializer takes in a set of points and calls the interpolate function to find the set of curves which defines the spline. The spline goes through all points passed in the initializer.
 */
class Spline {
    var curves = [Curve]()
    var originalPoints: [CGPoint]
    
    
    init(pts: [CGPoint]) {
        originalPoints = pts
        interpolate(pts)
    }
    
    func recompute() {
        curves = [Curve]()
        interpolate(originalPoints)
    }
    
    // computes the time length for each segment based on distance.
    private func timeLenForSegmentsFromDist(on pts: [CGPoint]) -> [Double] {
        var tLen = [Double]()
        for i in 1...pts.count-1{
            let prev = Vector(x: Double(pts[i-1].x), y: Double(pts[i-1].y))
            let curr = Vector(x: Double(pts[i].x), y: Double(pts[i].y))
            tLen.append(sqrt(Vector.norm(v1: Vector.vectorSubtract(v1: prev, v2: curr)))) // calculate the euclidian distance
        }
        return tLen
    }
    
    /**
        This computes the derivative of the curve parameter with respect to the time variable for each segement. We use the derivative for the change of variable. The parameter for each curve ranges from 0 to 1 and is a function of time t. More specifically the curve parameter variable k(t) = (t - t_{i}) / (t_{i+1} - t_{i}).  Thus for each curve the derivative k^(prime)(t) =  1 / (t_{i+1} - t_{i}). Hence equals to 1/ interval_length.
     */
    
    private func timeDerivative(on intervals: [Double]) -> [Double] {
        return intervals.map{1 / $0}
    }
    
    
    /*
     The interpolate function solves the following problem:
     given a set of n points, find all 2(n-1) intermediate control points of the n-1 cubic curves that go through these n points.
     More specifically for x componenent and y component, it solves Ax=b where
     A = 2 -1 0 ......................................0
         0  k^{prime}_{0} k^{prime}_{1} 0 ............0
         0  0 0 k^{prime}_{1} k^{prime}_{2} ..........0
         .
         .
         0  0 0 0 0.......k^{prime}_{n-2} k^{prime}_{n-1} 0
         (k^{prime}_{0})^2 -2(k^{prime}_{0})^2 2(k^{prime}_{1})^2 -(k^{prime}_{1})^2 0..........0
         0  0 (k^{prime}_{1})^2 -2(k^{prime}_{1})^2 2(k^{prime}_{2})^2 -(k^{prime}_{2})^2 ......0
         .
         .
         .
         0 0 0 .......k^{prime}_{n-2} -2k^{prime}_{n-2} 2k^{prime}_{n-1} -k^{prime}_{n-1}
         0 0 0 ...........-1  2
      
      b = [x0 (k^{prime}_{0} + k^{prime}_{1})x1 (k^{prime}_{1} + k^{prime}_{2})x2 ... (k^{prime}_{n-1}+k^{prime}_{n-2})xn-2 (k^{prime}_{1}^2 - k^{prime}_{0}^2)x1 (k^{prime}_{2}^2 - k^{prime}_{1}^2)x2 .... (k^{prime}_{n-2}^2 - k^{prime}_{n-1}^2)xn-2 xn-1]
      The solution x should contain the x coordinate of all 2(n-1) intermediate control points.
     It leverages the Accelerate swift framework for matrix computation.
     */
    private func interpolate(_ touchPoints: [CGPoint]) {
        let intervals = timeLenForSegmentsFromDist(on: touchPoints)
        let derivatives = timeDerivative(on: intervals)
        
        // make vector b for both x and y. It is a dense vector
       var bX = [Double]()
       var bY = [Double]()
       let num_pts = touchPoints.count
       
       for (i,p) in touchPoints.enumerated() {
           if i == num_pts-1 {
               break
           }
           if i == 0 { // entries on b that sets the second derivative of the stating point 0
               bX.append(Double(p.x))
               bY.append(Double(p.y))
           } else { // entries on b to line up the first derivative
               bX.append(Double(p.x) * (derivatives[i-1] + derivatives[i]))
               bY.append(Double(p.y) * (derivatives[i-1] + derivatives[i]))
           }
       }
        if num_pts > 2 { // entries on b to line up the second derivative
            for i in 1...(num_pts-2) {
                bX.append(Double(touchPoints[i].x) * (pow(derivatives[i], 2) - pow(derivatives[i-1],2)))
                bY.append(Double(touchPoints[i].y) * (pow(derivatives[i], 2) - pow(derivatives[i-1], 2)))
            }
        }
        
       // entries on b that sets the second derivative of the end point 0
       bX.append(Double(touchPoints[num_pts-1].x))
       bY.append(Double(touchPoints[num_pts-1].y))
       
       let bX_vec = DenseVector_Double(count: Int32(2*num_pts-2), data: &bX)
       let bY_vec = DenseVector_Double(count: Int32(2*num_pts-2), data: &bY)
       
       // build the matrix. It is a sparse matrix
       var row: [Int32] = [0, 0]
       var col: [Int32]  = [0, 1]
       var values: [Double] = [2, -1] // entries on matrix A that sets the second derivative of the stating point 0
        
        if num_pts > 2 {
            for i in 1...num_pts-2 { // entries on matrix A to line up the first derivative
                row.append(Int32(i))
                row.append(Int32(i))
                col.append(Int32(2*i-1))
                col.append(Int32(2*i))
                values.append(derivatives[i-1])
                values.append(derivatives[i])
            }
            for i in 0...num_pts-3 { // entries on matrix A line up the second derivative
                row.append(Int32(i + num_pts-1))
                row.append(Int32(i + num_pts-1))
                row.append(Int32(i + num_pts-1))
                row.append(Int32(i + num_pts-1))
                col.append(Int32(2*i))
                col.append(Int32(2*i+1))
                col.append(Int32(2*i+2))
                col.append(Int32(2*i+3))
                values.append(pow(derivatives[i],2))
                values.append(-2 * pow(derivatives[i],2))
                values.append(2 * pow(derivatives[i+1],2))
                values.append(-pow(derivatives[i+1],2))
            }
        }
       
       
        // entries on matrix A that sets the second derivative of the end point 0
       row.append(Int32(num_pts - 1 + num_pts - 2))
       row.append(Int32(num_pts - 1 + num_pts - 2))
       col.append(Int32(num_pts - 1 + num_pts - 2 - 1))
       col.append(Int32(num_pts - 1 + num_pts - 2))
       values.append(-1)
       values.append(2)
       
       var attributes = SparseAttributes_t()
       attributes.kind = SparseOrdinary
       
       let A = SparseConvertFromCoordinate(Int32(2*num_pts-2), Int32(2*num_pts-2), row.count, 1, attributes, &row, &col, values)
       
       // QR factorizarion for accelerated computation of system of equations defined by sparse matrix
       let QR = SparseFactor(SparseFactorizationQR, A) // why can structs be used this way?
       
       // call the solve
       var ctrX = [Double](repeating: 0, count: 2*num_pts-2)
       var ctrY = [Double](repeating: 0, count: 2*num_pts-2)
       let ctrX_vec = DenseVector_Double(count: Int32(2*num_pts-2), data: &ctrX)
       let ctrY_vec = DenseVector_Double(count: Int32(2*num_pts-2), data: &ctrY)
       SparseSolve(QR, bX_vec, ctrX_vec)
       SparseSolve(QR, bY_vec, ctrY_vec)
        
       // construct the cubic curves using the orginial points and the control points computed.
        for i in 0...2*num_pts-3 {
            if i % 2 == 0 {
                let n_curve = Int(i/2)
                let c = Curve(ctr1: touchPoints[n_curve], ctr2: CGPoint(x: ctrX_vec.data[i], y: ctrY_vec.data[i]), ctr3: CGPoint(x: ctrX_vec.data[i+1], y: ctrY_vec.data[i+1]), ctr4: touchPoints[n_curve+1])
                curves.append(c)
            }
        }
    }
}
