//
//  ViewController.swift
//  ARTest2
//
//  Created by steven on 2021/3/29.
//

import UIKit
import SceneKit
import ARKit
class ViewController: UIViewController {
    
    var sceneView: ARSCNView!
    var faceLabel = UILabel()
    var analysis = ""
    var isLeft = false
    var isRight = false
    var isUp = false
    var isDown = false
    let noseOptions = ["nose_1", "nose_2", "nose_3", "nose_4"]
    let eyeOptions = ["eye_1", "eye_2", "eye_3"]
    let mouthOptions = ["mouth_1", "mouth_2", "mouth_3", "mouth_4"]
    let hatOptions = ["hat_1", "hat_2", "hat_3", "hat_4"]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView()
        sceneView.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        self.view.addSubview(sceneView)
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    
    
    /// 張嘴巴
    func expression(anchor: ARFaceAnchor) {
        let jawOpen = anchor.blendShapes[.jawOpen]
        if jawOpen?.decimalValue ?? 0.0 > 0.1 {
            DispatchQueue.main.async {
                self.view.showToast(text: "張嘴巴")
            }
        }
    }
    
    /// 檢查搖頭
    func checkShakingHead() {
        if isLeft && isRight {
            DispatchQueue.main.async {
                self.view.showToast(text: "搖頭成立")
            }
            
            isLeft = false
            isRight = false
        }
    }
    
    /// 檢查點頭
    func checkNod() {
        if isUp && isDown {
            DispatchQueue.main.async {
                self.view.showToast(text: "點頭成立")
            }
            
            isUp = false
            isDown = false
        }
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        for (feature, indices) in zip(features, featureIndices) {
            let child = node.childNode(withName: feature, recursively: false) as? ImageNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
            
            switch feature {
                case "leftEye":
                    let scaleX = child?.scale.x ?? 1.0
                    let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                    child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
                case "rightEye":
                    let scaleX = child?.scale.x ?? 1.0
                    let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                    child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
                case "mouth":
                    let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
                    child?.scale = SCNVector3(1.2, 0.8 + jawOpenValue, 1.2)
                case "hat":
                    child?.scale = SCNVector3(1.0, 1.0, 1.0)
                    
                default:
                    break
            }
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
//        var node = SCNNode(geometry: faceMesh)
//        var clearMaterial = SCNMaterial(color: .clear)
//        node.geometry!.materials = [clearMaterial]


    // 臉部圖片
    guard let faceAnchor = anchor as? ARFaceAnchor,
          let device = sceneView.device else { return nil }
    let faceGeometry = ARSCNFaceGeometry(device: device)
    let node = SCNNode(geometry: faceGeometry)
    node.geometry?.firstMaterial?.fillMode = .lines

    node.geometry?.firstMaterial?.transparency = 0.0
    let noseNode = ImageNode(with: noseOptions)
    noseNode.name = "nose"
    node.addChildNode(noseNode)

    let leftEyeNode = ImageNode(with: eyeOptions)
    leftEyeNode.name = "leftEye"
    leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
    node.addChildNode(leftEyeNode)

    let rightEyeNode = ImageNode(with: eyeOptions)
    rightEyeNode.name = "rightEye"
    node.addChildNode(rightEyeNode)

    let mouthNode = ImageNode(with: mouthOptions)
    mouthNode.name = "mouth"
    node.addChildNode(mouthNode)

    let hatNode = ImageNode(with: hatOptions)
    hatNode.name = "hat"
    node.addChildNode(hatNode)

    updateFeatures(for: node, using: faceAnchor)

    
    // 臉上矛點
//        let clearMaterial = SCNMaterial(color: .link)
//        node.geometry!.materials = [clearMaterial]
//        node.geometry?.firstMaterial?.fillMode = .lines
//        for x in 0..<1220 {
//            let text = SCNText(string: "\(x)", extrusionDepth: 1)
//            let txtnode = SCNNode(geometry: text)
//            txtnode.scale = SCNVector3(x: 0.0002, y: 0.0002, z: 0.0002)
//            txtnode.name = "\(x)"
//            node.addChildNode(txtnode)
//            txtnode.geometry?.firstMaterial?.fillMode = .fill
//        }
//
    
    return node
}
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)
            
            DispatchQueue.main.async {
                self.faceLabel.text = self.analysis
            }
        }
        
        // 搖頭偵測
        if node.orientation.y > 0.2 {
            isLeft = true
        } else if node.orientation.y < -0.2 {
            isRight = true
        }
        checkShakingHead()

        // 點頭偵測
        if node.orientation.x > 0.2 {
            isUp = true
        } else if node.orientation.x < -0.03 {
            isDown = true
        }
        checkNod()
        
        /*
        // 眼睛看的地方
        if let faceAnchor = anchor as? ARFaceAnchor,
           let faceGeo = node.geometry as? ARSCNFaceGeometry {
            print(faceAnchor.lookAtPoint.y)
            print(faceAnchor.lookAtPoint.x)
        }
        */
        
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        
        // 臉部圖片
        updateFeatures(for: node, using: faceAnchor)
        
        // 臉上矛點
//        for x in 0..<1220 {
//            let child = node.childNode(withName: "\(x)", recursively: false)
//            child?.position = SCNVector3(faceAnchor.geometry.vertices[x])
//        }
//
//        faceGeometry.update(from: faceAnchor.geometry)
        
    }
}

extension SCNMaterial {
    convenience init(color: UIColor) {
        self.init()
        diffuse.contents = color
    }
    convenience init(image: UIImage) {
        self.init()
        diffuse.contents = image
    }
}
