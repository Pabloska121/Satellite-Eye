import ARKit
import Combine
import RealityKit
import SwiftUI

class CustomARView: ARView {
    @ObservedObject var satelliteInfo: SatelliteInfo // Observing SatelliteInfo
    private var anchorEntity: AnchorEntity?
    private var offScreenPoint: Entity?
    private var cancellables = Set<AnyCancellable>()

    required init(frame frameRect: CGRect) {
        self.satelliteInfo = SatelliteInfo() // Initialize satelliteInfo here
        super.init(frame: frameRect)
        configureSession()
        setupBindings()  // Setup bindings
    }

    required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, satelliteInfo: SatelliteInfo) {
        self.satelliteInfo = satelliteInfo
        super.init(frame: frame)
        configureSession()
        setupBindings()
    }

    private func configureSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.isAutoFocusEnabled = false
        configuration.environmentTexturing = .none
        session.run(configuration)
    }

    private func setupBindings() {
        satelliteInfo.$position
            .sink { [weak self] newPosition in
                guard let self = self else { return }
                if let position = newPosition {
                    self.updateSatelliteMarker(with: position)
                }
            }
            .store(in: &cancellables)
    }

    private func updateSatelliteMarker(with position: SatellitePosition) {
        let azimuth = position.azimut
        let elevation = position.elevationAngle
        let rad2grad = Double.pi / 180
        let distance: Double = 150.0
        let x = Float(distance * sin(azimuth * rad2grad) * cos(elevation * rad2grad))
        let y = Float(distance * sin(elevation * rad2grad))
        let z = -Float(distance * cos(azimuth * rad2grad) * cos(elevation * rad2grad))

        let newPosition = SIMD3<Float>(x, y, z)
        if let anchor = anchorEntity {
            anchor.position = newPosition  // Update existing anchor position
            anchor.look(at: SIMD3<Float>(0, 0, 0), from: anchor.position, relativeTo: nil)
        } else {
            let anchorEntity = AnchorEntity(world: newPosition)
            self.anchorEntity = anchorEntity
            scene.addAnchor(anchorEntity)

            // Add the circle to the anchor
            let circle = generateDecorativeCircle(radius: 10.0)
            anchorEntity.addChild(circle)

            // Rotate circle to face the user
            let up = SIMD3<Float>(0, 1, 0)
            let forward = normalize(SIMD3<Float>(-newPosition.x, -newPosition.y, -newPosition.z))
            anchorEntity.orientation = simd_quatf(from: up, to: forward)
        }

        // Check if the circle is off-screen and print results
        checkIfCircleIsOffScreen()
    }

    private func checkIfCircleIsOffScreen() {
        guard let anchorEntity = anchorEntity else { return }

        let sceneView = ARSCNView(frame: bounds)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        sceneView.pointOfView?.addChildNode(cameraNode)

        let sphereNode = SCNNode()
        print(anchorEntity)
        sphereNode.position = SCNVector3(anchorEntity.position.x, anchorEntity.position.y, anchorEntity.position.z)

        DispatchQueue.main.async {
            if sceneView.isNode(sphereNode, insideFrustumOf: cameraNode) {
                print("Satellite is in the center of the screen.")
            } else {
                print("Satellite is off the center or not visible.")
            }
        }
    }

    private func generateDecorativeCircle(radius: Float) -> Entity {
        let parentEntity = Entity()
        let dotCount = 25
        let dotSize: Float = 0.5

        // Create dots on the edge of the circle
        for i in 0..<dotCount {
            let angle = Float(i) * (2 * .pi / Float(dotCount))
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            let dot = MeshResource.generateSphere(radius: dotSize)
            let material = UnlitMaterial(color: .white) // Always visible, even in the dark

            let dotEntity = ModelEntity(mesh: dot, materials: [material])
            dotEntity.position = SIMD3<Float>(x, y, 0)

            parentEntity.addChild(dotEntity)
        }

        return parentEntity
    }
}
