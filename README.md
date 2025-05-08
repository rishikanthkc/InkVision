InkVision is an iOS Augmented Reality (AR) application that enables users to scan images of famous landmarks using their iPhone camera. Upon recognizing a landmark, the app overlays a live video related to that landmark in real-time. The project uses CoreML for image recognition, ARKit for AR rendering, and AVKit for video playback, built with Xcode.

Features

1. Landmark Recognition: Identifies landmarks using a custom-trained CoreML model (Landmark_Classifier).

2. Real-Time Video Overlay: Plays landmark-specific videos as AR overlays using AVKit.

3. Supported Landmarks:
  Taj Mahal
  Colosseum
  Eiffel Tower
  Statue of Liberty
  Golden Gate Bridge
  Leaning Tower of Pisa
  
4. Continuous Scanning: Classifies camera frames every 2 seconds for seamless recognition.

Requirements

iOS 16.0 or later
Xcode 14.0 or later
iPhone with ARKit support (iPhone 8 or newer recommended)
Custom-trained CoreML model (Landmark_Classifier.mlmodel)

Installation

Clone the Repository:git clone https://github.com/rishikanthkc/InkVision.git


Open in Xcode:
Open InkVision.xcodeproj in Xcode.


Add CoreML Model:
Place your custom-trained .mlmodel file in the project’s root directory.
Add it to the Xcode Project Navigator and ensure it’s included in the target.


Build and Run:
Select an ARKit-compatible iPhone or simulator.
Build and run (Cmd + R).



Usage

1. Launch InkVision on your iPhone.
2. Point the camera at a supported landmark image.
3. When a landmark is recognized (with >90% confidence), a corresponding video overlay plays automatically.
4. Move the camera to explore the AR experience; videos stop when no landmark is detected.

Project Structure

ViewController.swift: Core logic for AR session management, CoreML image classification, and video playback.
Assets.xcassets: App icons and visual assets.
Landmark_Classifier.mlmodel (required): Custom CoreML model for landmark recognition (not included).

Implementation Details

CoreML: Uses VNCoreMLModel to classify camera snapshots every 2 seconds via VNClassificationObservation.
ARKit: Configures ARWorldTrackingConfiguration with horizontal plane detection for stable AR rendering.
AVKit: Streams videos from Pixabay URLs or local files, displayed via AVPlayerLayer with .resizeAspectFill.
Logic Flow:
  Captures scene snapshots using sceneView.snapshot().
  Classifies images with a confidence threshold of 0.9.
  Plays videos only for new landmarks, pausing/removing when landmarks change or are not detected.
  Resets AR session on load and pauses on viewWillDisappear.



Dependencies

CoreML: For landmark classification.
ARKit: For AR session and rendering.
AVKit: For video playback.
Vision: For integrating CoreML with image processing.
SceneKit: For managing the AR scene.

Contributing
We welcome contributions! To contribute:

1. Fork the repository.
2. Create a feature branch (git checkout -b feature-branch).
3. Commit changes (git commit -m 'Add feature').
4. Push to the branch (git push origin feature-branch).
5. Open a Pull Request.

License

This project is licensed under the MIT License. See the LICENSE file for details.

Limitations

Requires a stable internet connection for streaming video URLs.
Local video playback requires correct file paths in the bundle (not implemented in this version).
Performance depends on device hardware and lighting conditions.

Acknowledgments

Built with CoreML, ARKit, and AVKit.
Video content sourced from Pixabay.

Contact
For issues or suggestions, please open a GitHub Issue.
