# Stretch Video - Development Guide

This guide provides comprehensive information for developers working on the Stretch Video application.

## 🏗️ Architecture Overview

### Web Application (React + TypeScript)
- **Frontend Framework**: React 18 with TypeScript for type safety
- **Animation**: Framer Motion for smooth, professional animations
- **Video Processing**: Custom WebGL shaders for real-time warping
- **State Management**: React hooks with custom contexts
- **Styling**: CSS modules with custom properties for theming

### iOS/macOS Application (SwiftUI)
- **UI Framework**: SwiftUI for modern, declarative interface
- **Video Processing**: AVFoundation for video manipulation
- **Graphics**: Metal shaders for GPU-accelerated effects
- **Cross-Platform**: Single codebase for iOS and macOS
- **Performance**: Hardware-optimized rendering pipeline

## 🎨 Design System

### Color Palette
```css
--bg-primary: #1C1C1E        /* Light charcoal background */
--bg-secondary: #2C2C2E      /* Secondary background */
--accent-purple: #9B5DE5     /* Primary accent color */
--text-primary: #FFFFFF      /* Primary text */
--text-secondary: #8E8E93    /* Secondary text */
--border-color: #38383A      /* Border color */
```

### Typography
- **Primary**: San Francisco (system font)
- **Fallback**: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto'
- **Weights**: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

### Spacing Scale
- 4px, 8px, 12px, 16px, 20px, 24px, 32px, 40px, 48px

## 🔧 Development Setup

### Prerequisites
- Node.js 16+ and npm
- Xcode 15+ (for iOS/macOS development)
- Git

### Web Development
```bash
# Install dependencies
cd web && npm install

# Start development server
npm start

# Run tests
npm test

# Build for production
npm run build
```

### iOS/macOS Development
```bash
# Open project in Xcode
open ios/StretchVideo/StretchVideo.xcodeproj

# Or use command line
xcodebuild -project ios/StretchVideo/StretchVideo.xcodeproj -scheme StretchVideo build
```

## 📁 Project Structure

### Web Application
```
web/
├── public/                   # Static assets
│   ├── index.html           # HTML template
│   ├── manifest.json        # PWA manifest
│   └── favicon.ico          # App icon
├── src/
│   ├── components/          # React components
│   │   ├── VideoUploader/   # File upload component
│   │   ├── VideoEditor/     # Main editing interface
│   │   ├── ExportPanel/     # Export controls
│   │   └── PerformanceOverlay/ # Performance monitoring
│   ├── utils/               # Utility functions
│   │   ├── VideoProcessor.ts # WebGL video processing
│   │   └── PerformanceMonitor.ts # Performance tracking
│   ├── types/               # TypeScript definitions
│   ├── App.tsx             # Main application
│   └── index.tsx           # Entry point
└── package.json            # Dependencies
```

### iOS/macOS Application
```
ios/StretchVideo/
├── StretchVideoApp.swift    # App entry point
├── ContentView.swift        # Main UI
├── VideoEditorView.swift    # Video editing interface
├── VideoProcessor.swift     # Video processing logic
├── ControlPoint.swift       # Data models
├── WarpShader.metal        # GPU shaders
├── Assets.xcassets/        # App icons and colors
└── Info.plist             # App configuration
```

## 🎯 Key Components

### VideoProcessor (Web)
Handles real-time video processing using WebGL:
```typescript
class VideoProcessor {
  // Load video and create WebGL context
  async loadVideo(videoUrl: string): Promise<void>
  
  // Update warp points for real-time preview
  updateWarpPoints(points: ControlPoint[]): void
  
  // Render frame with current transformations
  render(currentTime?: number): void
  
  // Export processed video
  async exportVideo(): Promise<Blob>
}
```

### VideoProcessor (iOS/macOS)
Handles video processing using AVFoundation and Metal:
```swift
class VideoProcessor: ObservableObject {
  // Load video asset
  func loadVideo(from url: URL) async throws
  
  // Add interactive control point
  func addControlPoint(at position: CGPoint)
  
  // Export warped video
  func exportVideo() async throws -> URL
}
```

### ControlPoint System
Interactive points for video manipulation:
```typescript
interface ControlPoint {
  id: string
  x: number              // Normalized X position (0-1)
  y: number              // Normalized Y position (0-1)
  type: 'anchor' | 'stretch'  // Point behavior
  strength: number       // Effect intensity (0-2)
  radius: number         // Influence area (0-1)
  locked: boolean        // Prevents movement
}
```

## 🎬 Video Processing Pipeline

### Real-Time Preview
1. **Mesh Generation**: Create grid of vertices based on resolution setting
2. **Warp Calculation**: Apply control point transformations to mesh
3. **GPU Rendering**: Use shaders to transform video texture
4. **Display**: Present result to canvas/video view

### Export Process
1. **Quality Settings**: Configure output resolution and compression
2. **Frame Processing**: Apply transformations to each frame
3. **Encoding**: Use WebCodecs API (web) or AVAssetWriter (iOS/macOS)
4. **Output**: Generate downloadable video file

## ⚡ Performance Optimization

### Web Optimizations
- **WebGL Context**: Reuse single context for all operations
- **Shader Compilation**: Cache compiled shaders
- **Texture Management**: Efficiently update video textures
- **Memory**: Clean up resources on component unmount

### iOS/macOS Optimizations
- **Metal Buffers**: Reuse GPU buffers where possible
- **Background Processing**: Use background queues for heavy operations
- **Memory Pressure**: Monitor and respond to memory warnings
- **Thermal State**: Adjust quality based on device thermal state

## 🐛 Debugging & Testing

### Performance Monitoring
Enable performance overlay in development:
```typescript
// Web
const monitor = new PerformanceMonitor();
monitor.startMonitoring();

// Check metrics
const metrics = monitor.getMetrics();
console.log(`FPS: ${metrics.frameRate}`);
```

### Common Issues
1. **Low Frame Rate**: Reduce mesh resolution or disable real-time preview
2. **Memory Leaks**: Ensure VideoProcessor is properly cleaned up
3. **Export Failures**: Check video format compatibility and file size limits
4. **GPU Errors**: Verify WebGL/Metal support and shader compilation

### Testing Strategy
- **Unit Tests**: Test utility functions and data transformations
- **Integration Tests**: Test video loading and processing pipeline
- **Performance Tests**: Measure rendering performance across devices
- **User Tests**: Validate interface usability and workflow

## 🚀 Deployment

### Web Deployment
```bash
# Build production bundle
npm run build

# Deploy to static hosting (Vercel, Netlify, etc.)
# Ensure proper MIME types for .wasm files if using WebAssembly
```

### iOS/macOS Deployment
```bash
# Archive for App Store
xcodebuild archive -project StretchVideo.xcodeproj -scheme StretchVideo

# Or build for local distribution
xcodebuild -project StretchVideo.xcodeproj -configuration Release
```

## 🔮 Future Enhancements

### Planned Features
- **AI Body Detection**: Automatic control point placement
- **Advanced Filters**: Additional video effects beyond warping
- **Batch Processing**: Process multiple videos simultaneously
- **Cloud Processing**: Offload heavy computation to backend
- **Collaboration**: Share projects and collaborate in real-time

### Technical Improvements
- **WebAssembly**: Move heavy computations to WASM for better performance
- **WebCodecs**: Use native video encoding APIs when available
- **Progressive Web App**: Add offline support and native app-like features
- **Accessibility**: Improve screen reader support and keyboard navigation

## 📚 Resources

### Documentation
- [WebGL Fundamentals](https://webglfundamentals.org/)
- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [Metal Best Practices](https://developer.apple.com/documentation/metal)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

### Tools
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/) for web debugging
- [Xcode Instruments](https://developer.apple.com/xcode/features/) for iOS/macOS profiling
- [GPU Frame Debugger](https://developer.apple.com/documentation/metal/debugging_gpu_frame_debugger) for Metal debugging

---

## 💡 Contributing

1. **Code Style**: Follow TypeScript/Swift conventions
2. **Documentation**: Update this guide when adding features
3. **Testing**: Add tests for new functionality
4. **Performance**: Profile changes before submitting
5. **Accessibility**: Ensure features work with assistive technologies

Happy coding! 🎬✨