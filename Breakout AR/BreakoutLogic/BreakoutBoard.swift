//
//  File.swift
//  Breakout AR
//
//  Created by SamuelIH on 10/31/20.
//

import Foundation
import SceneKit
// no arkit import here, this file is for game logic ONLY!


class BreakoutBoard: SCNScene {
    
    fileprivate struct BrickClass {
        var color: UIColor
        var roughness = UIColor.gray
        var metalness = UIColor.black
    }
    
    fileprivate let bricks : [BrickClass] = [
        .init(color: .red),
        .init(color: .orange),
        .init(color: .green),
        .init(color: .yellow)
    ]
    
    init(withSize: CGFloat = 0.3) {
        super.init()
        
        
        //MARK: Create the board
        for (rowIndex, brickRow) in bricks.enumerated() {
            /// The base material and base geom have to be defined per-brick, because they are instanced objects
            
            // base material
            let mat = SCNMaterial()
            mat.lightingModel = .physicallyBased
            
            // base geometry
            let brickGeom = SCNBox(width: withSize/16, height: withSize/32, length: withSize/32, chamferRadius: 0)
            
            //customize the material and assign it to the geom
            mat.diffuse.contents = brickRow.color
            mat.roughness.contents = brickRow.roughness
            mat.metalness.contents = brickRow.metalness
            brickGeom.firstMaterial = mat
            
            
            for i in 1...14 {
                /// Now we iterate through all the bricks, creating each row
                let brick = SCNNode(geometry: brickGeom)
                brick.position = SCNVector3(withSize / 14.0 * CGFloat(i), 0.0, withSize / 28.0 * CGFloat(rowIndex))
                brick.physicsBody = .init(type: .kinematic, shape: .init(geometry: brickGeom, options: nil))
                brick.physicsBody?.restitution = 1
                
                self.rootNode.addChildNode(brick)
            }
            
        }
        
        //MARK: Create the ball
        let ballMat = SCNMaterial()
        ballMat.lightingModel = .physicallyBased
        ballMat.metalness.contents = UIColor.white
        ballMat.roughness.contents = UIColor.black
        ballMat.diffuse.contents = UIColor.white
        
        let ballGeom = SCNSphere(radius: withSize/32)
        ballGeom.firstMaterial = ballMat
        
        let ballNode = SCNNode(geometry: ballGeom)
        ballNode.physicsBody = .init(type: .dynamic, shape: .init(geometry: ballGeom, options: nil))
        ballNode.physicsBody?.restitution = 1
        ballNode.position = .init(withSize/2, 0, withSize/2)
        
        self.rootNode.addChildNode(ballNode)
        
        //MARK: Configure the physics
        
        self.physicsWorld.gravity = .init(0, 0, 0)
        
        
        
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


