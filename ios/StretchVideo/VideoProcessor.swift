import AVFoundation
import Metal
import MetalKit
import SwiftUI
import CoreImage

/**
 * VideoProcessor handles video loading, processing, and export
 * Uses Metal for hardware-accelerated real-time video warping
 */
class VideoProcessor: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoaded = false
    @Published var isProcessing = false
    @Published var currentTime: TimeInterval = 0
    @Published var isPlaying = false
    @Published var controlPoints: [ControlPoint] = []
    @Published var warpSettings = WarpSettings()
    @Published var exportSettings = ExportSettings()
    @Published var videoMetadata: VideoMetadata?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    
    // Metal resources
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var ciContext: CIContext?
    
    // Video properties
    private var videoSize: CGSize = .zero
    private var videoComposition: AVVideoComposition?
    private var asset: AVAsset?
    
    // MARK: - Initialization
    init() {
        setupMetal()
        setupDisplayLink()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Load video from URL
    func loadVideo(from url: URL) async throws {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        do {
            let asset = AVAsset(url: url)
            try await loadAsset(asset)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
            throw error
        }
    }
    
    /// Add a control point at the specified position
    func addControlPoint(at position: CGPoint) {
        let normalizedPosition = CGPoint.fromViewCoordinates(position, in: videoSize)
        let newPoint = ControlPoint(position: normalizedPosition)
        controlPoints.append(newPoint)
        updateVideoComposition()
    }
    
    /// Update an existing control point
    func updateControlPoint(_ pointId: UUID, position: CGPoint? = nil, strength: Float? = nil, radius: Float? = nil) {
        guard let index = controlPoints.firstIndex(where: { $0.id == pointId }) else { return }
        
        if let position = position {
            controlPoints[index].position = CGPoint.fromViewCoordinates(position, in: videoSize)
        }
        if let strength = strength {
            controlPoints[index].strength = strength
        }
        if let radius = radius {
            controlPoints[index].radius = radius
        }
        
        updateVideoComposition()
    }
    
    /// Remove a control point
    func removeControlPoint(_ pointId: UUID) {
        controlPoints.removeAll { $0.id == pointId }
        updateVideoComposition()
    }
    
    /// Toggle playback
    func togglePlayback() {
        guard let player = player else { return }
        
        if player.rate == 0 {
            player.play()
            isPlaying = true
        } else {
            player.pause()
            isPlaying = false
        }
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = time
            }
        }
    }
    
    /// Export the warped video
    func exportVideo() async throws -> URL {
        guard let asset = asset else {
            throw VideoProcessorError.noVideoLoaded
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        return try await performVideoExport(asset: asset)
    }
    
    /// Reset the processor
    func reset() {
        player?.pause()
        player = nil
        playerItem = nil
        videoOutput = nil
        controlPoints.removeAll()
        isLoaded = false
        isPlaying = false
        currentTime = 0
        videoMetadata = nil
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        
        if let device = device {
            ciContext = CIContext(mtlDevice: device)
        }
        
        setupMetalPipeline()
    }
    
    private func setupMetalPipeline() {
        // Metal pipeline setup would go here
        // For this demo, we'll use Core Image filters instead
        // In production, you'd implement custom Metal shaders for optimal performance
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateTime() {
        guard let player = player else { return }
        
        let newTime = player.currentTime().seconds
        if !newTime.isNaN && !newTime.isInfinite {
            currentTime = newTime
        }
    }
    
    private func loadAsset(_ asset: AVAsset) async throws {
        self.asset = asset
        
        // Load asset properties
        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)
        
        guard let videoTrack = tracks.first(where: { $0.mediaType == .video }) else {
            throw VideoProcessorError.noVideoTrack
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        
        // Create metadata
        let metadata = VideoMetadata(
            duration: duration.seconds,
            size: naturalSize,
            frameRate: frameRate,
            bitrate: nil, // Would be calculated from asset
            format: "video", // Would be extracted from asset
            hasAudio: tracks.contains { $0.mediaType == .audio }
        )
        
        // Setup player
        let playerItem = AVPlayerItem(asset: asset)
        self.playerItem = playerItem
        
        // Setup video output for frame extraction
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        playerItem.add(videoOutput)
        self.videoOutput = videoOutput
        
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        
        await MainActor.run {
            self.videoMetadata = metadata
            self.videoSize = naturalSize
            self.isLoaded = true
            self.isProcessing = false
        }
    }
    
    private func updateVideoComposition() {
        guard let asset = asset, !controlPoints.isEmpty else {
            videoComposition = nil
            return
        }
        
        // Create video composition with warp effects
        // This is a simplified version - in production you'd create custom Core Image filters
        let composition = AVMutableVideoComposition(propertiesOf: asset)
        composition.customVideoCompositorClass = WarpVideoCompositor.self
        
        // Pass control points to compositor
        let instruction = WarpVideoCompositionInstruction()
        instruction.controlPoints = controlPoints
        instruction.warpSettings = warpSettings
        
        composition.instructions = [instruction]
        self.videoComposition = composition
        
        // Apply composition to player item
        playerItem?.videoComposition = composition
    }
    
    private func performVideoExport(asset: AVAsset) async throws -> URL {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoProcessorError.exportFailed
        }
        
        // Setup output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stretched_video")
            .appendingPathExtension(exportSettings.format.fileExtension)
        
        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4 // Would be determined by export settings
        
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw error
        }
        
        return outputURL
    }
    
    private func cleanup() {
        displayLink?.invalidate()
        player?.pause()
    }
}

// MARK: - Custom Video Compositor

class WarpVideoCompositor: NSObject, AVVideoCompositing {
    var sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // Handle render context changes
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? WarpVideoCompositionInstruction,
              let sourceBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: 1) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "VideoCompositor", code: -1))
            return
        }
        
        // Apply warp transformation
        let outputBuffer = applyWarp(to: sourceBuffer, with: instruction)
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputBuffer)
    }
    
    private func applyWarp(to pixelBuffer: CVPixelBuffer, with instruction: WarpVideoCompositionInstruction) -> CVPixelBuffer {
        // This is where you'd apply the actual warping using Metal or Core Image
        // For this demo, we'll return the original buffer
        // In production, you'd implement mesh warping based on control points
        return pixelBuffer
    }
}

// MARK: - Custom Video Composition Instruction

class WarpVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    var timeRange: CMTimeRange = CMTimeRange()
    var enablePostProcessing: Bool = false
    var containsTweening: Bool = true
    var requiredSourceTrackIDs: [NSValue]? = [NSValue(value: 1)]
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var controlPoints: [ControlPoint] = []
    var warpSettings = WarpSettings()
}

// MARK: - Error Types

enum VideoProcessorError: LocalizedError {
    case noVideoLoaded
    case noVideoTrack
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noVideoLoaded:
            return "No video is currently loaded"
        case .noVideoTrack:
            return "Video file does not contain a video track"
        case .exportFailed:
            return "Failed to export video"
        }
    }
}