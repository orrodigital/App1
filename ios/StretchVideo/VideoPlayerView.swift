import SwiftUI
import AVKit
import AVFoundation

/**
 * VideoPlayerView wraps AVPlayerLayer for SwiftUI integration
 * Handles video display with custom controls disabled
 */
struct VideoPlayerView: UIViewRepresentable {
    let videoProcessor: VideoProcessor
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.configure(with: videoProcessor)
        return view
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        uiView.updatePlayer(videoProcessor.player)
    }
}

class VideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    private weak var videoProcessor: VideoProcessor?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    func configure(with videoProcessor: VideoProcessor) {
        self.videoProcessor = videoProcessor
        setupPlayerLayer()
    }
    
    func updatePlayer(_ player: AVPlayer?) {
        playerLayer?.player = player
    }
    
    private func setupPlayerLayer() {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
    }
}

/**
 * ControlPointView represents an interactive control point on the video
 */
struct ControlPointView: View {
    let point: ControlPoint
    let isSelected: Bool
    let videoSize: CGSize
    let onPositionChange: (CGPoint) -> Void
    let onSelect: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isHovering = false
    
    var body: some View {
        let screenPosition = point.position.toViewCoordinates(in: videoSize)
        
        ZStack {
            // Influence radius (when selected)
            if isSelected {
                Circle()
                    .stroke(point.type.color.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: CGFloat(point.radius) * videoSize.width,
                        height: CGFloat(point.radius) * videoSize.width
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            
            // Control point
            Circle()
                .fill(point.type.color)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: point.type.systemImage)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                )
                .scaleEffect(isSelected ? 1.3 : (isHovering ? 1.1 : 1.0))
                .shadow(color: point.type.color.opacity(0.5), radius: 4)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.1), value: isHovering)
        }
        .position(
            x: screenPosition.x + dragOffset.width,
            y: screenPosition.y + dragOffset.height
        )
        .onTapGesture {
            onSelect()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newPosition = CGPoint(
                        x: screenPosition.x + value.translation.x,
                        y: screenPosition.y + value.translation.y
                    )
                    
                    // Clamp to video bounds
                    let clampedPosition = CGPoint(
                        x: max(0, min(videoSize.width, newPosition.x)),
                        y: max(0, min(videoSize.height, newPosition.y))
                    )
                    
                    onPositionChange(clampedPosition)
                    dragOffset = .zero
                }
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/**
 * ControlPointRow displays control point information in the sidebar
 */
struct ControlPointRow: View {
    let point: ControlPoint
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onUpdate: (ControlPoint) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Point indicator
                Circle()
                    .fill(point.type.color)
                    .frame(width: 12, height: 12)
                
                // Point info
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.type.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.0f%%, %.0f%%", point.position.x * 100, point.position.y * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                        Color(red: 0.61, green: 0.36, blue: 0.90).opacity(0.2) :
                        Color(red: 0.22, green: 0.22, blue: 0.23)
                    )
            )
            .onTapGesture {
                onSelect()
            }
            
            // Expanded controls
            if isExpanded {
                VStack(spacing: 12) {
                    ControlPointSlider(
                        label: "Strength",
                        value: Binding(
                            get: { point.strength },
                            set: { newValue in
                                var updatedPoint = point
                                updatedPoint.strength = newValue
                                onUpdate(updatedPoint)
                            }
                        ),
                        range: 0...2,
                        format: "%.1fx"
                    )
                    
                    ControlPointSlider(
                        label: "Radius",
                        value: Binding(
                            get: { point.radius },
                            set: { newValue in
                                var updatedPoint = point
                                updatedPoint.radius = newValue
                                onUpdate(updatedPoint)
                            }
                        ),
                        range: 0.05...0.5,
                        format: "%.0f%%",
                        multiplier: 100
                    )
                    
                    HStack {
                        Button("Toggle Type") {
                            var updatedPoint = point
                            updatedPoint.type = point.type == .stretch ? .anchor : .stretch
                            onUpdate(updatedPoint)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.61, green: 0.36, blue: 0.90))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Spacer()
                        
                        Toggle("Lock", isOn: Binding(
                            get: { point.isLocked },
                            set: { newValue in
                                var updatedPoint = point
                                updatedPoint.isLocked = newValue
                                onUpdate(updatedPoint)
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.61, green: 0.36, blue: 0.90)))
                    }
                }
                .padding(12)
                .background(Color(red: 0.17, green: 0.17, blue: 0.18))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct ControlPointSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: String
    let multiplier: Float
    
    init(label: String, value: Binding<Float>, range: ClosedRange<Float>, format: String, multiplier: Float = 1.0) {
        self.label = label
        self._value = value
        self.range = range
        self.format = format
        self.multiplier = multiplier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: format, value * multiplier))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range)
                .accentColor(Color(red: 0.61, green: 0.36, blue: 0.90))
        }
    }
}

/**
 * ExportView handles video export settings and process
 */
struct ExportView: View {
    @ObservedObject var videoProcessor: VideoProcessor
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportSettings = ExportSettings()
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Format:")
                            Spacer()
                            Picker("Format", selection: $exportSettings.format) {
                                ForEach(ExportSettings.VideoFormat.allCases, id: \.self) { format in
                                    Text(format.description).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Quality:")
                            Spacer()
                            Picker("Quality", selection: $exportSettings.quality) {
                                ForEach(ExportSettings.Quality.allCases, id: \.self) { quality in
                                    Text(quality.description).tag(quality)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Toggle("Preserve Original Quality", isOn: $exportSettings.preserveOriginalQuality)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                )
                
                // Export progress
                if isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.61, green: 0.36, blue: 0.90)))
                        
                        Text("Exporting video...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Error message
                if let exportError = exportError {
                    Text(exportError)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                
                Spacer()
                
                // Export button
                Button(action: exportVideo) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Text(isExporting ? "Exporting..." : "Export Video")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.61, green: 0.36, blue: 0.90))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isExporting)
            }
            .padding()
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .navigationTitle("Export Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func exportVideo() {
        isExporting = true
        exportError = nil
        exportProgress = 0
        
        Task {
            do {
                let outputURL = try await videoProcessor.exportVideo()
                
                await MainActor.run {
                    isExporting = false
                    exportProgress = 1.0
                    
                    // Share the exported video
                    let activityController = UIActivityViewController(
                        activityItems: [outputURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}