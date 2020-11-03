//
//  BreakoutBrick.swift
//  Breakout AR
//
//  Created by SamuelIH on 11/3/20.
//

import Foundation
import SceneKit

// a helper "func"
/// Creates and returns a new material and geometry.
fileprivate let brickGeom: (UIColor)->SCNGeometry = {color in
    let mat = SCNMaterial()
    mat.lightingModel = .physicallyBased
    let brickGeom = SCNBox(width: BreakoutBoard.boardSize/16, height: BreakoutBoard.boardSize/32, length: BreakoutBoard.boardSize/32, chamferRadius: 0)
    mat.diffuse.contents = color
    mat.roughness.contents = UIColor.black
    mat.metalness.contents = UIColor.black
    brickGeom.firstMaterial = mat
    return brickGeom
}

class BreakoutBrick: SCNNode {
    //MARK: Static Geometry Constants
    //    These are intentionally made as constants, and generated only once.
    // Generating these only once allows us to associate each material and geometry instance with multiple nodes.
    // This saves memory and is very good in practice.
    fileprivate static let redBrickGeom: SCNGeometry = {
        return brickGeom(.red)
    }()
    fileprivate static let orangeBrickGeom: SCNGeometry = {
        return brickGeom(.orange)
    }()
    fileprivate static let greenBrickGeom: SCNGeometry = {
        return brickGeom(.green)
    }()
    fileprivate static let yellowBrickGeom: SCNGeometry = {
        return brickGeom(.yellow)
    }()
    
    enum BrickType {
        case red
        case orange
        case green
        case yellow
    }
    
    /// Bricktype is only used as a shorthand for determining the type of this brick. The type itself has no effect on the properties of the brick, such as color, points, etc.
    let type: BrickType
    //MARK: INIT
    //The init here should be used to customize the bricks on the "brick" level, any customization that is specific to one type of brick should instead be set up in the initializers below
    init(geometry: SCNGeometry, type: BrickType) {
        self.type = type
        super.init()
        self.geometry = geometry
        self.physicsBody = .init(type: .kinematic, shape: .init(geometry: geometry, options: nil))
        self.physicsBody?.restitution = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// conveniance init
/// Since these are computed variables, and are re-evaluated each time they are called, this will insure that each call to them provides a new node instance.
extension BreakoutBrick {
    
    static var red: BreakoutBrick {
        get {
            let brick = BreakoutBrick(geometry: Self.redBrickGeom, type: .red)
            return brick
        }
    }
    static var orange: BreakoutBrick {
        get {
            let brick = BreakoutBrick(geometry: Self.redBrickGeom, type: .orange)
            return brick
        }
    }
    static var green: BreakoutBrick {
        get {
            let brick = BreakoutBrick(geometry: Self.redBrickGeom, type: .green)
            return brick
        }
    }
    static var yellow: BreakoutBrick {
        get {
            let brick = BreakoutBrick(geometry: Self.redBrickGeom, type: .yellow)
            return brick
        }
    }
}
