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
    static let boardSize: CGFloat = 0.3
    
    struct Masks {
        static let ball = 1 << 1
        static let bounds = 1 << 2
        static let brick = 1 << 3
    }
    
    fileprivate struct BrickClass {
        var color: UIColor
        var roughness = UIColor.gray
        var metalness = UIColor.black
    }
    
    fileprivate let bricks : [BreakoutBrick.BrickType] = [
        .red,
        .orange,
        .green,
        .yellow
    ]
    
    fileprivate var ball = SCNNode()
    var paddle = SCNNode()
    var ballSpeed = Float(0.1)
    var boardSize: CGFloat
    ///This node represents the entire board, you can move this node around to control the location of the board.
    var boardNode = SCNNode()
    
    override init() {
        
        self.boardSize = Self.boardSize
        
        super.init()
        
        
        //MARK: Create the board
        self.rootNode.addChildNode(boardNode)
        
        for (rowIndex, brickRow) in bricks.enumerated() {
            for i in 1...14 {
                /// Now we iterate through all the bricks, creating each row
                var brick: BreakoutBrick = .yellow
                switch brickRow {
                case .red:
                    brick = .red
                case .orange:
                    brick = .orange
                case .green:
                    brick = .green
                case .yellow:
                    brick = .yellow
                }
                brick.position = SCNVector3(boardSize / 14.0 * CGFloat(i), 0.0, boardSize / 28.0 * CGFloat(rowIndex))
                
                self.boardNode.addChildNode(brick)
            }
            
        }
        
        //create the "bounds"
        let boundGeom = SCNCylinder(radius: boardSize/100, height: boardSize)
        let boundCollider = SCNBox(width: boardSize/100, height: boardSize, length: boardSize, chamferRadius: 0)
        var boundNode = SCNNode(geometry: boundGeom)
        boundNode.physicsBody = .init(type: .kinematic, shape: .init(geometry: boundCollider, options: nil))
        boundNode.physicsBody?.categoryBitMask = Self.Masks.bounds
        boundNode.physicsBody?.collisionBitMask = Self.Masks.ball
        boundNode.physicsBody?.contactTestBitMask = Self.Masks.ball
        boundNode.physicsBody?.restitution = 1
        
        //left wall
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, 0, 0)
        boundNode.position = SCNVector3(0, 0, boardSize/2)
        self.boardNode.addChildNode(boundNode)
        
        //right wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, 0, 0)
        boundNode.position = SCNVector3(boardSize, 0, boardSize/2)
        self.boardNode.addChildNode(boundNode)
        
        //back wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, CGFloat(90).degreesToRadians, 0)
        boundNode.position = SCNVector3(boardSize/2, 0, 0)
        self.boardNode.addChildNode(boundNode)
        
        //front wall
        boundNode = boundNode.clone()
        boundNode.eulerAngles = SCNVector3(CGFloat(90).degreesToRadians, CGFloat(90).degreesToRadians, 0)
        boundNode.position = SCNVector3(boardSize/2, 0, boardSize)
        self.boardNode.addChildNode(boundNode)
        
        //MARK: Create the paddle
        let paddleGeom = SCNBox(width: boardSize/5, height: boardSize/32, length: boardSize/32, chamferRadius: 0)
        let paddleNode = SCNNode(geometry: paddleGeom)
        paddleNode.physicsBody = .init(type: .kinematic, shape: .init(geometry: paddleGeom, options: nil))
        paddleNode.physicsBody?.categoryBitMask = Self.Masks.bounds
        paddleNode.physicsBody?.collisionBitMask = Self.Masks.ball
        paddleNode.physicsBody?.contactTestBitMask = Self.Masks.ball
        paddleNode.position = .init(boardSize/2, 0, boardSize)
        self.boardNode.addChildNode(paddleNode)
        self.paddle = paddleNode
        
        
        //MARK: Create the ball
        let ballMat = SCNMaterial()
        ballMat.lightingModel = .physicallyBased
        ballMat.metalness.contents = UIColor.white
        ballMat.roughness.contents = UIColor.black
        ballMat.diffuse.contents = UIColor.white
        
        let ballGeom = SCNSphere(radius: boardSize/32)
        ballGeom.firstMaterial = ballMat
        
        let ballNode = SCNNode(geometry: ballGeom)
        ballNode.physicsBody = .init(type: .dynamic, shape: .init(geometry: ballGeom, options: nil))
        ballNode.physicsBody?.restitution = 1
        ballNode.physicsBody?.velocity = SCNVector3(0, 0, -0.1)
        ballNode.physicsBody?.damping = 0
        ballNode.physicsBody?.categoryBitMask = BreakoutBoard.Masks.ball
        ballNode.physicsBody?.contactTestBitMask = BreakoutBoard.Masks.brick | BreakoutBoard.Masks.bounds
        ballNode.physicsBody?.collisionBitMask = BreakoutBoard.Masks.brick | BreakoutBoard.Masks.bounds
        ballNode.position = .init(boardSize/2, 0, boardSize/2)
        
        self.boardNode.addChildNode(ballNode)
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
            
            // Convert the world space velocity to local velocity
            guard var localVelocity = node.parent?.convertVector(node.physicsBody!.velocity, from: nil) else {
                return n.transform
            }
            
            // prevent the ball from moving up or down. Even if we wipe the y value of the transform above,
            // the ball can still have a velocity in the y axis that will diminish the overall speed of the ball
            localVelocity.y = 0
            
            // the sideways velocity should never be greater than the forward-backward velocity
            // (as this would mean that the ball is bouncing from left to right, possibly endlessly)
            if (abs(localVelocity.x) > abs(localVelocity.z)) {
                let m : Float = (localVelocity.x < 0) ? -1 : 1
                localVelocity.x = localVelocity.z * m
            }
            
            // re-write the length of this vector, to enforce our desired speed
            let direction = localVelocity / localVelocity.length
            let finalLocalVelocity = direction * self.ballSpeed
            node.physicsBody!.velocity = node.parent!.convertVector(finalLocalVelocity, to: nil)
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
        
        if let brick = other as? BreakoutBrick {
            let brickBreak = SCNAction.sequence([.fadeOut(duration: 0.25), .removeFromParentNode()])
            brick.runAction(brickBreak)
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
