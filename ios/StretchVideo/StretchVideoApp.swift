import SwiftUI

/**
 * Stretch Video - Professional Video Warping Application
 * 
 * A production-ready iOS/macOS app for real-time video stretching and warping.
 * Built with SwiftUI, AVFoundation, and Metal for optimal performance.
 * 
 * Features:
 * - Real-time video processing with Metal shaders
 * - Interactive control point manipulation
 * - High-quality video export
 * - Cross-platform iOS/macOS support
 */
@main
struct StretchVideoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
struct SettingsView: View {
    @State private var exportQuality = "high"
    @State private var enableGPUAcceleration = true
    @State private var maxControlPoints = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Stretch Video Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            GroupBox("Export") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Default Quality:")
                        Picker("Quality", selection: $exportQuality) {
                            Text("High").tag("high")
                            Text("Medium").tag("medium")
                            Text("Low").tag("low")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                    
                    Toggle("Enable GPU Acceleration", isOn: $enableGPUAcceleration)
                        .help("Uses Metal for faster video processing")
                }
                .padding()
            }
            
            GroupBox("Performance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Max Control Points:")
                        Stepper(value: $maxControlPoints, in: 4...32) {
                            Text("\(maxControlPoints)")
                        }
                    }
                    
                    Text("Higher values allow more detailed warping but may reduce performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
#endif