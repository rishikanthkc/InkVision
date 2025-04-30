import UIKit
import ARKit
import SceneKit
import AVKit
import Vision
import CoreML

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    private var videoPlayer: AVPlayer?
    private var classificationTimer: Timer?
    private var lastPlayedLandmark: String?
    
    private let videoURLs: [String: String] = [
        "Taj Mahal": "https://cdn.pixabay.com/video/2019/05/13/23592-337668424_medium.mp4",
        "Colosseum": "https://cdn.pixabay.com/video/2024/03/16/204384-924209301_medium.mp4",
        "Eiffel Tower": "https://cdn.pixabay.com/video/2024/12/25/248701_tiny.mp4",
        "Statue of Liberty": "https://cdn.pixabay.com/video/2015/11/25/1366-147055432_medium.mp4",
        "Golden Gate Bridge": "https://cdn.pixabay.com/video/2018/09/24/18392-291585315_small.mp4",
        "Leaning Tower Of Pisa": "https://cdn.pixabay.com/video/2022/04/19/114507-701051365_tiny.mp4",
    ]
    
    private let model: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            return try VNCoreMLModel(for: Landmark_Classifier(configuration: config).model)
        } catch {
            print("❌ Failed to load ML model: \(error)")
            return nil
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARConfiguration.isSupported else {
            print("❌ ARKit not supported")
            return
        }
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene = SCNScene()
        
        resetARSession()
        
        classificationTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(classifySceneFrame), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        videoPlayer?.pause()
        classificationTimer?.invalidate()
    }
    
    private func resetARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("✅ AR Session Reset")
    }
    
    @objc private func classifySceneFrame() {
        DispatchQueue.main.async {
            let snapshot = self.sceneView.snapshot()
            self.classifyImage(snapshot) { [weak self] landmarkName in
                guard let self = self else { return }
                
                if let landmark = landmarkName { // Landmark recognized
                    print("✅ Recognized Landmark: \(landmark)")
                    DispatchQueue.main.async {
                        self.displayVideo(for: landmark) // Play the video for the recognized landmark
                    }
                } else { // No landmark recognized
                    print("❌ No landmark recognized")
                    DispatchQueue.main.async {
                        self.removeExistingVideoOverlay() // Stop and remove any playing video
                    }
                }
            }
        }
    }
    
    private func classifyImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let model = model else {
            print("❌ ML Model not loaded")
            completion(nil)
            return
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("❌ Could not convert UIImage to CIImage")
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                print("❌ No results from ML model")
                completion(nil)
                return
            }
            
            if topResult.confidence > 0.9 {
                completion(topResult.identifier)
            } else {
                completion(nil)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform ML request: \(error)")
                completion(nil)
            }
        }
    }
    
    private func displayVideo(for landmark: String) {
        guard let videoSource = videoURLs[landmark] else {
            print("❌ No video source found for \(landmark)")
            return
        }
        
        if videoSource.hasPrefix("local:") {
            displayLocalVideo(for: landmark)
            return
        }
        
        guard let videoURL = URL(string: videoSource) else {
            print("❌ Invalid URL: \(videoSource)")
            return
        }
        
        playVideo(with: videoURL, for: landmark)
    }
    
    private func displayLocalVideo(for landmark: String) {
        guard let videoSource = videoURLs[landmark] else {
            print("❌ No video source found for \(landmark)")
            return
        }
        
        let fileName = String(videoSource.dropFirst(6))
        guard let videoURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("❌ Local video file not found: \(fileName)")
            return
        }
        
        playVideo(with: videoURL, for: landmark)
    }
    
    private func playVideo(with videoURL: URL, for landmark: String) {
        if landmark != lastPlayedLandmark { // New landmark detected
            removeExistingVideoOverlay()
            lastPlayedLandmark = nil
        }
        
        if landmark == lastPlayedLandmark { // Same landmark already playing
            print("🚫 Landmark already playing: \(landmark)")
            return
        }
        
        lastPlayedLandmark = landmark
        
        let player = AVPlayer(url: videoURL)
        self.videoPlayer = player
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        print("🎥 Overlaying Video for \(landmark) using AVPlayerLayer")
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(removeExistingVideoOverlay), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    @objc private func removeExistingVideoOverlay() {
        if let sublayers = view.layer.sublayers {
            for layer in sublayers where layer is AVPlayerLayer {
                layer.removeFromSuperlayer()
            }
        }
        videoPlayer?.pause()
        videoPlayer = nil
        lastPlayedLandmark = nil // Reset lastPlayedLandmark when video is removed
        print("🛑 Video overlay removed")
    }
}
