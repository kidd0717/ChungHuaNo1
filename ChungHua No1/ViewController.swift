//
//  ViewController.swift
//  ChungHua No1
//
//  Created by MMY on 06/07/2017.
//  Copyright © 2017 MMY. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let VGG16Model = VGG16()
    let queue = { () -> OperationQueue in
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    let audioPlayer = { () -> AVAudioPlayer in
        let audioPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "music", withExtension: "mp3")!)
        audioPlayer.numberOfLoops = -1
        return audioPlayer
    }()
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
       
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let image = frame.capturedImage
        
        if queue.operationCount != 0 {
            return
        }
        
        queue.addOperation { () -> Void in
            do {
                let prediction = try self.VGG16Model.prediction(image: self.resize(pixelBuffer: image)!)
                DispatchQueue.main.async {
                    if prediction.classLabel.contains("toaster") {
                        self.showDragon(currentFrame: frame)
                    }
                }
            }
            catch let error as NSError {
                fatalError("Unexpected error ocurred: \(error.localizedDescription).")
            }
        }
    }
    
    func resize(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let imageSide = 224
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.applying(transform).cropping(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
        let ciContext = CIContext()
        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, kCVPixelFormatType_32ARGB, nil, &resizeBuffer)
        ciContext.render(ciImage, to: resizeBuffer!)
        return resizeBuffer
    }
    
    func showDragon(currentFrame: ARFrame) {
        if isPlaying {
            return
        }
        
        isPlaying = true
        //create plane
        let dragon = UIImage(named: "dragon2.png")
        
        let imagePlane = SCNPlane(width: dragon!.size.width / 1000, height: dragon!.size.height / 1000)
        imagePlane.firstMaterial?.diffuse.contents = dragon
        imagePlane.firstMaterial?.lightingModel = .constant
        
        //add plane node
        let planeNode = SCNNode(geometry: imagePlane)
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        //transform the plane node
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1
        planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        //play music
        audioPlayer.play()
    }
}
