import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { VideoFile, ControlPoint, WarpSettings, ExportSettings, DEFAULT_EXPORT_SETTINGS } from '../types';
import './ExportPanel.css';

interface ExportPanelProps {
  videoFile: VideoFile;
  controlPoints: ControlPoint[];
  warpSettings: WarpSettings;
  isExporting: boolean;
  onExport: () => void;
  onNewVideo: () => void;
  onWarpSettingsChange: (settings: WarpSettings) => void;
  onControlPointsChange: (points: ControlPoint[]) => void;
}

const ExportPanel: React.FC<ExportPanelProps> = ({
  videoFile,
  controlPoints,
  warpSettings,
  isExporting,
  onExport,
  onNewVideo,
  onWarpSettingsChange,
  onControlPointsChange
}) => {
  const [exportSettings, setExportSettings] = useState<ExportSettings>(DEFAULT_EXPORT_SETTINGS);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [selectedPointId, setSelectedPointId] = useState<string | null>(null);

  const formatFileSize = (bytes: number): string => {
    const mb = bytes / (1024 * 1024);
    if (mb < 1) return `${Math.round(bytes / 1024)}KB`;
    return `${mb.toFixed(1)}MB`;
  };

  const formatDuration = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handleExportSettingChange = (key: keyof ExportSettings, value: any) => {
    setExportSettings(prev => ({ ...prev, [key]: value }));
  };

  const selectedPoint = controlPoints.find(p => p.id === selectedPointId);

  return (
    <div className="export-panel">
      {/* Video Information */}
      <div className="panel-section">
        <h3 className="section-title">Video Info</h3>
        <div className="info-grid">
          <div className="info-item">
            <span className="info-label">Duration</span>
            <span className="info-value">{formatDuration(videoFile.duration)}</span>
          </div>
          <div className="info-item">
            <span className="info-label">Resolution</span>
            <span className="info-value">{videoFile.width} × {videoFile.height}</span>
          </div>
          <div className="info-item">
            <span className="info-label">Size</span>
            <span className="info-value">{formatFileSize(videoFile.size)}</span>
          </div>
          <div className="info-item">
            <span className="info-label">Format</span>
            <span className="info-value">{videoFile.format.split('/')[1].toUpperCase()}</span>
          </div>
        </div>
      </div>

      {/* Warp Settings */}
      <div className="panel-section">
        <h3 className="section-title">Warp Settings</h3>
        
        <div className="setting-group">
          <label className="setting-label">Global Strength</label>
          <div className="slider-container">
            <input
              type="range"
              min="0"
              max="2"
              step="0.1"
              value={warpSettings.strength}
              className="slider"
              onChange={(e) => onWarpSettingsChange({ 
                ...warpSettings, 
                strength: parseFloat(e.target.value) 
              })}
            />
            <span className="slider-value">{warpSettings.strength.toFixed(1)}×</span>
          </div>
        </div>

        <div className="setting-group">
          <label className="setting-label">Interpolation</label>
          <select
            value={warpSettings.interpolation}
            onChange={(e) => onWarpSettingsChange({ 
              ...warpSettings, 
              interpolation: e.target.value as any 
            })}
            className="setting-select"
          >
            <option value="linear">Linear</option>
            <option value="smooth">Smooth</option>
            <option value="elastic">Elastic</option>
          </select>
        </div>

        <div className="setting-group">
          <label className="setting-checkbox">
            <input
              type="checkbox"
              checked={warpSettings.preserveAspectRatio}
              onChange={(e) => onWarpSettingsChange({ 
                ...warpSettings, 
                preserveAspectRatio: e.target.checked 
              })}
            />
            <span className="checkmark"></span>
            Preserve Aspect Ratio
          </label>
        </div>
      </div>

      {/* Control Points */}
      <div className="panel-section">
        <h3 className="section-title">
          Control Points ({controlPoints.length})
        </h3>
        
        {controlPoints.length === 0 ? (
          <div className="empty-state">
            <p>No control points added yet</p>
            <p className="empty-hint">Click on the video to add points</p>
          </div>
        ) : (
          <div className="points-list">
            {controlPoints.map(point => (
              <motion.div
                key={point.id}
                className={`point-item ${selectedPointId === point.id ? 'selected' : ''}`}
                onClick={() => setSelectedPointId(point.id)}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                <div className="point-info">
                  <div className={`point-indicator ${point.type}`}></div>
                  <div className="point-details">
                    <span className="point-name">
                      {point.type === 'stretch' ? 'Stretch' : 'Anchor'} Point
                    </span>
                    <span className="point-coords">
                      {Math.round(point.x * 100)}%, {Math.round(point.y * 100)}%
                    </span>
                  </div>
                </div>
                {point.locked && (
                  <div className="lock-icon">🔒</div>
                )}
              </motion.div>
            ))}
          </div>
        )}

        {selectedPoint && (
          <div className="point-editor">
            <h4>Edit Point</h4>
            
            <div className="setting-group">
              <label className="setting-label">Strength</label>
              <div className="slider-container">
                <input
                  type="range"
                  min="0"
                  max="2"
                  step="0.1"
                  value={selectedPoint.strength}
                  className="slider"
                  onChange={(e) => {
                    const updatedPoints = controlPoints.map(p =>
                      p.id === selectedPoint.id 
                        ? { ...p, strength: parseFloat(e.target.value) }
                        : p
                    );
                    onControlPointsChange(updatedPoints);
                  }}
                />
                <span className="slider-value">{selectedPoint.strength.toFixed(1)}×</span>
              </div>
            </div>

            <div className="setting-group">
              <label className="setting-label">Radius</label>
              <div className="slider-container">
                <input
                  type="range"
                  min="0.05"
                  max="0.5"
                  step="0.05"
                  value={selectedPoint.radius}
                  className="slider"
                  onChange={(e) => {
                    const updatedPoints = controlPoints.map(p =>
                      p.id === selectedPoint.id 
                        ? { ...p, radius: parseFloat(e.target.value) }
                        : p
                    );
                    onControlPointsChange(updatedPoints);
                  }}
                />
                <span className="slider-value">{Math.round(selectedPoint.radius * 100)}%</span>
              </div>
            </div>

            <div className="point-actions">
              <button
                className="action-btn secondary"
                onClick={() => {
                  const updatedPoints = controlPoints.map(p =>
                    p.id === selectedPoint.id 
                      ? { ...p, type: p.type === 'stretch' ? 'anchor' : 'stretch' }
                      : p
                  );
                  onControlPointsChange?.(updatedPoints);
                }}
              >
                Toggle Type
              </button>
              <button
                className="action-btn danger"
                onClick={() => {
                  const updatedPoints = controlPoints.filter(p => p.id !== selectedPoint.id);
                  onControlPointsChange?.(updatedPoints);
                  setSelectedPointId(null);
                }}
              >
                Delete
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Export Settings */}
      <div className="panel-section">
        <h3 className="section-title">Export Settings</h3>
        
        <div className="setting-group">
          <label className="setting-label">Format</label>
          <select
            value={exportSettings.format}
            onChange={(e) => handleExportSettingChange('format', e.target.value)}
            className="setting-select"
          >
            <option value="mp4">MP4</option>
            <option value="mov">MOV</option>
            <option value="webm">WebM</option>
          </select>
        </div>

        <div className="setting-group">
          <label className="setting-label">Quality</label>
          <select
            value={exportSettings.quality}
            onChange={(e) => handleExportSettingChange('quality', e.target.value)}
            className="setting-select"
          >
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>

        <div className="setting-group">
          <label className="setting-checkbox">
            <input
              type="checkbox"
              checked={exportSettings.preserveOriginalQuality}
              onChange={(e) => handleExportSettingChange('preserveOriginalQuality', e.target.checked)}
            />
            <span className="checkmark"></span>
            Preserve Original Quality
          </label>
        </div>

        <button
          className="toggle-advanced"
          onClick={() => setShowAdvanced(!showAdvanced)}
        >
          Advanced Settings {showAdvanced ? '▼' : '▶'}
        </button>

        {showAdvanced && (
          <motion.div
            className="advanced-settings"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
          >
            <div className="setting-group">
              <label className="setting-label">Codec</label>
              <select
                value={exportSettings.codec}
                onChange={(e) => handleExportSettingChange('codec', e.target.value)}
                className="setting-select"
              >
                <option value="h264">H.264</option>
                <option value="h265">H.265</option>
                <option value="vp9">VP9</option>
              </select>
            </div>
          </motion.div>
        )}
      </div>

      {/* Actions */}
      <div className="panel-actions">
        <button
          className="action-btn secondary"
          onClick={onNewVideo}
          disabled={isExporting}
        >
          New Video
        </button>
        
        <button
          className="action-btn primary"
          onClick={onExport}
          disabled={isExporting || controlPoints.length === 0}
        >
          {isExporting ? (
            <span className="export-progress">
              <div className="mini-spinner"></div>
              Exporting...
            </span>
          ) : (
            'Export Video'
          )}
        </button>
      </div>
    </div>
  );
};

export default ExportPanel;