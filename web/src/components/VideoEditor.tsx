import React, { useRef, useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { VideoFile, ControlPoint, WarpSettings } from '../types';
import VideoProcessor from '../utils/VideoProcessor';
import './VideoEditor.css';

interface VideoEditorProps {
  videoFile: VideoFile;
  controlPoints: ControlPoint[];
  warpSettings: WarpSettings;
  onControlPointsChange: (points: ControlPoint[]) => void;
  onWarpSettingsChange: (settings: WarpSettings) => void;
}

const VideoEditor: React.FC<VideoEditorProps> = ({
  videoFile,
  controlPoints,
  warpSettings,
  onControlPointsChange,
  onWarpSettingsChange
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [selectedPointId, setSelectedPointId] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [canvasSize, setCanvasSize] = useState({ width: 0, height: 0 });
  const videoProcessor = useRef<VideoProcessor | null>(null);

  // Initialize video processor
  useEffect(() => {
    if (canvasRef.current && videoFile) {
      videoProcessor.current = new VideoProcessor(canvasRef.current);
      videoProcessor.current.loadVideo(videoFile.url);
    }
    
    return () => {
      if (videoProcessor.current) {
        videoProcessor.current.destroy();
      }
    };
  }, [videoFile]);

  // Update canvas size based on container
  const updateCanvasSize = useCallback(() => {
    if (containerRef.current && videoFile) {
      const container = containerRef.current;
      const containerRect = container.getBoundingClientRect();
      
      // Calculate canvas size maintaining aspect ratio
      const aspectRatio = videoFile.width / videoFile.height;
      const maxWidth = containerRect.width - 40; // Account for padding
      const maxHeight = containerRect.height - 120; // Account for controls
      
      let width, height;
      
      if (maxWidth / aspectRatio <= maxHeight) {
        width = maxWidth;
        height = maxWidth / aspectRatio;
      } else {
        width = maxHeight * aspectRatio;
        height = maxHeight;
      }
      
      setCanvasSize({ width, height });
      
      if (canvasRef.current) {
        canvasRef.current.width = width;
        canvasRef.current.height = height;
        canvasRef.current.style.width = `${width}px`;
        canvasRef.current.style.height = `${height}px`;
      }
    }
  }, [videoFile]);

  useEffect(() => {
    updateCanvasSize();
    window.addEventListener('resize', updateCanvasSize);
    return () => window.removeEventListener('resize', updateCanvasSize);
  }, [updateCanvasSize]);

  // Apply warp effect to video
  useEffect(() => {
    if (videoProcessor.current && warpSettings.realTimePreview) {
      videoProcessor.current.updateWarpPoints(controlPoints);
      videoProcessor.current.updateSettings(warpSettings);
    }
  }, [controlPoints, warpSettings]);

  // Handle video time updates
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const handleTimeUpdate = () => {
      setCurrentTime(video.currentTime);
      if (videoProcessor.current) {
        videoProcessor.current.render(video.currentTime);
      }
    };

    const handlePlay = () => setIsPlaying(true);
    const handlePause = () => setIsPlaying(false);

    video.addEventListener('timeupdate', handleTimeUpdate);
    video.addEventListener('play', handlePlay);
    video.addEventListener('pause', handlePause);

    return () => {
      video.removeEventListener('timeupdate', handleTimeUpdate);
      video.removeEventListener('play', handlePlay);
      video.removeEventListener('pause', handlePause);
    };
  }, []);

  // Convert screen coordinates to normalized video coordinates
  const screenToVideoCoords = useCallback((clientX: number, clientY: number): { x: number, y: number } => {
    if (!canvasRef.current) return { x: 0, y: 0 };
    
    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    
    const x = (clientX - rect.left) / rect.width;
    const y = (clientY - rect.top) / rect.height;
    
    return {
      x: Math.max(0, Math.min(1, x)),
      y: Math.max(0, Math.min(1, y))
    };
  }, []);

  // Convert normalized coordinates to screen coordinates
  const videoToScreenCoords = useCallback((x: number, y: number): { x: number, y: number } => {
    return {
      x: x * canvasSize.width,
      y: y * canvasSize.height
    };
  }, [canvasSize]);

  // Handle canvas click to add new control point
  const handleCanvasClick = useCallback((e: React.MouseEvent) => {
    if (isDragging) return;
    
    const coords = screenToVideoCoords(e.clientX, e.clientY);
    
    // Check if clicking near existing point (for selection)
    const clickRadius = 20 / Math.min(canvasSize.width, canvasSize.height);
    const nearbyPoint = controlPoints.find(point => {
      const distance = Math.sqrt(
        Math.pow(point.x - coords.x, 2) + Math.pow(point.y - coords.y, 2)
      );
      return distance < clickRadius;
    });

    if (nearbyPoint) {
      setSelectedPointId(nearbyPoint.id);
      return;
    }

    // Add new control point
    const newPoint: ControlPoint = {
      id: `point_${Date.now()}`,
      x: coords.x,
      y: coords.y,
      type: 'stretch',
      strength: 1.0,
      radius: 0.1,
      locked: false
    };

    onControlPointsChange([...controlPoints, newPoint]);
    setSelectedPointId(newPoint.id);
  }, [controlPoints, screenToVideoCoords, canvasSize, isDragging, onControlPointsChange]);

  // Handle control point dragging
  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDragging || !selectedPointId) return;

    const coords = screenToVideoCoords(e.clientX, e.clientY);
    const updatedPoints = controlPoints.map(point =>
      point.id === selectedPointId && !point.locked
        ? { ...point, x: coords.x, y: coords.y }
        : point
    );

    onControlPointsChange(updatedPoints);
  }, [isDragging, selectedPointId, controlPoints, screenToVideoCoords, onControlPointsChange]);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    const coords = screenToVideoCoords(e.clientX, e.clientY);
    const clickRadius = 20 / Math.min(canvasSize.width, canvasSize.height);
    
    const clickedPoint = controlPoints.find(point => {
      const distance = Math.sqrt(
        Math.pow(point.x - coords.x, 2) + Math.pow(point.y - coords.y, 2)
      );
      return distance < clickRadius;
    });

    if (clickedPoint && !clickedPoint.locked) {
      setSelectedPointId(clickedPoint.id);
      setIsDragging(true);
      e.preventDefault();
    }
  }, [controlPoints, screenToVideoCoords, canvasSize]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Delete' || e.key === 'Backspace') {
        if (selectedPointId) {
          const updatedPoints = controlPoints.filter(point => point.id !== selectedPointId);
          onControlPointsChange(updatedPoints);
          setSelectedPointId(null);
        }
      } else if (e.key === 'Escape') {
        setSelectedPointId(null);
      } else if (e.code === 'Space') {
        e.preventDefault();
        togglePlayback();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedPointId, controlPoints, onControlPointsChange]);

  const togglePlayback = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    if (isPlaying) {
      video.pause();
    } else {
      video.play();
    }
  }, [isPlaying]);

  const handleTimeSeek = useCallback((newTime: number) => {
    const video = videoRef.current;
    if (!video) return;

    video.currentTime = newTime;
    setCurrentTime(newTime);
  }, []);

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="video-editor" ref={containerRef}>
      {/* Hidden video element for processing */}
      <video
        ref={videoRef}
        src={videoFile.url}
        style={{ display: 'none' }}
        preload="metadata"
      />

      {/* Main canvas area */}
      <div className="canvas-container">
        <canvas
          ref={canvasRef}
          className="video-canvas"
          onClick={handleCanvasClick}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
        />

        {/* Control points overlay */}
        <div className="control-points-overlay" style={{ width: canvasSize.width, height: canvasSize.height }}>
          {controlPoints.map(point => {
            const screenCoords = videoToScreenCoords(point.x, point.y);
            return (
              <motion.div
                key={point.id}
                className={`control-point ${point.type} ${selectedPointId === point.id ? 'selected' : ''} ${point.locked ? 'locked' : ''}`}
                style={{
                  left: screenCoords.x - 8,
                  top: screenCoords.y - 8
                }}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                whileHover={{ scale: 1.2 }}
                whileTap={{ scale: 0.9 }}
              />
            );
          })}
        </div>

        {/* Instructions overlay */}
        {controlPoints.length === 0 && (
          <div className="instructions-overlay">
            <div className="instructions-content">
              <h3>Click to add control points</h3>
              <p>Add points where you want to stretch or anchor the video</p>
            </div>
          </div>
        )}
      </div>

      {/* Video controls */}
      <div className="video-controls">
        <button
          className="play-pause-btn"
          onClick={togglePlayback}
          aria-label={isPlaying ? 'Pause' : 'Play'}
        >
          {isPlaying ? (
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <rect x="6" y="4" width="4" height="16" />
              <rect x="14" y="4" width="4" height="16" />
            </svg>
          ) : (
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <polygon points="5,3 19,12 5,21" />
            </svg>
          )}
        </button>

        <div className="time-info">
          <span>{formatTime(currentTime)}</span>
          <span>/</span>
          <span>{formatTime(videoFile.duration)}</span>
        </div>

        <div className="timeline-container">
          <input
            type="range"
            className="timeline"
            min="0"
            max={videoFile.duration}
            step="0.1"
            value={currentTime}
            onChange={(e) => handleTimeSeek(parseFloat(e.target.value))}
          />
        </div>
      </div>
    </div>
  );
};

export default VideoEditor;