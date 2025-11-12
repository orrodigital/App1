#!/bin/bash

# Stretch Video - Production Deployment Script
# Handles both web and iOS/macOS deployment preparation

set -e  # Exit on any error

echo "🚀 Stretch Video - Production Deployment"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=$(date +"%Y.%m.%d.%H%M")
BUILD_DIR="./build"
DEPLOY_DIR="./deploy"

echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "  Version: $VERSION"
echo "  Build Directory: $BUILD_DIR"
echo "  Deploy Directory: $DEPLOY_DIR"
echo ""

# Pre-deployment checks
echo -e "${YELLOW}🔍 Running pre-deployment checks...${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ] && [ ! -f "web/package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found. Run this script from the project root.${NC}"
    exit 1
fi

# Check Node.js version
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION"
else
    echo -e "${RED}❌ Node.js not found${NC}"
    exit 1
fi

# Check Git status (ensure clean working directory)
if command -v git >/dev/null 2>&1; then
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠️  Warning: Working directory is not clean${NC}"
        echo "Uncommitted changes:"
        git status --short
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Git: Working directory clean"
    fi
fi

echo ""

# Create deployment directory
echo -e "${BLUE}📁 Preparing deployment directory...${NC}"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Deploy Web Application
echo -e "${GREEN}🌐 Building Web Application...${NC}"

cd web

# Install production dependencies
echo "📦 Installing dependencies..."
npm ci --only=production

# Run tests (if any)
if npm run test --dry-run >/dev/null 2>&1; then
    echo "🧪 Running tests..."
    CI=true npm test -- --coverage --watchAll=false
fi

# Build for production
echo "🔨 Building production bundle..."
npm run build

# Copy build files
echo "📋 Copying build files..."
cp -r build/* "../$DEPLOY_DIR/"

cd ..

# Create deployment package
echo -e "${BLUE}📦 Creating deployment package...${NC}"

# Add version info
cat > "$DEPLOY_DIR/version.json" << EOF
{
  "version": "$VERSION",
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "nodeVersion": "$NODE_VERSION",
  "platform": "$(uname -s)",
  "environment": "production"
}
EOF

# Add deployment instructions
cat > "$DEPLOY_DIR/DEPLOY.md" << 'EOF'
# Deployment Instructions

## Web Application

This build is ready for deployment to any static hosting service.

### Recommended Hosting Platforms

1. **Vercel** (Recommended)
   ```bash
   npx vercel --prod
   ```

2. **Netlify**
   - Drag and drop the build folder to Netlify dashboard
   - Or use Netlify CLI: `netlify deploy --prod --dir=.`

3. **AWS S3 + CloudFront**
   ```bash
   aws s3 sync . s3://your-bucket-name --delete
   aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
   ```

4. **GitHub Pages**
   - Push to `gh-pages` branch
   - Enable Pages in repository settings

### Environment Configuration

Set these environment variables in your hosting platform:

- `NODE_ENV=production`
- `REACT_APP_VERSION` (automatically set during build)

### Server Configuration

Ensure your server is configured to:

1. Serve `index.html` for all routes (SPA routing)
2. Set proper MIME types for video files
3. Enable gzip compression
4. Set appropriate cache headers

Example Apache .htaccess:
```apache
RewriteEngine On
RewriteRule ^(?!.*\.).*$ index.html [L]

# Cache static assets
<IfModule mod_expires.c>
  ExpiresActive on
  ExpiresByType text/css "access plus 1 year"
  ExpiresByType application/javascript "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>
```

Example Nginx configuration:
```nginx
location / {
  try_files $uri $uri/ /index.html;
}

location ~* \.(js|css|png|jpg|jpeg|gif|svg|woff|woff2)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

### Performance Checklist

- [ ] Enable gzip compression
- [ ] Set up CDN for static assets
- [ ] Configure proper cache headers
- [ ] Enable HTTP/2
- [ ] Set up SSL certificate
- [ ] Monitor Core Web Vitals

### Security Headers

Add these headers for enhanced security:

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob:; connect-src 'self';
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
```
EOF

# Create archive
echo "🗜️  Creating deployment archive..."
tar -czf "stretch-video-web-$VERSION.tar.gz" -C "$DEPLOY_DIR" .

# iOS/macOS Deployment Preparation
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo -e "${GREEN}📱 Preparing iOS/macOS Deployment...${NC}"
    
    # Check if Xcode is available
    if command -v xcodebuild >/dev/null 2>&1; then
        # Update version in iOS project
        if [ -f "ios/StretchVideo/Info.plist" ]; then
            /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" ios/StretchVideo/Info.plist
            /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" ios/StretchVideo/Info.plist
            echo "✅ Updated iOS app version to $VERSION"
        fi
        
        # Create iOS deployment instructions
        cat > "$DEPLOY_DIR/IOS_DEPLOY.md" << 'EOF'
# iOS/macOS Deployment Instructions

## App Store Deployment

1. **Prepare for Archive**
   ```bash
   cd ios
   xcodebuild clean -project StretchVideo.xcodeproj
   ```

2. **Archive the App**
   ```bash
   xcodebuild archive \
     -project StretchVideo.xcodeproj \
     -scheme StretchVideo \
     -configuration Release \
     -archivePath StretchVideo.xcarchive
   ```

3. **Export for App Store**
   ```bash
   xcodebuild -exportArchive \
     -archivePath StretchVideo.xcarchive \
     -exportOptionsPlist ExportOptions.plist \
     -exportPath ./export
   ```

4. **Upload to App Store Connect**
   - Use Xcode Organizer, or
   - Use Transporter app, or
   - Use altool: `xcrun altool --upload-app -f StretchVideo.ipa -u username -p password`

## TestFlight Beta

For beta testing, follow the same archive process but use TestFlight distribution in Xcode Organizer.

## Direct Distribution (Enterprise/Developer)

For direct distribution outside the App Store:

1. Export with Ad Hoc or Enterprise provisioning profile
2. Distribute via MDM or direct download
3. Ensure devices are registered in Apple Developer portal (Ad Hoc only)

## macOS Deployment

### Mac App Store
Follow the same process as iOS, but select macOS destination.

### Direct Distribution
1. Archive for macOS
2. Notarize the app with Apple
3. Distribute as DMG or ZIP file

```bash
# Notarization process
xcrun notarytool submit StretchVideo.app.zip \
  --apple-id your-email@example.com \
  --password app-specific-password \
  --team-id TEAM_ID
```
EOF
        
    else
        echo -e "${YELLOW}⚠️  Xcode not found - skipping iOS deployment preparation${NC}"
    fi
fi

# Final summary
echo ""
echo -e "${GREEN}✅ Deployment preparation complete!${NC}"
echo "========================================"
echo ""
echo -e "${PURPLE}📦 Deployment Package:${NC}"
echo "  Location: $DEPLOY_DIR"
echo "  Archive: stretch-video-web-$VERSION.tar.gz"
echo "  Version: $VERSION"
echo ""
echo -e "${PURPLE}📋 Next Steps:${NC}"
echo "  1. Review deployment files in $DEPLOY_DIR"
echo "  2. Test the production build locally"
echo "  3. Deploy to your hosting platform"
echo "  4. Monitor deployment and performance"
echo ""
echo -e "${BLUE}🔗 Quick Deploy Commands:${NC}"
echo ""
echo -e "${YELLOW}Vercel:${NC}"
echo "  cd $DEPLOY_DIR && npx vercel --prod"
echo ""
echo -e "${YELLOW}Netlify:${NC}"
echo "  cd $DEPLOY_DIR && npx netlify-cli deploy --prod --dir=."
echo ""
echo -e "${YELLOW}Test locally:${NC}"
echo "  cd $DEPLOY_DIR && npx serve -s ."
echo ""
echo -e "${GREEN}🎉 Happy deploying! 🚀${NC}"

# Make the script executable
chmod +x deploy.sh