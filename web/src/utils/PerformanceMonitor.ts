/**
 * Performance Monitor for Stretch Video
 * Tracks rendering performance and memory usage for optimization
 */

interface PerformanceMetrics {
  frameRate: number;
  renderTime: number;
  memoryUsage: number;
  gpuUtilization: number;
  lastUpdate: number;
}

class PerformanceMonitor {
  private metrics: PerformanceMetrics = {
    frameRate: 0,
    renderTime: 0,
    memoryUsage: 0,
    gpuUtilization: 0,
    lastUpdate: 0
  };

  private frameCount = 0;
  private lastFrameTime = 0;
  private renderStartTime = 0;
  private isMonitoring = false;

  constructor() {
    this.startMonitoring();
  }

  startMonitoring(): void {
    if (this.isMonitoring) return;
    
    this.isMonitoring = true;
    this.lastFrameTime = performance.now();
    this.updateMetrics();
  }

  stopMonitoring(): void {
    this.isMonitoring = false;
  }

  startRenderTimer(): void {
    this.renderStartTime = performance.now();
  }

  endRenderTimer(): void {
    if (this.renderStartTime > 0) {
      this.metrics.renderTime = performance.now() - this.renderStartTime;
      this.renderStartTime = 0;
    }
  }

  recordFrame(): void {
    if (!this.isMonitoring) return;

    this.frameCount++;
    const currentTime = performance.now();
    const deltaTime = currentTime - this.lastFrameTime;
    
    // Calculate frame rate (smoothed)
    const instantFPS = 1000 / deltaTime;
    this.metrics.frameRate = this.smoothValue(this.metrics.frameRate, instantFPS, 0.1);
    
    this.lastFrameTime = currentTime;
  }

  private updateMetrics(): void {
    if (!this.isMonitoring) return;

    // Update memory usage
    if ('memory' in performance) {
      const memInfo = (performance as any).memory;
      this.metrics.memoryUsage = memInfo.usedJSHeapSize / 1024 / 1024; // MB
    }

    // Update GPU utilization (WebGL context loss detection)
    this.metrics.gpuUtilization = this.estimateGPUUtilization();
    
    this.metrics.lastUpdate = performance.now();

    // Continue monitoring
    if (this.isMonitoring) {
      requestAnimationFrame(() => this.updateMetrics());
    }
  }

  private estimateGPUUtilization(): number {
    // Simple heuristic based on render time and frame rate
    const targetFrameTime = 1000 / 60; // 60 FPS
    const utilization = Math.min(100, (this.metrics.renderTime / targetFrameTime) * 100);
    return this.smoothValue(this.metrics.gpuUtilization, utilization, 0.05);
  }

  private smoothValue(current: number, target: number, factor: number): number {
    return current + (target - current) * factor;
  }

  getMetrics(): PerformanceMetrics {
    return { ...this.metrics };
  }

  getFormattedMetrics(): string {
    const m = this.metrics;
    return `FPS: ${m.frameRate.toFixed(1)} | Render: ${m.renderTime.toFixed(1)}ms | Memory: ${m.memoryUsage.toFixed(1)}MB | GPU: ${m.gpuUtilization.toFixed(1)}%`;
  }

  // Performance analysis methods
  isPerformanceGood(): boolean {
    return this.metrics.frameRate >= 30 && this.metrics.renderTime <= 16.67; // 60 FPS target
  }

  getPerformanceGrade(): 'excellent' | 'good' | 'fair' | 'poor' {
    const fps = this.metrics.frameRate;
    if (fps >= 55) return 'excellent';
    if (fps >= 45) return 'good';
    if (fps >= 25) return 'fair';
    return 'poor';
  }

  getOptimizationSuggestions(): string[] {
    const suggestions: string[] = [];
    
    if (this.metrics.frameRate < 30) {
      suggestions.push('Consider reducing mesh resolution for better performance');
    }
    
    if (this.metrics.renderTime > 20) {
      suggestions.push('Video processing is taking too long - try reducing quality settings');
    }
    
    if (this.metrics.memoryUsage > 500) {
      suggestions.push('High memory usage detected - consider reloading the page');
    }
    
    if (this.metrics.gpuUtilization > 90) {
      suggestions.push('GPU is at high utilization - disable real-time preview for complex effects');
    }

    return suggestions;
  }

  // Reset metrics
  reset(): void {
    this.frameCount = 0;
    this.metrics = {
      frameRate: 0,
      renderTime: 0,
      memoryUsage: 0,
      gpuUtilization: 0,
      lastUpdate: 0
    };
  }

  // Export performance data for analysis
  exportData(): object {
    return {
      timestamp: new Date().toISOString(),
      metrics: this.getMetrics(),
      grade: this.getPerformanceGrade(),
      suggestions: this.getOptimizationSuggestions(),
      browser: navigator.userAgent,
      platform: navigator.platform
    };
  }
}

export default PerformanceMonitor;