import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @StateObject private var videoProcessor = VideoProcessor()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showingVideoEditor = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching design specs
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.11, blue: 0.12), // #1C1C1E
                        Color(red: 0.17, green: 0.17, blue: 0.18)  // #2C2C2E
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingVideoEditor {
                    VideoEditorView(videoProcessor: videoProcessor) {
                        showingVideoEditor = false
                        videoProcessor.reset()
                    }
                } else {
                    WelcomeView(
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onVideoSelected: loadVideo
                    )
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                if let newItem = newItem {
                    loadVideoFromPhotos(item: newItem)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 1200, minHeight: 800)
        #endif
        .preferredColorScheme(.dark)
    }
    
    private func loadVideo(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await videoProcessor.loadVideo(from: url)
                await MainActor.run {
                    isLoading = false
                    showingVideoEditor = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadVideoFromPhotos(item: PhotosPickerItem) {
        isLoading = true
        errorMessage = nil
        
        item.loadTransferable(type: VideoFile.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoFile):
                    if let videoFile = videoFile {
                        Task {
                            do {
                                try await videoProcessor.loadVideo(from: videoFile.url)
                                await MainActor.run {
                                    isLoading = false
                                    showingVideoEditor = true
                                }
                            } catch {
                                await MainActor.run {
                                    isLoading = false
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct WelcomeView: View {
    let isLoading: Bool
    let errorMessage: String?
    let onVideoSelected: (URL) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isDragOver = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Stretch Video")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Pro")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.61, green: 0.36, blue: 0.90), // #9B5DE5
                                    Color(red: 0.49, green: 0.23, blue: 0.93)  // #7C3AED
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Text("Professional video stretching and warping")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Upload area
            VStack(spacing: 24) {
                if isLoading {
                    LoadingView()
                } else {
                    UploadAreaView(
                        isDragOver: isDragOver,
                        onDrop: handleDrop,
                        onPhotosPickerSelection: { selectedItem = $0 }
                    )
                    .photosPicker(
                        isPresented: .constant(selectedItem != nil),
                        selection: $selectedItem,
                        matching: .videos,
                        photoLibrary: .shared()
                    )
                    .onChange(of: selectedItem) { _, newItem in
                        if let newItem = newItem {
                            loadVideoFromPhotos(item: newItem)
                        }
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage)
                }
                
                // Features preview
                FeaturesView()
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: 600)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier("public.movie") {
            provider.loadItem(forTypeIdentifier: "public.movie", options: nil) { item, error in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        onVideoSelected(url)
                    }
                }
            }
            return true
        }
        
        return false
    }
    
    private func loadVideoFromPhotos(item: PhotosPickerItem) {
        // This would be implemented to load from PhotosPickerItem
        // For now, we'll use a placeholder implementation
    }
}

struct UploadAreaView: View {
    let isDragOver: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    let onPhotosPickerSelection: (PhotosPickerItem?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
            
            VStack(spacing: 8) {
                Text("Drop your video here")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("or click to browse files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                SpecRow(label: "Formats:", value: "MP4, MOV, M4V")
                SpecRow(label: "Max size:", value: "500MB")
                SpecRow(label: "Quality:", value: "Full resolution preserved")
            }
            .padding(.top, 8)
        }
        .padding(48)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isDragOver ? Color(red: 0.61, green: 0.36, blue: 0.90) : Color(.systemGray4),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDragOver ? 
                            Color(red: 0.61, green: 0.36, blue: 0.90).opacity(0.1) :
                            Color(red: 0.17, green: 0.17, blue: 0.18)
                        )
                )
        )
        .scaleEffect(isDragOver ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
        .onDrop(of: ["public.movie"], isTargeted: .constant(isDragOver)) { providers in
            return onDrop(providers)
        }
        .onTapGesture {
            // Trigger photos picker
            onPhotosPickerSelection(PhotosPickerItem(itemIdentifier: ""))
        }
    }
}

struct SpecRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .trim(from: 0.0, to: 0.75)
                .stroke(
                    Color(red: 0.61, green: 0.36, blue: 0.90),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Processing Video...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Analyzing video metadata")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FeaturesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you can do:")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                FeatureRow(
                    icon: "ruler",
                    text: "Stretch videos along X and Y axes with precision control points"
                )
                FeatureRow(
                    icon: "target",
                    text: "Add multiple warp points for custom body proportions"
                )
                FeatureRow(
                    icon: "bolt.fill",
                    text: "Real-time preview with instant visual feedback"
                )
                FeatureRow(
                    icon: "gem.fill",
                    text: "Export in full quality without compression"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.61, green: 0.36, blue: 0.90))
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Helper struct for PhotosPicker integration
struct VideoFile: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            VideoFile(url: received.file)
        }
    }
}

#Preview {
    ContentView()
}