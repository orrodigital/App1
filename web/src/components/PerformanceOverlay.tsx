import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import PerformanceMonitor from '../utils/PerformanceMonitor';
import './PerformanceOverlay.css';

interface PerformanceOverlayProps {
  performanceMonitor: PerformanceMonitor;
  isVisible?: boolean;
}

const PerformanceOverlay: React.FC<PerformanceOverlayProps> = ({
  performanceMonitor,
  isVisible = false
}) => {
  const [metrics, setMetrics] = useState(performanceMonitor.getMetrics());
  const [isExpanded, setIsExpanded] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);

  useEffect(() => {
    if (!isVisible) return;

    const interval = setInterval(() => {
      const newMetrics = performanceMonitor.getMetrics();
      setMetrics(newMetrics);
      setSuggestions(performanceMonitor.getOptimizationSuggestions());
    }, 1000);

    return () => clearInterval(interval);
  }, [performanceMonitor, isVisible]);

  if (!isVisible) return null;

  const grade = performanceMonitor.getPerformanceGrade();
  const gradeColor = {
    excellent: '#34C759',
    good: '#30D158',
    fair: '#FF9F0A',
    poor: '#FF3B30'
  }[grade];

  return (
    <AnimatePresence>
      <motion.div
        className="performance-overlay"
        initial={{ opacity: 0, x: 300 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: 300 }}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      >
        {/* Compact View */}
        <div className="performance-header" onClick={() => setIsExpanded(!isExpanded)}>
          <div className="performance-indicator">
            <div 
              className="performance-dot"
              style={{ backgroundColor: gradeColor }}
            />
            <span className="performance-fps">
              {metrics.frameRate.toFixed(0)} FPS
            </span>
          </div>
          
          <button className="expand-button">
            <motion.div
              animate={{ rotate: isExpanded ? 180 : 0 }}
              transition={{ duration: 0.2 }}
            >
              ▼
            </motion.div>
          </button>
        </div>

        {/* Expanded View */}
        <AnimatePresence>
          {isExpanded && (
            <motion.div
              className="performance-details"
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.3 }}
            >
              {/* Metrics Grid */}
              <div className="metrics-grid">
                <MetricCard
                  label="Frame Rate"
                  value={`${metrics.frameRate.toFixed(1)} FPS`}
                  status={metrics.frameRate >= 55 ? 'good' : metrics.frameRate >= 30 ? 'warning' : 'error'}
                  icon="⚡"
                />
                
                <MetricCard
                  label="Render Time"
                  value={`${metrics.renderTime.toFixed(1)}ms`}
                  status={metrics.renderTime <= 16 ? 'good' : metrics.renderTime <= 33 ? 'warning' : 'error'}
                  icon="⏱️"
                />
                
                <MetricCard
                  label="Memory"
                  value={`${metrics.memoryUsage.toFixed(0)}MB`}
                  status={metrics.memoryUsage <= 200 ? 'good' : metrics.memoryUsage <= 400 ? 'warning' : 'error'}
                  icon="💾"
                />
                
                <MetricCard
                  label="GPU Usage"
                  value={`${metrics.gpuUtilization.toFixed(0)}%`}
                  status={metrics.gpuUtilization <= 70 ? 'good' : metrics.gpuUtilization <= 85 ? 'warning' : 'error'}
                  icon="🎮"
                />
              </div>

              {/* Performance Grade */}
              <div className="performance-grade">
                <span className="grade-label">Performance:</span>
                <span 
                  className="grade-value"
                  style={{ color: gradeColor }}
                >
                  {grade.charAt(0).toUpperCase() + grade.slice(1)}
                </span>
              </div>

              {/* Optimization Suggestions */}
              {suggestions.length > 0 && (
                <div className="suggestions-section">
                  <h4 className="suggestions-title">💡 Optimization Tips</h4>
                  <ul className="suggestions-list">
                    {suggestions.map((suggestion, index) => (
                      <motion.li
                        key={index}
                        className="suggestion-item"
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.1 }}
                      >
                        {suggestion}
                      </motion.li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Actions */}
              <div className="performance-actions">
                <button
                  className="action-button secondary"
                  onClick={() => performanceMonitor.reset()}
                >
                  Reset
                </button>
                
                <button
                  className="action-button primary"
                  onClick={() => {
                    const data = performanceMonitor.exportData();
                    const blob = new Blob([JSON.stringify(data, null, 2)], { 
                      type: 'application/json' 
                    });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = 'stretch-video-performance.json';
                    a.click();
                    URL.revokeObjectURL(url);
                  }}
                >
                  Export Data
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </AnimatePresence>
  );
};

interface MetricCardProps {
  label: string;
  value: string;
  status: 'good' | 'warning' | 'error';
  icon: string;
}

const MetricCard: React.FC<MetricCardProps> = ({ label, value, status, icon }) => {
  const statusColor = {
    good: '#34C759',
    warning: '#FF9F0A',
    error: '#FF3B30'
  }[status];

  return (
    <div className="metric-card">
      <div className="metric-header">
        <span className="metric-icon">{icon}</span>
        <span className="metric-label">{label}</span>
      </div>
      <div className="metric-value" style={{ color: statusColor }}>
        {value}
      </div>
      <div 
        className="metric-indicator"
        style={{ backgroundColor: statusColor }}
      />
    </div>
  );
};

export default PerformanceOverlay;