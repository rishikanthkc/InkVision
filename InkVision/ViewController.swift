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
    private var isProcessingFrame = false
    private var consecutiveDetections = 0
    private let requiredConsecutiveDetections = 3
    private var lastDetectedLandmark: String?
    
    // Add these properties for better video control
    private var videoStartTime: TimeInterval = 0
    private var consecutiveNonDetections = 0
    private let maxNonDetectionsBeforeStop = 2 // Stop video after 2 consecutive non-detections
    private var isVideoPlaying = false
    
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
        
        // Faster classification for better responsiveness
        classificationTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(classifySceneFrame), userInfo: nil, repeats: true)
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
        // Prevent concurrent processing
        guard !isProcessingFrame else {
            print("⏳ Still processing previous frame, skipping...")
            return
        }
        
        isProcessingFrame = true
        
        DispatchQueue.main.async {
            let snapshot = self.sceneView.snapshot()
            self.classifyImage(snapshot) { [weak self] landmarkName in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.handleClassificationResult(landmarkName)
                    self.isProcessingFrame = false
                }
            }
        }
    }
    
    private func handleClassificationResult(_ landmarkName: String?) {
        if let landmark = landmarkName {
            // Reset non-detection counter when landmark is found
            consecutiveNonDetections = 0
            
            if isVideoPlaying {
                // If video is playing, check if it's the same landmark
                if landmark == lastPlayedLandmark {
                    print("✅ Landmark still detected during video: \(landmark)")
                    return // Continue playing the same video
                } else {
                    print("🔄 Different landmark detected during video, switching...")
                    removeExistingVideoOverlay()
                    // Reset detection counter for new landmark
                    consecutiveDetections = 1
                    lastDetectedLandmark = landmark
                }
            } else {
                // No video playing, normal detection logic
                if landmark == lastDetectedLandmark {
                    consecutiveDetections += 1
                    print("🔍 Consecutive detection \(consecutiveDetections)/\(requiredConsecutiveDetections) for: \(landmark)")
                } else {
                    // New landmark detected, reset counter
                    consecutiveDetections = 1
                    lastDetectedLandmark = landmark
                    print("🔍 New landmark detected: \(landmark)")
                }
                
                // Only play video if we have enough consecutive detections
                if consecutiveDetections >= requiredConsecutiveDetections {
                    print("✅ Confirmed landmark recognition after \(consecutiveDetections) detections: \(landmark)")
                    displayVideo(for: landmark)
                }
            }
        } else {
            // No landmark detected
            consecutiveNonDetections += 1
            print("❌ No landmark recognized (consecutive: \(consecutiveNonDetections))")
            
            if isVideoPlaying {
                // If video is playing and no landmark detected
                if consecutiveNonDetections >= maxNonDetectionsBeforeStop {
                    print("🛑 Stopping video due to consecutive non-detections")
                    removeExistingVideoOverlay()
                }
            } else {
                // Reset detection counters
                consecutiveDetections = 0
                lastDetectedLandmark = nil
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
            if let error = error {
                print("❌ ML request error: \(error)")
                completion(nil)
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                print("❌ No results from ML model")
                completion(nil)
                return
            }
            
            // Sort results by confidence
            let sortedResults = results.sorted { $0.confidence > $1.confidence }
            
            // Use different thresholds based on current state
            let confidenceThreshold: Float = self.isVideoPlaying ? 0.75 : 0.85
            let validResults = sortedResults.filter { $0.confidence > confidenceThreshold }
            
            guard let topResult = validResults.first else {
                print("❌ No high-confidence results (threshold: \(confidenceThreshold))")
                completion(nil)
                return
            }
            
            // Additional validation: check if the landmark name exists in our video URLs
            guard self.videoURLs.keys.contains(topResult.identifier) else {
                print("❌ Unrecognized landmark: \(topResult.identifier)")
                completion(nil)
                return
            }
            
            // Check for confidence gap if multiple results exist
            if validResults.count > 1 {
                let confidenceGap = topResult.confidence - validResults[1].confidence
                let requiredGap: Float = self.isVideoPlaying ? 0.03 : 0.05
                guard confidenceGap > requiredGap else {
                    print("❌ Ambiguous detection - confidence gap too small: \(confidenceGap)")
                    completion(nil)
                    return
                }
            }
            
            print("✅ High-confidence detection: \(topResult.identifier) (confidence: \(String(format: "%.3f", topResult.confidence)))")
            completion(topResult.identifier)
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
        // Remove existing video first
        removeExistingVideoOverlay()
        
        lastPlayedLandmark = landmark
        isVideoPlaying = true
        videoStartTime = CACurrentMediaTime()
        consecutiveNonDetections = 0 // Reset counter when starting video
        
        let player = AVPlayer(url: videoURL)
        player.automaticallyWaitsToMinimizeStalling = false
        self.videoPlayer = player
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        print("🎥 Playing video for \(landmark)")
        
        // Clean up previous observers
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    @objc private func videoDidFinishPlaying() {
        print("🎬 Video finished playing")
        removeExistingVideoOverlay()
    }
    
    @objc private func removeExistingVideoOverlay() {
        if let sublayers = view.layer.sublayers {
            for layer in sublayers where layer is AVPlayerLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        videoPlayer?.pause()
        videoPlayer = nil
        lastPlayedLandmark = nil
        isVideoPlaying = false
        
        // Reset all detection counters when video is removed
        consecutiveDetections = 0
        lastDetectedLandmark = nil
        consecutiveNonDetections = 0
        
        print("🛑 Video overlay removed")
    }
    
    // Clean up observers when view controller is deallocated
    deinit {
        NotificationCenter.default.removeObserver(self)
        classificationTimer?.invalidate()
    }
}
