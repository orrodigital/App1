import SwiftUI
import AVKit
import AVFoundation

struct VideoEditorView: View {
    @ObservedObject var videoProcessor: VideoProcessor
    let onClose: () -> Void
    
    @State private var selectedPointId: UUID? = nil
    @State private var showingExportSheet = false
    @State private var showingSettings = false
    @State private var videoViewSize: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main video editing area
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Video canvas
                    videoCanvasView
                        .background(Color.black)
                    
                    // Video controls
                    videoControlsView
                }
                .background(Color(red: 0.17, green: 0.17, blue: 0.18))
                
                // Right sidebar
                sidebarView
                    .frame(width: 320)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(videoProcessor: videoProcessor)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(warpSettings: $videoProcessor.warpSettings)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: onClose) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
            }
            
            Spacer()
            
            Text("Stretch Video")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.white)
                }
                
                Button(action: { showingExportSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(videoProcessor.controlPoints.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
    
    // MARK: - Video Canvas
    
    private var videoCanvasView: some View {
        GeometryReader { geometry in
            ZStack {
                // Video player view
                if let metadata = videoProcessor.videoMetadata {
                    VideoPlayerView(videoProcessor: videoProcessor)
                        .aspectRatio(metadata.aspectRatio, contentMode: .fit)
                        .clipped()
                        .background(
                            GeometryReader { videoGeometry in
                                Color.clear
                                    .onAppear {
                                        videoViewSize = videoGeometry.size
                                    }
                                    .onChange(of: videoGeometry.size) { _, newSize in
                                        videoViewSize = newSize
                                    }
                            }
                        )
                }
                
                // Control points overlay
                if !videoViewSize.equalTo(.zero) {
                    controlPointsOverlay
                        .frame(width: videoViewSize.width, height: videoViewSize.height)
                }
                
                // Instructions overlay (when no control points)
                if videoProcessor.controlPoints.isEmpty {
                    instructionsOverlay
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { location in
                addControlPoint(at: location)
            }
        }
        .padding(20)
    }
    
    private var controlPointsOverlay: some View {
        ZStack {
            ForEach(videoProcessor.controlPoints) { point in
                ControlPointView(
                    point: point,
                    isSelected: selectedPointId == point.id,
                    videoSize: videoViewSize
                ) { newPosition in
                    videoProcessor.updateControlPoint(point.id, position: newPosition)
                } onSelect: {
                    selectedPointId = point.id
                }
            }
        }
    }
    
    private var instructionsOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
            
            Text("Tap to add control points")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Add points where you want to stretch or anchor the video")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Video Controls
    
    private var videoControlsView: some View {
        HStack(spacing: 16) {
            Button(action: { videoProcessor.togglePlayback() }) {
                Image(systemName: videoProcessor.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let metadata = videoProcessor.videoMetadata {
                    Text("\(formatTime(videoProcessor.currentTime)) / \(metadata.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                
                if let duration = videoProcessor.videoMetadata?.duration {
                    Slider(
                        value: Binding(
                            get: { videoProcessor.currentTime },
                            set: { videoProcessor.seek(to: $0) }
                        ),
                        in: 0...duration
                    )
                    .accentColor(Color(red: 0.61, green: 0.36, blue: 0.90))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
    }
    
    // MARK: - Sidebar
    
    private var sidebarView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Video info section
                videoInfoSection
                
                // Warp settings section
                warpSettingsSection
                
                // Control points section
                controlPointsSection
            }
            .padding(20)
        }
    }
    
    private var videoInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Info")
                .font(.headline)
                .foregroundColor(.white)
            
            if let metadata = videoProcessor.videoMetadata {
                InfoRow(label: "Duration", value: metadata.formattedDuration)
                InfoRow(label: "Resolution", value: metadata.formattedSize)
                InfoRow(label: "Frame Rate", value: String(format: "%.1f fps", metadata.frameRate))
                InfoRow(label: "Audio", value: metadata.hasAudio ? "Yes" : "No")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
        )
    }
    
    private var warpSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Warp Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                SettingSlider(
                    label: "Global Strength",
                    value: $videoProcessor.warpSettings.globalStrength,
                    range: 0...2,
                    format: "%.1fx"
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Interpolation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Picker("Interpolation", selection: $videoProcessor.warpSettings.interpolationType) {
                        ForEach(WarpSettings.InterpolationType.allCases, id: \.self) { type in
                            Text(type.description).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle("Preserve Aspect Ratio", isOn: $videoProcessor.warpSettings.preserveAspectRatio)
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
        )
    }
    
    private var controlPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Control Points")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(videoProcessor.controlPoints.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            if videoProcessor.controlPoints.isEmpty {
                Text("No control points added yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(videoProcessor.controlPoints) { point in
                        ControlPointRow(
                            point: point,
                            isSelected: selectedPointId == point.id,
                            onSelect: { selectedPointId = point.id },
                            onDelete: { videoProcessor.removeControlPoint(point.id) },
                            onUpdate: { updatedPoint in
                                if let index = videoProcessor.controlPoints.firstIndex(where: { $0.id == point.id }) {
                                    videoProcessor.controlPoints[index] = updatedPoint
                                }
                            }
                        )
                    }
                }
            }
            
            if !videoProcessor.controlPoints.isEmpty {
                Button("Clear All Points") {
                    videoProcessor.controlPoints.removeAll()
                    selectedPointId = nil
                }
                .foregroundColor(.red)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
        )
    }
    
    // MARK: - Helper Methods
    
    private func addControlPoint(at location: CGPoint) {
        // Convert location to video coordinates
        if !videoViewSize.equalTo(.zero) {
            let relativeLocation = CGPoint(
                x: max(0, min(1, location.x / videoViewSize.width)),
                y: max(0, min(1, location.y / videoViewSize.height))
            )
            
            let newPoint = ControlPoint(position: relativeLocation)
            videoProcessor.controlPoints.append(newPoint)
            selectedPointId = newPoint.id
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
}

struct SettingSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: format, value))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range)
                .accentColor(Color(red: 0.61, green: 0.36, blue: 0.90))
        }
    }
}

// MARK: - Preview

#Preview {
    VideoEditorView(videoProcessor: VideoProcessor()) {
        // Close action
    }
}