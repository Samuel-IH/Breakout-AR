//
//  ViewController.swift
//  Breakout AR
//
//  Created by SamuelIH on 10/31/20.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var debugBall = SCNNode(geometry: SCNSphere(radius: 0.01))
    private var viewportSize = CGSize()
    
    private var lastMoveTime = 0.0
    
    var board = BreakoutBoard()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewportSize = self.sceneView.bounds.size
        handPoseRequest.maximumHandCount = 1
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showPhysicsShapes]
        // Set the scene to the view
        sceneView.scene = board
        
        let node = SCNNode(geometry: SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0))
        node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: node))
        sceneView.pointOfView?.addChildNode(node)
        
        sceneView.scene.rootNode.addChildNode(debugBall)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
extension ViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if (lastMoveTime == 0) { lastMoveTime = time }
        defer {
            lastMoveTime = time
        }
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: capturedImage, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            let points = try observation.recognizedPoints(.all)

            guard let wristPoint = points[.wrist] else {
                return
            }
            // Ignore low confidence points.
            guard wristPoint.confidence > 0.3 else {
                return
            }
            let v = self.viewportSize
            // Convert points from Vision coordinates to AVFoundation coordinates.
            let wrist = CGPoint(x: wristPoint.location.y * v.width, y: wristPoint.location.x * v.height)
            
            guard let wrist3D = self.sceneView.unprojectPoint(wrist, ontoPlane: simd_float4x4(sceneView.scene.rootNode.transform)) else {
                return
            }
            var difference = self.board.paddle.position.x - wrist3D.x
            
            let lerpSpeed = 10.0 //speed of the lerp, higher numbers mean more immediate results, too high and the paddle may not be smooth
            let lerp = min((time - lastMoveTime) * lerpSpeed, 1) // we have to clamp the results to 1 to prevent the potential of overdriving the lerp
            difference *= Float(lerp)// lerp our difference before we apply it below
            self.board.paddle.position.x -= difference
            self.debugBall.simdPosition = wrist3D
        } catch {
            print(error.localizedDescription)
        }
    }

}
