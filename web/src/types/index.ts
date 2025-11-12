// Type definitions for Stretch Video application

export interface VideoFile {
  file: File;
  url: string;
  duration: number;
  width: number;
  height: number;
  format: string;
  size: number;
  fps: number;
}

export interface ControlPoint {
  id: string;
  x: number; // 0-1 normalized coordinates
  y: number; // 0-1 normalized coordinates
  type: 'anchor' | 'stretch'; // anchor points stay fixed, stretch points move
  strength: number; // 0-2, multiplier for stretch effect
  radius: number; // 0-1, influence radius of the point
  locked: boolean; // prevents accidental movement
}

export interface WarpSettings {
  strength: number; // Global warp strength multiplier (0-2)
  interpolation: 'linear' | 'smooth' | 'elastic'; // Interpolation method
  preserveAspectRatio: boolean; // Maintain original aspect ratio
  realTimePreview: boolean; // Enable/disable real-time preview
  quality: 'draft' | 'preview' | 'final'; // Rendering quality
}

export interface ExportSettings {
  format: 'mp4' | 'mov' | 'webm';
  quality: 'high' | 'medium' | 'low';
  codec: 'h264' | 'h265' | 'vp9';
  bitrate?: number; // Custom bitrate in kbps
  frameRate?: number; // Custom frame rate
  resolution?: {
    width: number;
    height: number;
  };
  preserveOriginalQuality: boolean;
}

export interface VideoMetadata {
  duration: number;
  fps: number;
  width: number;
  height: number;
  bitrate: number;
  codec: string;
  format: string;
  fileSize: number;
  hasAudio: boolean;
}

export interface WarpTransform {
  sourcePoints: number[][]; // Array of [x, y] coordinates
  targetPoints: number[][]; // Array of [x, y] coordinates
  interpolationMethod: string;
  strength: number;
}

export interface RenderFrame {
  frameNumber: number;
  timestamp: number;
  imageData: ImageData;
  transform: WarpTransform;
}

export interface ExportProgress {
  percentage: number;
  currentFrame: number;
  totalFrames: number;
  estimatedTimeRemaining: number;
  stage: 'analyzing' | 'processing' | 'encoding' | 'finalizing';
}

// UI State interfaces
export interface UIState {
  selectedTool: 'select' | 'add' | 'remove';
  showGrid: boolean;
  showPreview: boolean;
  previewQuality: 'low' | 'medium' | 'high';
  currentTime: number;
  isPlaying: boolean;
  volume: number;
}

export interface AppState {
  videoFile: VideoFile | null;
  controlPoints: ControlPoint[];
  warpSettings: WarpSettings;
  exportSettings: ExportSettings;
  ui: UIState;
  isExporting: boolean;
  exportProgress: ExportProgress | null;
}

// Error types
export interface AppError {
  type: 'upload' | 'processing' | 'export' | 'memory' | 'format';
  message: string;
  details?: string;
  timestamp: number;
}

// Event types for component communication
export interface VideoEvents {
  onLoad: (metadata: VideoMetadata) => void;
  onTimeUpdate: (currentTime: number) => void;
  onPlay: () => void;
  onPause: () => void;
  onEnded: () => void;
  onError: (error: AppError) => void;
}

export interface ControlPointEvents {
  onAdd: (point: ControlPoint) => void;
  onUpdate: (pointId: string, updates: Partial<ControlPoint>) => void;
  onRemove: (pointId: string) => void;
  onSelect: (pointId: string) => void;
  onDeselect: () => void;
}

// Utility types
export type Coordinates = {
  x: number;
  y: number;
};

export type Rectangle = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type Size = {
  width: number;
  height: number;
};

// Constants
export const SUPPORTED_VIDEO_FORMATS = [
  'video/mp4',
  'video/quicktime',
  'video/webm',
  'video/avi',
  'video/mov',
  'video/mkv'
] as const;

export const MAX_FILE_SIZE = 500 * 1024 * 1024; // 500MB

export const DEFAULT_WARP_SETTINGS: WarpSettings = {
  strength: 1.0,
  interpolation: 'smooth',
  preserveAspectRatio: false,
  realTimePreview: true,
  quality: 'preview'
};

export const DEFAULT_EXPORT_SETTINGS: ExportSettings = {
  format: 'mp4',
  quality: 'high',
  codec: 'h264',
  preserveOriginalQuality: true
};