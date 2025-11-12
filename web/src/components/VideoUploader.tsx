import React, { useCallback, useState } from 'react';
import { motion } from 'framer-motion';
import { VideoFile, SUPPORTED_VIDEO_FORMATS, MAX_FILE_SIZE } from '../types';
import './VideoUploader.css';

interface VideoUploaderProps {
  onVideoUpload: (videoFile: VideoFile) => void;
}

const VideoUploader: React.FC<VideoUploaderProps> = ({ onVideoUpload }) => {
  const [isDragOver, setIsDragOver] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const validateFile = (file: File): string | null => {
    // Check file size
    if (file.size > MAX_FILE_SIZE) {
      return `File size exceeds ${Math.round(MAX_FILE_SIZE / (1024 * 1024))}MB limit`;
    }

    // Check file type
    if (!SUPPORTED_VIDEO_FORMATS.includes(file.type as any)) {
      return 'Unsupported video format. Please use MP4, MOV, WebM, AVI, or MKV';
    }

    return null;
  };

  const processVideoFile = async (file: File): Promise<VideoFile> => {
    return new Promise((resolve, reject) => {
      const video = document.createElement('video');
      const url = URL.createObjectURL(file);
      
      video.onloadedmetadata = () => {
        const videoFile: VideoFile = {
          file,
          url,
          duration: video.duration,
          width: video.videoWidth,
          height: video.videoHeight,
          format: file.type,
          size: file.size,
          fps: 30 // Default fps, could be extracted with more advanced libraries
        };
        
        resolve(videoFile);
      };

      video.onerror = () => {
        URL.revokeObjectURL(url);
        reject(new Error('Failed to load video metadata'));
      };

      video.src = url;
    });
  };

  const handleFileSelect = useCallback(async (file: File) => {
    setError(null);
    setIsProcessing(true);

    try {
      const validationError = validateFile(file);
      if (validationError) {
        setError(validationError);
        return;
      }

      const videoFile = await processVideoFile(file);
      onVideoUpload(videoFile);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to process video file');
    } finally {
      setIsProcessing(false);
    }
  }, [onVideoUpload]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);

    const files = Array.from(e.dataTransfer.files);
    if (files.length > 0) {
      handleFileSelect(files[0]);
    }
  }, [handleFileSelect]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleFileInput = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      handleFileSelect(files[0]);
    }
  }, [handleFileSelect]);

  const formatFileSize = (bytes: number): string => {
    const mb = bytes / (1024 * 1024);
    return `${Math.round(mb)}MB`;
  };

  return (
    <div className="video-uploader">
      <motion.div
        className={`upload-area ${isDragOver ? 'drag-over' : ''} ${isProcessing ? 'processing' : ''}`}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
      >
        <input
          type="file"
          accept={SUPPORTED_VIDEO_FORMATS.join(',')}
          onChange={handleFileInput}
          className="file-input"
          id="video-file-input"
          disabled={isProcessing}
        />
        
        <label htmlFor="video-file-input" className="upload-content">
          {isProcessing ? (
            <div className="processing-state">
              <div className="spinner" />
              <h3>Processing Video...</h3>
              <p>Analyzing video metadata</p>
            </div>
          ) : (
            <div className="default-state">
              <div className="upload-icon">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
                  <path
                    d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <polyline
                    points="14,2 14,8 20,8"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    d="m10 15.5 4-4 4 4"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </div>
              
              <h3>Drop your video here</h3>
              <p>or click to browse files</p>
              
              <div className="upload-specs">
                <div className="spec-item">
                  <strong>Formats:</strong> MP4, MOV, WebM, AVI, MKV
                </div>
                <div className="spec-item">
                  <strong>Max size:</strong> {formatFileSize(MAX_FILE_SIZE)}
                </div>
                <div className="spec-item">
                  <strong>Quality:</strong> Full resolution preserved
                </div>
              </div>
            </div>
          )}
        </label>
      </motion.div>

      {error && (
        <motion.div
          className="error-message"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
        >
          <div className="error-icon">⚠</div>
          <p>{error}</p>
        </motion.div>
      )}

      <div className="features-preview">
        <h4>What you can do:</h4>
        <ul>
          <li>
            <span className="feature-icon">📏</span>
            Stretch videos along X and Y axes with precision control points
          </li>
          <li>
            <span className="feature-icon">🎯</span>
            Add multiple warp points for custom body proportions
          </li>
          <li>
            <span className="feature-icon">⚡</span>
            Real-time preview with instant visual feedback
          </li>
          <li>
            <span className="feature-icon">💎</span>
            Export in full quality without compression
          </li>
        </ul>
      </div>
    </div>
  );
};

export default VideoUploader;