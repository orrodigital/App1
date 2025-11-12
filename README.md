# Stretch Video Pro 🎬

A **production-ready** macOS/iOS/web application for professional video stretching and warping with real-time preview. Built with modern technologies and optimized for performance.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/TypeScript-Ready-blue.svg)](https://www.typescriptlang.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017%2B-orange.svg)](https://developer.apple.com/swiftui/)
[![React](https://img.shields.io/badge/React-18-61dafb.svg)](https://reactjs.org/)

## ✨ Features

### 🎯 **Core Functionality**
- **Upload Videos**: Support for all common formats (MP4, MOV, WebM, AVI, MKV) with full resolution preservation
- **Interactive Control Points**: Click/drag interface for precise X/Y axis warping
- **Real-time Preview**: Hardware-accelerated preview with instant visual feedback
- **Multi-point Warping**: Add unlimited control points for custom body proportions
- **Freeform Stretching**: Not limited to presets - stretch to any aspect ratio
- **Quality Export**: Full-quality video output without compression artifacts

### 🚀 **Professional Features**
- **Performance Monitoring**: Real-time FPS, memory, and GPU utilization tracking
- **Error Recovery**: Comprehensive error boundaries with detailed reporting
- **Modular Architecture**: Ready for AI body-mapping integration
- **Cross-platform**: Single codebase for web, iOS, and macOS
- **Production Ready**: Robust error handling and deployment scripts

## 🏗️ Architecture

### 🌐 **Web Version** (React + TypeScript)
- **Framework**: React 18 with TypeScript for type safety
- **Animation**: Framer Motion for smooth, professional animations  
- **Video Processing**: Custom WebGL 2.0 shaders for real-time warping
- **Performance**: Hardware-accelerated rendering with performance monitoring
- **Error Handling**: Comprehensive error boundaries and recovery

### 📱 **iOS/macOS Version** (SwiftUI)
- **UI Framework**: SwiftUI for modern, declarative interface
- **Video Processing**: AVFoundation for professional video manipulation
- **Graphics**: Metal shaders for GPU-accelerated effects
- **Cross-Platform**: Single codebase supporting iOS 17+ and macOS 14+
- **Performance**: Hardware-optimized rendering pipeline

## 🎨 Design System

### Color Palette
- **Background**: Light charcoal (#1C1C1E)
- **Secondary**: Dark charcoal (#2C2C2E)
- **Accent**: Purple (#9B5DE5)
- **Text Primary**: White (#FFFFFF)
- **Text Secondary**: Gray (#8E8E93)

### Typography
- **Primary**: San Francisco (system font)
- **Weights**: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)
- **Style**: Clean, modern, and highly legible

## 🚀 Quick Start

### **Automated Setup**
```bash
chmod +x setup.sh
./setup.sh
```

### **Manual Setup**

#### Web Version
```bash
cd web
npm install
npm start
# Opens at http://localhost:3000
```

#### iOS/macOS Version
```bash
open ios/StretchVideo/StretchVideo.xcodeproj
# Build and run in Xcode
```

## 📁 Project Structure

```
stretch-video/
├── 📄 README.md                 # This file
├── 🔧 setup.sh                  # Automated setup
├── 🚀 deploy.sh                 # Production deployment
├── 📚 DEVELOPMENT_GUIDE.md      # Development documentation
├── 🌐 web/                      # React web application
│   ├── src/
│   │   ├── 📱 App.tsx           # Main application
│   │   ├── 🧩 components/       # UI components
│   │   ├── ⚡ utils/            # Video processing & performance
│   │   └── 🔷 types/            # TypeScript definitions
│   └── 📦 package.json
└── 📱 ios/                      # SwiftUI iOS/macOS app
    └── StretchVideo/
        ├── 🏠 ContentView.swift      # Main UI
        ├── 🎬 VideoProcessor.swift   # Video processing
        ├── ⚡ WarpShader.metal      # GPU shaders
        └── 🎯 ControlPoint.swift    # Data models
```

## 🎮 Usage

### **Basic Workflow**
1. **Upload Video**: Drag & drop or click to select video file
2. **Add Control Points**: Click anywhere on the video to add warp points
3. **Adjust Effects**: Drag points to stretch, modify strength and radius
4. **Real-time Preview**: See changes instantly with hardware acceleration
5. **Export**: Download full-quality processed video

### **Advanced Features**
- **Performance Overlay**: Press `Ctrl/Cmd + Shift + P` to toggle performance monitor
- **Multiple Point Types**: Switch between stretch and anchor points
- **Precise Controls**: Fine-tune strength (0-2x) and influence radius
- **Error Recovery**: Automatic error detection with recovery suggestions

## 🔧 Technology Stack

### **Web Technologies**
- **React 18** with TypeScript for type safety
- **WebGL 2.0** for hardware-accelerated video processing
- **Framer Motion** for smooth animations
- **Custom Shaders** for real-time mesh warping
- **Canvas API** for video manipulation
- **Modern Tooling** with hot reload and performance monitoring

### **iOS/macOS Technologies**
- **SwiftUI** for declarative, modern UI
- **AVFoundation** for professional video processing
- **Metal** for GPU-accelerated shaders
- **Core Image** for additional effects
- **PhotosPicker** for seamless media import

## ⚡ Performance

### **Optimization Features**
- **60 FPS Target**: Optimized for smooth real-time preview
- **Memory Management**: Efficient resource cleanup and monitoring
- **GPU Acceleration**: Hardware-accelerated processing on all platforms
- **Quality Scaling**: Dynamic quality adjustment based on device capabilities
- **Background Processing**: Non-blocking video export

### **Monitoring & Debugging**
- **Real-time Metrics**: FPS, render time, memory usage, GPU utilization
- **Performance Grading**: Automatic performance assessment with optimization suggestions
- **Error Reporting**: Comprehensive error logging and recovery
- **Debug Tools**: Development overlay with detailed performance data

## 🚀 Deployment

### **Web Deployment**
```bash
# Build and deploy
./deploy.sh

# Quick deploy to Vercel
cd deploy && npx vercel --prod

# Quick deploy to Netlify  
cd deploy && npx netlify-cli deploy --prod --dir=.
```

### **iOS/macOS Deployment**
```bash
# Archive for App Store
xcodebuild archive -project ios/StretchVideo/StretchVideo.xcodeproj -scheme StretchVideo

# TestFlight Beta
# Use Xcode Organizer for beta distribution
```

## 🛠️ Development

### **Environment Setup**
- **Node.js** 16+ for web development
- **Xcode** 15+ for iOS/macOS development
- **Git** for version control

### **Development Commands**
```bash
# Web development
cd web && npm start           # Start dev server
cd web && npm test           # Run tests
cd web && npm run build      # Production build

# iOS development
open ios/StretchVideo/StretchVideo.xcodeproj  # Open in Xcode
```

### **Key Development Features**
- **Hot Reload**: Instant updates during development
- **TypeScript**: Full type safety and IntelliSense
- **Error Boundaries**: Graceful error handling and recovery
- **Performance Profiling**: Built-in performance monitoring tools
- **Comprehensive Logging**: Detailed error reporting and debugging

## 🔮 Roadmap

### **Planned Features**
- 🤖 **AI Body Detection**: Automatic control point placement
- 🎨 **Advanced Filters**: Additional video effects beyond warping  
- 📊 **Batch Processing**: Process multiple videos simultaneously
- ☁️ **Cloud Processing**: Offload computation to backend services
- 👥 **Collaboration**: Share projects and collaborate in real-time

### **Technical Improvements**
- 🏃 **WebAssembly**: Move heavy computations to WASM for better performance
- 📱 **PWA Support**: Progressive Web App with offline capabilities
- ♿ **Accessibility**: Enhanced screen reader and keyboard support
- 🌍 **Internationalization**: Multi-language support

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- 📧 **Email**: support@stretchvideo.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/stretchvideo/issues)
- 📚 **Documentation**: [Development Guide](DEVELOPMENT_GUIDE.md)

---

**Built with ❤️ for professional video creators**

*Stretch Video Pro - Where precision meets creativity* ✨