//
//  Beacon.swift
//  Breakout AR
//
//  Created by SamuelIH on 11/4/20.
//

import Foundation
import SceneKit

class BreakoutBeacon: SCNNode {
    
    var lookAt: SCNLookAtConstraint
    fileprivate var beacon: SCNNode
    init(withPoV: SCNNode?) {
        //create the constraint for the text
        lookAt = SCNLookAtConstraint(target: withPoV)
        lookAt.localFront = .init(0, 0, 1)
        lookAt.isGimbalLockEnabled = true
        
        beacon = SCNNode(geometry: SCNSphere(radius: 0.01))
        
        super.init()
        
        //create the text
        let text = SCNText(string: "Tap a flat surface to place the board\n\n\n\n", extrusionDepth: 0)
        text.font = UIFont(name: "Helvetica Neue", size: 16)!
        let textNode = SCNNode(geometry: text)
        var min = textNode.boundingBox.min
        var max = textNode.boundingBox.max
        let width = max.x - min.x
        textNode.pivot = SCNMatrix4MakeTranslation(width / 2, -0.01, 0)
        textNode.scale = .init(0.001, 0.001, 0.001)
        textNode.position.y = 0.01
        
        textNode.constraints = [lookAt]
        
        //create the arrow
        let arrow = SCNText(string: "↓", extrusionDepth: 0)
        arrow.font = UIFont(name: "Helvetica Neue", size: 40)!
        let arrowNode = SCNNode(geometry: arrow)
        min = arrowNode.boundingBox.min
        max = arrowNode.boundingBox.max
        let arrowWidth = max.x - min.x
        arrowNode.position.x = (width / 2) - arrowWidth
        
        
        //arrowNode.pivot = SCNMatrix4MakeTranslation(width / 2, 0, 0)
        textNode.addChildNode(arrowNode)
        //arrowNode.position.y = -0.01
        
        
        //create a disc
        let plate = SCNNode(geometry: SCNTorus(ringRadius: 0.08, pipeRadius: 0.002))
        plate.scale.y = 0//flattened circle
        
        //create the parent node
        
        beacon.addChildNode(textNode)
        beacon.addChildNode(plate)
        self.addChildNode(beacon)
    }
    fileprivate init(withBeacon: BreakoutBeacon) {
        self.beacon = withBeacon.beacon.clone()
        self.lookAt = withBeacon.lookAt
        super.init()
        self.addChildNode(beacon)
    }
    func cloneBeacon() -> BreakoutBeacon {
        return BreakoutBeacon(withBeacon: self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
