#!/bin/bash

# Stretch Video - Setup Script
# Production-ready video stretching and warping application

echo "🎬 Setting up Stretch Video..."
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}📱 macOS detected - iOS/macOS app available${NC}"
    HAS_MACOS=true
else
    echo -e "${BLUE}🖥️  Non-macOS system - Web app only${NC}"
    HAS_MACOS=false
fi

echo ""
echo -e "${PURPLE}🚀 Stretch Video Features:${NC}"
echo "  ✨ Real-time video stretching with control points"
echo "  📐 Interactive X/Y axis warping"
echo "  🎯 Multiple control points for custom body proportions"
echo "  ⚡ Hardware-accelerated processing (Metal/WebGL)"
echo "  💎 Export full-quality videos without compression"
echo "  🎨 Beautiful dark UI with purple accents"
echo ""

# Setup Web Version
echo -e "${GREEN}🌐 Setting up Web Version (React + TypeScript)...${NC}"

if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js found: $(node --version)"
else
    echo -e "${RED}❌ Node.js not found. Please install Node.js 16+ first.${NC}"
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

if command -v npm >/dev/null 2>&1; then
    echo "✅ npm found: $(npm --version)"
else
    echo -e "${RED}❌ npm not found. Please install npm first.${NC}"
    exit 1
fi

echo ""
echo "📦 Installing web dependencies..."
cd web

# Check if package.json exists
if [ -f "package.json" ]; then
    npm install
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Web dependencies installed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to install web dependencies${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ package.json not found in web directory${NC}"
    exit 1
fi

cd ..

# Setup iOS/macOS Version (if on macOS)
if [ "$HAS_MACOS" = true ]; then
    echo ""
    echo -e "${GREEN}📱 Setting up iOS/macOS Version (SwiftUI)...${NC}"
    
    if command -v xcodebuild >/dev/null 2>&1; then
        echo "✅ Xcode found: $(xcodebuild -version | head -1)"
        
        # Check if iOS project exists
        if [ -f "ios/StretchVideo/StretchVideo.xcodeproj/project.pbxproj" ]; then
            echo "✅ iOS/macOS project configured"
        else
            echo -e "${RED}❌ iOS project files not found${NC}"
        fi
    else
        echo -e "${RED}❌ Xcode not found. Install Xcode from the App Store for iOS/macOS development.${NC}"
    fi
fi

# Create launch scripts
echo ""
echo -e "${BLUE}📄 Creating launch scripts...${NC}"

# Web launch script
cat > launch-web.sh << 'EOF'
#!/bin/bash
echo "🌐 Launching Stretch Video Web App..."
echo "======================================"
echo ""
echo "🎬 Starting development server..."
echo "📱 App will open at http://localhost:3000"
echo ""
echo "Features available:"
echo "  • Drag & drop video files"
echo "  • Click to add control points"
echo "  • Real-time warping preview"
echo "  • Export processed videos"
echo ""

cd web
npm start
EOF

chmod +x launch-web.sh

if [ "$HAS_MACOS" = true ]; then
    # iOS launch script
    cat > launch-ios.sh << 'EOF'
#!/bin/bash
echo "📱 Launching Stretch Video iOS/macOS App..."
echo "============================================="
echo ""
echo "🔨 Opening Xcode project..."
echo "📝 Build and run the project in Xcode"
echo ""
echo "Supported platforms:"
echo "  • iOS 17.0+"
echo "  • macOS 14.0+"
echo ""

open ios/StretchVideo/StretchVideo.xcodeproj
EOF
    
    chmod +x launch-ios.sh
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "================================"
echo ""
echo -e "${PURPLE}🚀 Quick Start:${NC}"
echo ""
echo -e "${BLUE}Web Version:${NC}"
echo "  ./launch-web.sh"
echo "  or manually: cd web && npm start"
echo ""

if [ "$HAS_MACOS" = true ]; then
    echo -e "${BLUE}iOS/macOS Version:${NC}"
    echo "  ./launch-ios.sh"
    echo "  or manually: open ios/StretchVideo/StretchVideo.xcodeproj"
    echo ""
fi

echo -e "${PURPLE}📚 Architecture Overview:${NC}"
echo ""
echo -e "${BLUE}Web (React + TypeScript):${NC}"
echo "  • web/src/App.tsx - Main application"
echo "  • web/src/components/ - UI components"
echo "  • web/src/utils/VideoProcessor.ts - WebGL video processing"
echo "  • Real-time preview with WebGL shaders"
echo ""

if [ "$HAS_MACOS" = true ]; then
    echo -e "${BLUE}iOS/macOS (SwiftUI):${NC}"
    echo "  • ios/StretchVideo/ContentView.swift - Main UI"
    echo "  • ios/StretchVideo/VideoProcessor.swift - AVFoundation processing"
    echo "  • ios/StretchVideo/WarpShader.metal - Metal shaders"
    echo "  • Hardware-accelerated with Metal"
    echo ""
fi

echo -e "${PURPLE}🎨 Design System:${NC}"
echo "  • Background: Light charcoal (#1C1C1E)"
echo "  • Accent: Purple (#9B5DE5)"
echo "  • Typography: San Francisco (system font)"
echo "  • Minimal, professional interface"
echo ""

echo -e "${PURPLE}🔧 Key Features Implementation:${NC}"
echo "  • Interactive control points with drag/drop"
echo "  • Real-time mesh warping"
echo "  • Multiple interpolation methods"
echo "  • Export with quality preservation"
echo "  • Modular architecture for AI integration"
echo ""

echo -e "${GREEN}✨ Ready to create amazing stretched videos!${NC}"
echo ""

# Check for potential issues
echo -e "${BLUE}💡 Troubleshooting:${NC}"
echo ""

if [ ! -f "web/node_modules/.bin/react-scripts" ]; then
    echo -e "${RED}⚠️  If web app fails to start, run: cd web && npm install${NC}"
fi

if [ "$HAS_MACOS" = true ]; then
    echo -e "${BLUE}📱 For iOS development:${NC}"
    echo "  • Ensure Xcode 15.0+ is installed"
    echo "  • iOS deployment target: 17.0+"
    echo "  • macOS deployment target: 14.0+"
fi

echo ""
echo -e "${GREEN}Happy video stretching! 🎬✨${NC}"