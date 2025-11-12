import Foundation
import SwiftUI

/**
 * ControlPoint represents an interactive point for video warping
 * 
 * Each control point has:
 * - Position (normalized coordinates 0-1)
 * - Type (anchor or stretch)
 * - Influence radius and strength
 * - Visual appearance properties
 */
struct ControlPoint: Identifiable, Codable {
    let id = UUID()
    var position: CGPoint
    var type: PointType
    var strength: Float
    var radius: Float
    var isLocked: Bool
    
    enum PointType: String, CaseIterable, Codable {
        case stretch = "stretch"
        case anchor = "anchor"
        
        var color: Color {
            switch self {
            case .stretch:
                return Color(red: 0.61, green: 0.36, blue: 0.90) // Purple #9B5DE5
            case .anchor:
                return Color.orange
            }
        }
        
        var systemImage: String {
            switch self {
            case .stretch:
                return "arrow.up.and.down.and.arrow.left.and.right"
            case .anchor:
                return "pin.fill"
            }
        }
        
        var description: String {
            switch self {
            case .stretch:
                return "Stretch Point"
            case .anchor:
                return "Anchor Point"
            }
        }
    }
    
    init(
        position: CGPoint,
        type: PointType = .stretch,
        strength: Float = 1.0,
        radius: Float = 0.1,
        isLocked: Bool = false
    ) {
        self.position = position
        self.type = type
        self.strength = strength
        self.radius = radius
        self.isLocked = isLocked
    }
}

/**
 * WarpSettings contains global parameters for video warping
 */
struct WarpSettings {
    var globalStrength: Float = 1.0
    var interpolationType: InterpolationType = .smooth
    var preserveAspectRatio: Bool = false
    var realTimePreview: Bool = true
    var meshResolution: Int = 32
    
    enum InterpolationType: String, CaseIterable {
        case linear = "linear"
        case smooth = "smooth"
        case elastic = "elastic"
        
        var description: String {
            switch self {
            case .linear:
                return "Linear"
            case .smooth:
                return "Smooth"
            case .elastic:
                return "Elastic"
            }
        }
    }
}

/**
 * ExportSettings for video output configuration
 */
struct ExportSettings {
    var format: VideoFormat = .mp4
    var quality: Quality = .high
    var preserveOriginalQuality: Bool = true
    var customBitrate: Int? = nil
    
    enum VideoFormat: String, CaseIterable {
        case mp4 = "mp4"
        case mov = "mov"
        case m4v = "m4v"
        
        var description: String {
            switch self {
            case .mp4:
                return "MP4"
            case .mov:
                return "MOV"
            case .m4v:
                return "M4V"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
    }
    
    enum Quality: String, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var description: String {
            switch self {
            case .high:
                return "High"
            case .medium:
                return "Medium"
            case .low:
                return "Low"
            }
        }
        
        var compressionQuality: Float {
            switch self {
            case .high:
                return 0.9
            case .medium:
                return 0.7
            case .low:
                return 0.5
            }
        }
    }
}

/**
 * VideoMetadata contains information about the loaded video
 */
struct VideoMetadata {
    let duration: TimeInterval
    let size: CGSize
    let frameRate: Float
    let bitrate: Int?
    let format: String
    let hasAudio: Bool
    
    var aspectRatio: CGFloat {
        return size.width / size.height
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedSize: String {
        return String(format: "%.0f × %.0f", size.width, size.height)
    }
}

/**
 * Extension for CGPoint to support normalized coordinates
 */
extension CGPoint {
    /// Convert from normalized coordinates (0-1) to view coordinates
    func toViewCoordinates(in size: CGSize) -> CGPoint {
        return CGPoint(
            x: x * size.width,
            y: y * size.height
        )
    }
    
    /// Convert from view coordinates to normalized coordinates (0-1)
    static func fromViewCoordinates(_ point: CGPoint, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x / size.width,
            y: point.y / size.height
        )
    }
    
    /// Calculate distance to another point
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

/**
 * Utility functions for control point management
 */
extension Array where Element == ControlPoint {
    /// Find the nearest control point to a given position
    func nearest(to position: CGPoint, within threshold: CGFloat = 0.05) -> ControlPoint? {
        return self
            .filter { $0.position.distance(to: position) <= threshold }
            .min { $0.position.distance(to: position) < $1.position.distance(to: position) }
    }
    
    /// Remove all locked control points
    mutating func removeUnlocked() {
        self = self.filter { !$0.isLocked }
    }
    
    /// Get all stretch points
    var stretchPoints: [ControlPoint] {
        return self.filter { $0.type == .stretch }
    }
    
    /// Get all anchor points
    var anchorPoints: [ControlPoint] {
        return self.filter { $0.type == .anchor }
    }
}