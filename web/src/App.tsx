import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import VideoUploader from './components/VideoUploader';
import VideoEditor from './components/VideoEditor';
import ExportPanel from './components/ExportPanel';
import ErrorBoundary from './components/ErrorBoundary';
import PerformanceOverlay from './components/PerformanceOverlay';
import { VideoFile, ControlPoint, WarpSettings } from './types';
import PerformanceMonitor from './utils/PerformanceMonitor';
import './App.css';

const App: React.FC = () => {
  const [videoFile, setVideoFile] = useState<VideoFile | null>(null);
  const [controlPoints, setControlPoints] = useState<ControlPoint[]>([]);
  const [warpSettings, setWarpSettings] = useState<WarpSettings>({
    strength: 1.0,
    interpolation: 'smooth',
    preserveAspectRatio: false,
    realTimePreview: true,
    quality: 'preview'
  });
  const [isExporting, setIsExporting] = useState(false);
  const [showPerformanceOverlay, setShowPerformanceOverlay] = useState(false);
  const performanceMonitorRef = useRef<PerformanceMonitor | null>(null);

  // Initialize performance monitoring
  useEffect(() => {
    performanceMonitorRef.current = new PerformanceMonitor();
    
    // Show performance overlay in development or when explicitly enabled
    const shouldShowPerformance = 
      process.env.NODE_ENV === 'development' || 
      localStorage.getItem('stretch_video_show_performance') === 'true';
    
    setShowPerformanceOverlay(shouldShowPerformance);

    // Keyboard shortcut to toggle performance overlay (Ctrl/Cmd + Shift + P)
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'P' && e.shiftKey && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        setShowPerformanceOverlay(prev => {
          const newValue = !prev;
          localStorage.setItem('stretch_video_show_performance', newValue.toString());
          return newValue;
        });
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      if (performanceMonitorRef.current) {
        performanceMonitorRef.current.stopMonitoring();
      }
    };
  }, []);

  const handleVideoUpload = (file: VideoFile) => {
    setVideoFile(file);
    setControlPoints([]); // Reset control points when new video is uploaded
  };

  const handleControlPointsChange = (points: ControlPoint[]) => {
    setControlPoints(points);
  };

  const handleWarpSettingsChange = (settings: WarpSettings) => {
    setWarpSettings(settings);
  };

  const handleExport = async () => {
    if (!videoFile) return;
    
    setIsExporting(true);
    try {
      // Export logic will be implemented in VideoProcessor
      console.log('Exporting video with settings:', {
        videoFile,
        controlPoints,
        warpSettings
      });
    } catch (error) {
      console.error('Export failed:', error);
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <ErrorBoundary
      onError={(error, errorInfo) => {
        // In production, send to error reporting service
        console.error('App Error:', error, errorInfo);
      }}
    >
      <div className="app">
        <header className="app-header">
          <div className="header-content">
            <h1 className="app-title">
              Stretch Video
              <span className="version-badge">Pro</span>
            </h1>
            <p className="app-subtitle">Professional video stretching and warping</p>
          </div>
        </header>

        <main className="app-main">
          <AnimatePresence mode="wait">
            {!videoFile ? (
              <motion.div
                key="uploader"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.3 }}
                className="uploader-container"
              >
                <ErrorBoundary fallback={
                  <div className="error-fallback">
                    <p>Failed to load video uploader. Please refresh the page.</p>
                  </div>
                }>
                  <VideoUploader onVideoUpload={handleVideoUpload} />
                </ErrorBoundary>
              </motion.div>
            ) : (
              <motion.div
                key="editor"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
                className="editor-container"
              >
                <div className="editor-layout">
                  <div className="video-panel">
                    <ErrorBoundary fallback={
                      <div className="error-fallback">
                        <p>Video editor encountered an error. Try reloading your video.</p>
                        <button onClick={() => setVideoFile(null)}>Back to Upload</button>
                      </div>
                    }>
                      <VideoEditor
                        videoFile={videoFile}
                        controlPoints={controlPoints}
                        warpSettings={warpSettings}
                        onControlPointsChange={handleControlPointsChange}
                        onWarpSettingsChange={handleWarpSettingsChange}
                      />
                    </ErrorBoundary>
                  </div>
                  <div className="controls-panel">
                    <ErrorBoundary fallback={
                      <div className="error-fallback">
                        <p>Export panel failed to load.</p>
                      </div>
                    }>
                      <ExportPanel
                        videoFile={videoFile}
                        controlPoints={controlPoints}
                        warpSettings={warpSettings}
                        isExporting={isExporting}
                        onExport={handleExport}
                        onNewVideo={() => setVideoFile(null)}
                        onWarpSettingsChange={handleWarpSettingsChange}
                        onControlPointsChange={handleControlPointsChange}
                      />
                    </ErrorBoundary>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </main>

        <footer className="app-footer">
          <p>Built with precision for professional video editing</p>
        </footer>

        {/* Performance Overlay */}
        {showPerformanceOverlay && performanceMonitorRef.current && (
          <PerformanceOverlay
            performanceMonitor={performanceMonitorRef.current}
            isVisible={showPerformanceOverlay}
          />
        )}
      </div>
    </ErrorBoundary>
  );
};

export default App;