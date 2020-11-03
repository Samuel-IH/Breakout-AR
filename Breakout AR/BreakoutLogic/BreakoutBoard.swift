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
    
    fileprivate var ball = SCNNode()
    var paddle = SCNNode()
    var ballSpeed = Float(0.1)
    
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
        
        //create the "bounds"
        let boundGeom = SCNCylinder(radius: withSize/100, height: withSize)
        let boundCollider = SCNBox(width: withSize/100, height: withSize, length: withSize, chamferRadius: 0)
        var boundNode = SCNNode(geometry: boundGeom)
        boundNode.physicsBody = .init(type: .static, shape: .init(geometry: boundCollider, options: nil))
        boundNode.physicsBody?.restitution = 1
        
        //left wall
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, 0, 0)
        boundNode.position = SCNVector3(0, 0, withSize/2)
        self.rootNode.addChildNode(boundNode)
        
        //right wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, 0, 0)
        boundNode.position = SCNVector3(withSize, 0, withSize/2)
        self.rootNode.addChildNode(boundNode)
        
        //back wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, CGFloat(90).degreesToRadians, 0)
        boundNode.position = SCNVector3(withSize/2, 0, 0)
        self.rootNode.addChildNode(boundNode)
        
        //front wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, CGFloat(90).degreesToRadians, 0)
        boundNode.position = SCNVector3(withSize/2, 0, withSize)
        self.rootNode.addChildNode(boundNode)
        
        //MARK: Create the paddle
        let paddleGeom = SCNBox(width: withSize/5, height: withSize/32, length: withSize/32, chamferRadius: 0)
        let paddleNode = SCNNode(geometry: paddleGeom)
        paddleNode.physicsBody = .init(type: .kinematic, shape: .init(geometry: paddleGeom, options: nil))
        paddleNode.position = .init(withSize/2, 0, withSize)
        self.rootNode.addChildNode(paddleNode)
        self.paddle = paddleNode
        
        
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
        ballNode.physicsBody?.velocity = SCNVector3(0, 0, -0.1)
        ballNode.physicsBody?.damping = 0
        ballNode.position = .init(withSize/2, 0, withSize/2)
        
        self.rootNode.addChildNode(ballNode)
        self.ball = ballNode
        
        //MARK: Configure the physics
        
        self.physicsWorld.gravity = .init(0, 0, 0)
        self.physicsWorld.contactDelegate = self
        
        //constraint to lock the ball
        let ballLock = SCNTransformConstraint(inWorldSpace: false) {
            node, matrix in
            guard node.physicsBody != nil else { return matrix }
            
            let n = SCNNode()
            n.transform = matrix
            n.position.y = 0
            node.transform = n.transform
            // prevent the ball from moving up or down, even if we wipe the y value of the transform above
            // the ball can still have a velocity in the y axis that will diminish the overall speed of the ball
            node.physicsBody!.velocity.y = 0
            // prevent the ball from moving sideways too much
            node.physicsBody!.velocity.x = min(node.physicsBody!.velocity.x, 0.5)
            node.physicsBody!.velocity.x = max(node.physicsBody!.velocity.x, -0.5)
            // re-write the length of this vector, to enforce our desired speed
            let vel = node.physicsBody!.velocity
            let direction = vel / vel.length
            node.physicsBody!.velocity = direction * self.ballSpeed
            // remove any angular velocity, ball spinning looks a little weird in a gravity-free environment
            node.physicsBody!.angularVelocity = .init(0, 0, 0, 0)
            
            // finally, return the transform
            return n.transform
        }
        self.ball.constraints = [ballLock]
        
        
        
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


extension BreakoutBoard: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        
        //first, make sure the ball is involved
        guard contact.nodeA == ball || contact.nodeB == ball else { return }
        
        //second, we "normalize" the contact, so we don't have to write two big if statements
        var other = contact.nodeA
        if contact.nodeA == ball {
            other = contact.nodeB
        }
        
        
    }
    
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}

extension SCNVector3 {
    /// Returns the length of the vector
    var length: Float {
        return sqrtf(self.x * self.x + self.y * self.y + self.z * self.z)
    }
}

func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    return SCNVector3(rhs * lhs.x, rhs * lhs.y, rhs * lhs.z)
}

func /(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    return SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
}
