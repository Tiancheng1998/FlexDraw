//
//  LineSimp.swift
//  draw
//
//  Created by Tony Wang on 12/15/19.
//  Copyright © 2019 Tony Wang. All rights reserved.
//

import Foundation
import UIKit


struct Vector {
    let x: Double
    let y: Double

    static func vectorSubtract(v1: Vector, v2: Vector) -> Vector {
        return Vector(x: v1.x-v2.x, y: v1.y-v2.y)
    }
    
    static func constMultiply(c: Double, v1: Vector) -> Vector {
        return Vector(x: c*v1.x, y: c*v1.y)
    }
    
    static func dot(v1: Vector, v2: Vector) -> Double {
        return Double(v1.x * v2.x + v1.y * v2.y)
    }
    
    static func norm(v1: Vector) -> Double {
        return sqrt(dot(v1: v1, v2: v1)) // we do not need to take sqrt to compare
    }
    
    static func pts2Vecs(from points: [CGPoint]) -> [Vector] {
        var vecs = [Vector]()
        for p in points {
            vecs.append(Vector(x: Double(p.x), y: Double(p.y)))
        }
        return vecs
    }
    
    static func vecs2Pts(from vecs: [Vector]) -> [CGPoint] {
        var pts = [CGPoint]()
        for v in vecs {
            pts.append(CGPoint(x: Double(v.x), y: Double(v.y)))
        }
        return pts
    }
    
    static func orthogonalDist(from v1: Vector, onto v2: Vector) -> Double {
        let coeff = Vector.dot(v1: v1, v2: v2)/Vector.dot(v1: v2, v2: v2)
        let proj = Vector.constMultiply(c: coeff, v1: v2)
        return Vector.norm(v1: Vector.vectorSubtract(v1: v1, v2: proj))
    }

}


func Ramer_recurse(_ vecs: [Vector], epsilon: Double) -> [Vector]{
    if vecs.count <= 2 {
        return vecs
    } else {
        let straight = Vector.vectorSubtract(v1: vecs.last!, v2: vecs.first!)
        var farthestPt = 1
        var farthestDist: Double = 0
        for i in 1...vecs.count-2 {
            let d = Vector.orthogonalDist(from: Vector.vectorSubtract(v1: vecs[i], v2: vecs.first!), onto: straight)
            if d > farthestDist {
                farthestDist = d
                farthestPt = i
            }
        }
        if farthestDist < epsilon {
            return [vecs.first!, vecs.last!]
        } else {
            let left = Ramer_recurse(Array(vecs[...farthestPt]), epsilon: epsilon)
            let right = Ramer_recurse(Array(vecs[farthestPt...]), epsilon: epsilon)
            return left+Array(right[1...])
        }
    }
}


func Ramer_Douglas_Peucker(points: [CGPoint], epsilon :Double) -> [CGPoint] {
    let vecs = Vector.pts2Vecs(from: points)
    let simplified = Ramer_recurse(vecs, epsilon: epsilon)
    return Vector.vecs2Pts(from: simplified)
}
