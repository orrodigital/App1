import React, { Component, ReactNode } from 'react';
import { motion } from 'framer-motion';
import './ErrorBoundary.css';

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
  errorInfo?: React.ErrorInfo;
  errorId: string;
}

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
}

class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    
    this.state = {
      hasError: false,
      errorId: this.generateErrorId()
    };
  }

  static getDerivedStateFromError(error: Error): Partial<ErrorBoundaryState> {
    return {
      hasError: true,
      error
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    
    this.setState({
      error,
      errorInfo
    });

    // Call optional error callback
    if (this.props.onError) {
      this.props.onError(error, errorInfo);
    }

    // In production, you would send this to an error reporting service
    this.reportError(error, errorInfo);
  }

  private generateErrorId(): string {
    return `error_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private reportError(error: Error, errorInfo: React.ErrorInfo) {
    const errorReport = {
      id: this.state.errorId,
      timestamp: new Date().toISOString(),
      message: error.message,
      stack: error.stack,
      componentStack: errorInfo.componentStack,
      userAgent: navigator.userAgent,
      url: window.location.href,
      userId: 'anonymous', // Would be actual user ID in production
    };

    // In production, send to error reporting service (Sentry, Bugsnag, etc.)
    console.error('Error Report:', errorReport);
    
    // Store locally for debugging
    try {
      localStorage.setItem(`stretch_video_error_${this.state.errorId}`, JSON.stringify(errorReport));
    } catch (e) {
      console.warn('Failed to store error report locally:', e);
    }
  }

  private handleRetry = () => {
    this.setState({
      hasError: false,
      error: undefined,
      errorInfo: undefined,
      errorId: this.generateErrorId()
    });
  };

  private handleReload = () => {
    window.location.reload();
  };

  private downloadErrorReport = () => {
    if (!this.state.error || !this.state.errorInfo) return;

    const errorReport = {
      id: this.state.errorId,
      timestamp: new Date().toISOString(),
      error: {
        message: this.state.error.message,
        stack: this.state.error.stack,
        name: this.state.error.name
      },
      componentStack: this.state.errorInfo.componentStack,
      browser: {
        userAgent: navigator.userAgent,
        language: navigator.language,
        platform: navigator.platform,
        cookieEnabled: navigator.cookieEnabled
      },
      page: {
        url: window.location.href,
        referrer: document.referrer,
        title: document.title
      },
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight,
        devicePixelRatio: window.devicePixelRatio
      }
    };

    const blob = new Blob([JSON.stringify(errorReport, null, 2)], {
      type: 'application/json'
    });
    
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `stretch-video-error-${this.state.errorId}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  render() {
    if (this.state.hasError) {
      // Use custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Default error UI
      return (
        <div className="error-boundary">
          <motion.div
            className="error-container"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.3 }}
          >
            <div className="error-header">
              <div className="error-icon">⚠️</div>
              <h1 className="error-title">Oops! Something went wrong</h1>
              <p className="error-subtitle">
                We encountered an unexpected error while processing your video.
              </p>
            </div>

            <div className="error-details">
              <details className="error-accordion">
                <summary>Technical Details</summary>
                <div className="error-info">
                  <div className="error-section">
                    <h3>Error Message</h3>
                    <code className="error-message">
                      {this.state.error?.message || 'Unknown error'}
                    </code>
                  </div>
                  
                  <div className="error-section">
                    <h3>Error ID</h3>
                    <code className="error-id">{this.state.errorId}</code>
                  </div>

                  {process.env.NODE_ENV === 'development' && this.state.error?.stack && (
                    <div className="error-section">
                      <h3>Stack Trace</h3>
                      <pre className="error-stack">
                        {this.state.error.stack}
                      </pre>
                    </div>
                  )}
                </div>
              </details>
            </div>

            <div className="error-suggestions">
              <h3>What can you try?</h3>
              <ul className="suggestions-list">
                <li>Check if your video file is in a supported format (MP4, MOV, WebM)</li>
                <li>Try with a smaller video file (under 500MB)</li>
                <li>Clear your browser cache and refresh the page</li>
                <li>Try using a different browser or device</li>
                <li>Check your internet connection</li>
              </ul>
            </div>

            <div className="error-actions">
              <button 
                className="action-button primary"
                onClick={this.handleRetry}
              >
                Try Again
              </button>
              
              <button 
                className="action-button secondary"
                onClick={this.handleReload}
              >
                Reload Page
              </button>
              
              <button 
                className="action-button tertiary"
                onClick={this.downloadErrorReport}
              >
                Download Error Report
              </button>
            </div>

            <div className="error-footer">
              <p>
                If this problem persists, please contact support with the error ID above.
              </p>
              <div className="support-links">
                <a href="mailto:support@stretchvideo.com" className="support-link">
                  📧 Email Support
                </a>
                <a href="https://github.com/stretchvideo/issues" className="support-link">
                  🐛 Report Bug
                </a>
              </div>
            </div>
          </motion.div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;

// Higher-order component for easier usage
export function withErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  errorBoundaryProps?: Omit<ErrorBoundaryProps, 'children'>
) {
  return function WrappedComponent(props: P) {
    return (
      <ErrorBoundary {...errorBoundaryProps}>
        <Component {...props} />
      </ErrorBoundary>
    );
  };
}

// Hook for error reporting in functional components
export function useErrorHandler() {
  return React.useCallback((error: Error, errorInfo?: any) => {
    console.error('Error caught by useErrorHandler:', error, errorInfo);
    
    // In production, send to error reporting service
    const errorReport = {
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      additional: errorInfo
    };
    
    console.error('Error Report:', errorReport);
  }, []);
}