import { Component } from 'react';

/**
 * Catches unhandled render errors in the subtree and shows a fallback UI
 * instead of crashing the whole app. Wrap your route tree or any section
 * you want isolated.
 */
export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    // In a real app, send to an error-tracking service (Sentry, etc.)
    console.error('Uncaught render error:', error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center p-8">
          <div className="text-center max-w-md">
            <h2 className="text-xl font-semibold mb-2 text-text">Something went wrong</h2>
            <p className="text-sm text-text-muted mb-4 font-mono">
              {this.state.error?.message}
            </p>
            <button
              className="px-4 py-2 rounded bg-primary text-white text-sm hover:opacity-90"
              onClick={() => this.setState({ hasError: false, error: null })}
            >
              Try again
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}
