# AR Landmark Recognition with Video Overlay

An iOS application that uses ARKit and Core ML to recognize famous landmarks in real-time and overlay contextual videos when landmarks are detected through the device camera.

## 🎯 Project Overview

This application combines computer vision, augmented reality, and machine learning to create an interactive landmark discovery experience. When users point their device camera at famous landmarks, the app automatically recognizes them and displays relevant video content as an overlay.

## ✨ Key Features

### 🔍 Real-time Landmark Recognition
- **Smart Detection System**: Uses a custom Core ML model (`Landmark_Classifier`) for accurate landmark identification
- **Consecutive Validation**: Requires 3 consecutive detections to minimize false positives
- **Dynamic Confidence Thresholds**: Adaptive confidence levels (85% for new detections, 75% during video playback)
- **Ambiguity Prevention**: Validates confidence gaps between top predictions to avoid uncertain results

### 🎥 Intelligent Video Playback
- **Seamless Overlay**: Videos play as full-screen overlays using `AVPlayerLayer`
- **Smart State Management**: Prevents unnecessary video restarts for the same landmark
- **Auto-switching**: Intelligently switches videos when different landmarks are detected
- **Graceful Stopping**: Stops video after 2 consecutive non-detections to prevent interruptions

### 🚀 Performance Optimizations
- **Concurrent Processing Protection**: Prevents frame processing conflicts with threading guards
- **Optimized Classification Timing**: 0.8-second intervals for responsive detection
- **Memory Management**: Proper cleanup of video players, timers, and notification observers
- **AR Session Management**: Efficient ARKit configuration with horizontal plane detection

## 🏛️ Supported Landmarks

The application currently recognizes these famous landmarks:
- **Taj Mahal** 🇮🇳
- **Colosseum** 🇮🇹  
- **Eiffel Tower** 🇫🇷
- **Statue of Liberty** 🇺🇸
- **Golden Gate Bridge** 🇺🇸
- **Leaning Tower of Pisa** 🇮🇹

## 🛠️ Technical Architecture

### Core Technologies
- **ARKit**: Real-time camera feed and AR session management
- **Core ML**: Machine learning model inference for landmark classification
- **Vision Framework**: Image processing and ML request handling
- **AVKit**: Video playback and overlay management
- **SceneKit**: 3D scene rendering (future expansion capability)


### Detection Pipeline
1. **Frame Capture**: ARSCNView captures camera frames at 0.8s intervals
2. **ML Processing**: Core ML model processes frames for landmark classification
3. **Validation**: Multiple validation layers ensure accuracy:
   - Confidence threshold validation
   - Consecutive detection confirmation
   - Known landmark verification
   - Ambiguity resolution
4. **Video Trigger**: Qualified detections trigger appropriate video overlays

## 📱 System Requirements

- **iOS 17.6+** (ARKit requirement)
- **Device with A14 processor or newer** (ARKit compatibility)
- **Camera access permissions**
- **Internet connection** (for streaming video content)

## 🔧 Installation & Setup

1. **Clone the repository**

2. **Open in Xcode**

3. **Add the ML Model**
- Place your `Landmark_Classifier.mlmodel` file in the project
- Ensure it's added to the target

4. **Configure Permissions**
- Camera usage permission is required in `Info.plist`

5. **Build and Run**
- Select a physical iOS device (ARKit requires physical device)
- Build and run the project

## 🎮 How to Use

1. **Launch the App**: Open the application on your iOS device
2. **Point Camera**: Aim your device camera at a supported landmark
3. **Wait for Recognition**: The app will analyze the scene automatically
4. **Enjoy Video**: Once detected, a contextual video will overlay your view
5. **Explore More**: Move to different landmarks for new content

## 🔮 Future Enhancements

- **Expanded Landmark Database**: Add more landmarks and cultural sites
- **3D AR Models**: Integrate 3D models alongside video content
- **Audio Narration**: Add voice-over descriptions for landmarks
- **Offline Mode**: Support for offline landmark recognition
- **User-Generated Content**: Allow users to add custom landmarks and videos
- **Social Features**: Share discoveries with friends
- **Travel Integration**: Connect with travel planning apps

## 🤝 Contributing

We welcome contributions! Areas where you can help:
- Adding new landmark recognition models
- Improving detection accuracy
- Adding new video content
- UI/UX enhancements
- Performance optimizations
- Documentation improvements

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Video content sourced from Pixabay
- ARKit and Core ML frameworks by Apple
- Open source community for inspiration and resources

**Note**: This application is designed for educational and demonstration purposes. Ensure you have proper permissions for any video content used in production applications.

